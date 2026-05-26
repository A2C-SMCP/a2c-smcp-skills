# Release — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。
> **GitHub**: A2C-SMCP/oasp-protocol

OASP 是**纯文档项目**，发布 = 部署多版本文档（mkdocs + mike）到两个目标：GitHub Pages + 公司服务器 `doc.turingfocus.cn/oasp`。

## 发布目标速览

| 目标 | URL | 机制 | 是否自动 |
|------|-----|------|---------|
| GitHub Pages | `https://a2c-smcp.github.io/oasp-protocol/latest/` | 本地 `inv docs.deploy`（mike push）。CI `docs.yml` 仅 `workflow_dispatch` 且**硬编码 0.1.0**，不能做版本化发布 | ❌ 走本地 |
| 公司服务器 | `https://doc.turingfocus.cn/oasp/latest/` | 本地 `inv docs.deploy`（默认 tar 同步）或单独 `inv docs.push-to-server` | ❌ 手动 |

> CI 不做版本化发布（硬编码 0.1.0），**所有版本化发布都在本地执行**。

---

## ⚠️ 公司服务器：禁用 git-pull 模式，它会静默假报成功

服务器目录 `/var/www/doc.turingfocus.cn/oasp` **不是 git 仓库**，且国内服务器连 GitHub 不稳。`inv docs.update-server` / `inv docs.deploy --sync-via=git` 在服务器执行 `git fetch + reset --hard origin/gh-pages`，对这台服务器**必然失败**——而且：

> **致命点：失败时仍打印 `✅ 更新完成`（假成功）。** `update_server()` 把错误降级为 warning 并正常返回，外层 task 无条件打印成功。对外站根本没刷新，却极易误判"发布成功"。（已核对 `scripts/docs/tasks.py`）

**正确做法——始终用 tar-over-SSH 上传模式：**

> **`inv docs.push-to-server`**：本地 `git archive gh-pages | ssh | tar -xpf` → staging 解压 → **原子 `mv` 替换** + 失败回滚，全程绕开服务器访问 GitHub，并回读服务器 `versions.json` / `latest` 软链做校验。
>
> `inv docs.deploy --version=X.Y.Z` 的默认 `sync_via="tar"` 即走此模式；无需也**不要**显式传 `--sync-via=git`。

---

## ⚠️ 部署务必显式传 `--version`

`inv docs.deploy` 的 `version` 默认值是 **`0.1.0`**。不传 `--version` 会把 `latest` 别名指向 `0.1.0`，覆盖正确版本。

```bash
# GitHub Pages + tar 同步服务器（一步到位，推荐）
inv docs.deploy --version=X.Y.Z --alias=latest
# 或：先只推 GitHub Pages，再单独同步服务器
inv docs.deploy --version=X.Y.Z --alias=latest --no-sync
inv docs.push-to-server
```

---

## 前置检查（在通用项之外）

| 检查项 | 方法 |
|--------|------|
| changelog 已收口 | 把 `docs/appendix/changelog.md` 的 `## [Unreleased]` 收为 `## [X.Y.Z] - <date>` |
| 文档版本来源 | docs 的 `{{ protocol_version }}` 宏**读 changelog 顶部 `## [X.Y.Z]`，不读 pyproject**（`scripts/docs/macros.py`）。changelog 顶部版本须与发布版本一致 |
| 顺序 | changelog 收口 → `inv docs.build` 核对 → commit → push → `inv docs.deploy --version=X.Y.Z` |

> oasp 的 `pyproject.toml` 也配了 bump-my-version，但**对外文档显示的版本由 changelog 顶部决定**，两者都要对齐。

---

## 发布后验收

1. **GitHub Pages 活**：`https://a2c-smcp.github.io/oasp-protocol/latest/` 返回 200。
2. **公司服务器活**：`https://doc.turingfocus.cn/oasp/latest/` 返回 200 且**内容确为新版本**（不要只看部署命令退出码——git 模式会假报成功）。
3. **服务器 `versions.json` / `latest`**：`push-to-server` 末尾会回读并打印，确认 `latest` 指向新版本。
4. **页面展示版本**：`{{ protocol_version }}` 渲染结果与本次 `X.Y.Z` 一致。
