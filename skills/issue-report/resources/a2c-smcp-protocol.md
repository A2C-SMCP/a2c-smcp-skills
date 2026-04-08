# Issue Report — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/a2c-smcp-protocol`
- **类型**：协议规范文档（MkDocs），非代码项目
- **路径模式**：`*/a2c-smcp-protocol`

## 版本信息

- **版本文件**：`pyproject.toml` → `[project]` 段的 `version` 字段
- **提取命令**：`grep '^version' pyproject.toml`

## 架构上下文

### 文档结构

- 规范文档：`docs/specification/`（architecture、events、data-structures、room-model、error-handling、security）
- 构建工具：MkDocs + invoke 任务
- 预览：`inv docs.serve`，构建：`inv docs.build`

### 协议项目的特殊性

协议项目的 Issue **不是代码 Bug**，而是以下类型：

| Issue 类型 | 协议项目含义 |
|-----------|------------|
| Bug Report | 规范文档中的不一致、歧义、错误描述 |
| Feature Request | 新增协议事件、新数据结构、新的交互模式 |
| Improvement | 现有规范的澄清、示例补充、边界条件明确化 |

### Bug Report 上下文收集要点

1. 定位具体的规范文档文件（`docs/specification/` 下）
2. 引用不一致的具体段落和章节
3. **交叉验证**：检查 Python SDK 和 Rust SDK 的实现是否一致
   - Python SDK：`A2C-SMCP/python-sdk` 的 `a2c_smcp/smcp.py` 和 `a2c_smcp/model.py`
   - Rust SDK：`A2C-SMCP/rust-sdk` 的 `crates/smcp/` 下的类型定义
4. 确认实现与规范的偏差方向（是实现错了，还是规范本身有问题）

### Feature / Improvement 上下文收集要点

1. 说明新协议特性的动机和使用场景
2. 评估对现有 SDK 实现的影响（哪些仓库需要跟进修改）
3. 考虑向后兼容性

## 跨项目影响

协议变更影响所有实现仓库，必须在 Issue 中明确列出：

| 关联仓库 | 影响方式 |
|---------|---------|
| `A2C-SMCP/python-sdk` | 需更新 TypedDict/Pydantic 定义 |
| `A2C-SMCP/rust-sdk` | 需更新 serde 结构体定义 |
| `A2C-SMCP/tfrobot-client` | 如涉及 Computer 行为变更 |
| `JIAQIA/office4ai` | 如涉及 MCP/Computer 交互变更 |
| `A2C-SMCP/ide4ai` | 如涉及 MCP/Computer 交互变更 |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| 规范不一致 | `bug`, `spec-inconsistency` |
| 新协议特性 | `enhancement`, `rfc` |
| 规范澄清/补充 | `improvement`, `documentation` |
| 涉及事件定义 | 追加 `events` |
| 涉及数据结构 | 追加 `data-structures` |
