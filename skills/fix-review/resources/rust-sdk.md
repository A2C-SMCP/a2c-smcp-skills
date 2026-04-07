# Fix Review — Rust SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

- **crate 边界**：组件 crate 只依赖 smcp 协议层，彼此不互依赖
- **serde 属性**：`Option<T>` → `skip_serializing_if`，`Vec/HashMap` → `default`，枚举 → `tag`
- **错误处理**：各 crate 自有 Error 枚举 + thiserror，不引入 anyhow
- **异步安全**：`Send + Sync`，共享状态用 `Arc<RwLock<T>>` 或 `DashMap`
- **协议兼容**：修改 `crates/smcp/` 时对照 Python SDK 确认 JSON 序列化兼容

## 修改顺序

协议层（`crates/smcp/`）→ 组件层（agent/computer/server）→ 集成层（tests/）

## 已知重复区域

修复触及这些区域时可考虑顺带消除重复（评估风险后决定）：
- `StdioServerConfig`/`SseServerConfig`/`HttpServerConfig` 共享字段
- `list_windows` URI 过滤排序在 stdio/sse 中重复
- `AsyncAgentEventHandler`/`AgentEventHandler` 默认实现相同

## 验证命令

```bash
cargo fmt-all && cargo build --workspace --all-features
cargo clippy-workspace && cargo test-ws
cargo test-agent / test-computer / test-server   # 涉及的组件
```
