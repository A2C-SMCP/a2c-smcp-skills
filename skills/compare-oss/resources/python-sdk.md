# Compare-OSS — python-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：Python，uv 管理依赖（`uv.lock`），pytest 测试
- 定位：SMCP Python SDK，协议**参考实现**——对比时「协议语义正确性/双实现一致性」权重高于纯性能
- 我方核心模块与架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 明确对比的是哪一端：Agent / Computer / Server，或跨端的协议层能力
- 参考实现身份意味着：对方的「更快但语义松」设计，先过 Phase 5「刻意设计」闸（协议先行约束）

## Phase 4 差异：基准 harness

复用既有 pytest 基座，别新造：

- 测试分层：`tests/unit_tests/`、`tests/integration_tests/`、`tests/e2e/`，fixtures 看各层 `conftest.py`
- 跑法：`uv run pytest tests/<层>/<路径> -v`
- 一次性基准测试放 scratchpad 或 `/tmp`，**不入库**；需要 Socket.IO 双端的场景，借 `tests/e2e/` 的既有启动方式
- 对方是 Python 项目时：在其 `/tmp/compare-oss/<name>` 目录内 `uv venv && uv pip install -e .`（或按其 README），用**它自己的测试 fixtures** 跑同一份场景数据

典型场景轴（构建数据即构想场景）：多工具并发调用、断线重连语义、大 payload（Blob/资源）传输、错误码语义对齐。

## 典型对比对象

- MCP 官方 python-sdk（协议层能力/API 人体工学）
- MCP 聚合/网关类项目（多 server 聚合、工具路由——与 Computer 端职责重叠）
- Python agent 框架的工具执行层
