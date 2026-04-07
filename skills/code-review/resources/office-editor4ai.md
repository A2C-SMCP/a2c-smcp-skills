# Code Review — Office Editor4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：JIAQIA/office-editor4ai
- **语言**：TypeScript，pnpm workspace monorepo
- **架构**：工具封装层（Office.js → 语义化工具）+ 协议暴露层（OASP Socket.IO）
- **子项目**：Excel(3001)、Word(3002)、PPT(3003)

## 模块边界

变更涉及 `/src/shared/` 时注意：这是符号链接共享代码，修改影响全部三个 Add-In。

## DRY 重点检查

- Schema/Handler 是否与 office4ai 端的 DTO/Handler 对齐？
- 共享代码（`/src/shared/`）中的修改是否适用于所有三个 Add-In？

## 项目特有审查维度

### OASP 协议合规

- 事件名格式：`{namespace}:{action}:{target}`
- /word（Stable）变更门槛高；/ppt、/excel（Draft）较低
- 错误码使用对应范围段

### Office.js API 限制

注意 API 可用性差异（Word/Excel/PPT 各不同），如 PPT 不支持视频/音频插入。

## 测试覆盖度

新增 Handler/Schema 应有对应测试。TypeScript 类型检查（`pnpm build`）作为最低质量门槛。

## 验证命令

```bash
pnpm build    # 类型检查 + 构建
pnpm test     # 测试（如有）
pnpm lint     # ESLint
```
