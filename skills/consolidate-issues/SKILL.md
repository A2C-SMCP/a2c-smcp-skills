---
name: consolidate-issues
description: SMCP 核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）Issue 消解与归并。三端同步开发产生的重复 Issue、双向镜像 Issue、细节冲突方案（如默认名不同）做跨仓聚类消解：可归并的归并，方案冲突的升级协议裁决，可统一的纳管成 Epic（tracking Issue 统一落 a2c-smcp-protocol），再衔接 advance-plan 编排推进节奏。当三仓出现重复开发、反复修改、互相要求对方对齐的 Issue 堆积时调用。
argument-hint: "[主题范围，缺省为三仓全量 open Issue]"
---

# Consolidate Issues — 三仓问题消解与 Epic 纳管

三端同步开发的典型损耗：python-sdk 和 rust-sdk 几乎同时发现同一协议不合理点、各自提了方案细节相异的 Issue；或者双方各提了一个"要求对方对齐"的镜像 Issue，两边都在改。本 skill 把三仓 Issue 列表**跨仓聚类消解**——用更好的问题组织提升解决效率和推进节奏，终结重复开发与反复修改。

## 与相关 skill 的边界

| Skill | 边界 |
|------|------|
| `issue-radar` | 只读态势扫描（单主题、动手前）。本 skill 是**全量写操作消解**，扫描口径复用它。 |
| `organize-github-issues` | **单仓**结构整理（Milestone / Label / 关闭）。本 skill 落地单仓操作时复用其"操作映射"。 |
| `advance-plan` | 跨项目推进**编排**。本 skill 产出的 Epic 需要节奏化推进时交它排波次。 |
| `split-task` | Epic 需进一步拆解时调用。 |
| `add-feature` | 冲突裁决触发协议变更时，走它的协议先行流程。 |

**工具依赖**：全程 `gh` CLI，执行前 `gh auth status` 验证。

---

## Step 1：范围确认

用 AskUserQuestion 确认消解模式：

| 模式 | 适用 |
|------|------|
| **全量消解** | 三仓 open Issue 积累明显、重复冲突已成常态 |
| **主题消解** | 针对某一主题（如某事件/数据结构）的相关 Issue 集中消解 |

## Step 2：三仓全量视图（渐进式）

按 `skills/issue-radar/SKILL.md` Step 2 的扫描口径拉取三仓 open Issue / open PR / protocol 仓 Discussions（未闭环的 cross-ask 问询也纳入视图）。**先列表后详情**：仅对进入聚类的候选读正文和评论。

## Step 3：跨仓聚类

把相关 Issue 按主题聚类，每簇标注类型：

| 类型 | 特征 | 例子 |
|------|------|------|
| **重复** | 两仓（或同仓）就同一问题各开了 Issue | 双 SDK 同时发现同一协议缺陷 |
| **镜像对齐** | python-sdk 与 rust-sdk 互相要求**对方**向自己对齐 | 双方同时开发中各自建了要求对方修改的任务 |
| **方案冲突** | 同一协议点两侧方案细节相异 | 默认名一个叫 `default` 一个叫 `main` |
| **级联** | 一个协议缺口 + 多个 SDK 跟进 Issue，散落未成树 | 协议改了，SDK 跟进 Issue 各自为政 |
| **独立** | 与其他仓无关的单仓问题 | 不消解，必要时转 `/organize-github-issues` |

聚类产出表：`| 簇 | 类型 | 涉及 Issue | 各方方案要点 | 分歧点 |`

## Step 4：消解策略商议（决策前置批处理，硬门槛）

**学 `advance-plan` Phase 3：先把所有待决点一次性批量征询清干净，再执行。未清空禁止任何写操作。**

对每一簇按类型给出建议策略，用 AskUserQuestion **批量**确认：

| 类型 | 消解策略 |
|------|---------|
| **重复** | 保留信息最全者为主 Issue；其余关闭，关闭评论注明 `Consolidated into <repo>#N`；主 Issue 回链被并者 |
| **镜像对齐** | 归并为**一个**对齐 Issue：先定基准方——协议有定义 → 协议为准；协议不管 → 与用户商定基准（通常参考实现 python-sdk）；非基准方 Issue 关闭或改为 blocked-by 对齐结论 |
| **方案冲突** | **升级协议裁决**：在 a2c-smcp-protocol 建（或复用）裁决 Issue，正文列两侧方案对比表；两侧 SDK Issue 标注 blocked-by 裁决；裁决需改协议 → 走 `/add-feature` 协议先行 |
| **级联** | 纳管成 Epic（Step 5），散落 Issue 挂为 sub-issue |

> 冲突裁决"协议管不管"的判定标准见单一源：`skills/answer-ask/resources/protocol-scope.md`。协议不管的冲突（纯 SDK 自治点）→ 在 protocol 仓 Discussion 对齐留痕，不建协议 Issue。

## Step 5：Epic 纳管

**跨仓 Epic（tracking Issue）统一落 a2c-smcp-protocol 仓**——它是三仓协同中枢。内容不触协议时也落这里，正文顶部标注 `> 协议不介入，本 Issue 仅作三仓协同留痕`。

Epic 正文结构（与 advance-plan 母计划口径一致）：

```markdown
## 目标
## 依赖图 [ASCII，触协议时协议节点置根]
## 子 Issue 勾选清单
- [ ] A2C-SMCP/a2c-smcp-protocol#N（协议裁决/变更，先行）
- [ ] A2C-SMCP/python-sdk#N — blocked-by 协议节点
- [ ] A2C-SMCP/rust-sdk#N — blocked-by 协议节点
```

挂 sub-issue（同 org 跨仓支持）：

```bash
# 取 Issue node ID
gh api repos/A2C-SMCP/<repo>/issues/<N> --jq .node_id
# 挂载
gh api graphql -F parentId=<Epic node_id> -F childId=<子 Issue node_id> -f query='
mutation($parentId: ID!, $childId: ID!) {
  addSubIssue(input: {issueId: $parentId, subIssueId: $childId}) {
    issue { number } } }'
```

## Step 6：执行消解（确认后）

执行顺序（每步向用户报进度）：

1. **建**：裁决 Issue / 对齐 Issue / Epic
2. **挂**：sub-issue 挂载、blocked-by 标注、互相引用
3. **改**：Label / Milestone 补齐（单仓细节复用 `organize-github-issues` Step 4 操作映射）
4. **关**：关闭被归并的重复/镜像 Issue，附归并说明评论

## Step 7：衔接推进

- Epic 需多波次推进（协议先行解锁、跨仓依赖）→ `/advance-plan <Epic#>` 接管编排
- 简单 Epic → 按勾选清单直接推进，各节点走 `/fix-issue` / `/add-feature`

## Step 8：消解报告

```markdown
## 三仓消解报告 (<日期>)

### 统计
- 扫描：protocol N / python N / rust N | 聚类簇数：N | 归并关闭：N | 升级裁决：N | 新建 Epic：N

### 消解明细
| 簇 | 类型 | 处理 | 结果 |
|----|------|------|------|
| <主题> | 重复/镜像/冲突/级联 | 归并到 <repo>#N / 裁决 <repo>#N / Epic <repo>#N | 链接 |

### 待用户跟进
- [需要联系哪位工程师暂停/对齐的事项]
```

---

## 强制约束

- **先商议后执行** — Step 4 决策未批量清空前，禁止任何写操作
- **不自动关闭** — 每个关闭都经用户确认，且必须附归并说明评论
- **冲突不私了** — 方案冲突必须升级 protocol 仓裁决/对齐留痕，禁止在单侧 SDK Issue 里拍板
- **Epic 统一落 protocol 仓** — 跨仓 Epic 不散落在 SDK 仓
- **不改正文** — 只做结构消解（关闭/挂载/标注/评论），不改他人 Issue 正文
- **渐进式获取** — 先列表后详情
