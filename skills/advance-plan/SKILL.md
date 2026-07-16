---
name: advance-plan
description: A2C-SMCP 跨项目推进计划编排层（conductor）。把已有 + 推进中新发现的 Issue#ID 排成有节奏的跨项目推进计划，随发现递归展开、随解决收敛回填，以 GitHub tracking Issue 为唯一载体。协议先行：触协议的节点置依赖图根，SDK 节点 blocked-by 它。本 skill 自身不拆解、不实现——需拆某节点调 split-task；推单节点调 add-feature/fix-issue；协议节点发布调 release；建新 Issue 调 issue-report；跨项目决策调 cross-ask。当用户说「制定推进计划」「推进这个跨项目任务」「编排多仓 Issue 落地节奏」，或 add-feature/fix-issue 执行中动态展开成跨项目推进树需接管时触发。
argument-hint: "<根 Issue#ID | Epic | 一句话推进目标>"
---

# Advance Plan — 跨项目推进计划编排（协议先行 + 递归展开/收敛）

把「已有 + 推进中新发现」的 Issue#ID 排成一个有节奏、跨项目的推进计划，随发现**递归展开**、随解决**收敛回填**，全程以 GitHub tracking Issue 为唯一载体。

**核心心法：分析 ≠ 征询 ≠ 拆解 ≠ 执行，四段严格分离、不交织。** 委托编排最常见的失败是「左脚绊右脚」——任务依赖 A、A 又要拆 B/C、拆 B/C 的原则又要临时问用户，三件事搅在一起。本 skill 用**决策前置批处理**（Phase 3 硬门槛）根治它。

> **定位（conductor）**：本 skill 是**运行时推进编排层**，自身不拆解、不实现。需要拆某节点 → 调 `split-task`；推进单节点 → 调 `add-feature`/`fix-issue`；协议节点发布 → 调 `release`；建新 Issue → 调 `issue-report`；跨项目决策 → 调 `cross-ask`。

---

## 与其他 skill 的关系

| Skill | 关系 |
|------|------|
| `split-task` | **事前拆（one-shot）**：把 Epic 静态切成子任务树 + 依赖图。本 skill 需拆某节点时**调用它**，消费其 sub-issue 树；不自带拆解逻辑。 |
| `add-feature` / `fix-issue` | **执行单节点**。反向衔接：二者执行中**动态展开成跨项目推进树**时**上交本 skill**接管级联 + 收敛，解决后返回（见文末「何时上交」）。 |
| `release` | 协议子节点「完成」判据 = **协议已发布** → 调用它收口。 |
| `issue-report` | 递归中新发现的跨仓工作 → 调用它建 Issue。 |
| `cross-ask` | 需其他项目工程师协助的决策点 → 调用它。 |
| `issue-radar` | **现状勘察增强**：核心三仓节点在 Phase 1 拉起它补充实时态势（在推 PR / Discussion / 镜像 Issue / 方案冲突）。 |
| `consolidate-issues` | **编排前预处理**：三仓 Issue 存在重复 / 镜像 / 冲突堆积时，先调它消解归并成 Epic，再进本 skill 排波次。 |

**split-task vs advance-plan**：前者是**静态一次性切刀**，后者是**运行时动态编排**——已有 + 新发现的节点排波次，展开-收敛不断循环。

---

## 前置依赖

| 平台 | 依赖 | 关键操作 |
|-----|------|---------|
| **GitHub（A2C 主平台）** | `gh` CLI（CLAUDE.md 强制用 gh，非 GitHub MCP）| tracking Issue 建/读/回填、`gh api graphql addSubIssue` 挂子计划 |

> `gh issue view` 若报 projectCards 弃用错误，一律带 `--json` 字段查询规避。

---

## Phase 0：输入识别

| 输入 | 处理 |
|------|------|
| 根 Issue#ID / `owner/repo#N` | `gh issue view <N> --repo <owner/repo> --json title,body,milestone,labels,subIssuesSummary` 拉现状 |
| Epic / 一句话目标 | `AskUserQuestion` 确认推进对象、涉及仓库、是否已有根 Issue |
| add-feature/fix-issue 上交 | 以上交节点为根，继承其已知上下文 |

**准出**：推进对象清晰，落地平台（GitHub 为主）确定。

---

## Phase 1：现状勘察

拉取相关 Issue#ID 现状，画出当前地形：

1. 每个相关 Issue 的 open/closed、关联 PR、blocked 状态
2. 归属：**协议仓库**（a2c-smcp-protocol / oasp-protocol）vs **代码仓库**（python-sdk / rust-sdk / office4ai / ide4ai / 客户端）
3. 已存在的父子 / Milestone 关联
4. 核心三仓节点 → 按 `skills/issue-radar/SKILL.md` 补充实时态势（在推 PR / Discussion / 镜像 Issue）；发现重复/冲突堆积 → 先 `/consolidate-issues` 消解再编排

**准出**：相关节点现状清单 + 跨仓归属明确。

---

## Phase 2：依赖分析（协议先行）

画跨项目依赖图，守**协议先行铁律**（复用 `split-task` Phase 0.6）：

| 结论 | 编排含义 |
|------|---------|
| **触协议** | 协议节点置**依赖图根**；所有代码节点 `blocked-by` 它。协议节点在依赖图中拆两级里程碑：**develop 就绪**（合 develop + push，解锁下游开工）与**已发布**（由 `release` 收口，解锁下游合 main / 发版）。 |
| **不触协议** | 纯代码编排，按各仓 main 可消费约束逐层排 `blocks` / `blocked-by`。 |

ASCII 画出跨仓依赖图，协议在根、跨 SDK 实现平行。**准出**：依赖图 + 关键路径清晰。

---

## Phase 3：决策前置批处理（硬门槛，治「左脚绊右脚」的核心）

**在产出计划前，先把本层所有待决点一次性批量征询、清干净。**

1. 列出本层**所有**需用户明确 / 决策的点：要不要新建 Issue、某节点是否要拆（拆则本 Phase 后调 `split-task`）、归属哪个仓库、是否 descope、波次优先级、每波负责人……
2. 用 `AskUserQuestion` **批量**征询；可多轮，但必须「清干净」再进 Phase 4。
3. 涉及其他项目工程师的决策 → 调 `cross-ask`；需新建 Issue → 调 `issue-report`。

> **硬门槛：本 Phase 未清空前，禁止产出计划（Phase 4）。** 分析（Phase 1-2）、征询（Phase 3）、产出（Phase 4）三段严格分离，不得交织。

---

## Phase 4：产出母计划 tracking Issue

确认后统一形成**一个跨项目、基于 Issue#ID 的推进计划**，落 GitHub **母计划 tracking Issue**：

```markdown
## 推进目标
## 依赖图 [ASCII，协议置根]
## 波次计划
- [ ] Wave 1: <协议节点> #<id>（develop 就绪解锁开工；release 发布解锁发版）— 负责人 / 验收
- [ ] Wave 2: <SDK 节点> #<id> blocked-by #<协议> — 负责人 / 验收
- [ ] Wave 3: <集成 / 客户端> #<id>
```

- Issue#ID **勾选清单** + ASCII **依赖图** + **波次 / 节奏**
- 跨仓母计划用 **Milestone 归集** + body 反向索引（复用 `split-task` Phase 7.2 口径）
- `AskUserQuestion` 确认后才建 Issue

**准出**：母计划 tracking Issue 已建，波次与验收清晰。

---

## Phase 5：推进执行（按波次驱动）

按依赖图波次逐层驱动，每个节点调对应 skill：

| 节点类型 | 驱动 |
|---------|------|
| 协议节点 | `add-feature`（评审 → 合 develop + push，解锁下游开工）→ `release`（发布，解锁下游合 main / 发版）|
| SDK / 客户端 Feature | `add-feature` |
| Bug 修复 | `fix-issue` |
| 新发现跨仓工作 | `issue-report` 建 Issue → 排入波次 |

每完成一个节点 → 回填母计划勾选。**前一波未收口不解锁下一波**（协议 develop 未 push 禁下游开工；协议未发布禁下游合 main / 发版）。

---

## Phase 6：异常递归（展开 → 收敛）

推进某 Issue#ID 时若临时发现异常 / 协议缺口 → **递归再入本 skill**：

1. **展开**：以异常节点为根开一个**子计划**（回 Phase 3 把子层决策清干净 → Phase 4 建子计划 tracking Issue），用 `gh api graphql addSubIssue` **挂为母计划 sub-issue**。
2. **收敛（硬步骤）**：子计划全绿后，**回填母计划**对应勾选 + 评论说明，继续原波次。

形成「**不断展开、不断收敛回来**」的开发管理模式。**收敛不是可选项——子计划不回填母计划即视为未完成。**

---

## Phase 7：收官

1. 全波次绿灯，逐层验收（协议已发布、SDK 已实现、集成回归通过）
2. 回填并关闭所有子计划 → 关根 Issue
3. 输出推进总结（展开-收敛链、关键决策留痕）

---

## 何时上交 advance-plan

**供 `add-feature` / `fix-issue` 引用的单一源。** 二者执行单节点时，若**动态展开成跨项目推进树**——协议缺口传导多个 SDK / 客户端、衍生多个跨仓 Issue、需按波次编排 + 收敛——**上交 `/advance-plan`** 以本节点为根接管级联与收敛，解决后返回原流程收尾。

> **边界（防 ping-pong）**：单仓内的普通多步 / 多文件展开由 add-feature / fix-issue 自身消化，**不上交**；只有**跨项目 / 协议缺口级联**才上交。advance-plan 波次驱动回调 add-feature / fix-issue 时同理——单仓展开不再递归上交。

---

## 关键决策点（必须与用户对齐）

| 决策点 | Phase | 问题 |
|--------|-------|------|
| 推进 scope | 0 | 推进对象与平台是否确定？ |
| 协议先行 | 2 | 是否触协议？协议节点是否置根？ |
| 决策清空 | 3 | 本层待决点是否**全部**清干净？（未清禁产出）|
| 母计划下单 | 4 | tracking Issue 波次是否可落地？ |
| 收敛回填 | 6 | 子计划是否已回填母计划？ |

---

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 分析 / 征询 / 拆解交织（左脚绊右脚）| 四段分离 + Phase 3 决策前置批处理 |
| 决策边推边问、一个个挤牙膏 | Phase 3 一次性批量问清，清干净再产出 |
| 递归子计划不收敛回母计划 | 收敛是硬步骤（回填勾选 / 评论）|
| 协议节点未置根 / SDK 超前于协议门级 | 协议节点置根；develop 已 push 解锁开工，发布解锁合 main / 发版 |
| 母计划只在会话内、跨会话丢失 | 必须落 GitHub tracking Issue，跨会话可续 |
| 自带拆解逻辑重复造轮子 | 需拆节点调 `split-task`，本 skill 只编排 |
