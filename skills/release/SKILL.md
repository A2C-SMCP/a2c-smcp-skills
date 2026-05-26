---
name: release
description: 引导 A2C-SMCP 各项目的版本发布流程——单一来源改版本号 → 打 vX.Y.Z tag → 推送触发 CI 发布 → 发布后验收。覆盖 SDK 包发布（PyPI / crates.io）与协议文档部署（GitHub Pages 自动 + 公司服务器手动）。当需要发布新版本、部署文档站点，或排查发布流程问题时使用。
argument-hint: "[project] [version]"
---

# Release — 跨项目发布流程

A2C-SMCP 各项目的发布共享同一骨架，但发布目标不同（SDK 包 / 文档站点）。本 Skill 引导通用流程，项目差异见 `resources/<project>.md`。

> **核心工作方式**：发布是不可逆的对外动作。每个关键步骤（打 tag、推送、触发部署）执行前必须用 AskUserQuestion 向用户确认；发布后必须做验收检查，不要默认 CI 成功。

---

## 发布骨架（所有项目通用）

```
1. 前置检查  →  2. 版本号管理  →  3. 推送触发发布  →  4. 发布后验收
   工作树干净     单一来源改版本      tag/commit 推送       制品可达 + 版本正确
   版本已更新     bump 生成 tag       CI 自动发布
```

每个项目把上述四步映射到自己的工具链。**动手前先读 `resources/<project>.md`**（当前已文档化：`a2c-smcp-protocol`、`oasp-protocol`）。其他项目暂无 resource 时，先读该仓库的 `.github/workflows/*publish*.yml`、`pyproject.toml` / `Cargo.toml` 确认实际机制，**不要凭经验臆测**。

---

## Step 0：解析参数与项目识别

- **project**（第一个 token）：要发布的仓库名，如 `a2c-smcp-protocol`、`python-sdk`、`rust-sdk`。留空则用 AskUserQuestion 确认当前所在仓库。
- **version**（第二个 token）：目标版本号或 bump 级别（`major`/`minor`/`patch`）。留空则读取项目当前版本，询问用户本次 bump 级别。

确认 `gh` 可用（涉及 CI run / release 查询）。

---

## Step 1：前置检查

发布前必须全部通过，任一不满足则停止并提示用户：

| 检查项 | 方法 |
|--------|------|
| 工作树干净 | `git status --porcelain` 无输出 |
| 在发布分支 | 通常为 `main`，与远端一致（`git fetch` 后无落后） |
| 版本单一来源 | 版本号只在一处定义（Python: `pyproject.toml`；Rust: `Cargo.toml`），其余文件由 bump 工具同步 |
| 测试/CI 绿 | 最近一次主干 CI run 成功（`gh run list`） |
| 变更已记录 | CHANGELOG / release notes 已更新（如项目有此约定） |

项目特有的前置项见 `resources/<project>.md`。

---

## Step 2：版本号管理

目标产物是一个 `vX.Y.Z` git tag（A2C-SMCP 约定 tag 前缀 `v`）。

| 工具 | 项目 | 命令 |
|------|------|------|
| bump-my-version | Python（python-sdk、a2c-smcp-protocol） | `bump-my-version bump <patch\|minor\|major>`，自动改全部版本字符串、commit、打 `v{new}` tag |
| Cargo | Rust（rust-sdk） | 手动改 `Cargo.toml` 版本，commit，`git tag vX.Y.Z` |

> bump-my-version 的 `[tool.bumpversion.files]` 会同步多个文件（含文档里的版本字符串）。**改版本号只跑 bump 工具，不要手改个别文件**，否则单一来源被破坏、各处版本不一致。

执行 bump 前用 AskUserQuestion 与用户确认 bump 级别与最终版本号。

---

## Step 3：推送触发发布

推送 commit 与 tag 是触发 CI 发布的动作，**执行前用 AskUserQuestion 明确确认**。

```bash
git push origin <branch>          # 推送 bump commit
git push origin vX.Y.Z            # 推送 tag
```

各项目 CI 的触发条件与发布目标不同：

| 项目 | 触发 | 发布目标 |
|------|------|---------|
| python-sdk | `publish.yml` | PyPI |
| rust-sdk | GitHub release `published` → `publish.yml` | crates.io |
| a2c-smcp-protocol | push `main`（docs/mkdocs 变更）→ `deploy-pages.yml` | GitHub Pages（自动）；公司服务器需**手动** `inv docs.deploy`，见 resource |
| oasp-protocol | CI `docs.yml` 仅 `workflow_dispatch` 且硬编码 `0.1.0`——**版本化发布走本地** `inv docs.deploy --version=X.Y.Z` | GitHub Pages + 公司服务器；服务器同步用 `inv docs.push-to-server`（tar-over-SSH），见 resource |

> rust-sdk 走 crates.io 时由 GitHub Release 发布触发，可能还需 `gh release create vX.Y.Z`——动手前读该仓库 workflow 确认。
> 文档类项目的版本号未必来自 `pyproject.toml`（如 oasp 由 changelog 顶部驱动），发布前确认版本来源，见 resource。

---

## Step 4：发布后验收

CI 跑完不等于发布成功，必须验收。通用项：

1. **CI run 成功**：`gh run list --workflow=<publish.yml> --limit 1`，确认最近一次 conclusion 为 success。
2. **制品可达**：
   - PyPI：`pip index versions <pkg>` 或访问 PyPI 页面，新版本可见。
   - crates.io：crate 页面新版本可见。
   - 文档站点：目标 URL 的 `/latest/`（或新版本路径）返回 200。
3. **版本一致**：制品/页面展示的版本号与 tag 一致。

项目特有验收项（如文档站点的 `versions.json`、多发布目标）见 `resources/<project>.md`。

---

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 手改个别文件的版本号 | 只跑 bump 工具，保持单一来源同步 |
| 推送 tag 不与用户确认 | 不可逆对外动作前用 AskUserQuestion 确认 |
| 假设 CI 一定成功 | 发布后查 `gh run list` + 验制品可达 |
| 对未文档化项目凭经验臆测 | 先读该仓库的 publish workflow 与版本配置 |
| 文档发布只发 GitHub Pages | 协议仓库公司服务器需手动部署，见 resource |
| 服务器部署任务打印 ✅ 就当成功 | 部分项目 git-pull 同步会静默假报成功，须验服务器实际刷新，见 resource |
