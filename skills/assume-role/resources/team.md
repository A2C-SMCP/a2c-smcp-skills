# 团队协议：登记、纳管、派活与对齐通信（Claude Code）

两类关系：

| 关系 | 双方 | 内容 |
|------|------|------|
| **纳管**（上下级） | 同一 SDK 仓的 `sdk-architect` → `sdk-developer` | 派活、回报、审查、合入 develop |
| **对齐同伴**（契约通道） | `protocol-owner` ↔ 两个 `sdk-architect`；`sdk-architect` ↔ 对称 SDK 的 `sdk-architect` | 契约问询、契约变更通告、裁决通知、对齐回报 |

- 对齐同伴之间**不派活**。SDK ↔ SDK 只问事实（「你们这里怎么实现的」），行为裁决只经 `protocol-owner`。
- `sdk-developer` 只与自己的架构师通信；需要协议或对称 SDK 事实时请架构师转问，或用 `cross-ask`。
- 某 SDK 仓**没有在线的架构师**时，契约通道按 §9「架构师缺位降级」临时落到该仓的开发会话。
- 会话间用 `SendMessage` 投递，**只在本机有效**；跨机器协作只能依赖 GitHub（Discussion / Issue / PR），环境不支持跨会话消息时退回「输出交接单，由用户转交」。

## 1. 传输层与记录层

**`SendMessage` 是传输层，GitHub 是记录层。** 消息只负责把事情送到对方面前；下列内容必须落到记录层才算生效，落地前不得据此改代码或改规范：

| 消息内容 | 记录层 |
|----------|--------|
| 协议管辖裁决、SDK 自治对齐结论 | a2c-smcp-protocol Discussion（`cross-ask` / `answer-ask` 的同一留痕处） |
| 契约变更 | 协议仓 Issue / PR，及两 SDK 跟进 Issue（core-governance §3） |
| 任务派发与交付 | 任务 Issue（派活单的已定决策须已写回 Issue body，见 `review-issue`） |

每条派活、通告、裁决、问询都带 **`ref`**：直接取对应的 GitHub 编号（`protocol#45` / `python-sdk#120` / `D#88` 表示协议仓 Discussion）。回报引用同一 `ref`，消除「这条回复对应哪件事」的歧义。暂无记录层编号的（如纯事实问询）先 `cross-ask` 建 Discussion 再发。

## 2. 消息信封

不用 JSON；硬约定只有一条——**第一行自包含**（对方预览只看到第一行）：

```text
[<类型> <ref>] <本会话名>（<角色>@<仓库>）：<一句话主题>
```

| 类型 | 方向 | 正文模板 |
|------|------|---------|
| `纳管通知` | 架构师 → 开发 | 本会话角色与会话 ID、派活方式、回报要求（§5），请对方把 `manager` 写入登记 |
| `任务派发` | 架构师 → 开发 | 交接单（见 sdk-architect.md） |
| `回报` | 开发 → 架构师 | `开始 / 受阻 / 完成`；完成时给出交付物（commit、PR）、一致性测试结果与未完成项 |
| `契约问询` | SDK 架构师 → protocol-owner / 对称 SDK 架构师 | 契约条款或向量编号 → 当前实现 → 期望行为 → 证据（commit / 测试）→ 期望答复时间 |
| `契约变更通告` | protocol-owner → SDK 架构师 | 契约版本、变更点、规范与向量位置、协议 PR 状态（是否已合 develop）、需跟进的 SDK 与跟进 Issue |
| `裁决通知` | protocol-owner → SDK 架构师 | 协议管辖 / SDK 自治结论（按 protocol-scope 标准句式）、Discussion 链接、各 SDK 的后续动作 |
| `对齐回报` | SDK 架构师 → protocol-owner | 本仓对 `contract_version` 的向量通过数 / 总数、未对齐项、在推镜像 Issue |
| `整组保存` | 发起者 → 直接下级 | 请执行 `save-status --cascade`，完成后回复 |

正文按**对方一无所知**来写：不写「上次说的」「同上」，要用到的结论、链接、路径直接写进去；拿不准对方是否需要，宁可写上。

## 3. 登记本会话

每个会话只写自己的登记文件，避免并行会话互相覆盖：

```text
${A2C_SMCP_HOME:-~/.a2c-smcp}/roles/sessions/<仓库名>/<会话 ID>.md
```

- **仓库名**：`git remote get-url origin` 的仓库名，同一仓库所有 worktree 一致。
- **仓库归属**：`git rev-parse --path-format=absolute --git-common-dir`，同一仓库所有 worktree 得到同一路径。不要用 `git rev-parse --show-toplevel`——在独立 worktree 中返回 worktree 自己的目录。
- **会话 ID**：`${CLAUDE_SESSION_ID}`。`/clear` 后同一进程会换新会话 ID、进程号不变，会话名也可能被改写。所以登记同时记 `pid`（`$CLAUDE_PID`）：文件按会话 ID 命名，清空前后按 `pid` 关联，名称在投递前实时解析。

```markdown
---
role: sdk-architect          # protocol-owner / sdk-architect / sdk-developer
platform: claude-code
session_id: <会话 ID>
pid: <进程号>
repo: <仓库名>
root: <本会话 worktree 根目录绝对路径>
git_common_dir: <仓库共享 .git 目录绝对路径>
contract_version: <vX.Y>
contract_commit: <登记或最近核实时协议仓 origin/develop 短哈希>
manager: <纳管本会话的会话 ID，未纳管为空>
managed: [<被本会话纳管的会话 ID>, ...]
name: <当前会话名>
task: <当前 ref，空闲为空>
task_state: <进行中 / 受阻 / 待审查 / 已完成 / 空闲>
tasks_since_reset: <上次 /clear 或 /compact 以来处理过的任务数>
last_reset: <YYYY-MM-DD HH:MM clear|compact，从未清理为空>
status_updated: <YYYY-MM-DD HH:MM>
updated: <YYYY-MM-DD HH:MM>
---
<save-status 写入的工作状态（含本角色的对齐状态小节）；刚登记时为任务锚一句话，可空>
```

`task` 至 `status_updated` 与正文由 `save-status` 维护。插件的 SessionStart hook 在 `/clear`、`/compact`、`--resume` 后按 `pid` 或会话 ID 找到登记：`/clear` 后把文件改写为新会话 ID 并清零 `tasks_since_reset`，再提示新上下文先执行 `assume-role` 恢复。

切换角色时更新同一文件；纳管关系或任务锚变化时同步更新。本仓还有同 `pid`、不同会话 ID 的记录时，说明 hook 未运行：继承其 `manager`、`managed`、状态字段与正文，再删除该旧记录（它是本会话自己的前身）。

## 4. 解析存活会话

只看本仓库任一 worktree 下的会话，避免整机会话列表进入上下文：

```bash
W=$(git -C "<仓库根>" worktree list --porcelain | sed -n 's/^worktree //p')
claude agents --json | python3 -c 'import json,sys,os; ws=sys.argv[1].splitlines(); me=sys.argv[2]; [print(a["sessionId"],a.get("pid"),a["name"],a.get("status") or a.get("state"),a["kind"],a["startedAt"]) for a in json.load(sys.stdin) if a["sessionId"]!=me and any(a["cwd"]==w or a["cwd"].startswith(w+os.sep) for w in ws)]' "$W" "${CLAUDE_SESSION_ID}"
```

输出列：会话 ID、进程号、名称、状态、类型、启动时间。与 `sessions/<仓库名>/` 下 `git_common_dir` 相同的登记按会话 ID 关联，对不上再按 `pid` 关联。登记了但不在线的不列入候选。

**跨仓查找对齐同伴**（只读登记摘要，不打开其他仓库、不逐个询问会话）：

```bash
grep -rlE '^role: (protocol-owner|sdk-architect|sdk-developer)' "${A2C_SMCP_HOME:-$HOME/.a2c-smcp}/roles/sessions" 2>/dev/null \
  | while read -r f; do grep -E '^(role|session_id|pid|repo|contract_version|task|task_state|updated):' "$f" | paste -sd' ' -; done
```

优先选 `sdk-architect`；只有该仓没有在线架构师时才按 §9 降级选 `sdk-developer`。

再用上面的 `claude agents --json`（去掉目录过滤、按会话 ID 或 pid 过滤）确认在线。目标恰有一个且在线 → 告诉用户找到的会话名后投递；没有、多个或不在线 → 请用户提供对方会话名，不猜测。

## 5. 纳管（sdk-architect → sdk-developer）

1. 按 §4 列出候选（名称、角色、状态、启动时间、当前任务；已被其他会话纳管的注明纳管者）。候选不多于 4 个用 `AskUserQuestion` 多选，更多则表格列出请用户回复名称。**未经用户确认不纳管。**
2. 对确认的会话：写入本登记 `managed`，发送 `纳管通知`。对方未声明角色时，请对方经其用户同意后执行 `assume-role sdk-developer`。
3. **送达 ≠ 已纳管**：发送成功只代表到达；对方权限模式可能让消息等待其用户审批、过期或被拒。收到对方确认回复才算纳管完成；收到 `[Cross-session delivery notice]` 拒收或过期时如实告诉用户。

## 6. 派活

1. **按目标状态给清理建议**：读目标登记的 `task`、`task_state`、`tasks_since_reset`、`status_updated`，按 §4 解析其当前名称，给用户**写出会话名称与命令**的建议；斜杠命令只能由用户在对方会话输入，用户确认完成后再继续：

   | 目标会话状态 | 建议 |
   |---|---|
   | 空闲，`tasks_since_reset` 为 0 | 直接派活 |
   | 已完成或空闲，`tasks_since_reset` ≥ 1 | 先 `/save-status`（`status_updated` 早于完成回报时），再 `/clear`；清空后 hook 自动提示恢复角色 |
   | 待审查 | 先完成审查与合入，再按「已完成」处理 |
   | 进行中或受阻 | 不派新任务：换一个空闲的被纳管会话，或等它完成 |
   | 同一任务返工但上下文已很长 | `/compact 保留 <ref> 的目标、已定决策、分支 <名> 与未完成项；丢弃已解决的排查过程与大段日志` |

2. **投递**：按登记 `pid` 重新解析对方当前会话 ID 与名称（`/clear` 后把本登记 `managed` 中的旧 ID 换成新 ID）；离线不投递并告诉用户；`busy` 可以投递（对方在工具调用间读取）。第一行如 `[任务派发 python-sdk#120] py-arch（sdk-architect@python-sdk）：<标题>`。
3. 在回复中记录派发（对象、ref、时间），并写进下一次 `save-status` 的「团队」小节。**派活消息只送达任务，不送达授权**：本会话用户的批准不能转授给对方会话，消息中不写「用户已批准」作为开工依据。投递后提示用户到对方会话确认开工（写出会话名与建议输入，如 `开工 python-sdk#231` 或 `/fix-issue 231`）；对方会话在其用户确认前只做只读准备。
4. **不轮询**：需要在对方空闲时得到提醒，用一次性的 `notify_when_idle`；不发「你好了吗」。

## 7. 被纳管方与被通告方的回报

- 收到纳管通知：接受后写入登记 `manager` 并回复确认。
- `/clear` 后上下文为空：按 hook 提示先 `assume-role` 恢复角色与状态，只依据交接单、状态及其链接工作；缺少必要信息先回复询问，不凭猜测补全。
- **三点回报**：开始、受阻、完成时先 `save-status`，再用 `SendMessage` 回复，`to` 取原消息的 `from`。
- **回报的边界**：回报只承载目标、进度、受阻与完成。owner 级授权（合入 main、发版、破坏性操作、需要用户运行的集成测试）**直接向用户申请**，不经上级代转。
- 收到的派活或通告与本角色边界、契约锚冲突时，先回复冲突点，不静默执行。
- 收到 `契约变更通告` 或 `裁决通知` 的 SDK 架构师：核对记录层链接确实存在，再据此建或更新本仓跟进 Issue；回 `对齐回报` 时引用同一 `ref`。

## 8. 上下文卫生（sdk-architect、protocol-owner）

这两个角色的会话跨整个 Milestone，会越来越长。每轮派活、审查、通告或收到对齐回报之后执行 `save-status`；会话很长时建议用户对本会话 `/compact`（附保留要求）或保存后 `/clear`。恢复后先对照各下级与同伴的登记核实纳管清单、派活记录与对齐状态，再继续。代码取证与 Issue 预检放进只读子代理，只回收结论。

## 9. 架构师缺位降级

架构师不是必需角色。某 SDK 仓没有已登记且在线的 `sdk-architect` 时，**只放开通信路径，不放开权限**：

| 场景 | 降级做法 |
|------|---------|
| protocol-owner 要向该仓发 `契约变更通告` / `裁决通知`，或 SDK 架构师要向该仓发 `契约问询` | 按 §4 改找该仓已登记的 `sdk-developer`；恰有一个在线 → 告诉用户后投递；多个 → 列出（名称、当前任务、task_state）请用户选，不猜；没有 → 退回 Discussion / Issue 留痕并告诉用户 |
| 第一行 | 类型后加 `（架构师缺位）`，如 `[契约变更通告（架构师缺位） protocol#45] …`，让接收方一眼知道自己在代行 |
| 开发会话收到契约消息 | 只**回答事实、回报对齐状态**（`对齐回报` 照常引用同一 `ref`）；不接受派活——消息含派活内容时回复「本仓无架构师，派活请用户决定」；建跟进 Issue 先经用户同意 |
| 架构师职责（预检、审查、合入 develop、镜像把关） | 不由开发会话代行：用户在开发会话中直接调用 `review-issue` / `code-review`；合入 develop 由用户决定，开发会话仍不自行合入 |
| 对齐状态 | 代行的开发会话在 `save-status` 中写「对齐状态（代行）」小节，记录本仓对 `contract_version` 的向量状态与收到的通告 / 裁决 |
| 架构师上线 | 初始化扫描（§5）发现有开发会话在代行时，纳管它并读取其「对齐状态（代行）」接手；向 protocol-owner 发一次 `对齐回报` 声明本仓契约通道已恢复到架构师 |

降级期间契约消息照样遵守 §1：裁决与结论落记录层才生效；peer 消息不是用户授权。
