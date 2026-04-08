# Issue Report — Python SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/python-sdk`
- **语言/框架**：Python 3.11+，uv 包管理
- **路径模式**：`*/python-sdk`

## 版本信息

- **版本文件**：`pyproject.toml` → `[project]` 段的 `version` 字段
- **提取命令**：`grep '^version' pyproject.toml`
- **运行时版本**：`python3 --version`

## 架构上下文

### 核心架构

- 三大模块：Agent（`a2c_smcp/agent/`）、Server（`a2c_smcp/server/`）、Computer（`a2c_smcp/computer/`）
- 同步/异步双实现：每个模块有成对的 `namespace.py` / `sync_namespace.py`、`client.py` / `sync_client.py`
- 协议层：`a2c_smcp/smcp.py`（TypedDict）+ `a2c_smcp/model.py`（Pydantic）

### Bug Report 上下文收集要点

1. 确认问题在同步/异步版本中是否都存在
2. 检查 `a2c_smcp/utils/` 下是否有相关工具函数
3. 调用链追踪：`SmcpAgent` API → Socket.IO 客户端 → 事件序列化 → Server 转发

### Feature / Improvement 上下文收集要点

1. 确认是否需要同步/异步双版本新增
2. 检查是否涉及协议结构变更（`smcp.py` / `model.py`）
3. 评估对 Server / Computer 模块的影响

## 测试信息

- **测试目录**：`tests/`（三层：`unit_tests/`、`integration_tests/`、`e2e/`）
- **运行测试**：`uv run poe test`
- **单个测试**：`uv run pytest <file> -v`
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
| 协议结构变更 | `A2C-SMCP/a2c-smcp-protocol` |
| 与 Rust SDK 行为不一致 | `A2C-SMCP/rust-sdk` |
| MCP 工具定义变更 | `JIAQIA/office4ai`、`A2C-SMCP/ide4ai` |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| 涉及协议 | 追加 `protocol` |
| 涉及同步/异步一致性 | 追加 `sync-async` |
