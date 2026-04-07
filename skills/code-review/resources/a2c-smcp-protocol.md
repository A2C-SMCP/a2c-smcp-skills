# Code Review — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：文档仓库（MkDocs），非代码项目
- **当前版本**：0.2.0 (RC)
- **文档结构**：`docs/specification/`（architecture, events, data-structures, room-model, error-handling, security）

## 协议文档的 Review 特殊性

不是代码审查，而是**规范一致性审查**。测试完整性等步骤不适用。

## 审查维度（替代通用步骤）

### 文档内交叉一致性

- events.md 中的事件定义 ↔ data-structures.md 中的类型定义 ↔ error-handling.md 中的错误码
- 新增事件是否同时定义了请求/响应数据结构？
- 新增错误场景是否在 error-handling.md 中有对应错误码？

### 跨 SDK 影响评估

规范变更是否会导致现有 SDK 实现需要修改？如果是，需列出受影响的 SDK 和预期变更范围。

### 向后兼容性

- 是否修改了已有事件/字段的语义？（高风险）
- 新增字段是否为 Optional？
- 是否需要版本协商机制？

### 简洁性与易用性

- 设计是否过度复杂？有更简单的方式吗？
- SDK 实现者是否容易理解和接入？
- 是否参考了同类协议（MCP、LSP）的做法？

## 验证命令

```bash
inv docs.serve    # 本地预览确认渲染正确
inv docs.build    # 构建验证
```
