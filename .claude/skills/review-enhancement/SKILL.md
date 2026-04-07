---
name: review-enhancement
description: 审查 enhance-skill 提交的 GitHub Issue，评估建议合理性，与用户商议后实施改进。用于 marketplace 维护者持续提升 Skill 质量。
argument-hint: "[issue-number]"
---

# Review Enhancement — Skill 改进审查与实施

审查 `enhance-skill` 提交到 GitHub 的改进建议，评估合理性，与用户商议后落地实施。

## 参数解析

`/review-enhancement [issue-number]`

- 提供 issue number → 直接审查该 Issue
- 未提供 → 列出所有待处理的 enhance Issue，由用户选择

---

## Step 1：获取待审查 Issue

### 指定 Issue

```bash
gh issue view <number> --repo A2C-SMCP/a2c-smcp-skills
```

### 未指定 → 列出待处理

```bash
gh issue list --repo A2C-SMCP/a2c-smcp-skills --label enhance --state open
```

展示列表供用户选择。

## Step 2：读取 Issue 并定位目标文件

解析 Issue 内容，提取：
- **目标 Skill**：从标题 `[skill-name]` 提取
- **目标文件**：Issue body 中的「目标 Skill → 文件」字段
- **反馈类型**：步骤错误 / 分支遗漏 / 信息过时 / 流程缺失 / Resource 缺失 / Resource 不准 / 体验改进

读取目标文件当前内容。

## Step 3：评估建议合理性

| 维度 | 评估要点 |
|------|---------|
| **准确性** | 建议指出的问题是否确实存在？ |
| **普适性** | 改进是否对所有使用者有益？ |
| **一致性** | 是否与 Skill 整体设计理念一致？ |
| **副作用** | 修改是否可能破坏其他项目的使用？ |
| **行数限制** | 修改后 SKILL.md ≤ 200 行、resource ≤ 100 行？ |

### 评估结论

**采纳** — 建议合理，可直接实施
**需讨论** — 有价值但需调整
**拒绝** — 不适合当前 Skill

## Step 4：与用户商议

用 `AskUserQuestion` 展示评估结论，征求用户意见。允许多轮讨论直到达成共识。

## Step 5：实施改进

1. **编辑文件**：按商议结果修改
2. **行数检查**：SKILL.md ≤ 200、resource ≤ 100
3. **关联检查**：步骤编号变更时同步 resource 引用

修改完成后展示 `git diff` 供用户确认。

## Step 6：关闭 Issue

1. **回复 Issue**：`gh issue comment <number> --repo A2C-SMCP/a2c-smcp-skills --body "<内容>"`
2. **关闭 Issue**：`gh issue close <number> --repo A2C-SMCP/a2c-smcp-skills`
3. **提交代码**（如有修改）：由用户决定是否立即提交推送

---

## 批量处理模式

当待处理 Issue 较多时，逐个处理。相关 Issue 合并处理，避免反复修改同一文件。
