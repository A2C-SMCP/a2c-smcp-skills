---
name: cross-ask-tf
description: 向 TuringFocus 生态发起跨生态问询报告生成。当 A2C-SMCP 项目（如 tfrobot-client、office-editor4ai）需要与 TuringFocus Robot 系统对接时（如登录鉴权获取配置、接入 Socket.IO 聊天能力），生成结构化问询问卷，由用户转发给 TF 工程师并收集回复。
argument-hint: "<目标TF项目> <问题简述或提问方向>"
---

# Cross Ask TF — 跨生态问询报告（A2C-SMCP → TuringFocus）

当 A2C-SMCP 工程师在开发对接 TuringFocus Robot 系统的功能时，生成结构化问询问卷。

**核心价值**：A2C-SMCP 工程师没有 TuringFocus 内部代码访问权限，不了解其登录接口、Socket 事件定义、Robot 配置结构。本 Skill 基于当前会话上下文和目标 TF 项目的架构特点，自动生成精准的问题清单，让跨生态沟通一次到位。

## 参数解析

`/cross-ask-tf <目标TF项目> <问题简述或提问方向>`

**目标项目识别**（不区分大小写，支持简写）：

| 输入 | 目标项目 | 工程师职责 |
|------|---------|-----------|
| `server` / `tfrobotserver` | TFRobotServer | 服务端 API / 鉴权 / Socket.IO 聊天 / Robot 配置 |
| `front` / `tfrobotfront` | TFRobotFront | BFF 路由 / Cookie 鉴权 / 前端 Socket.IO |
| `manager` / `tfrsmanager` | TFRSManager | 用户登录 / JWT Token / 租户账号 / 订阅配额 |
| `v2` / `robotv2` / `tfrobotv2` | TFRobotV2 | Robot 核心逻辑 / Chain / 工具注册 / 配置 Schema |
| `portal` / `frontportal` | TFRobotFrontPortal | 前台门户 / BFF / 多账号 |
| `admin` / `adminportal` | TFRobotAdminPortal | 管理后台 / 权限 |

未提供参数 → 用 `AskUserQuestion` 引导选择目标项目和描述问题。

---

## Step 1：分析当前会话上下文

回顾当前会话，提取：

| 信息 | 来源 |
|------|------|
| **当前 A2C 项目** | 工作目录（tfrobot-client / office-editor4ai / 等） |
| **正在做什么** | 会话中的任务描述、代码修改、报错信息 |
| **卡在哪里** | 接口不清楚、认证方式未知、事件格式未知 |
| **已知线索** | 已有的 URL、Token 样本、抓包数据、产品截图描述 |

## Step 2：加载目标 TF 项目问卷模板

读取 `{baseDir}/resources/<target-project>.md`，获取该 TF 项目的：
- 问卷必填字段（TF 工程师需要回答的关键维度）
- A2C 对接常见场景（帮助判断问题属于哪种场景）
- 信息格式要求（如 API 路径、认证 Header、Socket.IO 事件 Payload 等具体格式）

## Step 3：生成问询问卷

结合会话上下文和目标 TF 项目模板，生成 Markdown 格式的问询报告。**直接输出在聊天框**，用户可直接复制转发给 TF 工程师。

### 问卷格式

```markdown
# 跨生态问询 — A2C-SMCP → [目标TF项目名]

## 背景
> 来自 A2C-SMCP [当前项目] 工程师，正在处理 [任务简述]

[1-3 句话描述当前在做什么，遇到了什么对接问题，为什么需要 TF 工程师协助]

## 问题方向
[用户提供的问题简述，经过结构化整理]

## 请协助确认

[根据目标 TF 项目模板生成的具体问题列表，每个问题独立编号]

1. **[问题标题]**
   [问题详情 + 为什么需要这个信息]

2. **[问题标题]**
   [问题详情]

...

## 参考信息
[从当前会话中提取的相关代码片段/日志/配置/错误信息，帮助 TF 工程师理解上下文]

---
*请将回复直接粘贴到本项目的 Claude Code 会话中，以便继续处理。*
```

### 生成原则

1. **问题精准**：每个问题都应直接帮助解决当前对接阻塞，不问无关信息
2. **上下文充分**：包含足够背景，TF 工程师无需追问即可理解
3. **格式具体**：明确期望的回答格式（API curl 示例、TypeScript 类型、Socket 事件 Payload）
4. **数量克制**：通常 3-6 个问题，不超过 8 个
5. **项目特有字段**：必须覆盖 resource 模板中定义的必填字段

---

## A2C-SMCP 对接 TF 常见场景速查

| A2C 项目 → TF 目标 | 典型问题 |
|--------------------|---------|
| tfrobot-client → server | **登录接口（路径/参数/Token 格式）以便客户端获取配置** |
| tfrobot-client → manager | **用户认证 API、JWT 格式、Token 生命周期** |
| office-editor4ai → server | **Socket.IO 聊天事件定义、认证握手、消息格式** |
| office-editor4ai → front | **BFF 鉴权 Cookie 格式、登录 API 路由** |
| office-editor4ai → v2 | Robot 配置 Schema、Chain 状态定义 |
| Any A2C → server | **CORS 配置、跨域请求头要求** |

---

## 安全规则

1. **不包含敏感信息**：问卷中不嵌入密码、Token 明文、密钥等
2. **脱敏处理**：IP 地址、域名等环境特定值用占位符替代（如 `https://<tfrobot-server>/`）
3. **最小信息原则**：只包含解决问题必需的上下文，不暴露 A2C 内部未公开架构
