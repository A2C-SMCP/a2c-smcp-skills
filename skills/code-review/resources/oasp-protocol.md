# Code Review — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：文档仓库（MkDocs），非代码项目
- **当前版本**：0.1.8
- **文档结构**：`docs/specification/`（events-word, events-ppt, events-excel, data-structures, error-handling, connection, conventions）

## 审查维度（替代通用步骤）

### 文档内交叉一致性

- events-word/ppt/excel.md ↔ data-structures.md ↔ error-handling.md
- 新增事件是否包含 requestId/documentUri 三要素？
- 新增错误码是否落在正确范围段（1xxx-5xxx）？

### Stable vs Draft 门槛差异

- /word（Stable）：向后兼容为强制要求
- /ppt、/excel（Draft）：变更门槛较低

### 双端影响评估

规范变更会影响 office4ai（Server 端）和 office-editor4ai（Add-In 端）哪些文件？两端是否需要同步修改？

### 协议约定一致性

- 事件名 `{namespace}:{action}:{target}` 格式
- 字段 camelCase，错误码 SCREAMING_SNAKE
- 超时分级：简单查询 10s / 复杂操作 30s / 批量 60s

## 验证命令

```bash
inv docs.serve    # 本地预览
inv docs.build    # 构建验证
```
