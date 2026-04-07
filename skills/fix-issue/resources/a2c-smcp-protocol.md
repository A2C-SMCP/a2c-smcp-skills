# Fix Issue — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：文档仓库（MkDocs），非代码项目
- **当前版本**：0.2.0 (Release Candidate)
- **内容**：SMCP 协议规范，定义 Agent-Server-Computer 通信标准
- **文档结构**：`docs/specification/`（architecture, events, data-structures, room-model, error-handling, security）

## 此项目的 "Fix Issue" 特殊性

协议文档的 Bug 修复不同于代码修复：
- **不是 TDD** — 没有可执行的测试，但需要**交叉验证一致性**
- **影响面更大** — 协议修改会影响所有实现仓库（python-sdk, rust-sdk, tfrobot-client）

## 调用链路追踪（不适用）

协议文档无调用链路。问题来源通常是：
- SDK 实现者发现规范不清晰/自相矛盾
- 不同 SDK 对同一规范的理解产生分歧
- 新功能讨论中发现现有规范有缺陷

## Step 4 差异：验证方式（替代 TDD）

1. **文档内一致性**：events.md 中的事件定义 ↔ data-structures.md 中的类型定义 ↔ error-handling.md 中的错误码
2. **跨 SDK 对照**：修改后的规范是否与 python-sdk 和 rust-sdk 的现有实现一致？若不一致，需同步提 Issue
3. **本地预览验证**：`inv docs.serve` 确认文档渲染正确

## Step 7 差异：验证命令

```bash
uv venv && source .venv/bin/activate
uv pip install -e ".[docs]"
inv docs.serve       # 本地预览
inv docs.build       # 构建验证
```

## 发布后影响

协议修复发布后，需评估是否需要在实现仓库中同步跟进修改。
