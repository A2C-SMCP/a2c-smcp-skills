---
name: cross-ask
description: 跨项目问询报告生成。当前项目工程师遇到需要其他项目工程师协助的问题时，生成结构化问询问卷，由用户转发给对应工程师并收集回复。解决工程师视角局限、不知道该问什么的问题。
argument-hint: "<目标项目> <问题简述或提问方向>"
---

# Cross Ask — 跨项目问询报告

当工程师在当前项目遇到需要其他项目工程师协助解决的问题时，生成结构化问询问卷。

**核心价值**：工程师往往只了解自己负责的项目，缺乏全局视角，不知道该向谁问什么。本 Skill 基于当前会话上下文和目标项目的架构特点，自动生成精准的问题清单，让跨项目沟通一次到位。

## 参数解析

`/cross-ask <目标项目> <问题简述或提问方向>`

**目标项目识别**（不区分大小写，支持简写）：

| 输入 | 目标项目 | 工程师职责 |
|------|---------|-----------|
| `python` / `python-sdk` | python-sdk | SMCP Python SDK（参考实现、sync/async、MCP 客户端管理） |
| `rust` / `rust-sdk` | rust-sdk | SMCP Rust SDK（生产实现、workspace crates、Tokio） |
| `protocol` / `smcp` | a2c-smcp-protocol | SMCP 协议规范（Socket.IO 三角色、数据结构定义） |
| `office` / `office4ai` | office4ai | Office MCP Server（Word 工具、LibreOffice UNO、Gymnasium） |
| `ide` / `ide4ai` | ide4ai | AI IDE MCP 工具（代码导航/编辑/LSP/终端） |
| `oasp` | oasp-protocol | OASP 协议规范（Office AddIn Socket.IO） |
| `editor` / `office-editor` | office-editor4ai | Office Add-Ins（Word/Excel/PPT、React、FluentUI） |
| `client` / `tfrobot` | tfrobot-client | Computer 桌面客户端（Tauri、MCP 服务器管理） |

未提供参数 → 用 `AskUserQuestion` 引导选择目标项目和描述问题。

---

## Step 1：分析当前会话上下文

回顾当前会话，提取：

| 信息 | 来源 |
|------|------|
| **当前项目** | 工作目录 |
| **正在做什么** | 会话中的任务描述、代码修改、报错信息 |
| **卡在哪里** | 最近的错误、疑问、不确定的假设 |
| **已知线索** | 已收集的日志、代码片段、配置信息 |

## Step 2：加载目标项目问卷模板

读取 `{baseDir}/resources/<target-project>.md`，获取该项目的：
- 问卷必填字段（该项目工程师需要回答的关键维度）
- 常见协作场景（帮助判断问题属于哪种场景）
- 信息格式要求（如 API 路径、数据结构定义、协议事件名等具体格式）

## Step 3：生成问询问卷

结合会话上下文和目标项目模板，生成 Markdown 格式的问询报告。**直接输出在聊天框**，用户可直接复制转发。

### 问卷格式

```markdown
# 跨项目问询 — [目标项目名]

## 背景
> 来自 [当前项目] 工程师，正在处理 [任务简述]

[1-3 句话描述当前在做什么，遇到了什么问题，为什么需要目标项目工程师协助]

## 问题方向
[用户提供的问题简述，经过结构化整理]

## 请协助确认
[根据目标项目模板生成的具体问题列表，每个问题独立编号]

1. **[问题标题]**
   [问题详情 + 为什么需要这个信息]

2. **[问题标题]**
   [问题详情]

...

## 参考信息
[从当前会话中提取的相关代码片段/日志/配置/错误信息，帮助对方理解上下文]

---
*请将回复直接粘贴到本项目的 Claude Code 会话中，以便继续处理。*
```

### 生成原则

1. **问题精准**：每个问题都应直接帮助解决当前阻塞，不问无关信息
2. **上下文充分**：包含足够的背景，对方无需追问即可理解并回答
3. **格式具体**：明确期望的回答格式（如 TypedDict 定义、Rust struct、Office JS API 等）
4. **数量克制**：通常 3-6 个问题，不超过 8 个
5. **项目特有字段**：必须覆盖 resource 模板中定义的必填字段

---

## 项目间常见协作场景速查

| 发起方 → 目标方 | 典型问题 |
|----------------|---------|
| python-sdk ↔ rust-sdk | SDK API 一致性、行为差异、sync/async vs Tokio 实现差异 |
| SDK → protocol | 事件定义、数据结构字段含义、协议版本变更影响 |
| office4ai ↔ editor4ai | MCP 工具实现、Socket.IO 事件处理、OASP 数据流 |
| office4ai / editor4ai → oasp | OASP 事件格式、命名空间定义、请求/响应结构 |
| client → rust-sdk | smcp-computer 库 API、MCP 传输层（stdio/SSE/HTTP） |
| client → office4ai / ide4ai | MCP Server 启动参数、工具 schema、健康检查 |
| ide4ai → protocol | MCP 工具注册、Computer 角色行为 |
| Any → protocol | 三角色模型、Room 隔离机制、事件命名规范 |

---

## 安全规则

1. **不包含敏感信息**：问卷中不嵌入密码、Token、密钥等
2. **脱敏处理**：IP 地址、域名等环境特定值用占位符替代
3. **最小信息原则**：只包含解决问题必需的上下文，不暴露无关代码
