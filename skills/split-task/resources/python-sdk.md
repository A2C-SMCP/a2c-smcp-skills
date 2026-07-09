# Split Task — python-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。本文件是 python-sdk 执行 split-task 的差异化内容。

## 项目上下文

- 语言/框架：Python 3.11+，asyncio，Pydantic / TypedDict，`uv` + hatchling
- 角色：SMCP 协议的**参考实现**（Rust SDK 为生产实现，二者行为须一致）
- 三方角色同仓：Agent / Computer / Server 都在 `a2c_smcp/` 下

---

## 模块边界识别（Phase 1 引用）

切刀位优先沿角色/模块落，跨角色混切是反模式：

| 模块 | 路径 | 边界含义 |
|------|------|---------|
| 协议数据结构 | `a2c_smcp/smcp.py`、`a2c_smcp/utils/` | 事件/数据 TypedDict、window_uri、mime 等**跨角色共享** |
| Agent | `a2c_smcp/agent/` | Agent 侧：消费 desktop / skills，发起 `client:*` 事件 |
| Computer | `a2c_smcp/computer/` | Computer 侧：MCP 聚合、desktop 组织、skill staging、tool 调用 |
| Server | `a2c_smcp/server/` | Server 侧：Socket.IO namespace、房间模型、事件转发 |

**切刀启发**：
- 改动跨角色共享的协议数据结构 → `smcp.py` / `utils` **单独成第一刀**
- 单角色内改动 → 沿角色切（Computer 的 desktop vs skills vs mcp_clients）
- 跨 SDK 一致性关注点（序列化）→ 独立成刀，勿与业务混切

### 跨模块"先后顺序"硬约束

- 协议数据结构（`smcp.py` TypedDict）改动必须在最早一刀；agent/computer/server 不可在其之前 merge
- 涉及协议语义的改动**不得超前于 a2c-smcp-protocol 发布**（协议先行，见主文件 Phase 0.6）
- 接口签名变更须同刀同步其单测 mock，禁止一刀只改实现不改 mock（中间态 mock 漂移）

---

## 关键架构能力守护清单（Phase 6 引用）

集成测试 sub-task 须从下列 python-sdk 跨边界不变量评估覆盖——**任何单模块 sub-task 都无法独立守护**：

### 1. 跨 SDK 序列化兼容
**为什么是不变量**：Python TypedDict 与 Rust struct 表示同一协议结构，字段名/序列化格式漂移即跨语言互通断裂，单测视角难发现。
**集成测试覆盖**：对关键事件/数据结构做跨语言 round-trip 断言（Python 序列化 → Rust 反序列化，反之亦然），或至少与 `a2c-smcp-protocol` 规范样例逐字段对齐。

### 2. Socket.IO 事件契约
**为什么是不变量**：`client:*` / `server:*` / `notify:*` 事件名与 payload 由协议规定，三角色跨进程通信，事件漂移运行时才暴露。
**集成测试覆盖**：Agent↔Server↔Computer 端到端事件回路用例（`tests/integration_tests/`），断言事件名/payload 与 `events.md` 一致。

### 3. Desktop 组织 / Skill staging 语义
**为什么是不变量**：desktop 的 priority/fullscreen 组织、skill 的三 source 物化语义须与协议 `desktop.md` / `skill.md` 一致（如 priority 读 annotations 非 URI query）。
**集成测试覆盖**：多窗口组织排序 + 三 source 模式 staging 的端到端用例。

### 4. 房间模型隔离
**为什么是不变量**：Server 的房间隔离一旦破损即跨会话数据串扰。
**集成测试覆盖**：多房间并存场景，A 房间事件对 B 房间不可见。

---

## python-sdk 拆分实操约定

- **测试组织**：`tests/unit_tests/<module>/`、`tests/integration_tests/`、`tests/e2e/`；集成回归 sub-task 全部进 `integration_tests/` 或 `e2e/`
- **验证命令**：
  - 单测：`uv run pytest tests/unit_tests/ -n auto`
  - Lint / 类型：`uv run ruff check .` + `uv run mypy a2c_smcp/`
- **GitHub 子任务命名**：`[<模块>] <一句话职责>`，如 `[computer] skill staging 三 source 物化` / `[集成回归] 跨 SDK 序列化兼容守护`
