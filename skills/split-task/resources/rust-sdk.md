# Split Task — rust-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。本文件是 rust-sdk 执行 split-task 的差异化内容。

## 项目上下文

- 语言/框架：Rust，Cargo workspace（多 crate），`rmcp` MCP SDK，async（tokio）
- 角色：SMCP 协议的**生产实现**（python-sdk 为参考实现，二者行为须一致）
- workspace 分 crate，天然是清晰的切刀边界

---

## 模块边界识别（Phase 1 引用）

切刀位优先沿 crate 落，`smcp` 核心 crate 是所有 crate 的依赖底座：

| crate | 边界含义 |
|-------|---------|
| `smcp` | **核心协议类型 / 数据结构**（`lib.rs` / `skill_name` / `version`）——所有 crate 依赖它 |
| `smcp-agent` | Agent 侧 |
| `smcp-computer` | Computer 侧（skill staging、desktop 组织）|
| `smcp-client-transport` | 传输层（Socket.IO client 等）|
| `smcp-server-core` | Server 核心逻辑（房间、转发）|
| `smcp-server-hyper` | Server 的 hyper HTTP 集成 |

**切刀启发**：
- 改动 `smcp` 核心类型 → **单独成第一刀**（下游 crate 全依赖）
- 单 crate 内改动 → 沿模块切
- Server 逻辑与 HTTP 集成分离切（`smcp-server-core` vs `smcp-server-hyper`）

### 跨 crate"先后顺序"硬约束

- `smcp`（核心类型）改动必须在最早一刀；下游 crate 不可在其之前 merge（否则 workspace 编译破）
- trait / 接口签名变更须**同刀同步所有 impl 与 mock**，禁止一刀只改 trait 定义留下游 crate 编译红
- 涉及协议语义的改动**不得超前于协议发布**（协议先行，见主文件 Phase 0.6）
- 编译期/类型期耦合（trait 定义 + 首个 impl）属**必要打包**，宁可一刀大，不引入过渡 trait

---

## 关键架构能力守护清单（Phase 6 引用）

集成测试 sub-task 须从下列 rust-sdk 跨边界不变量评估覆盖——**任何单 crate sub-task 都无法独立守护**：

### 1. 跨 SDK 序列化兼容
**为什么是不变量**：Rust struct 与 Python TypedDict 表示同一协议结构，serde 序列化格式漂移即跨语言互通断裂。
**集成测试覆盖**：关键事件/数据结构的跨语言 round-trip 断言（Rust ↔ Python），或与 `a2c-smcp-protocol` 规范样例逐字段对齐（rust-sdk 常已有此类 round-trip 测试，扩展即可）。

### 2. workspace 编译完整性
**为什么是不变量**：多 crate 依赖 `smcp`，核心类型变更易在下游 crate 留编译红，且单 crate 测试不覆盖跨 crate 契约。
**集成测试覆盖**：`cargo test --workspace` 全绿；trait 契约变更加跨 crate 端到端用例。

### 3. async 并发安全（Send + Sync）
**为什么是不变量**：Computer / Server 大量 async 并发共享状态（注册表、房间、连接池），改动易引入竞态或破坏 `Send`/`Sync` bound。
**集成测试覆盖**：共享状态改动的 sub-task 加多任务并发场景测试（tokio 多 task）。

### 4. Socket.IO 事件契约 / 房间模型
**为什么是不变量**：与 python-sdk 同源协议契约，事件名/payload/房间隔离漂移运行时才暴露。
**集成测试覆盖**：Agent↔Server↔Computer 端到端事件回路 + 多房间隔离用例。

---

## rust-sdk 拆分实操约定

- **测试组织**：各 crate `src/` 内联 `#[cfg(test)]` 单测 + `crates/<crate>/tests/` 集成测试；跨 crate 集成回归 sub-task 进相应 `tests/`
- **验证命令**：
  - 测试：`cargo test --workspace`
  - Lint：`cargo clippy --workspace --all-targets -- -D warnings`
  - 编译检查：`cargo check --workspace`
- **GitHub 子任务命名**：`[<crate>] <一句话职责>`，如 `[smcp] 新增事件数据结构` / `[smcp-computer] desktop 组织` / `[集成回归] 跨 SDK 序列化兼容守护`
