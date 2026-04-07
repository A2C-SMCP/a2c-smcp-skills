---
name: enhance-skill
description: 反馈 A2C-SMCP Marketplace Skill 的问题或改进建议。自动识别当前会话中使用的 Skill，提取优化点，收集版本信息，提交 GitHub Issue 到 a2c-smcp-skills 仓库。当使用某个 Skill 时发现步骤错误、分支遗漏、文档过时等问题时调用。
argument-hint: "[改进描述]"
---

# Enhance Skill — Marketplace Skill 反馈

当使用 Marketplace Skill 过程中发现问题或有改进想法时，通过本 Skill 提交结构化反馈到 GitHub 仓库。

## 参数解析

`/enhance-skill [改进描述]`，改进描述可选，未提供时从会话上下文自动提取。

---

## Step 1：识别目标 Skill

从当前会话上下文中识别用户正在使用（或刚使用完）的 Marketplace Skill：

1. 搜索会话中最近调用的 `/skill-name` 或 `/<plugin>:<skill>` 命令
2. 如果找到多个，用 `AskUserQuestion` 确认反馈针对哪一个
3. 如果未找到，直接询问用户要反馈哪个 Skill

确定目标后，记录 **Skill 名称**。

## Step 2：读取目标 Skill 源文件

从 marketplace 仓库中读取目标 Skill 的全部文件：

```bash
ls {marketplaceRoot}/skills/<skill-name>/
```

读取内容：
- `SKILL.md` — 主流程
- `resources/` 下所有文件 — 项目差异和补充指南

同时确定当前用户所在项目，找到对应的 resource 文件（如果有）。

## Step 3：提取改进点

结合会话上下文和 Skill 源文件，分析以下维度：

| 维度 | 典型问题 |
|------|---------|
| **步骤错误** | 命令不正确、路径已变更、API 已废弃 |
| **分支遗漏** | 某种场景/条件未覆盖 |
| **信息过时** | 版本/配置已变更 |
| **流程缺失** | 缺少必要步骤、顺序不合理 |
| **Resource 缺失** | 某项目应有差异指南但未创建 |
| **Resource 不准** | 项目 resource 中的信息与实际不符 |
| **体验改进** | 步骤可简化、可增加自动化 |

用 `AskUserQuestion` 向用户确认提取到的改进点。

## Step 4：收集版本信息

```bash
# Marketplace 版本
git -C {marketplaceRoot} log --oneline -1

# 当前项目版本
git log --oneline -1
```

记录 Marketplace commit hash、当前项目名称和 commit hash。

## Step 5：检查 gh CLI 可用性

```bash
gh auth status
```

如不可用，将格式化的 Issue 内容输出到会话中，供用户手动提交到 GitHub。

## Step 6：格式化并提交 GitHub Issue

### Issue 标题

格式：`[<skill-name>] <简要描述>`

### Issue 内容

```markdown
## 反馈类型

<步骤错误 / 分支遗漏 / 信息过时 / 流程缺失 / Resource 缺失 / Resource 不准 / 体验改进>

## 目标 Skill

- **Skill**: <skill-name>
- **文件**: <SKILL.md 和/或 resources/xxx.md>
- **Marketplace 版本**: <commit hash>

## 使用上下文

- **项目**: <当前项目名称>
- **项目版本**: <commit hash>
- **OS**: <macOS / Linux / Windows>

## 问题描述

<具体描述哪里有问题、在什么场景下触发>

## 建议改进

<具体的改进建议>

---
*由 enhance-skill 自动生成*
```

### 提交

```bash
gh issue create --repo A2C-SMCP/a2c-smcp-skills \
  --title "<格式化标题>" \
  --body "<格式化内容>" \
  --label "enhance"
```

提交成功后输出 Issue 链接。

---

## 注意事项

- **不自动修改 Skill 文件**：本 Skill 仅提交反馈 Issue
- **敏感信息过滤**：提交前检查，移除 IP、密码、Token 等
- **一次一个改进**：多个改进点各创建独立 Issue
