# Cross Ask TF — TFRSManager 问卷模板

> 当 A2C-SMCP 工程师需要向 TFRSManager 工程师提问时，使用此模板。

## 项目职责

TFRSManager 是 TuringFocus SaaS 管理服务层：Go Gin 双服务（user-service 8080 / admin-service 8081）、GORM + PostgreSQL、多租户（Organization → Account → User）、JWT 认证。**管理用户账号、订阅配额、数字员工实例**。

## A2C 常见对接场景

| A2C 项目 | 对接需求 |
|---------|---------|
| tfrobot-client | 用户通过 Manager 登录，拿到 JWT Token，再携 Token 访问 TFRobotServer |
| office-editor4ai | 了解多账号/多组织模型，理解登录后 namespace 和 robotId 的来源 |

## 问卷必填字段

### 1. 涉及的服务层

| 服务 | 说明 |
|------|------|
| **user-service (8080)** | 用户登录、JWT 获取、账号/组织管理、数字员工实例 |
| **admin-service (8081)** | 管理员操作，通常不涉及 A2C 对接 |

### 2. 用户登录与 JWT（高频对接点）

如问题涉及登录认证，必须明确：

- **登录 API 路径 + Method**（user-service 端口 8080 + 路径）
- **支持的登录方式**：用户名密码 / 邮箱 / OAuth？
- **JWT 结构**：payload 中包含哪些字段（userId、orgId、namespace、robotId 等）
- **Token 有效期 + 刷新接口**
- **Token 如何在请求中携带**：Authorization Bearer、Cookie 还是自定义 Header？
- **多账号场景**：用户属于多个 Organization 时，如何选择/切换账号？

### 3. 数字员工实例信息

如需通过 Manager 获取用户可访问的 Robot Server 信息：

- 获取用户名下数字员工实例列表的 API
- 实例详情包含的字段（server endpoint、namespace、robotId、状态）
- 与 TFRobotServer 鉴权的关联（Manager Token 如何转化为 Server Token）

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 登录 API | `curl` 示例 + 响应 JSON 示例（含 token 字段路径） |
| JWT 结构 | JWT payload 字段列表 + Go struct 定义或 JSON 示例 |
| 实例列表 | 响应字段列表 + TypeScript 接口定义 |
| 多账号流程 | 步骤序列（登录 → 选组织 → 获取 Token）+ 涉及的 API 列表 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| tfrobot-client | Manager 的登录 API 路径和请求格式？Token 存在 JWT 里还是另外签发？ |
| tfrobot-client | 用户登录 Manager 后，如何获知自己对应的 TFRobotServer 地址？ |
| tfrobot-client | Manager Token 和 Server Token 是同一个还是需要额外换取？ |
| office-editor4ai | 多组织用户的 namespace 和 robotId 从哪个 API 获取？ |
