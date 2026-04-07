# Fix Issue — Python SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Python 3.11+，uv 管理
- **架构**：三模块（Agent/Server/Computer）同步/异步双实现
- **协议定义**：smcp.py（TypedDict）+ model.py（Pydantic）双文件
- **测试**：pytest 三层 — unit_tests / integration_tests / e2e

## 调用链路追踪

- **Agent 侧**：SmcpAgent API → Socket.IO client → 事件序列化 → Server
- **Server 侧**：Socket.IO 连接管理 → 房间/会话 → 事件路由 → 通知广播
- **Computer 侧**：事件接收 → MCP 客户端状态机 → MCP Server 调用 → 结果聚合

## Step 5 差异：架构原则

- **同步/异步双实现必须同步更新**：namespace.py ↔ sync_namespace.py，client.py ↔ sync_client.py
- **协议定义双文件必须同步**：smcp.py（TypedDict）↔ model.py（Pydantic）
- **复用优先**：检查 `a2c_smcp/utils/` 下已有工具，优先增强而非新建
- **MCP 客户端状态机**：修改状态转换时注意 transitions 库约束

## Step 7 差异：验证命令

```bash
# 测试
uv run poe test                    # 全量测试
uv run pytest <test_file> -v       # 单个测试文件

# Lint + 类型检查
uv run poe lint                    # ruff + mypy
```

## 协议一致性检查

修改 `smcp.py` 或 `model.py` 时，必须对照 a2c-smcp-protocol 规范文档。字段名、类型、Optional 标记必须完全一致。
