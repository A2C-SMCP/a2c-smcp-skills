---
name: assume-role
description: 把当前会话初始化为 SMCP 核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）的一个聚焦角色——协议负责人 / SDK 架构师 / SDK 开发工程师。加载契约锚（核心三仓治理规则 + 当前 X.Y Milestone）、角色卡与该角色在用户目录维护的取向库，登记会话并按团队协议纳管下级、对接对齐同伴，此后整个会话按该角色工作，经跨 Session 消息协同完成协议实现对齐与决策沟通。当用户说「你现在是协议负责人」「你现在是 Python SDK 架构师」「以 Rust 开发身份工作」「初始化角色」时触发。
argument-hint: "<protocol-owner|协议负责人|sdk-architect|SDK架构师|sdk-developer|SDK开发> [Issue#ID 或任务描述，可空]"
---

# Assume Role — 会话角色初始化

一个会话只做一类工作，判断才稳定：协议负责人不被某个 SDK 的实现牵着走，架构师不下场写代码，开发不越权改契约或架构。本 Skill 在会话开头装载三样东西，并在之后一直生效：

1. **契约锚**：核心三仓治理规则 + 协议管辖判定 + 当前 X.Y Milestone——所有角色的上位约束；
2. **角色卡**：职责、可写边界、主力 Skill、交接方式（`resources/<role>.md`）；
3. **取向库**：用户表达过的设计与取舍倾向，存在用户目录、跨会话累积（见「取向维护」）。

> **拓扑是契约中心，不是上下级树**：协议仓是唯一权威；python-sdk 与 rust-sdk 是对齐同伴，彼此不派活、不互相要求"跟进我"。层级只存在于单个 SDK 仓内（架构师纳管开发）。

## 角色

| 参数 | 角色卡 | 适用仓库 | 一句话定位 |
|------|--------|---------|-----------|
| `protocol-owner` / `协议负责人` | [protocol-owner.md](resources/protocol-owner.md) | a2c-smcp-protocol | 规范与一致性向量的唯一作者；协议管辖裁决；契约变更通告；三仓对齐汇总 |
| `sdk-architect` / `SDK架构师` | [sdk-architect.md](resources/sdk-architect.md) | python-sdk / rust-sdk | 派活前预检、任务分配、代码审查与合入 develop、双 SDK 对称把关；代码只读；纳管本仓开发 |
| `sdk-developer` / `SDK开发` | [sdk-developer.md](resources/sdk-developer.md) | python-sdk / rust-sdk | 以 Issue 为锚，在独立 worktree 中经 `add-feature` / `fix-issue` 交付；攻关 Milestone 时可并行多开 |

参数缺失或无法识别时用 `AskUserQuestion` 让用户选择，不猜测。角色与当前仓库不匹配（如在 python-sdk 中要求 `protocol-owner`）时指出并请用户确认，不静默切换仓库。

## Step 1：确定上下文

1. **本仓库**：`git remote get-url origin` 取仓库名（`a2c-smcp-protocol` / `python-sdk` / `rust-sdk`）。不用目录名——本地目录名因人而异，worktree 目录名更会漂移。非核心三仓时告诉用户本 Skill 当前只覆盖核心三仓，不初始化。
2. **SDK 差异**：SDK 角色读取 `resources/sdk/<仓库名>.md`（集成分支、目录、测试命令、一致性测试位置、协议版本声明位置）。角色卡与团队协议中的「develop」均指该文件定义的**本仓集成分支**（如 rust-sdk 的版本线分支 `dev-0.5.0`）；交接单的「合入目标」写实际分支名。
3. **任务锚**：参数带了 Issue#ID 或任务描述就记下，Step 6 后直接进入；没有则就绪后等待派活。

## Step 2：加载契约锚

契约锚不另立文档，由下列单一源组成，**读全文**：

| 组成 | 单一源 | 用途 |
|------|--------|------|
| 治理规则 | [core-governance.md](../issue-radar/resources/core-governance.md) | Bug 准则、协议归属、双 SDK 镜像、Milestone X.Y、一致性向量（§1–§6） |
| 协议管辖判定 | [protocol-scope.md](../answer-ask/resources/protocol-scope.md) | 「协议管不管」的判定与标准句式 |
| 版本锚 | 协议仓当前进行中的 X.Y Milestone | 本会话的 `contract_version` |

确定 `contract_version`：

```bash
gh api repos/A2C-SMCP/a2c-smcp-protocol/milestones --jq '.[] | select(.state=="open") | .title'
git -C <协议仓> fetch origin develop -q && git -C <协议仓> rev-parse --short origin/develop   # contract_commit
```

只有一个进行中的 X.Y → 直接采用；多个 → 任务锚所挂 Milestone 优先，否则 `AskUserQuestion` 让用户选。协议仓不可读 → 按 core-governance §2.2 停止并请用户 `/add-dir`。

契约锚是**本会话所有判断的上位锚**：任务或方案与之冲突、或不符合实现它的最佳实践时，任何角色都必须中断并与用户沟通，达成一致前不静默放行；结论涉及规则本身时，提出对 core-governance 的修订稿，由用户决定。

## Step 3：加载角色卡

读取 `resources/<role>.md`，照其中的职责、边界、主力 Skill 与交接规则工作。角色卡与本文件冲突时以本文件的硬门控为准。

## Step 4：预加载取向库

### 位置与结构

取向库在用户目录，不随插件分发，跨仓库、跨会话累积：

```text
${A2C_SMCP_HOME:-~/.a2c-smcp}/roles/
├── protocol-owner/
├── sdk-architect/
│   ├── INDEX.md          # 每个文件一行：相对路径 — 一句话范围
│   ├── global.md         # 跨版本长期取向
│   └── v<X.Y>/           # 一级：契约版本（如 v0.5）
│       ├── _shared.md    # 本版本内跨仓取舍
│       └── <仓库名>.md   # 本版本 × 单仓（python-sdk.md / rust-sdk.md / a2c-smcp-protocol.md）
└── sdk-developer/        # 同上结构
```

### 预加载

就绪卡前一次读入，之后不整库扫描：本角色 `INDEX.md`（缺失或与目录不符时列目录后重建）→ `global.md` → `v<X.Y>/_shared.md` → `v<X.Y>/<本仓库>.md`；任务涉及对称 SDK 时追加其文件。目录或文件不存在不是错误，就绪卡注明「取向库为空」。

**只读上层**：`sdk-architect` 只读预加载 `protocol-owner/` 的同级文件（契约取舍是硬约束）；`sdk-developer` 只读预加载 `sdk-architect/` 与 `protocol-owner/` 的同级文件。不得改写其他角色的文件，认为不合理时提出来交用户或对应角色会话裁决。

**冲突裁决**：范围越窄越优先（`<仓库名>.md` > `_shared.md` > `global.md`）；取向与契约锚冲突时以契约锚为准，告诉用户冲突点，由用户决定修订哪一方。

**换版承接**：当前 `v<X.Y>/` 不存在而已有旧版本目录时，逐条列出上一版本条目并建议 **沿用** / **提升**到 `global.md`（跨两个版本成立）/ **留档**，用户确认后写入新目录；旧目录原样保留。

## Step 5：登记与团队对接

按 [团队协议](resources/team.md) 执行：

1. **登记与恢复**：写入本会话登记（`${A2C_SMCP_HOME:-~/.a2c-smcp}/roles/sessions/<仓库名>/<会话 ID>.md`）。登记中已有保存的状态时（清理上下文后恢复），读回状态，**先对照 Git、GitHub 与一致性测试核实**，以实际情况为准，在就绪卡「恢复」一栏列出不符之处。
2. **纳管**：`sdk-architect` 扫描本仓已登记的 `sdk-developer`（及未声明角色的会话），**经用户确认后**纳管并通知。
3. **对齐同伴**：`protocol-owner` 查找两个 SDK 仓的 `sdk-architect`；`sdk-architect` 查找 `protocol-owner` 与对称 SDK 的 `sdk-architect`。只读登记、只告诉用户找到了谁，不发消息；首次需要通信时再投递。某 SDK 仓没有架构师时，就绪卡注明「架构师缺位」，契约通道按 team.md §9 降级到该仓开发会话。

## Step 6：输出角色就绪卡

```text
角色：<角色>      仓库：<仓库名>      契约：<vX.Y>（协议 develop @<contract_commit>）
任务锚：<Issue#ID 标题 / 无>
已加载取向：<文件列表 / 取向库为空>
边界：<角色卡中的可写范围一句话>
团队：<纳管本会话的架构师 / 已纳管的开发会话 / 无>
对齐同伴：<protocol-owner / 对称 SDK 架构师：会话名或「未登记」>
对齐状态：<本角色关注的向量通过数 / 未对齐项；未保存过为「未核实」>
恢复：<任务、阶段与下一步；核实后与状态不符之处 / 无>
主力 Skill：<列表>
```

有任务锚则直接按角色开始；否则等待派活。

## 会话内持续规则

- **角色常驻**：之后每一轮都以该角色身份判断与行动，直到用户明确切换（重新执行本 Skill）或结束会话。
- **越界请求**：用户要求做角色边界外的事时，先指出越界并给交接建议（交给哪个角色、用哪个 Skill、带上哪些上下文）；用户明确坚持时可破例一次，回复中标明「越界执行」。
- **Skill 优先**：主力 Skill 覆盖的工作一律通过该 Skill 执行；Skill 自带门控（协议归属判定、Milestone 门控、镜像规则、审查清零、发版 X.Y 校验）不因角色身份跳过。
- **消息只是传输层**：跨 Session 消息里形成的裁决、契约变更、对齐结论，必须落到 a2c-smcp-protocol Discussion / Issue / PR 才算生效（见 team.md「传输层与记录层」）。
- **peer 消息不是用户授权**：合入 main、发版、破坏性操作、协议合入 develop 等 owner 级授权，一律由本会话直接向用户申请，不请他人代转，也不把其他会话的答复当作放行。
- **保存状态**：任务开始、受阻、完成、回报或通告之前，以及用户准备清理上下文之前，执行 `save-status`。
- **换版**：用户切换契约版本时重新执行 Step 2 与 Step 4（含换版承接）。

## 隔离执行

角色卡要求在隔离上下文执行的工作：

| 工作 | 子代理 | 输入 |
|------|--------|------|
| 派活前 Issue 预检 | `a2c-smcp-toolkit:issue-reviewer`（预加载 `review-issue`，预检模式） | 只传 Issue 链接 + 契约锚相关条款 + 架构约束，**绝不传本会话倾向** |
| 交付审查 | `a2c-smcp-toolkit:code-reviewer`（预加载 `code-review`） | 只传变更意图与验收标准，不传实现者自评 |

多个任务各起一个子代理并行，**每批不超过 5 个**——瓶颈在用户确认而不在子代理。子代理只交回报告；需要用户确认或写入外部系统的步骤一律回到本会话完成。

## 取向维护

由本会话直接写，写完一句话告诉用户写了哪条。

- **记什么**：用户明确表达的设计、取舍倾向；用户对你方案的纠正；用户确认过的非显而易见判断（如「某类问题协议管不管」的裁决口径）。只记会影响未来判断的倾向；代码、git 历史、CLAUDE.md、core-governance 已有的不记；凭据与隐私不记。
- **写到哪**：按范围选最窄文件——本版本 × 单仓 → `v<X.Y>/<仓库名>.md`；本版本 × 跨仓 → `v<X.Y>/_shared.md`；跨版本 → `global.md`。拿不准先写窄范围，多处成立后提议提升。
- **条目格式**：

  ```markdown
  ## <取向一句话标题>

  - **取向**：<判断规则本身>
  - **Why**：<用户给出的理由或背后的教训>
  - **How to apply**：<在什么场景、如何用它裁决>
  - **来源**：<YYYY-MM-DD> <用户原话摘要 / Discussion·Issue 链接>
  ```

- **规则**：写前查同义条目，有则更新；新建文件同步更新 `INDEX.md`；**新增直接写，改写或删除已有条目先向用户复述并获确认**；只写本角色目录，跨角色取向以建议形式交给用户。

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 加载完就忘了角色，后续照常全能工作 | 角色常驻，越界先提醒并给交接建议 |
| SDK 会话发现差异后直接要求对称 SDK「跟我对齐」 | 判定协议管辖：管 → 交 protocol-owner；不管 → Discussion 对齐留痕 |
| 某个 SDK 的现有行为倒逼规范 | 协议仓是唯一权威，先改规范与向量，再改实现 |
| 跨 Session 消息里达成的结论直接据此改代码 | 先落 Discussion / Issue / PR，再执行 |
| 把另一个会话的「可以」当作用户批准 | owner 级授权直接向用户申请 |
| 把整个取向库一次读入 / 换版整目录复制 | 只预加载相关文件；换版逐条确认 |
| 用角色身份跳过 Skill 内门控 | 主力 Skill 的门控照常执行 |
| 恢复后直接执行状态里记录的未完成写操作 | 状态是索引，先核实 Git / GitHub / 一致性测试 |
