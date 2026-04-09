---
name: organize-jira
description: 阶段性 Jira 任务梳理与结构化。扫描项目残留任务，分析结构问题，交互式商议 Epic 归档与优先级排序，批量执行归档操作。当阶段性开发完成后需要整理 Jira 任务时调用。
argument-hint: "<项目Key 或 JQL 或 Issue Key 列表>"
---

# Organize Jira — 任务梳理与结构化

阶段性开发完成后，Jira 任务往往散乱：缺少 Epic 归档、状态过期、关系不清晰。本 Skill 系统性梳理并结构化归档。

---

## Step 1：Jira 连接与范围确定

### 1.1 连接确认

使用 `mcp__atlassian__getVisibleJiraProjects` 获取可用项目列表，与用户确认目标 `cloudId` 和 `projectKey`。

### 1.2 确定梳理范围

通过 AskUserQuestion 确认模式：

| 模式 | 适用场景 | JQL 策略 |
|------|---------|---------|
| **全量扫描** | 项目内积累大量未处理任务 | `project = <KEY> AND status != Done ORDER BY created DESC` |
| **范围梳理** | 针对特定主题/时间段/一组 Issue | 用户提供 JQL 或 Issue Key 列表 |

**渐进式获取原则**：首次查询**只取摘要字段**，不读详情。

```
fields: ["summary", "status", "issuetype", "priority", "parent"]
```

使用 `mcp__atlassian__searchJiraIssuesUsingJql` 分页获取（每页 50），逐页展示标题摘要。

---

## Step 2：建立全局视图

### 2.1 任务分类统计

按维度汇总展示给用户：

- **按类型**：Epic / Story / Task / Bug / Sub-task 各多少
- **按状态**：待办 / 进行中 / 已完成 各多少
- **按归属**：已归入 Epic vs 无 parent 的独立任务

### 2.2 识别结构问题

| 问题类型 | 识别方法 |
|---------|---------|
| **散落任务** | 无 parent 且非 Epic 类型的 Issue |
| **状态过期** | 实际已完成但状态仍为待办/进行中 |
| **关系不当** | 通过 Relates 链接但更适合 parent 关系 |
| **重复/过时** | 标题相似或描述明显过时 |

对识别出的问题任务，再使用 `mcp__atlassian__getJiraIssue` 按需读取详情（**仅限用户选定的关注范围**）。

---

## Step 3：Epic 规划与优先级商议

**此步骤为多轮交互，每个决策都通过 AskUserQuestion 与用户逐一确认。**

### 3.1 Epic 归档建议

基于全局视图，逐组提出归档方案：

1. 哪些散落任务可归入**现有 Epic**？
2. 哪些任务需要**新建 Epic** 统一管理？建议 Epic 名称和描述
3. 哪些任务应保持**独立**（一次性任务、不属于任何主题）？

每组使用 AskUserQuestion 确认，用户可调整分组和 Epic 命名。允许多轮迭代直到满意。

### 3.2 优先级排序

对需保留的未完成任务，提出优先级建议：

| 优先级 | 判定依据 |
|--------|---------|
| **高** | 阻塞其他任务 / 影响核心功能 / 用户明确要求 |
| **中** | 有明确价值但不紧急 |
| **低** | nice-to-have / 可延后 |

使用 AskUserQuestion 展示排序方案，用户可逐项调整。

### 3.3 状态清理建议

- 哪些任务应关闭（已完成/过时/重复）？
- 哪些任务状态需更新？

所有决策确认后，汇总为完整的执行计划展示给用户做最终审批。

---

## Step 4：执行梳理

**展示完整操作清单，获取用户最终确认后才执行。**

### 操作映射

| 操作 | 工具 |
|------|------|
| 创建 Epic | `mcp__atlassian__createJiraIssue`（issueTypeName: "Epic"） |
| 设置 parent | `mcp__atlassian__editJiraIssue`（fields: `{"parent": {"key": "EPIC-KEY"}}`） |
| 更新优先级 | `mcp__atlassian__editJiraIssue`（fields: `{"priority": {"name": "..."}}`） |
| 推进状态 | `mcp__atlassian__transitionJiraIssue`（先 getTransitions 查可用状态） |
| 添加关联 | `mcp__atlassian__createIssueLink` |

### 执行顺序

1. **创建 Epic**（如有新建需求）
2. **归档**：设置 parent 关系，将任务挂入 Epic
3. **更新**：优先级和状态变更
4. 每步完成后向用户报告进度

---

## Step 5：梳理报告

输出结构化报告：

```markdown
## 梳理报告 — <项目Key> (<日期>)

### 统计
- 扫描任务数：N | 新建 Epic：N | 归档：N | 状态更新：N | 优先级调整：N

### 新建 Epic
- EPIC-KEY: <标题>

### 归档明细
| Epic | 归入任务 |
|------|---------|
| EPIC-KEY | TASK-1, TASK-2, ... |

### 状态变更
| 任务 | 原状态 → 新状态 |

### 优先级调整
| 任务 | 原优先级 → 新优先级 |

### 待后续处理
- [未纳入本次梳理的任务及原因]
```

---

## 强制约束

- **渐进式获取** — 首次只取标题/状态/类型，深入分析时才读详情
- **先确认再执行** — 每个 Epic 归档和优先级决策都经用户确认
- **不自动关闭** — 状态变更必须获得用户明确同意
- **不修改内容** — 仅调整结构（parent、status、priority、link），不改 Issue 正文
