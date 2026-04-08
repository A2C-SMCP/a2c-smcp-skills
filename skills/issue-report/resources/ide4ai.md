# Issue Report — IDE4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/ide4ai`
- **语言/框架**：Python，MCP Server（AI IDE 工具集）
- **路径模式**：`*/ide4ai`

## 版本信息

- **版本文件**：`pyproject.toml` → `[project]` 段的 `version` 字段
- **提取命令**：`grep '^version' pyproject.toml`
- **运行时版本**：`python3 --version`

## 架构上下文

### 核心架构

- 高内聚低耦合设计，兼容 A2C-SMCP / MCP / Gymnasium 接口
- 核心能力：代码导航（LSP）、精确编辑、终端执行、工作区管理
- **安全机制**：命令白名单，不可绕过

### 两类演进路径

| 部分 | 演进约束 |
|------|---------|
| 纯 MCP 工具 | 可自由演进，不受 A2C 协议约束 |
| 协议感知部分 | 必须遵循 A2C-SMCP 规范 |

### Bug Report 上下文收集要点

1. 确认问题涉及哪类能力（LSP / 编辑 / 终端 / 工作区）
2. 检查是否触及命令白名单限制
3. 确认问题在哪个 MCP 工具的调用中发生
4. 多语言 LSP 场景需注明语言和 LSP 服务器类型

### Feature / Improvement 上下文收集要点

1. 确认新功能属于纯 MCP 工具还是协议感知功能
2. 评估是否需要新增命令到白名单
3. 检查现有 MCP 工具列表避免重复

## 测试信息

- **测试目录**：`tests/`
- **运行测试**：`uv run pytest`
- **Lint**：`uv run ruff check .`

## 环境信息收集

```bash
python3 --version
grep '^version' pyproject.toml
```

## 跨项目影响

| 场景 | 关联仓库 |
|------|---------|
| MCP 工具接口变更 | `A2C-SMCP/python-sdk`（Computer 注册机制） |
| A2C 协议交互变更 | `A2C-SMCP/a2c-smcp-protocol` |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| 涉及 LSP | 追加 `lsp` |
| 涉及安全/白名单 | 追加 `security` |
