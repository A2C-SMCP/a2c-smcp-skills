# Cross Ask — tfrobot-client 问卷模板

> 当其他项目工程师需要向 Computer 客户端工程师提问时，使用此模板。

## 项目职责

tfrobot-client 是 A2C-SMCP 的跨平台桌面客户端（Tauri 2 + React 18 + Rust），graphical wrapper around `smcp-computer` 库。管理 MCP Server 生命周期、SMCP Server 连接和日志系统。

## 问卷必填字段

### 1. 涉及的架构层

| 层 | 说明 |
|----|------|
| **前端 UI** | React + TypeScript + Ant Design 5 + Zustand + i18next |
| **Tauri IPC** | Rust ↔ TypeScript 通信、Command 定义 |
| **Rust 后端** | Tauri 命令实现、smcp-computer 集成、Tokio 异步 |
| **MCP 管理** | MCP Server CRUD、生命周期管理（启动/停止/重启） |
| **SMCP 连接** | SMCP Server 连接管理、Socket.IO 客户端 |
| **安全/存储** | 系统钥匙串（keyring）凭证存储、双层日志系统 |

### 2. MCP Server 管理相关

如问题涉及 MCP Server：
- 涉及的 Tauri Command 名称
- MCP 传输类型（stdio / SSE / HTTP）
- Server 状态和生命周期事件
- 嵌入式运行时检测逻辑

### 3. Tauri IPC 相关

如涉及前后端通信：
- Command 名称和参数结构（Rust struct）
- 前端调用方式（`invoke` / `listen`）
- 返回值类型和错误处理

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| Tauri Command | 命令名 + Rust 签名 + TS 调用示例 |
| MCP 管理 | 操作流程 + 状态转换 + 配置参数 |
| UI 交互 | 页面路由 + Zustand store + 用户操作流 |
| 日志/调试 | 日志位置 + 过滤方式 + 常见排错 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| rust-sdk | **客户端如何使用 smcp-computer 库？初始化配置？** |
| office4ai | **客户端如何启动和管理 MCP Server 进程？** |
| ide4ai | **客户端对 IDE MCP 工具的集成方式？** |
| python-sdk | **客户端连接 SMCP Server 的参数和重连策略？** |
