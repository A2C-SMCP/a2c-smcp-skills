# Compare-OSS — office4ai 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 语言/工具链：Python，uv + pytest（`testpaths = ["tests"]`），另有 `manual_tests/` 存放需真实 Office 环境的手动用例
- 定位：Office 文档 MCP Server（Word 工具集），Computer 官方内置 MCP 工具
- 我方核心模块与架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：我方模块定位

- 明确对比的是**工具面**（提供哪些文档操作能力）还是**通道面**（与 Office 加载项的 OASP/Socket.IO 通信）——通道面的对比常要连带 oasp-protocol / office-editor4ai 一起看
- 对方多为「文档操作 MCP server」：先分清它走的是文件级操作（python-docx 直改文件）还是应用级操作（驱动运行中的 Office）——两种路线能力面天然不同，Phase 1 盘点必须标注路线，避免拿路线差异当能力差距

## Phase 4 差异：基准 harness

- 可自动化的部分：`uv run pytest tests/ -v`，借既有 fixtures 造文档场景
- 依赖真实 Word 环境的场景：参照 `manual_tests/` 的做法跑手动对照，报告里显式标注「手动实测」而非自动基准
- 一次性基准脚本放 scratchpad/`/tmp`，不入库

典型场景轴（真实文档负载，不是 API 冒烟）：复杂样式保持（多级列表/表格嵌套）、修订与批注往返、大文档（百页级）操作延迟、中文排版语义。

## 典型对比对象

- 其他 Word/Office 文档 MCP server（工具面盘点第一对象）
- python-docx 直改 vs 应用级驱动的两条路线代表项目（路线级对比）
- 文档格式转换/渲染管线类项目（能力边界参照）
