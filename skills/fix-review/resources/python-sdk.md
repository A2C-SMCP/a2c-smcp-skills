# Fix Review — Python SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

- **同步/异步双实现**：修改异步版本时，同步版本必须同步更新
- **协议双文件**：smcp.py（TypedDict）↔ model.py（Pydantic）必须字段一致
- **复用优先**：检查 `a2c_smcp/utils/` 下已有工具，增强现有而非新建
- **类型注解**：mypy strict，函数签名必须完整注解

## 修改顺序

协议层（smcp.py/model.py）→ 模块层（agent/server/computer）→ 工具层（utils）→ 测试层

## 验证命令

```bash
uv run poe lint      # ruff + mypy
uv run poe test      # 全量测试
```
