# Cross Ask — office4ai 问卷模板

> 当其他项目工程师需要向 Office MCP Server 工程师提问时，使用此模板。

## 项目职责

office4ai 是 Office 文档管理的 MCP Server，提供 Word/PPT/Excel 操作工具集（27+ 计划）。基于 Gymnasium 环境接口，包含 Workspace Socket.IO 服务器架构和 LibreOffice UNO Bridge 两层集成。同时作为 OASP 协议客户端与 Office Add-In 交互。

## 问卷必填字段

### 1. 涉及的架构层

| 层 | 说明 |
|----|------|
| **MCP Tools** | 工具定义、参数 schema、返回结构 |
| **Workspace/Environment** | Gymnasium 环境接口、Workspace 基类和实现 |
| **Socket.IO Server** | SocketIOBaseModel DTO 编码、事件处理 |
| **UNO Bridge** | LibreOffice UNO 接口、两层 Bridge 架构 |
| **OASP Client** | 遵循 OASP 协议与 Office Add-In 交互 |

### 2. MCP 工具相关

如问题涉及 MCP 工具：
- 工具名称和所属文档类型（Word / PPT / Excel）
- 参数 schema（JSON Schema 格式）
- 返回值结构和含义
- 工具是否有副作用（修改文档 vs 只读查询）

### 3. DTO/序列化规则

office4ai 有特殊序列化约定：
- Python 代码使用 `snake_case`
- 传输/协议层使用 `camelCase` alias（SocketIOBaseModel）
- 字段映射需明确 Python 字段名和 wire format 名

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| MCP 工具 | 工具名 + 参数 schema + 返回结构 + 使用示例 |
| 环境/Workspace | 接口定义 + 状态管理 + 生命周期 |
| Socket.IO 事件 | 事件名 + DTO 类定义 + 编码规则 |
| UNO Bridge | 调用路径 + 类型映射 + 错误处理 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| editor4ai | MCP 工具的参数格式和返回结构？ |
| editor4ai | Socket.IO 事件的 DTO 编码规则和字段映射？ |
| client | MCP Server 的启动参数和健康检查？ |
| protocol | Computer 角色的工具注册实现方式？ |
| python-sdk | MCP 工具的 schema 如何发现和聚合？ |
