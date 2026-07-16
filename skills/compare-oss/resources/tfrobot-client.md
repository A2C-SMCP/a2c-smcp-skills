# Compare-OSS — tfrobot-client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：Tauri（Rust `src-tauri/` + TypeScript 前端），pnpm；单测 Vitest（`pnpm test`），端到端 Playwright（`pnpm test:e2e`）
- 定位：Computer 跨平台桌面客户端——聚合本机 MCP 工具（office4ai / ide4ai 等）接入 SMCP 网络
- 我方核心模块与架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 先定位对比层：前端 UI/状态、Tauri IPC 层、Rust 侧 MCP 聚合/SMCP 接入（依赖 rust-sdk）——涉 rust-sdk 内核的线索转到 rust-sdk 的 resource 处理
- 对方多为「MCP 桌面客户端/聚合器」：分清它是 chat 客户端内置 MCP（用户直连）还是我方这种 Computer 形态（被远端 Agent 驱动）——形态差异先记入 Phase 5 隐藏前提

## Phase 4 差异：基准 harness

- 前端逻辑：Vitest（`pnpm test`），可自动化对称基准
- Rust 侧：`cargo test`（在 `src-tauri/` 内），性能线索优先 criterion 一次性 bench（放 `/tmp`，不入库）
- 端到端：Playwright（`e2e/playwright.config.ts`）——启动开销大，只给「必须全链路才能暴露」的质量线索用
- 桌面客户端的对称性陷阱：Electron（对方常见）vs Tauri 的内存/包体对比是**框架差异不是设计差异**——此类结论标注框架归因，别记成对方工程能力

典型场景轴：多 MCP server 并发启停与故障隔离、工具清单热更新、长会话内存曲线、断网重连后状态恢复。

## 典型对比对象

- 其他 MCP 桌面客户端/聚合器（形态最接近的第一对象）
- chat 类客户端的 MCP 管理层（工具管理 UX 参照）
- Tauri vs Electron 选型类线索走 Phase 3 实时数据
