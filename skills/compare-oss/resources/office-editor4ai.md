# Compare-OSS — office-editor4ai 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：TypeScript，pnpm monorepo（word-editor4ai / excel-editor4ai / ppt-editor4ai 三个加载项包），Vitest 单测 + 合约测试（`pnpm test`、`pnpm test:contract`）
- 定位：Office 加载项（Word/Excel/PPT Add-Ins），OASP 的加载项端实现
- 测试规范：见项目根 `TESTING_STANDARD.md`、`E2E_TESTING.md`；架构约定见 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 先定位到具体加载项包（word/excel/ppt），三包能力面差异大，禁止拿「PPT 没有的能力」当整体短板
- 对方多为「Office add-in + AI」类项目：分清它是 taskpane 独立应用还是可编程工具面——我方是被 MCP 工具驱动的执行端，交互形态天然不同

## Phase 4 差异：基准 harness

- 纯逻辑层（文档结构处理、消息编解码）：Vitest，`pnpm --filter <package> test`，可自动化对称基准
- 涉 Office.js 运行时的场景：**合约测试**（`pnpm test:contract`）+ 真实 Office 环境手动实测（参照 `E2E_TESTING.md`），报告标注「手动实测」
- Office.js API 行为差异（宿主版本/Requirement Set）是常见隐藏前提——对方「能做到」的操作先确认其要求的 Requirement Set 我方目标环境是否满足

典型场景轴：大文档批量编辑吞吐（Office.js batch/sync 策略）、样式保真、跨 Word/Excel/PPT 的一致工具语义、加载项挂起恢复。

## 典型对比对象

- 其他 Office add-in AI 编辑集成（能力面第一对象）
- Office Scripts / VBA-桥接类自动化方案（路线级对比）
- Google Workspace add-on 的等价实现（跨生态设计参照，仅架构层结论）
