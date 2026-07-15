---
name: answer-ask
description: 回复 SMCP 核心三仓（a2c-smcp-protocol / python-sdk / rust-sdk）的 cross-ask 问询。输入必须是合法的 a2c-smcp-protocol GitHub Discussion 链接（三仓问询统一留痕处），其他形式一律拒绝。读取问卷后以当前项目身份起草回复——先表明来源项目，再逐条给出看法；以协议身份回复时先按 resources/protocol-scope.md 判定问题是否属协议管辖，不管辖的显式声明并交双 SDK 对齐。当用户收到其他项目转达的问询 Discussion 链接需要回复时调用。
argument-hint: "<a2c-smcp-protocol Discussion 链接> [回复要点]"
---

# Answer Ask — 三仓问询回复

与 `/cross-ask` 配对：cross-ask 把三仓（a2c-smcp-protocol / python-sdk / rust-sdk）之间的问询统一落到 a2c-smcp-protocol 仓的 GitHub Discussion 留痕；本 skill 供**被问方**工程师在自己项目的会话中，以本项目身份正式回复该 Discussion。

---

## Step 0：输入校验（强制）

**合法输入只有一种**：`https://github.com/A2C-SMCP/a2c-smcp-protocol/discussions/<N>`

以下一律**拒绝执行**并给出引导：

| 非法输入 | 引导 |
|---------|------|
| Issue / PR 链接 | 回复 Issue 走 `/fix-issue`、`/add-feature` 或 `gh issue comment`，不走本 skill |
| 其他仓库的 Discussion 链接 | 三仓问询统一留痕在 a2c-smcp-protocol，请发起方先用 `/cross-ask` 迁移 |
| 纯文字问题 / 粘贴的问卷全文 | 请发起方先用 `/cross-ask` 创建 Discussion 后转达链接——无留痕不回复 |

## Step 1：读取问询上下文

```bash
gh api graphql -F number=<N> -f query='
query($number: Int!) {
  repository(owner: "A2C-SMCP", name: "a2c-smcp-protocol") {
    discussion(number: $number) {
      id title body url category { name }
      comments(first: 50) { nodes { id author { login } body createdAt } } } } }'
```

提取：

1. **来源项目 / 目标项目**：标题格式 `[cross-ask] <来源项目> → <目标项目>: <主题>`；标题不规范则从正文推断
2. **问题清单**：问卷"请协助确认"的编号问题
3. **已有回复**：先读评论，已被回答的问题不重复回答，只补充或修正

## Step 2：确定回复身份

| 情形 | 处理 |
|------|------|
| 当前工作目录 ∈ 三仓 | 该项目即回复身份 |
| 标题目标项目 ≠ 当前项目 | 提醒用户：可能转达对象有误；确认后可以第三方身份补充意见 |
| 当前目录不在三仓 | AskUserQuestion 确认以哪个项目身份回复 |

## Step 3：管辖判定（回复定调）

按 `{baseDir}/resources/protocol-scope.md` 判定问题属于**协议管辖**还是 **SDK 自治**：

| 判定 | 回复身份 = a2c-smcp-protocol | 回复身份 = python-sdk / rust-sdk |
|------|------------------------------|----------------------------------|
| **协议管辖** | 给权威答复：引用规范章节 / `data-structures.md` 定义；现有规范无答案 → 说明将走 `/add-feature` 协议先行流程并给出计划 | 只给实现侧观察与诉求，**不得替协议拍板**；回复中显式建议「需协议裁决」 |
| **SDK 自治** | 显式声明「协议不介入，属 SDK 实现细节」，建议双 SDK 在本 Discussion 直接对齐、结论留痕 | 给出本 SDK 的实现现状、约束与建议方案 |

## Step 4：调研与起草

**先核实再回答**：涉及本项目代码行为的问题，先在本项目代码中确认（引用 GitHub permalink），禁止凭印象回答。

回复格式模板：

```markdown
**[回复来源：<python-sdk / rust-sdk / a2c-smcp-protocol>]**

## 结论
[一句话总回答]

## 逐条回复
1. **[对应问卷问题 1]**
   [回答 + 依据：代码 permalink / 协议规范章节 / 测试结果]
2. ...

## 管辖判定（协议身份回复时必填）
本问题属于 [协议管辖 / SDK 自治]。[一句话理由，判定标准见 protocol-scope]

## 后续动作
[需协议变更走 add-feature / 需 <项目> 补充回复 / 本侧将建 Issue 跟进（附链接）/ 无]
```

## Step 5：确认与提交

1. AskUserQuestion 向用户确认回复内容（**未确认不得提交**）
2. 提交评论：

```bash
gh api graphql -F discussionId=<Step 1 的 discussion id> -F body='<回复全文>' -f query='
mutation($discussionId: ID!, $body: String!) {
  addDiscussionComment(input: {discussionId: $discussionId, body: $body}) {
    comment { url } } }'
```

3. Q&A 类别且本回复完整解答问询 → 经用户确认后可标记为答案：

```bash
gh api graphql -F commentId=<comment id> -f query='
mutation($commentId: ID!) {
  markDiscussionCommentAsAnswer(input: {id: $commentId}) { discussion { number } } }'
```

## Step 6：闭环转达

- 回复结论**需要另一个项目跟进或回复**（如 SDK 回复中建议"需协议裁决"）→ **显式要求用户**把 Discussion 链接转达给该项目工程师，由其执行 `/answer-ask <链接>` 接力回复
- 回复引出本项目代码变更 → 引导走 `/fix-issue` 或 `/add-feature`，并把产生的 Issue 链接补充评论到 Discussion
- 双 SDK 对齐类结论 → 提醒用户：对齐结论以本 Discussion 为准，两侧各自建实现 Issue 时引用它

---

## 强制约束

- **禁止非法输入执行** — 不是 a2c-smcp-protocol 的 Discussion 链接一律拒绝并引导
- **禁止匿名回复** — 回复必须以 `**[回复来源：xxx]**` 开头
- **禁止越权拍板** — SDK 身份不得替协议做管辖内决策；协议身份对不管辖的问题必须显式声明不介入
- **禁止凭印象回答** — 涉及代码行为必须先在本项目核实并给出依据
- **禁止未确认提交** — 回复内容必须经用户审阅确认
