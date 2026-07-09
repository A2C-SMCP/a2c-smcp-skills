---
name: split-task
description: 把一个较大的 A2C-SMCP Epic / Story / GitHub Issue（或 Jira / CNB Issue）科学拆成多个可独立交付的子任务，输出含依赖图与集成回归守护的拆分方案，并在对应平台用 sub-issue 能力下单。A2C 特有：涉及协议的拆分强制「协议先行」——协议子任务置于依赖图根，代码仓库子任务 blocked-by 它。当用户说「拆分这个任务」「把 Epic 拆成子任务」「分解 Story」「给个切刀方案」时触发。
argument-hint: "<GitHub Issue URL/编号 | Jira Key | CNB Issue | 设计文档路径 | 自由描述>"
---

# Split Task — A2C-SMCP Epic/Story 科学拆分

把一个较大 Epic/Story/Issue 切成职责清晰、可独立追踪的子任务清单，并在原平台用 sub-issue 能力落地。

**层级化硬约束**（按 Phase 0.5 识别选用）：
- **PR 边界（Epic → Story / Issue）**：每子任务单独 merge 后 main 可消费（编译 / 测试 / 业务行为不破）
- **Story 内分解（Story → Sub-task）**：默认同上；仅在**编译期/类型期耦合**（Protocol/interface/type signature、Rust trait 等）必要打包时可豁免中间态破坏——PR 显式标注「Story 边界前禁单独 merge」，依赖图末端 sub-task 必须把 main 拉回可消费

**软指标 + 必要打包**：单 sub-task ~200 LOC 参考；逻辑边界 > 行数；运行时耦合的原子单元保留打包，宁可大不引入 Optional default / 临时兼容层等过渡债。

> **A2C 跨仓天性**：A2C-SMCP 的 Epic 常天然跨仓（协议 + python-sdk + rust-sdk + 客户端）。拆分对象往往不是单仓，依赖图跨仓库，且受**协议先行**（见 Phase 0.6）与**跨 SDK 一致性**（见 Phase 6）两条 A2C 铁律约束。

---

## 与其他 skill 的关系

| Skill | 角色 | 衔接 |
|------|------|------|
| `split-task`（本 skill）| **事前拆**：把大 Epic/Story/Issue 切成子任务 | 输出平台原生 sub-issue 编号列表 + 跨仓依赖图 |
| `add-feature` | 单 Story 端到端实现（含协议先行门控）| 对每个 feature 型子任务单独驱动；**协议子任务必走它** |
| `fix-issue` | 单 Issue 修复 | 对每个修复型子任务单独驱动 |
| `organize-github-issues` | 事后归档 | 全部子任务 merge 后做最终结构梳理 |

`add-feature` Step 1.1 规模评估判定为**大型**（跨多仓/多协议线）时，应先调用 `split-task` 完成方法论级拆分，再回流 `add-feature` 驱动每个子项。

---

## 前置依赖

按拆分对象所在平台启用对应能力，启动时检查可用性，缺失则停止并提示：

| 平台 | 依赖 | 关键操作 |
|-----|------|---------|
| **GitHub（A2C 主平台）** | `gh` CLI（CLAUDE.md 强制用 gh，非 GitHub MCP）| `gh issue view --json` 读；`gh issue create` 建；`gh api graphql` 的 `addSubIssue` 关联原生 sub-issue |
| Jira | Atlassian MCP | `getJiraIssue` / `createJiraIssue`(issueType=Sub-task, parent=<key>) / `createIssueLink` |
| CNB | CNB MCP | `cnb_get_issue` / `cnb_create_issue`（无 sub-issue API，body 标 `Parent: #<n>` + `sub-task` label）|

> `gh issue view` 若报 projectCards 弃用错误，一律带 `--json` 字段查询规避。

---

## Phase 0：输入识别

| 输入形式 | 处理 |
|---------|------|
| GitHub Issue URL / `owner/repo#N` | `gh issue view <N> --repo <owner/repo> --json title,body,milestone,labels` 拉详情；记录 owner/repo |
| Jira Key | `getJiraIssue` 拉详情；记录 project key |
| CNB Issue | `cnb_get_issue` 拉详情；记录 repo path |
| 设计文档路径 | Read 文件；`AskUserQuestion` 询问落地平台与父级 Issue |
| 自由描述 | `AskUserQuestion` 确认归属仓库、落地平台、是否已有父 Issue |
| 未提供 | 引导用户给出拆分对象 |

**准出**：拆分对象 scope 清晰（目标产物 / 影响模块 / 关键约束），落地平台与父 Issue 已确定。

---

## Phase 0.5：识别拆分层级

| 拆分对象 | 子产物 | 硬约束 |
|---------|-------|-------|
| Epic | Story / Issue | main 可消费（强）|
| Story / Issue | Sub-task | 同上；编译期/类型期耦合可豁免中间态，末端 sub-task 拉回 main 可消费 |

---

## Phase 0.6：协议先行归属判定（A2C 铁律，强制）

**判定拆分对象是否触及协议**（A2C 事件/数据结构/错误码/房间模型，或 OASP 命名空间事件）：

| 结论 | 拆分含义 |
|------|---------|
| **涉及协议** | 必须切出一个**协议子任务**（落 a2c-smcp-protocol 或 oasp-protocol），置于**依赖图根**；所有代码仓库子任务（python-sdk / rust-sdk / office4ai / 客户端）**blocked-by** 它。协议子任务由 `/add-feature` 驱动（协议评审 → 合并 → 发布），**发布前禁止任何代码子任务 merge**。 |
| **不涉及协议** | 纯代码拆分，按标准 main 可消费约束 |

> **硬门控**：协议子任务的"完成"判据是**协议已发布**（非仅 main 可消费）。这替换了该根节点的 Phase 3 判据。参见 `skills/add-feature/SKILL.md` 协议先行门控。

---

## Phase 1：改动地形勘察

**目标**：搞清 scope 内会动多少地——A2C 场景先定**跨仓范围**，再逐仓勘察。

1. **跨仓范围**：本次改动落哪些仓库（协议 / python-sdk / rust-sdk / office4ai / ide4ai / 客户端）
2. **受影响文件清单**：每仓 grep 关键符号 / 模块路径
3. **模块归属**：每个文件落到哪个 layer / crate
4. **依赖追踪**：上游 caller / 下游 callee / 跨 SDK 共享的协议数据结构

**按项目类型**：参见 `{baseDir}/resources/<project>.md` 的「模块边界识别」章节

**准出**：跨仓地形图清晰（受影响仓库 + 文件 + 模块 + 依赖）。

---

## Phase 2：候选切分识别

**目标**：按职责轴画切刀候选。每条切刀线写明：**职责描述**（一句话）、**范围**（文件清单）、**粗估 LOC**、**所属仓库**。

**A2C 切刀启发**：
- **协议单独成刀**：任何协议变更切成独立子任务，置根（Phase 0.6）
- **沿仓库/层切**：python-sdk（agent/computer/server）、rust-sdk（crate 边界）、office4ai（OASP 双路径）各成刀
- **跨 SDK 平行切**：同一协议变更的 python-sdk 与 rust-sdk 实现是**平行子任务**（都 blocked-by 协议）
- **沿职责切**：数据结构 vs 行为新增 vs 测试守护

**准出**：候选切刀清单，每刀职责单一、可一句话描述、标明所属仓库。

---

## Phase 3：切刀验证（"main 状态可消费"测试）

**目标**：检验每条切刀线单独 merge 后其所在 repo 的 main 是否仍可消费。**决刀位的硬门槛。**

> 协议根子任务用 Phase 0.6 判据（协议已发布）替代本表；代码子任务用下表。Story 内分解仅**编译期/类型期耦合**可豁免中间态破坏，末端 sub-task 必须拉回。

| 检查项 | 通过条件 |
|--------|---------|
| 编译 | 无类型错误（mypy / cargo check）、无未定义引用 |
| 测试 | 现有测试全过，新增测试对应通过 |
| 业务行为 | 关键链路不破（手测或冒烟）|
| 不引入临时债 | 无 Optional default / 临时兼容层 / 半修中间态 |
| **未超前于协议** | 代码子任务不实现尚未发布的协议语义（A2C）|

**任何一项不通过** → 撤回此刀，与相邻 sub-task **合并成更大原子单元**。

**准出**：每个保留 sub-task 通过其 repo 的 main 可消费验证。

---

## Phase 4：三轴平衡评估

| 轴 | 评估问题 |
|---|---------|
| 可观察性 | 该 sub-task 自带验证手段？验证范围与改动匹配？ |
| 可维护性 | 改动单一模块/crate？依赖明确？ |
| 独立性 | 能与其他 sub-task 并行开发？是否需串行？ |

低分项需说明理由（如协议→SDK 的串行顺序）或调整切刀。

---

## Phase 5：依赖图绘制（A2C 跨仓）

ASCII 画出 blocks / blocked-by，**协议子任务在根，跨 SDK 实现平行**：

```
[协议] a2c-smcp-protocol 事件新增 ──┬──→ [python-sdk] computer 实现 ─┐
  (add-feature 发布后解锁)          └──→ [rust-sdk] smcp-computer 实现 ┼─→ [集成] 跨 SDK 序列化兼容守护
                                        [客户端] tfrobot-client 适配 ─┘
```

标注每个 sub-task 所属仓库、可否并行 ship、关键路径长度。**准出**：跨仓依赖图 + 并行路径已明确。

---

## Phase 6：集成测试 sub-task 设计（依赖图末端）

**目标**：纯测试子任务，零生产风险，守护**任何单 sub-task 都无法独立守护的跨边界能力**回归。放依赖图末端、单独成刀、不混功能改动。

**A2C 必守不变量**（与项目专属清单叠加）：
- **跨 SDK 序列化兼容**：python-sdk 与 rust-sdk 对同一协议结构的序列化/反序列化互通（跨语言 round-trip）
- **协议 conformance**：实现严格符合已发布协议规范（事件名/字段/错误码）

**按项目类型**：参见 `{baseDir}/resources/<project>.md` 的「关键架构能力守护清单」章节

### 覆盖完整性核验（必勾，与 Phase 3 并列硬门槛）

- [ ] **父级验收逐条映射**：父 Epic/Story 每条验收标准都映射到至少一个 sub-task，无验收悬空
- [ ] **跨 sub-task invariant 守护**：跨越 sub-task 边界的关键不变量（协议 conformance / 跨 SDK 兼容 / FSM / 房间模型等）每条有对应用例
- [ ] **协议先行闭环**（如涉及协议）：协议子任务已在根、已发布，代码子任务全部 blocked-by 且不超前
- [ ] **依赖图末端唯一**：末端测试是依赖图唯一汇聚点（如非唯一，回 Phase 5 调整）

任何一项未勾 → 末端 sub-task 范围必须扩，或回 Phase 2 重新切。

**准出**：集成测试 sub-task 验收清单已列出，覆盖完整性核验全勾。

---

## Phase 7：用户确认 + 平台落地 sub-issue

### 7.1 输出最终拆分方案

```markdown
## 拆分方案
### 拆分理念  [为什么这么切，含"为什么不再细拆 X"]
### Sub-task 清单
#### 1. [仓库] 标题
- 目标 / 范围（文件清单）/ 预估 LOC / 测试 / 依赖(blocked-by、blocks) / 可独立 ship / 验收
### 依赖图 [ASCII]
### 总 LOC 估算  [符合软指标 / 承认必要打包]
```

`AskUserQuestion` 确认方案，用户可逐项调整。**未确认前不在任何平台创建子项。**

### 7.2 按平台原生 sub-issue 能力下单

| 平台 | 落地步骤 |
|-----|---------|
| **GitHub 同仓子项** | 1) `gh issue create --repo <owner/repo> --title ... --body ...`；2) 取父子 node id：`gh issue view <n> --json id`；3) `gh api graphql -f query='mutation($p:ID!,$c:ID!){addSubIssue(input:{issueId:$p,subIssueId:$c}){clientMutationId}}' -f p=<父id> -f c=<子id>` 关联原生 sub-issue |
| **GitHub 跨仓子项**（A2C Epic 跨仓）| 原生 sub-issue 跨仓支持有限——用 **Milestone 归集** + 子 Issue body 写 `Part of <owner/repo>#<父号>` + 父 Issue 追加 `## Sub-tasks` 任务清单反向索引（与 `add-feature` Step 1.3 父子检测方式对齐）|
| Jira | `createJiraIssue`(issueType=Sub-task, parent=<父 Key>)；`createIssueLink` 补 blocks 关系 |
| CNB | `cnb_create_issue`(body 顶写 `Parent: #<父号>`) + `cnb_set_issue_labels` 加 `sub-task` + 父 Issue 追加任务清单 |

完成后输出子项编号列表 + 跨仓依赖图，供 `add-feature` / `fix-issue` 接力。

---

## 关键决策点（必须与用户对齐）

| 决策点 | Phase | 问题 |
|--------|-------|------|
| 输入 scope | 0 | 拆分对象与落地平台是否确定？ |
| 协议先行 | 0.6 | 是否涉及协议？协议子任务是否置根？ |
| 拆分层级 | 0.5 | 拆 Story 还是 Sub-task？适用哪套硬约束？ |
| main 可消费 | 3 | 哪些刀必须撤回打包？ |
| 拆分方案 | 7 | 最终 sub-task 清单是否可下单？ |

---

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 涉及协议却不置协议子任务于根 | Phase 0.6 强制协议先行，协议子任务在依赖图根 |
| 代码子任务超前实现未发布协议 | 代码 blocked-by 协议发布，Phase 3 明确禁超前 |
| python-sdk 改了 rust-sdk 不同步 | 跨 SDK 平行子任务 + 末端跨 SDK 序列化兼容守护 |
| 凭行数硬切，破 main | 用「main 可消费」硬约束验证每刀 |
| Sub-task 层硬套「main 可消费」过度打包 | Phase 0.5 层级化约束 + Story 边界守护 |
| 为达小 PR 引入 Optional default / 兼容层 | 承认必要打包，宁可大不引入过渡债 |
| 漏集成回归 | 末端单独留集成测试 sub-task |
| 用 GitHub MCP 建子项 | 按 CLAUDE.md 用 `gh` CLI + `gh api graphql addSubIssue` |
| 跳过用户确认直接建子项 | 方案确认后才下单 |
