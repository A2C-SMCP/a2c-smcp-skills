# 核心三仓治理规则（单一源）

> 本文档是 SMCP 核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）协同治理规则的**单一源**，被 `issue-report` / `fix-issue` / `add-feature` / `release` 在对应门控步骤引用。修改规则只改这里，不得在各 SKILL.md 里另立副本。
>
> 事故背景：rust-sdk#187 曾把协议规范中定义的数据结构当"SDK 负责"单独变更，分支领先 develop 4 个 commit、未挂 Milestone、未对照 python-sdk —— 一旦合并即成 rust-sdk 孤立于协议与 python-sdk 的 Feature。本文档的每一条规则都对应此类事故的一个漏洞点。

## 适用范围

| 仓库 | 角色 | 治理强度 |
|------|------|---------|
| a2c-smcp-protocol | 协议规范（source of truth） | §2 / §4 适用 |
| python-sdk | SMCP 参考实现 | 全部条款强制 |
| rust-sdk | SMCP 生产实现 | 全部条款强制 |

OASP 线（oasp-protocol + office4ai + office-editor4ai）可类比适用：office4ai ↔ office-editor4ai 的镜像原则同 §3，协议辖区判定同 §2（协议仓换为 oasp-protocol）。

---

## §1 Bug 判定准则

**Bug 类问题的定义**——三条同时满足才算 Bug，走 Bug 治理路线（`fix-issue`）：

| # | 判据 | 含义 |
|---|------|------|
| 1 | 「正确性」无疑义 | 错误是客观的：实现与已共识的规范/预期不符，不存在"改成 A 还是改成 B"的设计选择 |
| 2 | 协议侧与 Python / Rust SDK 侧已达成共识 | 正确的行为是什么，三端已有一致答案，不需要新的裁决 |
| 3 | 单纯是某一个语言 SDK 的实现问题 | 只修一边代码即可闭环，不需要其他仓库配合变更 |

**反例判定**（以下**不是** Bug，不得按本仓 Bug / Improvement 提报补救方案）：

- 涉及共享数据结构 / 事件 / 字段 / 错误码 / 序列化格式的**形状或语义变更** → 协议变更，走 §2 协议辖区路线
- 正确行为本身有待裁决（协议未定义、定义模糊、两 SDK 行为不一致且各执一词）→ 协议先行澄清
- 修复需要对称 SDK 同步变更才能保持互操作 → 触协议或触 §3 镜像

> **硬性规则**：类型判定（Bug / Feature / Improvement）之前必须先过 §2 协议归属判定。"改进一下数据结构"经常被误报为 Improvement——只要该结构定义于协议规范，它就是协议变更。

---

## §2 协议归属判定（协议先行判定）

**核心问题**：这个 Issue / 需求 / 修复，是协议该管的，还是 SDK 自己的实现选择？

### 2.1 判定信号

| 归属 | 信号 |
|------|------|
| **协议辖区** | 结构/事件/字段/错误码/序列化格式**定义于协议规范**，本次变更其形状或语义；跨 SDK 行为一致性（Python vs Rust 互操作）；wire format 兼容性；房间/会话模型 |
| **SDK 自治区** | 纯内部实现（日志、缓存、错误处理内部策略）；协议未定义的结构/行为；协议明确留给 SDK 的实现选择 |

**关键判据**：在协议规范里 `grep` 得到该结构/事件名 → **它就是协议辖区**，与"看起来像 SDK 运行时语义"无关。协议没有规定、或明文授权 SDK 自行实现的，才是 SDK 自治区。

### 2.2 协议仓库可读性前置（强制，不可跳过）

判定前**必须**能读到协议仓库。本地读不到时：

1. **停止判定与提报**，要求开发者执行：

```bash
git clone git@github.com:A2C-SMCP/a2c-smcp-protocol.git
```

2. 把协议仓库目录加入开发项目工作区保证可读（Claude Code：`/add-dir <path-to>/a2c-smcp-protocol`；其他环境为等价操作），然后重新判定。

> 没有读协议仓库就下"这是 SDK 自己的事"的结论，是 rust-sdk#187 事故的直接成因。

### 2.3 判定动作（以 develop 分支为准）

**协议仓 develop 分支是最新近况，同时可接受新需求** —— 判定一律对照 develop，不必等 main：

```bash
git -C <path-to>/a2c-smcp-protocol fetch origin develop
git -C <path-to>/a2c-smcp-protocol grep -n "<结构名/事件名>" origin/develop -- docs/
```

命中 `docs/specification/`（或 guides 中的规范示例）→ 该结构定义于协议 → 协议辖区。

### 2.4 结果分支

| 结论 | 后续动作 |
|------|---------|
| **协议辖区** | **停止在本仓提报补救方案 / 开工**。改向协议仓提报变更 Issue（`/issue-report` 在协议仓执行）或转 `/add-feature` 走协议先行流程；本仓若仍需 Issue，挂 follow-up 并引用协议 Issue |
| **SDK 自治区** | 继续本仓流程，并执行 §3 双 SDK 对称检查 |
| 协议模糊 / 未覆盖 | AskUserQuestion 与用户确认：先到协议仓澄清（推荐），还是按现有理解推进并在协议仓留痕 |

---

## §3 双 SDK 镜像规则（python-sdk ↔ rust-sdk）

**前提约定（不可打破）**：python-sdk 与 rust-sdk 功能几乎一比一，技术选型都按相同模式制定，为的就是双方维护时互为参考。

| 场景 | 动作 |
|------|------|
| 不触协议，但问题/需求属 SDK 共享实现策略（对称 SDK 存在同样结构、同样模式的代码） | **必须对照提镜像 Issue 到对称项目**，两 Issue 互相引用（"mirror of <repo>#N"）。不镜像 = 单边演化，规则上禁止 |
| 触协议 | 协议仓单 Issue + 两 SDK 各一跟进 Issue（由 `add-feature` Step 5 治理），两 SDK 跟进 Issue 挂同 X.Y Milestone（§4） |

**判定动作**：在对称 SDK 仓库中 grep 同名结构/模式（如 `PickString`），命中即存在对称实现，需要镜像。镜像 Issue 经 `issue-report` 流程提报（其 Step 6 强制本规则），内容引用本侧 Issue 与协议依据。

---

## §4 Milestone 版本治理

### 4.1 强制挂载

**python-sdk / rust-sdk 的所有任务（Issue）必须归属一个带有版本的 Milestone，才能推进实现。** 未挂 Milestone 的 Issue：

- `issue-report`：提报时即挂（无合适 Milestone → 经用户确认创建）
- `fix-issue`：开工门控阻断（Step 1.4）
- `add-feature`：追踪结构建立时即挂（Step 1.1）

协议仓的协议变更 Issue 同样归入版本化 Milestone，与 SDK 跟进 Milestone **同 X.Y**。

### 4.2 版本对齐约定（X.Y.Z）

| 段 | 对齐要求 |
|----|---------|
| **X.Y** | **协议 + Python + Rust 三方严格对齐**。同一功能线在三仓的 Milestone / 发布版本必须同 X.Y，版本号与文档能相互对上 |
| **Z** | 不要求严格对齐，各仓按自身 patch 节奏自由 |

### 4.3 协议先行问题的动工条件

协议先行的问题：**协议侧在 develop 分支发布（合入 + push）后，代码侧即可动工**，不需要严格按 main 分支确认。main 发布对应的是"合 main / 发版"门，由 `release` Step 1 校验阻断。

> 两级门（开工门 4a / 发版门 4b）的单一源在 `skills/add-feature/SKILL.md` Step 4，此处只引用不复制。

### 4.4 操作命令

```bash
# 列现有 Milestone
gh api repos/A2C-SMCP/<repo>/milestones --jq '.[].title'
# 创建版本化 Milestone
gh api repos/A2C-SMCP/<repo>/milestones -f title="vX.Y.Z" -f description="<功能线说明>"
# 挂载 Issue
gh issue edit <N> -R A2C-SMCP/<repo> --milestone "vX.Y.Z"
```

> 当前现状（2026-08 实测）：rust-sdk 有 `v0.3.1`；protocol 有 `v0.3.1` + `v0.4.0`；python-sdk 尚无 Milestone —— python-sdk 侧任务需先补齐同 X.Y 的 Milestone。

---

## §5 门控落点总表

| 规则 | issue-report | fix-issue | add-feature | release |
|------|-------------|-----------|-------------|---------|
| §1 Bug 准则 | Step 1 类型判定 | Step 2.3 / 3.1 | — | — |
| §2 协议归属判定 | Step 2.5 门控 | Step 3.1 判定 | Step 0 归属判定 | — |
| §3 双 SDK 镜像 | Step 6 跨项目联动 | Step 3.4 对称检查 | Step 0 无协议分支 / Step 5 | — |
| §4 Milestone 治理 | Step 5 提交前 | Step 1.4 开工门控 | Step 1.1 / Step 5 | Step 1 前置检查（X.Y 对齐） |

---

## 附录：事故案例 rust-sdk#187（判定推演）

**发生了什么**：rust-sdk#187 提议把 `MCPServerPickStringInput.options` 从 `list[str]` 改为 `{label, value}[]`，正文判定"该能力是通用 Computer 运行时语义，由 SDK 负责"。作为 `enhancement` 在 rust-sdk 单仓推进，`in-progress`、无 Milestone、无 python-sdk 镜像，分支领先 develop 4 个 commit。

**正确推演**：

1. **§2.2 可读性前置**：确认本地能读协议仓（已 clone + add-dir）。
2. **§2.3 develop 核对**：`git grep -n "MCPServerPickStringInput" origin/develop -- docs/` → 命中 `docs/specification/data-structures.md`，其中 `options: list[str]` 是协议规定的字段形状；python-sdk 与 rust-sdk 均按此实现。
3. **§2.4 结论**：变更共享数据结构的形状 = **协议辖区**，不是"SDK 负责"。正确路径：向协议仓提变更 Issue → 协议侧合入 develop 并 push（4a 开工门）→ python-sdk / rust-sdk 各建跟进 Issue、挂同 X.Y Milestone（§3 + §4）对称推进 → 协议 main 发布后才可合 main / 发版（4b 发版门）。
4. **§1 校验**：该变更存在设计选择（`{label,value}` vs 其他形状），"正确性"有待协议裁决 → 从来不是 Bug。
