# Learnings

## best_practice | GitHub Actions working-directory 路径陷阱
**Date:** 2026-03-27
**Pattern-Key:** github-actions-working-directory
**Context:** kids-brain-app Flutter APK 构建

**问题：**
workflow 里写了 `working-directory: kids-brain-app`，但仓库根目录本身就是 app，没有子目录。导致 CI 每次都找不到路径，构建失败。反复提交 fix 也没查出根因。

**根因：**
没有检查仓库目录结构就直接假设有子目录层级。

**正确做法：**
修改 workflow 前先确认 `ls` 仓库根目录，确保 `working-directory` 路径真实存在。如果 app 在根目录，直接删掉 `working-directory` 即可，APK 输出路径也要同步修改（去掉前缀）。

**Fix Applied:**
- 删除 `working-directory: kids-brain-app`
- APK path 从 `kids-brain-app/build/...` 改为 `build/...`

**Commit:** 631cef7

---

## best_practice | gh CLI 未安装，无法用命令行查 GitHub Actions 状态
**Date:** 2026-03-27
**Pattern-Key:** gh-cli-not-installed
**Context:** kids-brain-app CI 状态检查

**问题：**
尝试 `gh run list` 查 Actions 状态，但系统没有安装 gh CLI。

**替代方案：**
1. 直接访问 https://github.com/{owner}/{repo}/actions（私有仓库需登录）
2. 用 GitHub API + token：`curl -H 'Authorization: token TOKEN' https://api.github.com/repos/{owner}/{repo}/actions/runs`
3. 让用户自己看 Actions 页面

---
