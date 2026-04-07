# Fix Review — OASP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 协议文档的 Fix Review 特殊性

与 a2c-smcp-protocol 类似，但需额外注意：
- Stable（/word）vs Draft（/ppt, /excel）变更门槛差异
- 修复影响 office4ai 和 office-editor4ai 双端

## 验证方式（替代代码验证）

1. events-word/ppt/excel.md ↔ data-structures.md ↔ error-handling.md 交叉一致性
2. 双端影响评估
3. `inv docs.serve` 本地预览

## 修复后影响

协议修复发布后，需评估 office4ai 和 office-editor4ai 是否需同步跟进。
