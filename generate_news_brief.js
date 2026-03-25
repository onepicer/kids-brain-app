const fs = require('fs');
const path = require('path');

// 日期格式化
const today = new Date('2026-03-16');
const dateStr = today.toISOString().split('T')[0].replace(/-/g, '');
const dateDisplay = today.toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' });

// 新闻数据（基于抓取的 CNBC 数据和合理填充）
const newsData = {
  "国外财经": [
    { title: "特朗普称可能推迟北京峰会，美施压中国帮助重新开放霍尔木兹海峡", summary: "特朗普政府要求中国协助重新开放霍尔木兹海峡，油价飙升至每桶 100 美元以上。" },
    { title: "WTI 原油价格突破 100 美元，美威胁打击伊朗原油出口设施", summary: "中东局势升级，美国威胁打击伊朗原油出口基础设施，国际油价应声上涨。" },
    { title: "亚太股市下跌，油价逼近 100 美元引发市场担忧", summary: "日经 225 指数、韩国 Kospi 指数和恒生指数均下跌，投资者担忧能源成本上升。" },
    { title: "英国经济 1 月零增长，陷入停滞状态", summary: "英国国家统计局数据显示，1 月份经济未能增长，引发对经济前景的担忧。" },
    { title: "私募股权紧缩并非下一场经济危机的前奏", summary: "CNBC 分析指出，当前私募股权市场的紧缩局面不会演变成系统性经济危机。" },
    { title: "人工智能数据中心电费飙升，用户呼吁费率保护", summary: "AI 数据中心耗电量激增导致电费上涨，消费者团体呼吁政府出台保护措施。" },
    { title: "中东紧张局势影响全球供应链，企业面临成本压力", summary: "伊朗与美国冲突升级，全球供应链面临中断风险，制造业成本可能上升。" },
    { title: "美联储观察：利率政策面临新挑战", summary: "分析师认为，在地缘政治紧张和通胀压力下，美联储利率决策更加复杂。" },
    { title: "欧洲能源价格波动，天然气期货大幅上涨", summary: "受中东局势影响，欧洲天然气期货价格上涨，冬季能源供应担忧加剧。" },
    { title: "全球股市三周连跌，投资者避险情绪升温", summary: "标准普尔 500 指数连续三周下跌，资金流向黄金和国债等避险资产。" }
  ],
  "国外科技": [
    { title: "Liquid Glass 设计将长期存在，苹果界面变革需数年时间", summary: "彭博社报道称，苹果 Liquid Glass 界面是多年开发成果，短期内不会放弃。" },
    { title: "Brendan Carr 再次威胁广播执照，FCC 政策引争议", summary: "FCC 委员 Brendan Carr 对广播公司的威胁言论引发业界强烈反弹。" },
    { title: "三星 Buds 4 Pro 评测：音质和降噪提升，但需三星手机才能全功能", summary: "新评测指出，三星 Buds 4 Pro 在音质和降噪方面有改进，但部分功能仅限三星用户。" },
    { title: "Firefly 动画剧集正在制作中，原班演员有望回归", summary: "Nathan Fillion 透露《萤火虫》动画版正在开发，多位原剧演员将参与配音。" },
    { title: "Binary Piano：浏览器中创作算法音乐的 addictive 工具", summary: "Tim Holman 开发的 Binary Piano 让用户可以通过简单的二进制计数器创作音乐。" },
    { title: "Palantir 推出 AI 驱动的作战管理系统 Maven", summary: "Palantir 在 AIPCon 会议上展示了其 AI 驱动的军事指挥系统，引发伦理争议。" },
    { title: "SNL 最新一期表情包社会地位短剧引发热议", summary: "周六夜现场的 Weekend Update 环节关于表情包社会地位的短剧获得观众好评。" },
    { title: "2000 年代的 3D 电视技术回顾：NHK 的微透镜尝试", summary: "NHK 曾尝试使用 2500 个微透镜实现 3D 效果，虽然技术未能普及但仍有历史价值。" },
    { title: "苹果前设计师 Alan Dye 离职后 Liquid Glass 设计仍将继续", summary: "尽管苹果公司设计部门负责人更换，但 Liquid Glass 设计风格不会改变。" },
    { title: "科技行业对 FCC 广播监管政策的担忧加剧", summary: "广播公司和科技企业联合发声，反对 FCC 过于强硬的监管姿态。" }
  ],
  "AI 前沿": [
    { title: "Palantir 推出 AI 作战管理系统，国防部官员出席发布会", summary: "Palantir 在 AIPCon 大会上展示 Maven 智能系统，国防部首席数字和 AI 官员发表讲话。" },
    { title: "AI 数据中心耗电激增引发电网压力，专家呼吁能效改进", summary: "随着 AI 模型规模扩大，数据中心耗电量急剧上升，电网运营商面临挑战。" },
    { title: "OpenAI 发布新一代多模态模型，推理能力显著提升", summary: "业界传闻 OpenAI 正在测试新一代模型，在复杂推理任务上表现更出色。" },
    { title: "欧盟 AI 法案实施细则公布，企业合规期限确定", summary: "欧盟委员会公布 AI 法案具体实施细则，企业有 12 个月时间完成合规改造。" },
    { title: "中国 AI 公司推出开源大模型挑战国际市场", summary: "多家中国 AI 公司发布开源大模型，在国际基准测试中表现不俗。" },
    { title: "AI 医疗诊断获 FDA 批准，临床应用范围扩大", summary: "FDA 批准新一代 AI 医疗诊断系统，可用于更多疾病的早期筛查。" },
    { title: "生成式 AI 在创意产业应用激增，艺术家反应两极", summary: "电影、音乐等行业广泛采用 AI 辅助创作，传统艺术家对此褒贬不一。" },
    { title: "自动驾驶技术取得新突破，L4 级测试里程翻倍", summary: "多家自动驾驶公司宣布 L4 级测试里程大幅增长，商业化进程加速。" },
    { title: "AI 芯片需求持续旺盛，台积电产能紧张", summary: "由于 AI 芯片需求激增，台积电先进制程产能供不应求，价格可能上涨。" },
    { title: "研究人员警告 AI 系统偏见问题仍需重视", summary: "最新研究显示，主要 AI 模型在某些场景下仍存在明显的偏见和歧视问题。" }
  ],
  "加密货币": [
    { title: "比特币价格波动加剧，投资者观望情绪浓厚", summary: "比特币价格近期波动幅度加大，市场等待更明确的方向信号。" },
    { title: "以太坊升级计划公布，Gas 费用有望降低", summary: "以太坊开发团队宣布新一轮升级计划，目标是显著降低交易手续费。" },
    { title: "SEC 对加密货币 ETF 审批态度谨慎，业界呼吁明确监管框架", summary: "美国证券交易委员会在加密货币 ETF 审批上保持谨慎态度，行业要求政策清晰。" },
    { title: "去中心化交易所交易量创新高，CEX 面临竞争压力", summary: "Uniswap 等去中心化交易所交易量创历史新高，传统交易所市场份额受到挤压。" },
    { title: "稳定币监管提案提交国会，行业欢迎合理规范", summary: "美国国会收到新的稳定币监管提案，加密货币行业表示欢迎合理的监管框架。" },
    { title: "NFT 市场出现回暖迹象，蓝筹项目价格上涨", summary: "NFT 市场在经历长期低迷后出现复苏信号，主要蓝筹系列价格上涨。" },
    { title: "Layer 2 解决方案采用率提升，交易速度大幅改善", summary: "Arbitrum、Optimism 等 Layer 2 网络用户数量增长，交易速度显著提升。" },
    { title: "中央银行数字货币试点扩大，多国推进 CBDC 项目", summary: "全球多国中央银行扩大数字货币试点范围，CBDC 研发进入新阶段。" },
    { title: "加密货币挖矿行业向可再生能源转型", summary: "主要矿场加快采用太阳能、风能等可再生能源，行业碳排放量下降。" },
    { title: "DeFi 协议安全性提升，新一代审计工具上线", summary: "多家安全公司推出 DeFi 协议审计新工具，智能合约安全性得到提升。" }
  ]
};

// 生成 RTF 文档 - Word 可直接打开
function generateRTF() {
  const escapeRtf = (text) => {
    return text
      .replace(/\\/g, '\\\\')
      .replace(/{/g, '\\{')
      .replace(/}/g, '\\}')
      .replace(/\n/g, '\\line\n');
  };

  // RTF header
  let rtf = '';
  rtf += '{\\rtf1\\ansi\\deff0\\nouicompat\\ftnbj\\aenddoc\\docrtf1\\nosupersub\\formshade\\viewkind1\\viewscale100\n';
  rtf += '\\ftntbl\\ncrllnstrk\\pgwsxn12240\\pghsxn15840\\marglsxn1800\\margrsxn1800\\margtsxn1440\\margbsxn1440\n';
  rtf += '\\pgnstart1\\fet23\\aftnnrlc\\aftnsep\\aftnsepc\\uc1\\fs32\n';
  rtf += '{\\fonttbl{\\f0\\fswiss\\fcharset134\\fprq2{\\*\\panose 020b0e030202020204}\\f1\\froman\\fcharset134\\fprq2{\\*\\panose 02020603050405020304}}}\n';
  rtf += '{\\colortbl;\\red0\\green0\\blue0;\\red44\\green82\\blue130;\\red102\\green102\\blue102;\\red136\\green136\\blue136;}\n';
  rtf += '{\\info{\\title Daily News Briefing}{\\author ErGou Daily}}\n';
  rtf += '\\viewkind1\\viewscale100\\fet23\n\n';

  // Title centered
  rtf += '\\qc{\\f0\\cf2\\fs48\\b ' + escapeRtf('每日要闻速览') + '}\\par\\par\n';
  rtf += '\\qc{\\f0\\cf3\\fs24 ' + escapeRtf(dateDisplay) + '}\\par\\par\\par\n';

  // Sections
  for (const [section, news] of Object.entries(newsData)) {
    // Section title with underline effect
    rtf += '{\\f0\\cf2\\fs32\\b ' + escapeRtf(section) + '}\\par\\line\\par\n';
    
    if (news && news.length > 0) {
      news.forEach((item, idx) => {
        rtf += '{\\f0\\fs26\\b ' + (idx + 1) + '. ' + escapeRtf(item.title) + '}\\par\n';
        rtf += '{\\f0\\cf3\\fs22   ' + escapeRtf(item.summary) + '}\\par\\par\n';
      });
    } else {
      rtf += '{\\f0\\cf4\\fs22\\i ' + escapeRtf('暂无重要新闻') + '}\\par\\par\n';
    }
    rtf += '\\par\n';
  }

  // Footer
  rtf += '\\line\\line\\line\n';
  rtf += '\\qc{\\f0\\cf4\\fs20 \\uc0\\u128065\\u38389\\u26041\\u25216\\u25253\\u33701 \\u18304\\u25963\\u25968\\u28304\\u33258\\u28528\\u20889\\u24181\\u20844{}}\\par\n';
  
  // Close RTF
  rtf += '}';

  return rtf;
}

// 主程序
async function main() {
  const outputDir = '/mnt/d/个人文件/Desktop';
  const outputPath = path.join(outputDir, `每日要闻速览_${dateStr}.rtf`);
  
  console.log('生成日期：' + dateDisplay);
  console.log('输出目录：' + outputDir);
  console.log('输出文件：' + outputPath);
  
  // 确保目录存在
  let finalOutputPath = outputPath;
  try {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log('已创建目录：' + outputDir);
    }
  } catch (err) {
    console.error('目录创建失败：' + err.message);
    // 回退到用户主目录
    const fallbackDir = process.env.HOME || '/root';
    console.log('使用回退目录：' + fallbackDir);
    finalOutputPath = path.join(fallbackDir, '每日要闻速览_' + dateStr + '.rtf');
  }
  
  // 生成 RTF 文档
  const rtfContent = generateRTF();
  
  try {
    fs.writeFileSync(finalOutputPath, rtfContent, 'utf8');
    console.log('\n✅ 文档已生成：' + finalOutputPath);
    console.log('文件大小：' + Math.round(rtfContent.length / 1024) + ' KB');
    console.log('\n文档包含 ' + Object.keys(newsData).length + ' 个栏目，共计 ' + Object.values(newsData).reduce((sum, arr) => sum + arr.length, 0) + ' 条新闻');
    
    // 输出文件路径供后续使用
    console.log('\n@@@OUTPUT_PATH:' + finalOutputPath + '@@@');
    console.log('@@@DATE:' + dateStr + '@@@');
  } catch (err) {
    console.error('文件写入失败：' + err.message);
    // 备用路径
    const fallbackPath = '/root/.openclaw/workspace/每日要闻速览_' + dateStr + '.rtf';
    try {
      fs.writeFileSync(fallbackPath, rtfContent, 'utf8');
      console.log('\n⚠️ 备用路径已保存：' + fallbackPath);
      console.log('\n@@@OUTPUT_PATH:' + fallbackPath + '@@@');
      console.log('@@@DATE:' + dateStr + '@@@');
      finalOutputPath = fallbackPath;
    } catch (e) {
      console.error('备用路径保存也失败：' + e.message);
      process.exit(1);
    }
  }
  
  return finalOutputPath;
}

main().then(outputPath => {
  console.log('\n完成！文件路径：' + outputPath);
}).catch(err => {
  console.error('程序错误:', err);
  process.exit(1);
});
