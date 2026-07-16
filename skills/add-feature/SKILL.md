---
name: add-feature
description: A2C-SMCP 体系新增功能的流程门控。强制协议先行（分级）——涉及协议的 Feature 须先在协议仓评审合入 develop 并 push，代码仓才可在 develop 开工；协议正式发布后，代码仓才可合入 main/发版。当用户提出新功能需求或 Feature Request 时调用。
argument-hint: "<feature 描述> [--review <block|all|discuss>]"
---

# Add Feature — 协议先行流程门控

A2C-SMCP 体系的核心原则：**协议先行，代码跟进**。设计与裁决必须先在协议仓达成；真正的硬不变量是「**绝不向外发布一个没有协议依据的 SDK**」——门控按分支分级（见 Step 4）。

---

## Step 0：判定协议归属

**判定规则**：

| 协议线 | 协议仓库 | 代码仓库 | 判定依据 |
|--------|---------|---------|---------|
| A2C | a2c-smcp-protocol | python-sdk, rust-sdk, tfrobot-client | 涉及 Agent-Server-Computer 通信、事件定义、数据结构、房间模型 |
| OASP | oasp-protocol | office4ai, office-editor4ai | 涉及 Office Add-In 与 AI 后端的 Socket.IO 通信、命名空间事件 |
| 无协议约束 | — | ide4ai 等独立项目 | 纯 MCP 工具、不涉及 A2C 通信协议的独立功能 |

**动作**：

1. 分析用户描述的 Feature，判断是否涉及协议变更
2. 如涉及多条协议线，按协议线分别走流程
3. 如不涉及任何协议（纯 MCP 工具等），跳至 Step 6 直接实现

> **注意**：独立演进的项目（如 ide4ai）在实现与 A2C 协议相关的部分时，仍需遵守已发布的协议规范，不得违反。

使用 AskUserQuestion 与用户确认判定结果。

---

## Step 0.5：三仓态势扫描门控（SMCP 核心三仓强制）

当前项目或协议线涉及核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）时，建立追踪结构（Step 1）前**必须**按 `skills/issue-radar/SKILL.md` 扫描三仓态势：同一 Feature / 协议点是否已有人推进？在推方案与本次设想是否冲突？

- 🟢 无人推进 → 继续 Step 1；🟡 有人推进且方案合理 → 挂靠在推 Issue/Epic，不重复立项
- 🔴 有人推进但方案冲突/存疑 → **显式向用户报告推进现状**（谁、在哪、方案分歧点），请用户协调对应工程师暂停对齐后再继续；**用户未决策不得进入 Step 1**
- Step 3 协议变更设计的 round-N 修订中方案发生实质变化 → **重走本门控**并告知用户，由用户协同各方

---

## Step 1：Issue 追踪治理

根据 Feature 规模建立合适的 GitHub 追踪结构（Milestone + Issue + Label），确保变更可溯源。

### 1.1 规模评估

| 变更规模 | 判定依据 | 追踪策略 |
|---------|---------|---------|
| **大型** | 跨多仓库/多协议线、预估多轮迭代 | 创建 Milestone → 拆分多个 Issue → 统一 Label |
| **中型** | 单仓库内、有明确边界 | 创建 Issue（可含 checklist 子任务）→ 归入现有或新建 Milestone |
| **小型** | 单文件级、改动收敛 | 至少创建 1 个 Issue 记录 |

### 1.2 已有 Issue 审视

如果用户带着已提报的 Issue 进来：

- **层级匹配** → 直接复用，避免重复记录
- **层级不匹配**（实际规模大于 Issue 层级）→ 将其关联到合适的 Milestone，补充必要的 Issue 拆分

**原则**：最少噪音 + 科学管理。不创建重复记录，已有 Issue 能复用则复用。

### 1.3 父 Issue 阅读 —— 北极星校验（强制）

**目的**：当前 Issue 若隶属父 Issue（Epic / Tracking / Parent），其承载整体设计意图、范围边界与验收标准。**后续协议判定、变更设计、实现方案必须服从父 Issue 北极星方向**，避免单个 Feature 偏离整体规划。

**检测父 Issue**：

| 平台 | 父子关系载体 | 检测方式 |
|------|-------------|---------|
| GitHub | Sub-issues / `Parent: #N`、`Part of #N`、`Tracked by #N` 引用 / 同 Milestone tracking issue / checklist 反向引用 | `gh issue view <N> --json body,milestone,parent,trackedInIssues,subIssuesSummary`，再看正文显式引用 |
| Jira | Epic Link / Parent Link / Sub-task 的 parent | `mcp__atlassian__getJiraIssue` 返回的 `parent` / `customfield_*` Epic Link |

**执行动作**：

1. 检测是否存在父 Issue（≥1 层直接父级，有 Epic 一并读）。**有**则读其标题 / 描述 / 验收标准 / 已关联子 Issue / 评论关键决策，提炼北极星要素——整体目标、范围边界、已定设计决策（协议方向 / 架构选型 / 兼容策略 / 依赖顺序）、跨仓库协作约束、验收标准；在 Step 0～6 每个决策点对齐校验（协议归属一致？设计未擅自扩张？依赖顺序合约束？）。
2. **无父 Issue**：记为"以当前 Issue 为顶层范围"跳过。**方向冲突**：停止推进，用 AskUserQuestion 确认是父 Issue 拆分/调整，还是当前 Feature 归属有误。

> **硬性规则**：父 Issue 存在时，其已明确的整体设计决策优先级高于本 Feature 局部直觉。偏离须显式与用户对齐，必要时先调整父 Issue。

### 1.4 Label 治理

确保 Feature 相关 Issue 具有统一的 Label 标记：

- **类型**：`type/feature`、`type/protocol-change`、`type/enhancement`
- **优先级**：`priority/high`、`priority/medium`、`priority/low`

检查目标仓库是否已有这些 Label，缺失则建议创建（通过 `gh label create`）。

使用 AskUserQuestion 与用户确认追踪方案后，执行创建操作。

> **运行时上交 advance-plan**：本 Feature 执行中若**动态展开成跨项目推进树**（协议缺口传导多个 SDK/客户端、衍生多个跨仓 Issue、需按波次编排 + 收敛）→ 上交 `/advance-plan` 以本节点为根接管级联与收敛，解决后返回本流程收尾。单仓内普通多步展开由本 skill 自身消化，不上交。触发边界见单一源：`skills/advance-plan/SKILL.md`「何时上交 advance-plan」。

---

## Step 1.5：用户体验影响澄清门控（协议设计敲定前，强制）

**当 Feature 触及用户可感知的交互时，此步骤为强制门控。** 触发信号：UI 状态、操作步骤、命令行为、可见能力（skill / tool）出现/消失时机、默认行为等；纯内核 / 协议内部、无用户可感差异的变更豁免（豁免须显式说明）。

未经用户对「体验 before/after」做出判断并接受，**不得敲定 Step 2 / Step 3 协议设计**。与协议门控、cross-ask 门控同级。用 AskUserQuestion 把「舞台 / 现状走查 / 改后走查 / 跨场景权衡 / 决策取景框」交用户拍板。

> 触发 / 豁免细则与场景化产出模板见单一源：`skills/fix-issue/resources/ux-impact-gate.md`。

---

## Step 2：协议合规检查

**检查清单**：

- [ ] 阅读相关协议仓库的当前规范（事件定义、数据结构、错误码等）
- [ ] 判断：Feature 在现有协议范围内可实现？还是需要新增/修改协议？
- [ ] 如需协议变更，明确变更范围（新事件、新字段、新错误码等）

**结果分支**：
- **现有协议已支持** → 跳至 Step 6（代码实现）
- **需要协议变更** → 继续 Step 3

> 按协议线参见对应 resource：
> - A2C → `{baseDir}/resources/a2c.md`
> - OASP → `{baseDir}/resources/oasp.md`

---

## Step 3：协议变更设计

动手修改协议前，评估向后兼容性和设计合理性。

### 3.1 向后兼容评估

- [ ] 新增字段是否为 Optional？现有客户端能否忽略？
- [ ] 是否修改了已有事件/字段的语义？（**高风险，需充分论证**）
- [ ] 已部署的 Agent/Computer/Server 升级路径是否清晰？
- [ ] 是否需要版本协商机制？

使用 AskUserQuestion 与用户确认向后兼容设计方案。

### 3.2 设计原则检查

- [ ] **简洁性**：是否有更简单的方式达成目标？避免过度设计
- [ ] **易用性**：SDK 实现者是否容易理解和接入？
- [ ] **一致性**：命名、结构是否与现有协议风格一致？
- [ ] **业界实践**：是否参考了同类协议（MCP、LSP、Socket.IO 等）的做法？

---

## Step 3.5：消费方实现可行性验证（强制门控）

**原则**：协议先行 ≠ 盲目先行。协议草案必须经消费方工具栈验证可实现，再进入 Step 4。

**触发**：所有「新增事件 / 新增数据结构 / 新增错误码 / 修改既有字段语义」**强制执行**；仅「修复 typo / 纯文档补充」可豁免。

**动作**：

1. 按 Step 0 协议线列出所有消费方仓库
2. 对每个消费方执行 `/cross-ask <target-project> <变更要点>`，转发对应工程师
3. 按各协议线 cross-ask 清单核对：OASP 见 `{baseDir}/resources/oasp.md`；A2C 见 `{baseDir}/resources/a2c.md`
4. 收到回复按 P0/P1/P2/P3 整理 → 回 Step 3 修订；P0 全消化后才进 Step 4
5. 消费方反馈"不可行"≠ 砍字段：先按协议线指引做级联回退（如 OASP：Add-In 不可 → 评估 Server 离线实现），两侧都不行再砍

**门控规则**：任一 cross-ask 反馈含 P0（cast 不过 / API 不存在 / 错误码冲突），**禁止进入 Step 4**，必须 round-N 修订后再次 cross-ask 验证通过。

---

## Step 4：协议评审与发布（分级门控点）

**门控按分支分级**——「协议必须正式发布」的硬约束不取消，只从「开工门」搬到「发版门」：

| 门级 | 判据 | 解锁 |
|------|------|------|
| **4a 开工门** | 协议 PR 评审合入 protocol `develop` **且已 push 到 origin**（可被跨仓工程师与 CI 引用）；代码仓 develop 的 `PROTOCOL_VERSION` 对齐 protocol develop 版本（如 `0.3.0` ↔ `0.3.0-dev`） | 代码仓可在自己的 `develop` 上实现（含合入代码仓 develop） |
| **4b 发版门** | 协议合入 protocol `main`，版本号按 SemVer 更新，tag + 文档上线（GitHub Pages / doc.turingfocus.cn）；代码仓 main 的 `PROTOCOL_VERSION` == protocol main 最新 tag | 代码仓才可合入 `main` / 对外发版（由 `release` skill Step 1 校验阻断） |

**硬性门控**：

> 本地未推送的协议文本**不解锁任何代码工作**；协议未正式发布前，**任何代码仓不得合入 main / 对外发版**。
> 决策归属不变：协议语义仍必须先在协议仓达成并落稿，SDK 不得自行拍板。

使用 AskUserQuestion 确认当前门级（develop 已合入并 push？main 已发布？），获取协议 PR 链接或版本号。

---

## Step 5：代码仓库关联

协议过 4a 开工门后（发版跟进则以 4b 为准），确认哪些代码仓库需要跟进实现，并按 Step 1 治理方案落地追踪结构。

**动作**：

1. 根据 Step 0 判定的协议线，列出需要跟进的代码仓库
2. 确认各仓库的实现优先级和依赖关系
3. 按 Step 1 治理方案，在各代码仓库创建对应 Issue，归入 Milestone 并标记 Label，引用协议 PR/版本号

**依赖关系原则**：
- SDK 仓库（python-sdk, rust-sdk）通常先实现
- 客户端/应用仓库（tfrobot-client, office4ai, office-editor4ai）依赖 SDK 更新后跟进

---

## Step 6：代码实现（仅限已通过门控的 Feature）

**前置条件检查**：

- [ ] 如涉及协议变更（开工前）：协议已合 protocol `develop` 且已 push origin？
- [ ] 如涉及协议变更（合 main / 发版前）：协议已正式发布且 `PROTOCOL_VERSION` 对齐最新 tag？
- [ ] 如不涉及协议：确认不违反现有协议规范？

### 依赖管理（如涉及新包引入）

**包选择**：
- Feature 已指定包名 → 直接采用
- Feature 未指定 → 主动推荐业界标准库，通过 AskUserQuestion 与用户确认
- 原则：避免造轮子，大胆推荐成熟的第三方库

**版本确认**：
- 通过 WebSearch 查询包的最新稳定版本（PyPI / npm / crates.io）
- 默认推荐最新稳定版；大版本跨越时向用户提供多个选项
- 用户最终决策版本约束

### 代码实现

按各项目自身的开发流程实现 Feature。

---

## Step 7：隔离审查硬门控（实现后强制）

实现完成后，**禁止自评满意直接收尾**。用 Agent 工具拉起隔离上下文的 `a2c-smcp-toolkit:code-reviewer` 子代理客观复审，按 `--review` 等级走 `/fix-review` 修复，🔴 未清零不算完成。子代理拉起时须传入「变更意图」（需求 / 验收标准 / 父 Issue 北极星），**不传**实现自评。

> 流水线、`--review` 分级、琐碎豁免（含 `--review none`）见单一源：`skills/code-review/resources/embedded-review-gate.md`。

---

## 流程总览

```
Feature 需求 → Step 0 判定协议归属 → Step 0.5 三仓态势门控 ◄ 核心三仓强制（🔴 须用户协调）
  → Step 1 Issue 追踪治理 → Step 1.5 体验门控 ◄ 用户可感变更强制
  ├─ 无协议约束 ─────────────────────→ Step 6 代码实现
  ├─ Step 2 协议合规检查 ── 已支持 ───→ Step 6 代码实现
  └─ 需协议变更 → Step 3 协议变更设计
       → Step 3.5 消费方 cross-ask 验证 ◄ 强制门控（P0 → 回 Step 3）
       → Step 4 协议评审与发布 ◄ 分级门控（4a 开工 / 4b 发版）
       → Step 5 代码仓库关联 → Step 6 代码实现
  → Step 7 隔离审查硬门控 ◄ code-reviewer 子代理，🔴 清零才放行
```

## 反模式警示

| 反模式 | 正确做法 |
|--------|---------|
| 先写代码再补协议 | 协议先行，代码跟进 |
| 不看三仓在推事项直接立项开工 | 核心三仓先过 issue-radar 态势门控；有人在推且方案冲突时，由用户协调暂停对齐，方案变化后重扫 |
| 协议未合 develop（或未 push origin）就开始实现 | 等协议合入 protocol develop 并 push 后再动代码（4a 开工门） |
| 协议未正式发布就合 main / 发版 | 发版门（4b）：`PROTOCOL_VERSION` == 协议 main 最新 tag，由 release 校验阻断 |
| 为了实现方便修改协议语义 | 协议设计服务于简洁性和易用性，非实现便利 |
| 破坏向后兼容而不与用户确认 | 任何兼容性破坏必须经过明确确认 |
| 独立项目无视协议约束 | 涉及 A2C 协议部分仍需遵守规范 |
| 用户可感变更凭技术分析直接定方案 | 触及用户可感交互的变更，先做体验 before/after + 跨场景权衡交用户拍板（Step 1.5，纯内核豁免） |
| 协议草案直接合并不验证消费方实现可行性 | 任何新事件/字段/错误码必须经至少一轮 cross-ask 双向验证，P0 反馈全部消化后再进入 Step 4 |
| 消费方反馈"做不到"就直接砍协议字段 | 先级联问其他消费方（OASP：Add-In→Server）；只有所有消费方都不能时才砍 |
| 实现完直接自评满意就收尾 | 经隔离上下文 code-reviewer 子代理客观复审，🔴 清零才算完成（琐碎改动可豁免） |
