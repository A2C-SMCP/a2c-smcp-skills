# Troubleshoot — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

MCP Server + OASP 协议 Server 端。位于 Computer ↔ Office Add-In 之间，是 OASP 数据流的中枢。

## 日志管理体系

office4ai 使用 loguru 统一日志，通过环境变量配置：

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `OFFICE4AI_LOG_DIR` | `./logs` | 日志文件目录，设为空字符串禁用文件日志 |
| `OFFICE4AI_LOG_LEVEL` | `INFO` | 最低日志级别 |
| `OFFICE4AI_LOG_CONSOLE` | `true` | 是否输出到控制台 |

**日志文件**：`{LOG_DIR}/office4ai-mcp_{date}.log`，按天轮转，保留 3 天。
**统一拦截**：socketio/engineio/aiohttp/uvicorn 的 stdlib logging 均桥接到 loguru。

## dev 模式日志收集

```bash
# 调低日志级别，同时输出到控制台和文件
OFFICE4AI_LOG_LEVEL=DEBUG uv run office4ai-mcp serve

# 日志文件默认在 ./logs/office4ai-mcp_YYYY-MM-DD.log
```

**关键日志关注点**：
- `Client registered:` — Add-In 连接事件
- `Document not connected:` — URI 匹配失败（参见 debug-socketio-connection skill）
- `Tool call:` / `Tool result:` — MCP 工具调用链路

## artifact 模式日志收集

通过 `uvx` 直接运行时，日志文件写入**当前工作目录**下的 `./logs/`：

```bash
# uvx 运行（常见场景）— 日志自动写入 ./logs/
OFFICE4AI_LOG_LEVEL=DEBUG uvx office4ai-mcp serve

# 查看日志文件
ls ./logs/office4ai-mcp_*.log
tail -f ./logs/office4ai-mcp_$(date +%Y-%m-%d).log

# 如果需要指定日志目录
OFFICE4AI_LOG_DIR=/tmp/office4ai-logs uvx office4ai-mcp serve

# 检查 Socket.IO 端口
lsof -i :5100   # 默认端口
```

**注意**：uvx 运行时无需手动 tee 转存，loguru 文件 sink 自动持久化日志。如需禁用文件日志仅看控制台，设置 `OFFICE4AI_LOG_DIR=""`。

## 跨系统排查（OASP 链路）

office4ai 问题常需联合 office-editor4ai 排查：
1. 检查 office4ai 侧 Socket.IO Server 是否收到事件
2. 检查 office-editor4ai 侧 Socket.IO Client 是否发出事件
3. 对比事件名和数据结构是否与 OASP 协议一致

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| Document not connected | URI 规范化不一致（URL 编码/符号链接） |
| 工具调用超时 | Add-In 端 Office.js 操作耗时过长 |
| MCP 工具未注册 | 检查 OfficeMCPServer._register_tools() |
| LibreOffice UNO 错误 | UNO Bridge 连接状态、LibreOffice 进程 |
