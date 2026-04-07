# Fix Review — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

- **DTO 规范**（🔴 级别）：snake_case 字段 + camelCase alias，嵌套继承 `SocketIOBaseModel`
- **Tool 开发**：继承 `BaseTool`，不绕过 `BaseTool.execute()` 执行链
- **MCP Input**：复用 DTO 层已有嵌套类型，不重新定义
- **类型注解**：mypy strict，`str | None` 而非 `Optional[str]`

## 修改顺序

DTO 层（`dtos/`）→ 资源层（`resources/`）→ 工具层（`tools/`）→ Server → 测试

## OASP 协议兼容

涉及 DTO 或 Socket.IO 事件修改时：
- 对照 oasp-protocol 协议定义确认兼容
- 确认 office-editor4ai（Add-In 端）的 Schema/Handler 对齐

## 验证命令

```bash
poe format && poe lint && poe typecheck
poe test-unit          # 单元测试
poe test-contract      # 契约测试（Socket.IO 变更时）
poe test               # 全量测试
```
