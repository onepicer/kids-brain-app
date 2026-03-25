# RackNerd VPS 部署指南

> 系统：Ubuntu 22.04 | 位置：美国（RackNerd）| 目标：梯子 + OpenClaw

---

## 一、VPS 基础优化（降低延迟的关键）

### 1.1 系统更新

```bash
apt update && apt upgrade -y
apt install -y curl wget nano ufw unzip
```

### 1.2 开启 BBR（TCP 拥塞控制）

```bash
# 检查当前
sysctl net.ipv4.tcp_congestion_control

# 开启 BBR
cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl -p
# 验证
sysctl net.ipv4.tcp_congestion_control
# 应该输出: net.ipv4.tcp_congestion_control = bbr
```

### 1.3 网络缓冲区优化（减少延迟抖动）

```bash
cat >> /etc/sysctl.conf << 'EOF'
# 网络缓冲优化
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
# 减少 TIME_WAIT
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
# 优化 UDP（Hysteria2 基于 QUIC/UDP）
net.core.rmem_default=1048576
net.core.wmem_default=1048576
EOF

sysctl -p
```

### 1.4 防火墙基础配置

```bash
ufw allow 22/tcp     # SSH
ufw allow 443/udp    # Hysteria2（默认端口）
ufw allow 80/tcp     # 可选
ufw enable
```

---

## 二、Hysteria2 部署

> 选择 Hysteria2 的原因：
> - 基于 QUIC（UDP），比 TCP 协议延迟更低
> - 内置 Brutal 拥塞控制，针对高丢包网络优化
> - 端口跳跃功能，对抗 QoS 限速
> - Android / PC 客户端齐全

### 2.1 安装 Hysteria2

```bash
# 一键安装
bash <(curl -fsSL https://get.hy2.sh/)
```

### 2.2 生成自签证书

```bash
# 安装 openssl
apt install -y openssl

# 生成证书（用自己的域名或随便填一个）
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=localhost" -days 36500
```

### 2.3 配置服务端

```bash
cat > /etc/hysteria/config.yaml << 'EOF'
# Hysteria2 服务端配置

listen: :443

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: 替换为你的强密码  # 至少16位随机字符串

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true

# 端口跳跃（多端口，对抗运营商 QoS 限速）
ports:
  - 443
  - 8443
  - 9443

# 速度设置
bandwidth:
  up: 100 mbps    # VPS 实际上行带宽，填实际值
  down: 500 mbps  # VPS 实际下行带宽，填实际值

# 忽略客户端带宽设置（服务端控制）
ignoreClientBandwidth: false
EOF
```

> **带宽说明**：`up/down` 填 VPS 的实际带宽能力（可看 RackNerd 面板或用 `speedtest-cli` 测）。这会影响 Brutal 拥塞控制的效果，填准了延迟更稳。

### 2.4 启动服务

```bash
systemctl enable hysteria-server
systemctl start hysteria-server

# 查看状态
systemctl status hysteria-server

# 防火墙放行端口跳跃端口
ufw allow 8443/udp
ufw allow 9443/udp
```

### 2.5 客户端配置

#### Android 客户端
1. 下载：[Hysteria2 Android](https://github.com/apernet/hysteria/releases) 或 Google Play 搜索 "Hysteria"
2. 配置：
```yaml
server: 你的VPS_IP:443
auth: 替换为你的强密码
tls:
  sni: bing.com
  insecure: true
bandwidth:
  up: 30 mbps     # 你的手机实际上行
  down: 100 mbps  # 你的手机实际下行
fastOpen: true
socks5:
  listen: 127.0.0.1:1080
http:
  listen: 127.0.0.1:8080
ports:
  - 443
  - 8443
  - 9443
```

#### PC 客户端（Windows）
1. 下载：[Hysteria2 Windows](https://github.com/apernet/hysteria/releases)
2. 配置文件 `config.yaml`：
```yaml
server: 你的VPS_IP:443
auth: 替换为你的强密码
tls:
  sni: bing.com
  insecure: true
bandwidth:
  up: 30 mbps
  down: 200 mbps
fastOpen: true
socks5:
  listen: 127.0.0.1:1080
http:
  listen: 127.0.0.1:8080
ports:
  - 443
  - 8443
  - 9443
```
3. 运行：`hysteria-windows-amd64 -c config.yaml`
4. 浏览器设置代理 `127.0.0.1:8080`（HTTP）或用系统代理

#### Clash / Clash Verge 用户（替代方案）
如果习惯用 Clash 客户端，Hysteria2 可以通过 [Clash.Meta (mihomo)] 内核支持：
```yaml
proxies:
  - name: hysteria2-vps
    type: hysteria2
    server: 你的VPS_IP
    port: 443
    password: 替换为你的强密码
    sni: bing.com
    skip-cert-verify: true
    up: 30
    down: 200
    ports: 443,8443,9443
```

---

## 三、OpenClaw 部署

### 3.1 安装 Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node -v  # 确认 v22.x
```

### 3.2 安装 OpenClaw

```bash
npm install -g openclaw
openclaw --version
```

### 3.3 初始化配置

```bash
openclaw setup
# 按提示配置：
# - 模型提供商（填 Z.AI API Key）
# - Telegram Bot Token（如需远程通知）
# - 其他按需
```

### 3.4 设置 systemd 服务（开机自启）

```bash
cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw
systemctl start openclaw
systemctl status openclaw
```

### 3.5 配置 Tailscale（可选，远程管理）

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
# 按提示在浏览器中登录授权
```

---

## 四、延迟优化专项

### 4.1 确认 VPS 带宽（重要！）

```bash
apt install -y speedtest-cli
speedtest-cli --simple
# 记录 Download 和 Upload 的实际值
# 回到 2.3 填入 bandwidth.up / bandwidth.down
```

### 4.2 客户端带宽也要填准

- **手机**：上行一般 10-30 Mbps，下行 50-200 Mbps（看你的运营商套餐）
- **电脑**：上行一般 30-100 Mbps，下行 100-500 Mbps

> 💡 **带宽参数是延迟优化的核心**：Hysteria2 的 Brutal 模式根据带宽值来决定发送速率。填得太高会拥塞丢包反而更慢，填得太低跑不满。建议填实际值的 **80%**。

### 4.3 端口跳跃对抗 QoS

很多运营商会对 UDP 443 端口限速。端口跳跃让流量分散到多个端口，有效规避：

```yaml
# 客户端和服务端都要填相同的端口列表
ports:
  - 443
  - 8443
  - 9443
```

### 4.4 DNS 优化

推荐在客户端或路由器层面配置：
- 国内域名走本地 DNS（114.114.114.114 或 223.5.5.5）
- 国外域名走 DoH（1.1.1.1 或 8.8.8.8）

Clash 用户可以在配置中设置 split-dns。

### 4.5 如果还是不满意

- 检查 VPS 到国内的物理线路（RackNerd 一般是洛杉矶/圣何塞机房，走太平洋海底光缆）
- 考虑换 CN2 GIA / CMIN2 线路的 VPS（延迟可能降到 120-150ms，但价格贵不少）
- Cloudflare CDN 中转会增加延迟，不推荐用于延迟敏感场景

---

## 五、维护命令速查

```bash
# Hysteria2
systemctl status hysteria-server
journalctl -u hysteria-server -f    # 实时日志
hysteria version                     # 版本

# OpenClaw
systemctl status openclaw
journalctl -u openclaw -f           # 实时日志
openclaw status                      # 状态
openclaw channels status             # 渠道状态

# 网络
ping 你的VPS_IP                      # 测延迟
speedtest-cli --simple               # 测带宽
ufw status                           # 防火墙
```

---

## 六、安全提醒

- [x] 修改 SSH 默认端口（建议改成非 22）
- [x] 禁用密码登录，只用 SSH 密钥
- [x] Hysteria2 密码用 16 位以上随机字符串
- [x] UFW 防火墙只开必要端口
- [x] 定期 `apt update && apt upgrade`

### SSH 加固

```bash
# 生成密钥（本地操作）
ssh-keygen -t ed25519

# 上传到 VPS
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@你的VPS_IP

# 禁用密码登录
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 改端口（可选）
sed -i 's/#Port 22/Port 52222/' /etc/ssh/sshd_config

systemctl restart sshd
# 记得 ufw allow 52222/tcp
```

---

*最后更新：2026-03-21*
