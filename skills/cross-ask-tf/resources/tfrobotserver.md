# Cross Ask TF — TFRobotServer 问卷模板

> 当 A2C-SMCP 工程师需要向 TFRobotServer 工程师提问时，使用此模板。

## 项目职责

TFRobotServer 是 TuringFocus 服务端层：FastAPI API、Celery Workers（Robot/Memory）、SQLAlchemy ORM、Socket.IO 实时通信。封装 TFRobotV2 核心逻辑，对外提供 HTTP/WebSocket 接口。**A2C 项目对接的主要入口**。

## A2C 常见对接场景

| A2C 项目 | 对接需求 |
|---------|---------|
| tfrobot-client | 登录后获取 Robot 配置，避免用户手动输入 Server 地址/参数 |
| office-editor4ai | 接入 Socket.IO 聊天，让用户在 Office 插件中直接登录并与 Robot 对话 |

## 问卷必填字段

### 1. 涉及的对接层

必须明确问题涉及哪一层：

| 层 | 说明 |
|----|------|
| **认证/登录 API** | 用户名密码登录、Token 获取与刷新、Cookie vs Bearer 模式 |
| **Robot 配置 API** | 获取 Robot 列表、配置详情（Server 地址、参数、凭证） |
| **Socket.IO 聊天** | 连接握手、Room 加入、消息发送/接收事件 |
| **CORS & 跨域** | 客户端/插件跨域访问的 Header 要求 |

### 2. 认证接口信息（高频对接点）

如问题涉及登录/鉴权，必须明确：

- **登录 API 路径 + HTTP Method**（如 `POST /api/v1/auth/login`）
- **请求 Body 结构**（username/password 字段名，是否支持 email 登录）
- **响应中 Token 的位置**（JSON body / Set-Cookie Header）
- **Token 类型**：adminToken（Bearer）还是 httpOnly Cookie
- **Token 有效期 + 刷新机制**
- **是否需要先通过 BFF（TFRobotFront）中转**，还是可以直连 Server

### 3. Robot 配置获取

如问题涉及获取 Robot/Server 配置：

- 获取当前用户可用 Robot 列表的 API
- 单个 Robot 详情 API（包含哪些字段：namespace、robotId、server endpoint 等）
- 需要哪些 Header（Authorization: Bearer `<token>` 格式？）

### 4. Socket.IO 聊天事件（高频对接点）

如涉及接入聊天：

- **连接 URL 和命名空间**（namespace）
- **握手认证方式**（auth 参数？query 参数？cookie？）
- **加入 Room 的事件名 + Payload 结构**
- **发送消息的事件名 + Payload 结构**（`send_message` / `chat` 等）
- **接收消息的事件名 + Payload 结构**（流式还是整条？）
- **断线重连时是否需要重新加入 Room**

### 5. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 登录 API | `curl` 示例 + 响应 JSON 示例（敏感字段可脱敏） |
| Robot 配置 | 响应字段列表 + TypeScript 接口定义 |
| Socket.IO | 事件名 + Payload TypeScript 类型 + 连接代码示例 |
| CORS | 需要的 Header 列表 + 允许的 Origin 配置方式 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| tfrobot-client | 客户端如何通过用户名密码登录后获取 Robot 配置？Token 存哪里？ |
| tfrobot-client | 登录 API 需要直连 TFRobotServer，还是必须走 TFRobotFront BFF 代理？ |
| office-editor4ai | Socket.IO 连接时如何传递认证信息？连接参数结构？ |
| office-editor4ai | 聊天消息发送/接收的事件名和 Payload 格式？流式响应支持？ |
| office-editor4ai | Office 插件（浏览器环境）访问 Server 的 CORS 配置要求？ |
