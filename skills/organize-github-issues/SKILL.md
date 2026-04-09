---
name: organize-github-issues
description: 阶段性 GitHub Issue 梳理与结构化。扫描项目残留 Issue，分析结构问题，交互式商议 Milestone/Label 归档与优先级排序，批量执行整理操作。当项目积累大量未处理 Issue 需要系统性整理时调用。
argument-hint: "<owner/repo 或搜索条件>"
---

# Organize GitHub Issues — Issue 梳理与结构化

项目开发过程中 Issue 越积越多，阶段性完成后往往散乱：缺少 Milestone 归档、已完成未关闭、Label 不统一。本 Skill 系统性梳理并结构化归档。

**工具依赖**：全程通过 `gh` CLI 操作，执行前先验证 `gh auth status`。

---

## Step 1：确定目标仓库与梳理范围

### 1.1 仓库确认

```bash
gh repo view <owner/repo> --json name,description,hasIssuesEnabled
```

如用户未指定仓库，从当前目录推断（`gh repo view`）。

### 1.2 确定梳理范围

通过 AskUserQuestion 确认模式：

| 模式 | 适用场景 | 命令 |
|------|---------|------|
| **全量扫描** | 项目内积累大量未处理 Issue | `gh issue list -R <repo> --state open --limit 200 --json number,title,state,labels,milestone,assignees` |
| **范围梳理** | 针对特定 Label/Milestone/时间段 | `gh issue list -R <repo> --label <label>` 或 `gh search issues "repo:<repo> <条件>"` |

**渐进式获取原则**：首次查询**只取编号、标题、状态、Label、Milestone**，不读详情。

---

## Step 2：建立全局视图

### 2.1 Issue 分类统计

获取现有 Label 和 Milestone 信息：

```bash
gh label list -R <repo> --json name,description
gh api repos/<owner>/<repo>/milestones --jq '.[].title'
```

按维度汇总展示：

- **按 Label**：bug / feature / enhancement / 各自定义 Label 各多少
- **按 Milestone**：已归入 Milestone vs 无 Milestone 的散落 Issue
- **按状态**：open / closed 各多少
- **按活跃度**：长期无更新的 Issue（> 30 天无评论/变更）

### 2.2 识别结构问题

| 问题类型 | 识别方法 |
|---------|---------|
| **散落 Issue** | 无 Milestone 且无明确 Label 归属 |
| **应关闭未关闭** | 实际已解决但状态仍为 open |
| **Label 混乱** | 缺少 Label 或 Label 使用不一致 |
| **重复/过时** | 标题相似或长期无活动 |

对识别出的问题 Issue，再按需读取详情：

```bash
gh issue view <number> -R <repo> --json title,body,comments,labels,milestone
```

---

## Step 3：Milestone 规划与优先级商议

**此步骤为多轮交互，每个决策都通过 AskUserQuestion 与用户逐一确认。**

### 3.1 Milestone 归档建议

基于全局视图，逐组提出归档方案：

1. 哪些散落 Issue 可归入**现有 Milestone**？
2. 哪些 Issue 需要**新建 Milestone** 统一管理？建议 Milestone 名称和描述
3. 哪些 Issue 应保持**独立**（一次性问题、不属于任何里程碑）？

每组使用 AskUserQuestion 确认，用户可调整分组和命名。允许多轮迭代直到满意。

### 3.2 优先级与 Label 整理

对需保留的未关闭 Issue，提出分级建议：

| 优先级 | 判定依据 | 建议 Label |
|--------|---------|-----------|
| **高** | 阻塞其他工作 / 影响核心功能 | `priority/high` |
| **中** | 有明确价值但不紧急 | `priority/medium` |
| **低** | nice-to-have / 可延后 | `priority/low` |

同时检查 Label 使用一致性，建议统一命名和清理冗余 Label。

使用 AskUserQuestion 展示排序方案，用户可逐项调整。

### 3.3 关闭建议

- 哪些 Issue 应关闭（已解决/过时/重复）？关闭时附说明评论
- 哪些 Issue 需补充 Label 或重新分配？

所有决策确认后，汇总为完整的执行计划展示给用户做最终审批。

---

## Step 4：执行梳理

**展示完整操作清单，获取用户最终确认后才执行。**

### 操作映射

| 操作 | 命令 |
|------|------|
| 创建 Milestone | `gh api repos/<owner>/<repo>/milestones -f title="..." -f description="..."` |
| 归入 Milestone | `gh issue edit <number> -R <repo> --milestone "<name>"` |
| 添加 Label | `gh issue edit <number> -R <repo> --add-label "<label>"` |
| 移除 Label | `gh issue edit <number> -R <repo> --remove-label "<label>"` |
| 关闭 Issue | `gh issue close <number> -R <repo> -c "<关闭原因>"` |
| 创建 Label | `gh label create "<name>" -R <repo> --description "..." --color "..."` |

### 执行顺序

1. **创建** Milestone 和 Label（如有新建需求）
2. **归档**：将 Issue 归入 Milestone、补充 Label
3. **关闭**：附评论说明后关闭过时/已解决的 Issue
4. 每步完成后向用户报告进度

---

## Step 5：梳理报告

输出结构化报告：

```markdown
## 梳理报告 — <owner/repo> (<日期>)

### 统计
- 扫描 Issue 数：N | 新建 Milestone：N | 归档：N | Label 调整：N | 关闭：N

### 新建 Milestone
- <Milestone 名>：<描述>

### 归档明细
| Milestone | 归入 Issue |
|-----------|-----------|
| <name> | #1, #2, ... |

### Label 调整
| Issue | 变更 |
|-------|------|
| #N | +label, -label |

### 已关闭
| Issue | 关闭原因 |
|-------|---------|

### 待后续处理
- [未纳入本次梳理的 Issue 及原因]
```

---

## 强制约束

- **渐进式获取** — 首次只取标题/Label/Milestone，深入分析时才读详情
- **先确认再执行** — 每个归档和优先级决策都经用户确认
- **不自动关闭** — 关闭操作必须获得用户明确同意，且附评论说明
- **不修改内容** — 仅调整结构（Milestone、Label、状态），不改 Issue 正文
