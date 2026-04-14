# Cross Ask TF — TFRobotV2 问卷模板

> 当 A2C-SMCP 工程师需要向 TFRobotV2 工程师提问时，使用此模板。

## 项目职责

TFRobotV2 是机器人核心逻辑层：Thought Chain（推理链）、Drive（工具执行）、Brain（记忆系统）、Grammar（指令解析）。V2 作为库被 TFRobotServer 的 Celery Workers 调用，**不独立部署**——对外行为通过 Server API 和 Socket.IO 事件暴露。

## A2C 常见对接场景

| A2C 项目 | 对接需求 |
|---------|---------|
| office-editor4ai | 理解聊天过程中 Chain 状态变化对应的 Socket.IO 事件，正确渲染消息流 |
| tfrobot-client | 理解 Robot 配置 Schema 中各字段的含义，提供合理的配置 UI |

## 问卷必填字段

### 1. 涉及的核心子系统

| 子系统 | A2C 相关度 | 典型问题 |
|--------|-----------|---------|
| **Thought Chain** | 高 | Chain 执行状态（init/thinking/doing/succeeded/failed）在 Socket.IO 事件中如何体现？ |
| **Drive（工具）** | 中 | 工具调用过程中推送的事件？工具参数 schema 格式？ |
| **Robot 配置** | 高 | 配置 JSON 中各字段含义（scene、factory、参数列表） |
| **Grammar** | 低 | 通常不涉及 A2C 对接 |
| **Brain（记忆）** | 低 | 通常不涉及 A2C 对接 |

### 2. Robot 配置 Schema（高频对接点）

如需理解 Robot 配置结构：

- Robot 配置的顶层字段列表（`scene`、`factory` 等核心字段含义）
- 对 A2C 集成有影响的字段（如 LLM 模型选择、上下文长度、工具列表）
- 配置的 JSON Schema 或 TypeScript 接口定义

### 3. Chain 执行状态与 Socket 事件

如涉及聊天消息流处理：

- Chain 状态机的状态列表（init → thinking → doing → succeeded/failed）
- 每个状态变化对应推送的 Socket.IO 事件名和 Payload
- 流式文本输出的事件格式（token 级别还是句子级别？）
- 工具调用开始/结束的事件格式

### 4. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 配置 Schema | Python TypedDict / JSON Schema / 带注释的 JSON 示例 |
| 状态机 | 状态列表 + 转换条件 + 对应 Socket 事件名 |
| Socket Payload | 事件名 + TypeScript 类型定义 + 示例 JSON |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| office-editor4ai | 聊天时有哪些 Socket 事件？流式文本输出的 Payload 格式？工具调用如何区分于普通消息？ |
| office-editor4ai | Chain 进入 failed 状态时推送的事件格式？如何向用户显示错误？ |
| tfrobot-client | Robot 配置中 `scene` 字段的可选值及含义？哪些字段影响 UI 展示？ |
