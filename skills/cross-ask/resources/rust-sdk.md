# Cross Ask — rust-sdk 问卷模板

> 当其他项目工程师需要向 Rust SDK 工程师提问时，使用此模板。

## 项目职责

rust-sdk 是 A2C-SMCP 协议的 Rust 生产实现，workspace 包含核心 crate（smcp-agent / smcp-computer / smcp-server-core + smcp-server-hyper），基于 Tokio 异步运行时。作为生产实现，强调性能、类型安全和内存安全。

## 问卷必填字段

### 1. 涉及的 Crate

必须明确问题属于哪个 crate：

| Crate | 典型问题 |
|-------|---------|
| **smcp-computer** | MCP 服务器管理、工具注册/去重、stdio/SSE/HTTP 传输层 |
| **smcp-agent** | AI 客户端、Socket.IO 客户端（tf-rust-socketio） |
| **smcp-server-core** | 服务端核心逻辑、socketioxide 集成 |
| **smcp-server-hyper** | HTTP 层、Hyper 集成 |

### 2. 与 Python SDK 的一致性

Rust SDK 以 Python SDK 为对标基准。如问题涉及行为差异：
- Rust 实现与 Python 参考实现的差异点
- 差异是有意的（性能优化）还是 bug
- 是否需要与 python-sdk 工程师同步确认

### 3. Rust 特有问题

如涉及 Rust 语言特性：
- 所有权/生命周期相关的设计决策
- 异步（Tokio）相关问题
- 序列化（serde）规则：JSON-only，snake_case → camelCase

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| API 行为 | Rust struct/trait 定义 + 方法签名 |
| 与 Python 差异 | 对比说明 + 差异原因 |
| 传输层 | 协议细节 + 配置参数 |
| 构建/测试 | cargo 命令 + feature flags |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| python-sdk | Rust 实现对某个协议的处理是否与 Python 一致？ |
| client | smcp-computer 库的 API 使用方式？初始化配置？ |
| protocol | Rust 实现对协议新增字段的支持情况？ |
