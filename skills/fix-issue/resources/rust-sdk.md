# Fix Issue — Rust SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Rust，Cargo workspace，Tokio 异步运行时
- **架构**：Workspace crates — smcp（协议类型）、smcp-agent、smcp-computer、smcp-server-core、smcp-server-hyper
- **Feature flags**：agent/computer/server/full/e2e 各自独立

## 调用链路追踪

- **Agent 侧**：AsyncSmcpAgent API → tf-rust-socketio → 事件序列化 → Server 转发
- **Computer 侧**：事件接收 → tool_registry 分发 → MCP Server 调用（stdio/SSE/HTTP）→ 结果聚合
- **Server 侧**：socketioxide 连接管理 → 会话/房间管理 → 事件路由 → 广播通知
- **跨组件**：事件命名约定（client:/server:/notify:）→ JSON 序列化边界 → ACK 响应链路

## 问题层级

| 层级 | 对应代码 |
|------|---------|
| 协议层 | `crates/smcp/`：事件定义、数据结构、serde 属性 |
| 传输层 | Socket.IO 连接/重连/命名空间 |
| 业务层 | 各组件 crate 的逻辑 |
| 集成层 | MCP Server 管理、工具注册与去重、资源聚合 |

## Step 5 差异：架构原则

- **crate 边界清晰**：smcp 只放协议定义；组件 crate 不互相依赖，只依赖 smcp
- **feature 隔离**：避免交叉依赖
- **re-export 统一**：根包通过 feature gate 统一 re-export
- **错误处理**：各 crate 定义 Error 枚举（thiserror），API 返回 `Result<T, XxxError>`
- **异步安全**：`Send + Sync` 约束，共享状态用 `Arc<RwLock<T>>` 或 `DashMap`
- **JSON 兼容性**：serde 属性必须确保与 Python SDK 互操作

## Step 7 差异：验证命令

```bash
cargo fmt-all                              # 格式化
cargo build --workspace --all-features     # 编译
cargo clippy-workspace                     # Lint
cargo test-ws                              # 全量单元测试
cargo test-agent / test-computer / test-server  # 组件测试
```

## 协议一致性检查

修改 `crates/smcp/` 中类型时，必须对照 a2c-smcp-protocol 规范，并确认 serde 序列化结果与 Python SDK 兼容。关键行为修改时，参考 Python 参考实现确认一致性。
