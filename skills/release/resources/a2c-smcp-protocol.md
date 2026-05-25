# Release — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。
> **GitHub**: A2C-SMCP/a2c-smcp-protocol

协议仓库是**纯文档项目**，发布 = 部署多版本文档站点（mkdocs + mike）。有**两个发布目标**，分别走不同机制。

## 发布目标速览

| 目标 | URL | 机制 | 是否自动 |
|------|-----|------|---------|
| GitHub Pages | `https://a2c-smcp.github.io/a2c-smcp-protocol/latest/` | push `main`（含 docs/mkdocs 变更）→ `deploy-pages.yml` 用 mike 构建推 gh-pages | ✅ 自动 |
| 公司服务器 | `https://doc.turingfocus.cn/a2c-smcp/latest/` | 本地 `inv docs.deploy` | ❌ 手动 |

CI **只**部署 GitHub Pages，从不碰公司服务器。

---

## ⚠️ 公司服务器：先选对 mode，再部署

公司服务器 `doc.turingfocus.cn` 位于**中国大陆**，访问 GitHub 不稳定/通常不可达。`inv docs.deploy` 的默认 `--mode=git` 正好踩这个坑——这是发布时最容易出错的点。

**模式选择优先级：**

> **优先 `inv docs.deploy --mode=upload`**：本地 mike 构建 → 打 tar → SFTP 上传 → 远端解压覆盖 + 修正权限，**全程绕开服务器访问 GitHub**。
>
> **仅当确认服务器到 GitHub 网络通畅时**，才退回默认的 `--mode=git`（服务器侧 `git fetch + reset --hard origin/gh-pages`）。

**为什么**：
- `mode=git` SSH 到服务器执行 `git fetch origin gh-pages`，要求**服务器能拉到 GitHub**——对这台大陆服务器多半不成立，会失败或挂起。
- `mode=upload` 在本地构建并打包，只用 SFTP 把产物推上去，服务器无需访问 GitHub。
- 默认值是 `git`（`scripts/docs/tasks.py` 的 `deploy(..., mode="git")`），docstring 虽有提示但默认值仍是坑，发布前务必显式带 `--mode=upload`。

> 单独触发上传（已先跑过 `inv docs.build` 时）：`inv docs.upload-server`。
> 两个目标一起发：`inv docs.deploy-all --mode=upload`。

---

## 前置检查（在通用项之外）

| 检查项 | 方法 |
|--------|------|
| 版本单一来源 | 版本号只在 `pyproject.toml` 的 `version` 改 |
| 版本字符串同步 | 跑 `bump-my-version bump <level>`，自动同步 `docs/index.md`、`docs/specification/index.md`、`docs/specification/versioning.md`、`mkdocs.yml`、`CLAUDE.md` 等 6 处；**不要手改这些文件** |
| tag 已推送 | bump 生成的 `vX.Y.Z` tag 已 `git push origin vX.Y.Z` |
| 各处版本一致 | 上述文件的版本字符串与 `pyproject.toml` 一致 |
| 部署凭证 | SFTP/SSH 凭证已配（`DeployConfig.from_env()`），否则 deploy 会跳过服务器更新 |

> bump 提交会改 `docs/**` 与 `mkdocs.yml`，推送到 `main` 即触发 `deploy-pages.yml`，GitHub Pages 自动更新——无需手动 deploy GitHub 侧。

---

## 发布后验收

1. **GitHub Pages CI 成功**：`gh run list --workflow=deploy-pages.yml --limit 1` conclusion 为 success。
2. **`versions.json` 正确**：gh-pages 分支根的 `versions.json` 含新版本，且 `latest` 别名指向它（mike 维护）。
3. **两个站点都活**：
   - `https://a2c-smcp.github.io/a2c-smcp-protocol/latest/` 返回 200
   - `https://doc.turingfocus.cn/a2c-smcp/latest/` 返回 200
4. **版本展示一致**：页面展示版本与本次 `vX.Y.Z` 一致。

公司服务器站点没更新时，最常见原因就是用了 `mode=git` 而服务器拉不到 GitHub——改用 `--mode=upload` 重发。
