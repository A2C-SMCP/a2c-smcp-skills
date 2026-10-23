---
name: save-status
description: 把当前会话的 assume-role 角色工作状态（任务进度、会话内决策、分支与合并状态、验证结果、一致性向量对齐状态、团队与派活记录）写入团队登记文件，供 /clear 或 /compact 后由 SessionStart hook 注入恢复；用户要求整组保存时沿纳管关系向下传一跳。用户说「保存状态」「save status」「准备 clear / compact」「整组保存」，或 assume-role 规则要求在任务开始、受阻、完成、回报或通告前保存时使用。
argument-hint: "[--cascade]"
---

# Save Status — 保存会话工作状态

会话上下文会越来越长，`/clear` 或 `/compact` 是必要的卫生操作。本 Skill 把清理会丢掉、且 Git 与 GitHub 里查不到的工作状态落到用户目录的团队登记里——**不在会话上下文里，`/clear` 不会丢**；清理后由 SessionStart hook 注入、`assume-role` 读回。

**状态是索引，不是事实来源。** Git、GitHub、一致性测试是事实；状态记录指针（Issue / PR 编号、分支、Discussion 链接）和只存在于会话里的信息（下一步打算、未写回的决策、待用户决定的问题）。不复制 Issue 正文、diff 或日志。

## 1. 定位登记文件

`${A2C_SMCP_HOME:-~/.a2c-smcp}/roles/sessions/<仓库名>/<会话 ID>.md`，会话 ID 为 `${CLAUDE_SESSION_ID}`。

- 找不到时，按同仓库登记中 `pid` 等于 `$CLAUDE_PID` 的记录定位（`/clear` 后 hook 未运行的情况）。
- 仍找不到，说明本会话没有用 `assume-role` 初始化：告诉用户先初始化角色，不自行创建登记。

## 2. 采集状态

只记录**会话内独有、清理后会丢**的信息。Git、GitHub 与对齐事实**当场用命令核实**后再写，不凭记忆：

```bash
git -C "<工作目录>" rev-parse --abbrev-ref HEAD && git -C "<工作目录>" rev-parse --short HEAD
git -C "<工作目录>" status --short | head -20
git -C "<工作目录>" log --oneline @{u}..HEAD 2>/dev/null   # 未推送的提交
git -C "<仓库根>" worktree list
gh pr list -R A2C-SMCP/<仓库名> --head <分支> --json number,state,isDraft,reviewDecision
git -C "<协议仓>" fetch -q origin develop && git -C "<协议仓>" rev-parse --short origin/develop
```

**对齐状态**按角色采集（命令见 `skills/assume-role/resources/sdk/<仓库名>.md`「对齐状态采集」）：

| 角色 | 采集 |
|------|------|
| sdk-developer | 本任务相关的向量 / 一致性测试：当场运行，记通过数 / 总数与失败原因；架构师缺位且代行契约通道时，另按 sdk-architect 口径采集全仓状态，写入「对齐状态（代行）」 |
| sdk-architect | 本仓对 `contract_version` 的向量副本状态（SAME / STALE / MISSING / 本仓独有）、场景向量映射缺口、一致性测试通过数 / 总数、在推镜像 Issue 与对方状态 |
| protocol-owner | 各 SDK 最近一次 `对齐回报` 的内容与时间（不代为运行 SDK 测试）；待裁决问询、未回复的通告 |

运行不了的测试写「未核实（原因）」，不按推测填写。PR、Issue 状态查不到时写「未核实」。

## 3. 写入登记

更新 frontmatter 中的机器字段（其余字段保持不变）：

```yaml
name: <当前会话名，从 claude agents --json 中本会话行读取>
task: <当前 ref，如 python-sdk#120；空闲时为空>
task_state: <进行中 / 受阻 / 待审查 / 已完成 / 空闲>
tasks_since_reset: <上次 clear 或 compact 以来处理过的任务数；新任务开始时 +1>
contract_commit: <本次核实的协议 origin/develop 短哈希>
status_updated: <YYYY-MM-DD HH:MM>
```

正文整体替换为下列状态，按角色取用小节，没有内容的小节省略；总长控制在 6000 字以内（hook 注入上限约 9000 字）：

```markdown
## 状态（<YYYY-MM-DD HH:MM>）

- 当前任务：<ref 标题>｜<Skill 与阶段，如 fix-issue Step 5>｜<task_state>
- 下一步：<恢复后第一件要做的事>

### 进度
- 已完成：<要点>
- 未完成：<要点>
- 受阻：<原因；在等谁、等什么>
- 待用户决定：<问题与推荐>

### 会话内决策（尚未写回记录层）
- <决策 — 理由 — 应写回的位置（Issue body / Discussion / PR）>

### Git
- 工作目录：<worktree 路径>｜分支：<名称>（基线 <分支>）｜HEAD：<短哈希>
- 未提交：<改动摘要 / 无>｜未推送提交：<数量>
- PR：<链接与状态>｜合入 develop：<是 / 否 / 不适用>｜main 合并申请：<状态 / 不适用>

### 验证
- 已运行：<测试或命令 — 结果>
- 审查：<code-review 结论；未清零的 🔴 数>
- 待用户运行：<命令>

### 对齐状态（契约 <vX.Y> @<contract_commit>）
- <sdk-developer：本任务相关向量与测试 — 通过数 / 总数 — 失败原因>
- <sdk-architect：数据向量副本 SAME/STALE/MISSING/独有 逐文件；场景向量映射缺口；一致性测试 通过数 / 总数；在推镜像 Issue — 对方状态>
- <protocol-owner：python-sdk / rust-sdk 各自最近对齐回报 — 时间 — 通过数 / 总数 — 未对齐项；待裁决问询；未回复通告>

### 环境占用
- <端口、测试服务、容器、后台进程 — 释放或交接方式>

### 团队（sdk-architect、protocol-owner）
- 纳管会话：<名称 — 角色 — 当前任务 — task_state>
- 派活记录：<时间 — 对象 — ref — 状态>
- 待合入 develop：<分支 — 审查状态>
- 对齐同伴：<会话名 — 角色@仓库 — 最近一次通信 ref 与时间>
```

不写凭据、密钥、令牌、个人隐私。会话内决策应尽快写回记录层，写回后从状态中移除。

## 4. 整组保存（`--cascade`，仅在用户要求时）

1. 先保存本会话。
2. 读取本会话登记的 `managed`，按 `assume-role` 团队协议解析每个下级的当前名称，用 `SendMessage` 发送：`[整组保存] <本会话名>（<角色>@<仓库>）：请执行 save-status --cascade，完成后回复已保存`。
3. 只发给直接下级，不发给上级或对齐同伴；收到请求的会话按同样规则只向自己的下级再传一跳。
4. 汇总各下级的回复告诉用户；没有回复或消息被拒收的会话单独列出，不视为已保存。不轮询，需要等待时用 `notify_when_idle`。

## 5. 收尾

一句话告诉用户保存了什么（任务、阶段、分支、对齐状态摘要），并按 `tasks_since_reset` 与 `task_state` 给出清理建议：

- 任务已完成、接下来换任务 → 建议 `/clear`；清理后 hook 自动注入状态。
- 同一任务仍在进行但上下文已很长 → 建议带保留要求的压缩：

  ```text
  /compact 保留 <ref> 的目标、已定决策、分支 <名称>、对齐状态与未完成项；丢弃已解决的排查过程与大段日志
  ```
