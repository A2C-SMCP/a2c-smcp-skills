# Issue Report — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/oasp-protocol`
- **类型**：协议规范文档（MkDocs），非代码项目
- **路径模式**：`*/oasp-protocol`

## 版本信息

- **版本文件**：`pyproject.toml` → `[project]` 段的 `version` 字段
- **提取命令**：`grep '^version' pyproject.toml`

## 架构上下文

### 文档结构

- 规范文档：`docs/specification/`（events-word、events-ppt、events-excel、data-structures、error-handling、connection、conventions）
- 构建工具：MkDocs + invoke 任务
- 预览：`inv docs.serve`，构建：`inv docs.build`

### 稳定性分级

| 命名空间 | 稳定性 | Issue 门槛 |
|---------|--------|-----------|
| `/word` 事件 | **Stable** | 高门槛：需确认向后兼容，Bug 修复需慎重 |
| `/ppt` 事件 | **Draft** | 较低门槛：仍在迭代，可接受较大变更 |
| `/excel` 事件 | **Draft** | 较低门槛：仍在迭代，可接受较大变更 |

### Bug Report 上下文收集要点

1. 定位具体规范文档文件（`docs/specification/` 下）
2. 标注涉及的命名空间和稳定性级别
3. **双端验证**：检查 office4ai（Server 端）和 office-editor4ai（Add-In 端）实现是否一致
4. 确认不一致的方向：是实现偏离了规范，还是规范本身有缺陷

### Feature / Improvement 上下文收集要点

1. 说明新事件/结构的使用场景
2. 标注目标命名空间和稳定性级别
3. 评估对双端实现的影响量

## 跨项目影响

OASP 协议变更影响双端实现：

| 关联仓库 | 影响方式 |
|---------|---------|
| `JIAQIA/office4ai` | Server 端事件处理/DTO 需更新 |
| `JIAQIA/office-editor4ai` | Add-In 端事件监听/Handler 需更新 |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| 规范不一致 | `bug`, `spec-inconsistency` |
| 新事件/结构 | `enhancement` |
| 规范澄清/补充 | `improvement`, `documentation` |
| Word 相关（Stable） | 追加 `word`, `stable` |
| PPT 相关（Draft） | 追加 `ppt`, `draft` |
| Excel 相关（Draft） | 追加 `excel`, `draft` |
