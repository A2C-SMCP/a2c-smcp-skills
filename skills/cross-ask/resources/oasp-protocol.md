# Cross Ask — oasp-protocol 问卷模板

> 当其他项目工程师需要向 OASP 协议规范工程师提问时，使用此模板。

## 项目职责

oasp-protocol 定义 Office AddIn Socket Protocol（OASP）规范——AI Agent 通过 Socket.IO 控制 Microsoft Office 的通信协议。三层系统：AI Agent → Server（Python 后端 office4ai）→ Office AddIn（office-editor4ai）。

## 问卷必填字段

### 1. 涉及的协议层面

| 层面 | 说明 |
|------|------|
| **命名空间** | `/word`（稳定）、`/ppt`（草案）、`/excel`（草案） |
| **事件定义** | 事件命名格式：`{namespace}:{action}:{target}`，方向和 payload |
| **请求/响应** | 必填字段：requestId (UUID v4)、documentUri、timestamp |
| **命名规范** | JSON 字段 camelCase、事件名 kebab-with-colon、错误码 SCREAMING_SNAKE_CASE |

### 2. 具体事件信息

如问题涉及特定 OASP 事件：
- 完整事件名（如 `word:insert:paragraph`）
- 事件方向（Server → AddIn / AddIn → Server）
- 请求和响应 payload 结构
- 所属命名空间的稳定性状态

### 3. 与 A2C-SMCP 协议的关系

OASP 是 A2C-SMCP 体系中 Computer ↔ Office AddIn 的子协议：
- A2C-SMCP 管理 Agent/Server/Computer 三角色通信
- OASP 管理 Computer（office4ai）与 Office AddIn（office-editor4ai）的通信
- 问询时需区分问题属于哪层协议

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 事件定义 | 事件名 + 方向 + 请求/响应 JSON 结构 |
| 命名规范 | 规则说明 + 正确/错误示例 |
| 命名空间 | 支持的操作列表 + 稳定性状态（稳定/草案） |
| 错误处理 | 错误码 + 含义 + 恢复建议 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| office4ai | 某个 OASP 事件的 payload 格式和必填字段？ |
| editor4ai | 新增 Office 操作对应的事件命名和结构规范？ |
| office4ai / editor4ai | 协议版本变更对现有实现的影响？ |
| protocol | OASP 与 A2C-SMCP 协议的边界和集成方式？ |
