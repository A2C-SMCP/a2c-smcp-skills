# Compare-OSS — rust-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：Rust，cargo workspace（`crates/` 下多 crate：smcp、smcp-agent、smcp-client-transport、smcp-computer、smcp-server-core、smcp-server-hyper）
- 定位：SMCP Rust SDK，**生产实现**——性能/资源占用类对比在本项目权重最高
- 我方核心模块与架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 先定位到具体 crate（对比对方的哪一层：传输/协议/聚合/服务端）
- 与 python-sdk 的双实现一致性是硬约束：对方「更优」的设计若破坏双 SDK 对齐，Phase 5「刻意设计」闸拦下

## Phase 4 差异：基准 harness

- 单元/集成：`cargo test`（workspace 全量）或 `cargo test -p <crate>`；e2e 见 `tests/`（`e2e_*_test.rs` + `tests/common/`）
- 性能基准：优先 criterion（`cargo bench`）；无既有 bench 基座时，一次性 bench 写在 `/tmp` 的独立 crate 里跑，**不入库**
- 对称性提醒：Rust（我方）vs 对方（可能是 Python/Go/TS）跨语言比吞吐没意义——比的应是**同语言对手**或「架构模式在同负载下的行为」（如背压策略、并发模型），跨语言时结论只到架构层
- 对方是 Rust 项目时：在 `/tmp/compare-oss/<name>` 内 `cargo test` 验证其可跑，借其 fixtures 喂同一份场景数据

典型场景轴：高并发工具调用吞吐、重连风暴恢复、大 Blob 流式传输、内存占用曲线。

## 典型对比对象

- MCP 官方 rust-sdk / rmcp（协议层能力/异步模型）
- Rust 侧 Socket.IO / WebSocket 传输实现（selection 类：选型线索走 Phase 3）
- 其他 Rust agent 运行时的工具执行层
