---
name: issue-radar
description: SMCP 核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）Issue 态势扫描。在解决问题、提报 Issue、发起跨项目问询之前，或开发/方案制定过程中方案发生变化时，扫描三仓 open Issue / PR / Discussion，识别同主题是否已有人推进、在推方案与本次意图是否冲突（如默认名不同、双向镜像 Issue）。发现冲突时显式向用户报告推进现状，要求用户协调对应工程师暂停对齐后再继续。被 fix-issue / add-feature / issue-report 作为前置门控按名拉起，也可独立调用。
argument-hint: "<主题/问题简述>"
---

# Issue Radar — 三仓态势扫描

三端同步开发下，python-sdk 与 rust-sdk 可能几乎同时发现同一个协议不合理点，但方案细节相异（如默认名不同）；也可能互相向对方提出"要求对齐"的镜像 Issue。本 skill 在动手前扫清态势：**先认清谁已经在做什么，再决定自己做什么。**

**定位**：只读侦察。本 skill 不建 Issue、不改状态、不归并——归并消解交 `/consolidate-issues`，提报交 `/issue-report`，问询交 `/cross-ask`。

## 三仓定义（SMCP 核心协同区）

| 仓库 | GitHub | 角色 |
|------|--------|------|
| a2c-smcp-protocol | A2C-SMCP/a2c-smcp-protocol | 协议规范（source of truth）+ 三仓协同留痕中枢（Discussions） |
| python-sdk | A2C-SMCP/python-sdk | SMCP 参考实现 |
| rust-sdk | A2C-SMCP/rust-sdk | SMCP 生产实现 |

## 触发场景

| 场景 | 拉起方 |
|------|--------|
| 修复问题、根因分析前 | `fix-issue` Step 1.3 门控 |
| 新增 Feature、建追踪结构前 | `add-feature` Step 0.5 门控 |
| 提报 Issue 前 | `issue-report` Step 2.5 门控 |
| 开发中 / 方案制定中**方案发生变化** | 任意流程重入本 skill |
| 发起三仓问询前摸底（建议） | `cross-ask` |
| 用户主动了解三仓态势 | 直接调用 |

> 当前项目不属于核心三仓时，本 skill 不适用，上游门控自动豁免。

---

## Step 1：提取扫描主题与关键词

从参数 / 当前会话上下文提取：

1. **主题一句话**：本次要解决/提报/变更的是什么
2. **关键词组**（中英文都要）：事件名（如 `client:call_tool`）、数据结构名（如 `CallToolRequest`）、字段名、默认值名、模块/行为名
3. **本侧意图方案要点**：如果上游流程已有初步方案（如"默认名定为 X"），逐条列出——Step 3 要拿它与在推方案比对

## Step 2：三仓扫描（渐进式）

**先列表后详情**：首轮只取编号/标题/负责人等元数据，命中候选再读详情。

```bash
# 1) 三仓 open Issue 列表
for repo in a2c-smcp-protocol python-sdk rust-sdk; do
  gh issue list -R A2C-SMCP/$repo --state open --limit 100 \
    --json number,title,labels,assignees,milestone,updatedAt
done

# 2) 关键词定向搜索（含 closed，防止主题刚被处理完）
gh search issues "<关键词>" --repo A2C-SMCP/a2c-smcp-protocol \
  --repo A2C-SMCP/python-sdk --repo A2C-SMCP/rust-sdk \
  --json repository,number,title,state,updatedAt

# 3) open PR —— 有人已在写代码是最强的推进信号
for repo in a2c-smcp-protocol python-sdk rust-sdk; do
  gh pr list -R A2C-SMCP/$repo --state open --json number,title,author,headRefName,updatedAt
done

# 4) protocol 仓 Discussions（cross-ask 问询留痕中枢，未闭环的讨论也算在推）
gh api graphql -f query='{ search(type: DISCUSSION, first: 20,
  query: "repo:A2C-SMCP/a2c-smcp-protocol <关键词>") {
    nodes { ... on Discussion { number title updatedAt category { name } } } } }'
```

命中候选后读详情（一律带 `--json`，规避 projectCards 弃用错误）：

```bash
gh issue view <N> -R A2C-SMCP/<repo> --json title,body,comments,assignees,labels,milestone,url
```

## Step 3：关联性与推进强度判定

### 3.1 关联类型

| 关系 | 判定信号 | 含义 |
|------|---------|------|
| **同主题在推** | 同一事件/字段/行为的 Issue 有 assignee / 关联 PR / 近期评论 | 已有人在做 |
| **镜像 Issue** | python-sdk 与 rust-sdk 各有一个要求**对方**对齐的 Issue | 双方并行互提，典型冲突源 |
| **方案冲突** | 两仓对同一协议点各给方案，细节相异（默认名 / 字段名 / 语义） | 需统一裁决 |
| **级联在推** | 协议 Issue + 多个 SDK 跟进 Issue 已成树 | 已有推进树，本次应挂靠 |

### 3.2 推进强度（由强到弱）

有 open PR 关联 > assignee + 近 7 天有评论 > 仅有 assignee > 无人认领的 open Issue。

### 3.3 在推方案合理性评估

对每条"同主题在推"线索，从 Issue 正文 / 评论 / PR diff 提炼**在推方案要点**，与 Step 1 的本侧意图逐条比对，标注：`一致` / `分歧（列出具体点）` / `信息不足`。分歧点必须具体到值，如「对方默认 room 名 `default`，本侧分析建议 `agent_room`」。

## Step 4：态势报告（固定格式，直接输出给用户）

```markdown
## 三仓态势报告 — <主题>

### 相关线索
| # | 位置 | 标题 | 推进人 | 强度 | 与本次关系 |
|---|------|------|--------|------|-----------|
| 1 | <repo>#N / PR#N / discussion#N | ... | @xxx | PR 在推 / 认领 / 无人 | 同主题 / 镜像 / 冲突 / 级联 |

### 在推方案 vs 本侧意图
| 分歧点 | 在推方案 | 本侧意图 | 影响 |
|--------|---------|---------|------|

### 结论：🟢 / 🟡 / 🔴（见 Step 5）
```

## Step 5：结论分级与门控动作

| 态势 | 灯色 | 动作 |
|------|------|------|
| 无相关线索；或相关 Issue 已关闭且结论与本侧一致 | 🟢 | 返回上游继续；后续建 Issue / 写方案时引用扫描到的线索 |
| 有人推进，方案与本侧判断一致或更优 | 🟡 挂靠 | 不重复开工。返回上游改走挂靠：在对方 Issue 评论补充本侧信息、关注进展；需深入讨论 → `/cross-ask` |
| 有人推进，方案与本侧判断**冲突或存疑** | 🔴 | 走下方红灯处理 |
| 双向镜像 Issue / 同主题重复 Issue 堆积 | 🔴 | 报告现状，引导 `/consolidate-issues` 归并后再继续 |

### 🔴 红灯处理（硬门控）

1. **显式向用户报告推进现状**：谁（assignee / PR author）、在哪（repo#N）、在推方案要点、逐条分歧点、分歧的技术影响（跨端不一致 / 返工风险）
2. 用 AskUserQuestion 请用户决策：
   - **暂停协调（推荐）**：请用户找到对应项目正在推进的工程师**暂停**，双方对齐优化方案后再继续
   - **挂靠对方方案**：接受在推方案，本侧意图调整
   - **坚持并行**：必须说明理由，并经用户确认后在对方 Issue 评论留痕本侧不同意见（本 skill 唯一允许的写操作）
3. **用户未决策前，禁止返回上游流程继续动手。**

## 返回上游

被门控拉起时，把「态势报告 + 灯色 + 用户决策结果」带回上游 skill：🟢 原流程继续；🟡 上游按挂靠调整（复用已有 Issue、引用在推结论）；🔴 按用户决策执行。

---

## 强制约束

- **只读** — 不创建/修改任何 Issue / PR / Discussion（红灯"坚持并行"的留痕评论除外，且须经用户确认）
- **门控不可跳过** — 被上游拉起时必须完整执行，唯一豁免：当前项目不属于核心三仓
- **红灯必须点名** — 报告必须给出"谁在推进 + 具体分歧点"，禁止模糊表述"可能有冲突"
- **方案变更必须重扫** — 上游流程中方案发生实质变化（根因结论改变、设计方向调整）时重入本 skill
- **渐进式获取** — 先列表后详情，避免上下文爆炸
