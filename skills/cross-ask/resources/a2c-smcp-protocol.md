# Cross Ask — a2c-smcp-protocol 问卷模板

> 当其他项目工程师需要向协议规范工程师提问时，使用此模板。

## 项目职责

a2c-smcp-protocol 定义 A2C-SMCP Socket.IO 协议规范（当前版本 0.1.2-rc1），包括三角色模型（Agent / Server / Computer）、事件定义、数据结构和 Room 隔离机制。所有 SDK 和客户端实现以此为权威来源。

## 问卷必填字段

### 1. 涉及的协议层面

| 层面 | 说明 |
|------|------|
| **事件定义** | 事件名（`client:*` / `server:*` / `notify:*`）、触发条件、payload 结构 |
| **数据结构** | TypedDict 定义（`data-structures.md` 为 source of truth）、字段含义 |
| **Room 机制** | Room 命名规则、隔离策略、广播范围 |
| **角色行为** | Agent / Server / Computer 各自的职责边界和交互流程 |
| **版本管理** | 版本号语义、向后兼容性规则、bump-my-version 配置 |

### 2. 具体事件/结构信息

如问题涉及特定事件或数据结构：
- 事件全名（如 `client:call_tool`）
- 涉及的数据类型名（如 `CallToolRequest`）
- 当前协议版本中的定义

### 3. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 事件定义 | 事件名 + 方向 + payload TypedDict + 触发时机 |
| 数据结构 | TypedDict 完整定义 + 字段说明 + 可选/必填标注 |
| 行为规范 | 角色行为描述 + 正常/异常流程 |
| 版本变更 | 变更内容 + 影响范围 + 迁移说明 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| python-sdk / rust-sdk | 某个事件的 payload 结构和语义？ |
| python-sdk / rust-sdk | 协议新版本的变更内容和迁移指南？ |
| office4ai | Computer 角色的 MCP 工具注册协议？ |
| client | 连接建立流程和认证机制？ |
| ide4ai | Computer 角色的行为规范和事件约定？ |
