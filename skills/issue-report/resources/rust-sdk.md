# Issue Report — Rust SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/rust-sdk`
- **语言/框架**：Rust，Cargo workspace，Tokio 异步运行时
- **路径模式**：`*/rust-sdk`

## 版本信息

- **版本文件**：`Cargo.toml` → `[workspace.package]` 段的 `version` 字段
- **提取命令**：`grep '^version' Cargo.toml`
- **工具链版本**：`rustc --version`

## 架构上下文

### 核心架构

- Workspace crates：`smcp`（协议）、`smcp-agent`、`smcp-computer`、`smcp-server-core`、`smcp-server-hyper`
- Feature flags：`agent` / `computer` / `server` / `full` / `e2e` 各自独立
- 统一 re-export：根包通过 feature gate 暴露，用户用 `use a2c_smcp::*`

### 问题层级

| 层级 | 位置 | 说明 |
|------|------|------|
| 协议层 | `crates/smcp/` | 事件定义、数据结构、serde 序列化 |
| 传输层 | Socket.IO (`tf-rust-socketio`) | 连接管理、重连、命名空间 `/smcp` |
| 业务层 | 各组件 crate | Agent/Computer/Server 业务逻辑 |
| 集成层 | MCP Server 管理 | 工具注册、去重、资源聚合 |

### Bug Report 上下文收集要点

1. 确认问题出在哪个 crate，检查 crate 边界是否清晰
2. 检查 serde 属性（`rename`/`skip_serializing_if`/`default`）是否与 Python SDK 兼容
3. 调用链追踪：`AsyncSmcpAgent` API → Socket.IO → 事件序列化 → Server 转发
4. 检查 `Send + Sync` 约束、`Arc<RwLock<T>>` / `DashMap` 使用是否正确

### Feature / Improvement 上下文收集要点

1. 确认涉及哪些 crate，是否需要新增 crate
2. 评估 feature flag 影响
3. 检查公开 API 变更是否需要更新根包 re-export

## 测试信息

- **单元测试**：各 crate 内 `#[cfg(test)]`
- **E2E 测试**：`tests/` 目录，需 `e2e` feature + `--ignored`
- **运行测试**：`cargo test-ws`
- **组件测试**：`cargo test-agent` / `cargo test-computer` / `cargo test-server`
- **Lint**：`cargo fmt-all` + `cargo clippy-workspace`
- **编译检查**：`cargo build --workspace --all-features`

## 环境信息收集

```bash
rustc --version
cargo --version
grep '^version' Cargo.toml
```

## 跨项目影响

| 场景 | 关联仓库 |
|------|---------|
| 协议结构变更 | `A2C-SMCP/a2c-smcp-protocol` |
| 与 Python SDK 序列化不兼容 | `A2C-SMCP/python-sdk` |
| smcp-computer crate 变更 | `A2C-SMCP/tfrobot-client`（下游依赖） |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| 涉及特定 crate | 追加 `crate:<name>`（如 `crate:smcp-agent`） |
| 涉及协议兼容性 | 追加 `protocol` |
