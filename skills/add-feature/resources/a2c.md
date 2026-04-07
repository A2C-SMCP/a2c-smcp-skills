# Add Feature — A2C 协议线

> 通用流程参见 SKILL.md 主文件。

## 协议线概况

- **协议仓库**：A2C-SMCP/a2c-smcp-protocol
- **代码仓库**：python-sdk（参考实现）、rust-sdk（生产实现）、tfrobot-client（桌面客户端）
- **当前版本**：0.2.0 (Release Candidate)
- **版本管理**：pyproject.toml 单一来源 + bump-my-version + mike 多版本文档

## 协议核心模型

**三角色模型**（不可变更）：

| 角色 | 数量约束 | 职责 |
|------|---------|------|
| Agent | 每房间最多 1 个（独占） | 工具调用发起方 |
| Server | 全局 1 个（逻辑） | 信令中枢：连接管理、消息路由、通知广播 |
| Computer | 每房间可多个 | MCP Server 宿主，统一管理和暴露工具 |

**事件分类**（/smcp 命名空间，共 20 个事件）：

| 前缀 | 方向 | 事件数 | 示例 |
|------|------|--------|------|
| client:* | Agent → Server → Computer | 5 | tool_call, get_tools, get_config, get_desktop, get_finder |
| server:* | 客户端 → Server | 8 | join_office, leave_office, update_config, update_tool_list, tool_call_cancel, list_room |
| notify:* | Server → 广播 | 7 | enter_office, leave_office, update_config, update_tool_list, tool_call_cancel |

**错误码体系**：
- 通用 HTTP 风格：400/401/403/404/408/500
- 工具调用 4001-4005（Not Found / Disabled / Execution Failed / Timeout / Requires Confirmation）
- 房间管理 4101-4104（Room Full / Not Found / Not In Room / Cross Room Access）
- Finder 4201-4204（Document Not Found / Page Out of Range / Element Not Found / Invalid DPE URI）

## Step 1 差异：协议合规检查

SMCP 协议规范文档位于 `docs/specification/`：

| 文档 | 关注场景 |
|------|---------|
| events.md | 新增/修改事件（client:*/server:*/notify:*） |
| data-structures.md | 新增/修改 TypedDict 消息结构（AgentCallData, ToolCallReq, SMCPTool 等） |
| room-model.md | 涉及房间隔离、Agent/Computer 角色变更 |
| error-handling.md | 新增错误码（⚠️ 标注为草案状态） |
| security.md | 涉及凭证传播、权限模型 |

**SMCP 不可违反的约束**：
- 三角色模型（Agent/Server/Computer）及数量约束不可变更
- 事件前缀约定（client:/server:/notify:）及路由语义必须遵守
- Room 隔离规则：Agent 独占、Computer 绑定、禁止跨 Room 访问
- 零凭证传播：敏感 Token 仅存在 Computer 本地，不向 Agent 暴露
- 所有请求必须含 req_id 做关联与去重

**子系统扩展注意**：
- Desktop 系统（window:// 资源聚合）和 Finder 系统（dpe:// 文档目录）是独立子系统
- 新增子系统级 Feature 需同时评估 client:get_* 事件和 server:update_* 通知事件的配套

## Step 2 差异：向后兼容评估

**各角色实现要求**：

| 角色 | 必须实现 | 建议实现 |
|------|---------|---------|
| Server | 所有 server:* 处理 + client:* 路由 + notify:* 广播 | — |
| Computer | 所有 client:* 处理 + 房间管理事件 | — |
| Agent | — | 所有 notify:* 监听（自动发现工具、清理状态） |

新增事件时需确认：是否为 Agent "建议实现" 变为 "必须实现"？这属于**破坏性变更**。

## Step 4 差异：代码仓库关联

**实现顺序建议**：
1. python-sdk（参考实现，先验证协议可行性）
2. rust-sdk（生产实现，跟进对齐）
3. tfrobot-client（依赖 rust-sdk 的 smcp-computer crate）

**python-sdk 双实现一致性**：
- 同步/异步双实现需同步更新（namespace.py + sync_namespace.py、client.py + sync_client.py）
- 协议定义双文件需同步：smcp.py（TypedDict）+ model.py（Pydantic）
- Server 和 Agent 均提供同步/异步双栈

**rust-sdk Workspace crates 对齐**：
- 协议类型在 smcp crate 中定义
- 各角色 crate（smcp-agent / smcp-computer / smcp-server-core / smcp-server-hyper）按需跟进
- Feature flags 控制模块启用（agent/computer/server/full/e2e）
