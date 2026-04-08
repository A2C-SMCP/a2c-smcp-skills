# Issue Report — Office Editor4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`JIAQIA/office-editor4ai`
- **语言/框架**：TypeScript，pnpm workspace monorepo
- **路径模式**：`*/office-editor4ai`

## 版本信息

- **版本文件**：`package.json` → `version` 字段
- **提取命令**：`node -p "require('./package.json').version"`
- **运行时版本**：`node --version`

## 架构上下文

### 核心架构

- **双层架构**：工具封装层（Office.js → 语义工具）+ 协议暴露层（OASP Socket.IO）
- **三个独立 Add-In**：Excel(3001)、Word(3002)、PPT(3003)
- **共享代码**：`/src/shared/` 通过 symlink 在三个 Add-In 间共享
- 实现 OASP 协议的 Add-In 端

### 稳定性分级（继承自 OASP 协议）

| Add-In | 稳定性 | 说明 |
|--------|--------|------|
| Word | **Stable** | 变更门槛高，需确保向后兼容 |
| PPT | **Draft** | 可接受较大变更 |
| Excel | **Draft** | 可接受较大变更 |

### Bug Report 上下文收集要点

1. 确认问题在哪个 Add-In（Word/Excel/PPT）
2. 区分问题层级：Office.js 工具层 / OASP Socket.IO 协议层 / 共享代码层
3. 如果涉及共享代码（`/src/shared/`），注意影响所有三个 Add-In
4. 检查事件名格式是否符合 `{namespace}:{action}:{target}` 约定
5. 检查错误码范围（1xxx-5xxx）是否正确

### Feature / Improvement 上下文收集要点

1. 确认目标 Add-In 和稳定性级别
2. 评估是否涉及共享代码变更（影响范围放大）
3. 检查是否需要 office4ai Server 端配合

## 测试信息

- **构建检查**：`pnpm build`
- **Lint**：`pnpm lint`
- **测试**：`pnpm test`

## 环境信息收集

```bash
node --version
pnpm --version
node -p "require('./package.json').version"
```

## 跨项目影响

| 场景 | 关联仓库 |
|------|---------|
| OASP 事件/Schema 变更 | `JIAQIA/office4ai`（Server 端需同步） |
| OASP 协议本身有问题 | `A2C-SMCP/oasp-protocol` |

**配对仓库特别注意**：office-editor4ai 与 office4ai 是配对项目（Add-In 端 ↔ Server 端），Schema/Handler 变更必须双向同步。

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| Word Add-In | 追加 `word` |
| Excel Add-In | 追加 `excel` |
| PPT Add-In | 追加 `ppt` |
| 涉及共享代码 | 追加 `shared` |
| 需要 office4ai 配合 | 追加 `cross-repo` |
