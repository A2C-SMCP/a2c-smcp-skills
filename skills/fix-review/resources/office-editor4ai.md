# Fix Review — Office Editor4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

- **共享代码**：`/src/shared/` 符号链接，修改影响全部三个 Add-In（Word/Excel/PPT）
- **OASP 合规**：事件名 `{namespace}:{action}:{target}`，字段 camelCase
- **Stable vs Draft**：/word 变更门槛高，/ppt 和 /excel 较低

## 双端协调

修复涉及 OASP 事件时，确认 office4ai（Server 端）的对应 DTO/Handler 是否需要同步修改。

## 验证命令

```bash
pnpm build    # 类型检查 + 构建
pnpm lint     # ESLint
```
