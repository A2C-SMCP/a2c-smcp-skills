# Compare-OSS — ide4ai 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：Python，uv + pytest（`testpaths = ["tests"]`）
- 定位：AI IDE 工具（代码导航/编辑/LSP/终端），Computer 官方内置 MCP 工具
- 我方核心模块与架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 明确对比哪条能力线：代码导航（符号/引用）、编辑、LSP 集成、终端——对方项目常只覆盖其中一两条，Phase 1 盘点先对齐能力面再对比深度

## Phase 4 差异：基准 harness

- 跑法：`uv run pytest tests/ -v`，借既有 fixtures
- LSP/导航类质量线索的场景构造要点：
  - **用真实仓库当 fixture**（如 clone 一个中等规模开源 Python 仓），不是玩具文件——符号解析/引用查找的差距只在真实代码密度下暴露
  - 典型场景轴：跨文件符号跳转召回、重命名波及正确性、诊断延迟、大文件（千行级）编辑响应、终端长任务输出处理
- 对称：我方与对方（多为 LSP-桥接类工具）接同一 LSP server、同一仓库、同一批查询，比召回/延迟
- 一次性基准放 scratchpad/`/tmp`，不入库

## 典型对比对象

- LSP-桥接类 MCP server / agent 代码导航工具（能力面最重叠）
- 编码 agent 内置的编辑/导航工具层（如各 CLI coding agent 的工具集设计）
- 终端会话管理类 MCP 工具
