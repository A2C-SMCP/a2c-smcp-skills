# Issue Report — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`JIAQIA/office4ai`
- **语言/框架**：Python，uv 包管理，MCP Server + Gymnasium 环境
- **路径模式**：`*/office4ai`

## 版本信息

- **版本文件**：`pyproject.toml` → `[project]` 段的 `version` 字段
- **提取命令**：`grep '^version' pyproject.toml`
- **运行时版本**：`python3 --version`

## 架构上下文

### 核心架构

- LibreOffice UNO Bridge 双层架构
- **双协议身份**：
  - 作为 OASP Server：事件格式 `{namespace}:{action}:{target}`
  - 作为 SMCP Computer 的 MCP Server：工具定义遵循 MCP 规范
- 调用链：AI Agent → MCP Tool → Socket.IO 事件 → Office Add-In 执行

### Bug Report 上下文收集要点

1. 确认问题涉及哪个协议身份（OASP Server / MCP Server）
2. 检查 DTO/Handler 是否与 office-editor4ai 同步
3. 调用链追踪：MCP Tool 调用 → Socket.IO 事件发送 → Add-In 侧响应
4. 区分问题层级：MCP 工具定义层 / Socket.IO 事件层 / UNO Bridge 层

### Feature / Improvement 上下文收集要点

1. 确认新功能属于哪个协议域（OASP / MCP / Gymnasium）
2. 评估是否需要 office-editor4ai 配合实现
3. 检查现有 MCP 工具列表，避免功能重复

## 测试信息

- **测试目录**：`tests/`
- **运行测试**：`uv run poe test`
- **Lint**：`uv run poe lint`（ruff + mypy）

## 环境信息收集

```bash
python3 --version
grep '^version' pyproject.toml
uv --version
```

## 跨项目影响

| 场景 | 关联仓库 |
|------|---------|
| OASP 事件/Schema 变更 | `JIAQIA/office-editor4ai`（Add-In 侧需同步） |
| OASP 协议本身有问题 | `A2C-SMCP/oasp-protocol` |
| MCP 工具定义变更 | `A2C-SMCP/python-sdk`（Computer 注册机制） |
| A2C 协议交互变更 | `A2C-SMCP/a2c-smcp-protocol` |

**配对仓库特别注意**：office4ai 与 office-editor4ai 是配对项目（Server 端 ↔ Add-In 端），DTO/Handler 变更必须双向同步。

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| 涉及 OASP 协议 | 追加 `oasp` |
| 涉及 MCP 工具 | 追加 `mcp-tool` |
| 需要 editor4ai 配合 | 追加 `cross-repo` |
