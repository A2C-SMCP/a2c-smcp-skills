# Code Review — Rust SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Rust，Cargo workspace，Tokio 异步运行时
- **架构**：Workspace crates — smcp / smcp-agent / smcp-computer / smcp-server-core / smcp-server-hyper

## 模块边界

依赖方向严格单向：各组件 crate 只依赖 `smcp` 协议层，彼此不互相依赖。检查：
- 是否引入了违反方向的 crate 依赖
- 新公开类型是否需要在 crate `lib.rs` 和根包 `src/lib.rs` 的 feature-gated re-export 中同步

## DRY 重点检查

**已知重复区域**（新变更不应加剧）：
- `StdioServerConfig`/`SseServerConfig`/`HttpServerConfig` 三者共享 5 个相同字段
- `list_windows` 中 window URI 过滤排序在 stdio/sse 客户端中重复
- `AsyncAgentEventHandler` 与 `AgentEventHandler` 默认实现完全相同

**已有抽象**：
- MCP 客户端共性：`BaseMCPClient<P>` 泛型组合
- 工具注册去重：`MCPServerManager.tool_registry`
- 配置构建：`with_xxx(mut self) -> Self` builder 模式

## 项目特有审查维度

### serde 序列化一致性

涉及 `Serialize`/`Deserialize` 结构体时必须检查：
- `Option<T>` → `#[serde(skip_serializing_if = "Option::is_none")]`
- `Vec<T>` / `HashMap` → `#[serde(default)]`
- 枚举 → `#[serde(tag = "type")]` 内部标记
- MCP 字段 → `#[serde(rename = "camelCase")]`

### 跨 SDK 兼容性

修改 `crates/smcp/` 中的类型时，确认 JSON 序列化结果与 Python SDK 兼容。

## 测试约定

| 约定 | 检查点 |
|------|--------|
| 单元测试 | 内联 `mod tests` |
| 异步测试 | `#[tokio::test]`，超时保护必须 |
| 测试辅助 | 复用 `common/mod.rs` 中的 factory/helper |
| E2E | feature 门控 `#[cfg(all(feature = "agent", ...))]` + `#[ignore]` |
| 命名 | `test_<subject>_<scenario>` |

## 测试覆盖度

```bash
cargo llvm-cov --workspace    # 如安装了 cargo-llvm-cov
cargo test-ws                 # 至少全量测试通过
```

每个功能变更必须有对应测试。涉及新 crate 公开 API 时须有单元测试覆盖。

## 验证命令

```bash
cargo fmt-all && cargo build --workspace --all-features
cargo clippy-workspace && cargo test-ws
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
