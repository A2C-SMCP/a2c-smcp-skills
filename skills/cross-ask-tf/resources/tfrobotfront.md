# Cross Ask TF — TFRobotFront 问卷模板

> 当 A2C-SMCP 工程师需要向 TFRobotFront 工程师提问时，使用此模板。

## 项目职责

TFRobotFront 既是主前端 UI（Robot Factory 编辑器、Chat Player），**也是 BFF 后端**——通过 Next.js Route Handlers 代理 TFRobotServer 的全部 API（约 60 个路由），负责鉴权、Cookie 管理、请求转发。TFRobotFront 工程师同时处理前端 UI 问题和 BFF 代理问题。

## A2C 常见对接场景

| A2C 项目 | 对接需求 |
|---------|---------|
| office-editor4ai | 理解 Front BFF 的登录路由和 Cookie 格式，以便在 Add-In 中实现登录 |
| tfrobot-client | 了解 BFF 层对 Server API 的代理规则，判断客户端是否需要走 BFF |

## 问卷必填字段

### 1. 涉及的功能区域

| 区域 | 说明 |
|------|------|
| **BFF 路由层** | Next.js Route Handlers，代理 Server 全部 API，含鉴权、Cookie 注入、请求转发 |
| **Middleware** | 拦截所有请求，注入 auth Cookie（adminToken / tfNamespace / tfRobotId） |
| **登录路由** | 跳过 middleware 鉴权的特殊路由，支持 adminToken 和 password 两种登录模式 |
| **Socket.IO 代理** | Front 是否代理 Server 的 Socket.IO 连接，还是前端直连 Server |

### 2. BFF 鉴权与 Cookie（高频对接点）

如问题涉及 Front BFF 认证，必须明确：

- **登录路由路径**（如 `/api/auth/login`）+ 请求参数
- **Cookie 三件套名称**：`adminToken` / `tfNamespace` / `tfRobotId` 的含义和格式
- **Cookie 是 httpOnly 的吗**？前端 JS 能直接读取吗？
- **middleware 放行规则**：哪些路径跳过鉴权（`/login`、`/_next` 等）
- **外部客户端/插件访问 BFF**：是否支持非浏览器 Cookie 的 Bearer Token 模式？

### 3. 第三方客户端直连 Server vs 走 BFF

A2C 工程师需要判断是否必须经过 BFF：

- 直连 Server API 时，认证方式与走 BFF 有何不同？
- Server 端有没有独立的 Token 鉴权模式（不依赖 BFF Cookie）？
- 哪些 Server API 不经过 BFF 也能访问？

### 4. Socket.IO 连接（如 office-editor4ai 场景）

如涉及从 Add-In 连接 Socket.IO：

- Socket.IO 是连接到 Front BFF，还是直连 TFRobotServer？
- 连接参数从哪里获取（`/api/utils/socketio` 等）？
- auth Cookie 如何在 WebSocket 握手中传递？

### 5. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| BFF 登录路由 | 路径 + Method + 请求 Body + 响应（Cookie Set 说明） |
| Cookie 格式 | 字段名 + 类型 + 示例值（脱敏）+ 有效期 |
| 直连 vs BFF | 建议方案 + 对应的认证方式差异 |
| middleware 规则 | 放行路径列表 + 新增路由是否需要修改 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| office-editor4ai | Add-In（浏览器环境）如何通过 Front BFF 完成登录？Cookie 能否在 Add-In 中使用？ |
| office-editor4ai | Front BFF 的 Socket.IO 连接参数（auth 字段）如何获取和传递？ |
| tfrobot-client | 桌面客户端应该直连 TFRobotServer 还是走 Front BFF？认证差异是什么？ |
| tfrobot-client | 如果走 BFF，客户端如何处理 httpOnly Cookie（非浏览器环境）？ |
