# Cross Ask — python-sdk 问卷模板

> 当其他项目工程师需要向 Python SDK 工程师提问时，使用此模板。

## 项目职责

python-sdk 是 A2C-SMCP 协议的 Python 参考实现，包含三个模块（Computer / Server / Agent），通过 Socket.IO 通信。作为参考实现，其行为定义通常是其他 SDK 的对标基准。

## 问卷必填字段

### 1. 涉及的核心模块

必须明确问题属于哪个模块：

| 模块 | 典型问题 |
|------|---------|
| **Computer** | MCP 客户端管理、工具发现/聚合、桌面窗口管理、MCP 传输层（stdio/SSE） |
| **Server** | Socket.IO 事件路由、Room 管理、信号中转、连接生命周期 |
| **Agent** | AI 客户端接入、工具调用流程、会话管理 |
| **Protocol/DTO** | TypedDict 数据结构（`smcp.py`）、Pydantic 模型（`model.py`）、序列化规则 |

### 2. 同步/异步一致性

Python SDK 维护 sync/async 双版本。如问题涉及 API 行为：
- 问题出现在 sync 还是 async 版本？
- 两个版本的行为是否一致？
- 是否涉及事件循环（asyncio）相关问题？

### 3. MCP 客户端管理

如涉及 MCP 工具/服务器管理：
- 涉及的 MCP 传输类型（stdio / SSE）
- 工具发现和聚合逻辑（重名处理、schema 合并）
- 客户端状态机（初始化 → 就绪 → 断开）

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| API 行为 | 函数签名 + 参数说明 + 返回值 + sync/async 差异 |
| 数据结构 | TypedDict 或 Pydantic 模型定义 |
| 事件流程 | Socket.IO 事件序列 + payload 结构 |
| 序列化 | snake_case ↔ camelCase 转换规则 + 具体字段映射 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| rust-sdk | Python SDK 某个 API 的行为语义？作为对标基准 |
| rust-sdk | sync/async 两版本在某场景下的行为差异？ |
| protocol | 参考实现对某个协议字段的解读和处理方式？ |
| client | MCP 客户端的初始化参数和生命周期管理？ |
| office4ai | Computer 模块如何注册和管理 MCP 工具？ |
