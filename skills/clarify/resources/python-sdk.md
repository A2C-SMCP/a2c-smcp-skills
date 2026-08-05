# Clarify — python-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：SMCP Python SDK（协议参考实现）
- **语言/工具链**：Python，uv 管理依赖，pytest 测试
- **定位**：SMCP 协议的 Python 参考实现——它的 API 设计、行为语义会直接影响到 rust-sdk 是否需要对齐，以及协议规范的修订方向

## 影响视角定义

python-sdk 使用**标准三视角**（终端用户 + 开发者 + SDK 消费者），且视角 2 和视角 3 在本项目中权重更高：

| 视角 | 本项目中的含义 |
|------|---------------|
| **终端用户** | 使用 python-sdk 构建的 AI Agent/Computer 应用的最终用户 |
| **开发者** | 用 python-sdk 写代码的 Python 开发者——他们调用 SDK 的 Agent/Server/Computer API |
| **SDK 消费者** | 依赖 python-sdk 的外部项目开发者——他们要兼容你的 API 变更、适配你的行为版本 |

## 关键用户画像

### 画像 1：AI 应用开发者（调用方）
- 场景：在自己的 Python 项目中引入 SMCP SDK，连到 Agent 系统
- 敏感点：API 稳定性、文档清晰度、报错信息可理解性
- 典型问题：「这个 `@agent.tool` 装饰器加了参数后，我之前的代码还能跑吗？」

### 画像 2：SDK 消费者项目维护者
- 场景：项目依赖了 python-sdk 的某个版本，升级时评估 breaking change
- 敏感点：changelog 中「breaking」项的真实影响、deprecation 过渡期长度
- 典型问题：「v0.5 的变更是否要求我重写 Computer 端到 Server 的连接逻辑？」

### 画像 3：协议/SDK 协作者（rust-sdk 维护者）
- 场景：python-sdk 的行为变更需要 rust-sdk 对齐
- 敏感点：双实现一致性、语义差异
- 典型问题：「py-sdk 把 timeout 默认值从 30s 改 60s，rust-sdk 要不要同步？」

## 典型决策场景

| 场景 | 核心影响维度 |
|------|-------------|
| API 签名变更（加参数/改返回值） | 开发者适配成本 + SDK 消费者 break |
| 默认行为变更（timeout/重试/连接策略） | 终端用户体验（隐式行为变化）+ 双实现对齐 |
| 新增模块/移除废弃 API | SDK 消费者迁移成本 + 开发者学习曲线 |
| 协议层对齐变更 | 三视角全涉及——且必须联动 rust-sdk |
