# Fix Review — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 协议文档的 Fix Review 特殊性

协议文档的 review 问题通常是：
- 规范内交叉不一致（events.md ↔ data-structures.md ↔ error-handling.md）
- 描述模糊/有歧义
- 与 SDK 实现不匹配

## 验证方式（替代代码验证）

1. 文档内交叉一致性检查
2. 跨 SDK 影响评估：修改是否需要 python-sdk / rust-sdk 同步跟进
3. `inv docs.serve` 本地预览确认渲染正确

## 修复后影响

协议文档修复发布后，需评估是否在实现仓库提 Issue 跟进。
