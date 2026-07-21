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

## 验证加速：绕开 IDE build 锁争抢

**根因**：RustRover/VS Code 的 rust-analyzer 后台 `cargo check` 与命令行 cargo 共用同一 `target/`，Cargo 文件锁串行化 ⇒ 抢锁卡顿（rust-analyzer#4616/#12707）。征兆：`cargo test` 长时间 0 产出、CPU≈0，`lsof target/debug` 见 `rust-analyzer` 持锁。

**根治（用户一次性配置，推荐）**：IDE 设 `rust-analyzer.targetDir: true` ⇒ rust-analyzer 用独立 target 子目录，不再抢锁（官方最佳实践，原始需求 #6007）。

**Skill 侧（保证覆盖 + 不干等）**：

1. **先 lib 后集成**：`cargo test --lib` 先跑拿绿/红信号，集成/全量套件随后台。
2. **全量套件后台跑 + 轮询输出文件**：`run_in_background` 启动，`Read` 输出文件查进度，勿阻塞回合；**勿 `tail -N` 截断**（漏看失败列表），用 `grep` 取全量 result/FAILED 行。
3. **跳过已知环境 flake**：`-- --skip test_http_client_connection_timeout`（环境性网络超时）并注明。
4. **别一条命令跑两次 cargo**（如 `grep`+`awk` 各跑一次）——翻倍编译。
5. **争锁降级**：lib 全绿 + 隔离审查子代理通常已足够，全量集成留给 CI，勿干等。
6. **极端需要时**：给 Claude 自己的 cargo 单独 `CARGO_TARGET_DIR`（如 `target-claude`）彻底隔离（rust-analyzer#12760 该 env var 对 rust-analyzer 自身有 bug，但 Claude 的 cargo 不受影响）。
