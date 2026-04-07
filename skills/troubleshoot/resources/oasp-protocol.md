# Troubleshoot — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

OASP 协议规范仓库。排查 office4ai ↔ office-editor4ai 通信问题时作为参照。

## 排查中的协议参考

### 事件定义验证

对照 `docs/specification/events-word.md`（或 events-ppt/events-excel）：
- 事件名格式 `{namespace}:{action}:{target}` 是否正确
- 请求是否包含 requestId + documentUri
- 字段是否 camelCase

### 错误码验证

对照 `docs/specification/error-handling.md`：
- 1xxx 通用 / 2xxx 连接 / 3xxx 文档 / 4xxx 校验 / 5xxx Excel 专用
- 错误码数值是否在正确范围段

### 命名空间状态

- /word：Stable — 行为应完全符合规范
- /ppt、/excel：Draft — 可能存在规范与实现不完全对齐的情况

### 超时排查

对照 `docs/specification/conventions.md` 的超时约定：
- 简单查询 10s / 复杂操作 30s / 批量 60s
- 超时问题需确认是超出约定还是操作本身耗时过长
