#!/usr/bin/env bash
# 监控 CPU、内存、磁盘 使用率，超阈值时发送提醒
# 阈值设置（可自行修改）
CPU_TH=80      # percent
MEM_TH=80
DISK_TH=90
NET_TH=1000000   # bytes per second, 示例 1 MB/s
# 获取使用率
cpu=$(top -bn1 | grep "%Cpu(s)" | awk '{print 100 - $8}')
mem=$(free | grep Mem | awk '{print $3/$2 * 100}')
disk=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
# 网络流量（使用 /proc/net/dev 统计所有非 lo 接口的入站+出站速率）
net_bytes=$(awk 'NR>2 {in+=$2; out+=$10} END {print in+out}' /proc/net/dev)
# 计算每秒速率（需要两次采样，间隔 1 秒）
sleep 1
net_bytes2=$(awk 'NR>2{in+=$2; out+=$10} END{print in+out}' /proc/net/dev)
net_rate=$(( net_bytes2 - net_bytes ))
msg=""
if (( ${cpu%.*} > CPU_TH )); then
  msg+="⚠️ CPU 使用率 ${cpu}% 超过阈值 ${CPU_TH}%\n"
fi
if (( ${mem%.*} > MEM_TH )); then
  msg+="⚠️ 内存使用率 ${mem}% 超过阈值 ${MEM_TH}%\n"
fi
if (( disk > DISK_TH )); then
  msg+="⚠️ 磁盘使用率 ${disk}% 超过阈值 ${DISK_TH}%\n"
fi
if [[ -n $msg ]]; then
  # 通过 OpenClaw 系统事件发送提醒
  openclaw gateway cron add --job='{"schedule":{"kind":"once"},"payload":{"kind":"systemEvent","text":"'$msg'"},"sessionTarget":"main","enabled":true}' >/dev/null 2>&1
fi