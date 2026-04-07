# Fix Issue — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：文档仓库（MkDocs），非代码项目
- **当前版本**：0.1.8
- **内容**：Office AddIn Socket Protocol，定义 AI Agent 控制 Office 文档的通信规范
- **文档结构**：`docs/specification/`（events-word, events-ppt, events-excel, data-structures, error-handling, connection, conventions）

## 此项目的 "Fix Issue" 特殊性

与 a2c-smcp-protocol 类似，协议文档修复需交叉验证一致性，且影响 office4ai 和 office-editor4ai 两个实现仓库。

**Stable vs Draft 差异**：
- /word 事件（Stable）：修复需更谨慎，向后兼容为强制要求
- /ppt 和 /excel 事件（Draft）：修复门槛较低，但仍需协议评审

## 调用链路追踪（不适用）

问题来源通常是：
- office4ai 或 office-editor4ai 开发者发现规范不清晰/有误
- 双端实现时发现事件定义不完整
- Office.js API 限制导致规范需要调整

## Step 4 差异：验证方式（替代 TDD）

1. **文档内一致性**：events-word/ppt/excel.md ↔ data-structures.md ↔ error-handling.md
2. **双端对照**：修改后的规范是否与 office4ai 和 office-editor4ai 的实现一致？
3. **本地预览验证**：`inv docs.serve`

## Step 7 差异：验证命令

```bash
uv venv && source .venv/bin/activate
uv pip install -e ".[docs]"
inv docs.serve       # 本地预览
inv docs.build       # 构建验证
```
