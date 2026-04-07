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
