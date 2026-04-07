# Fix Issue — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：JIAQIA/office4ai
- **语言**：Python，uv 管理
- **架构**：MCP Server + Gymnasium 环境，LibreOffice UNO Bridge 双层
- **协议**：实现 OASP 协议（office4ai 作为 Server 端），同时作为 SMCP Computer 的 MCP Server

## 调用链路追踪

- **MCP 工具调用**：AI Agent → MCP Tool → Socket.IO 事件发送 → Office Add-In 执行 → 结果返回
- **UNO 直接操作**：AI Agent → MCP Tool → LibreOffice UNO API → 文档操作
- **跨系统问题**：需区分根因在 office4ai（Server 端）还是 office-editor4ai（Add-In 端）

## 双协议注意

office4ai 处于两条协议线的交叉点：
- **作为 OASP Server**：事件名/数据结构必须符合 OASP 协议（`{namespace}:{action}:{target}` 格式）
- **作为 SMCP Computer 的 MCP Server**：工具定义必须符合 MCP 规范

涉及 OASP 事件修改时，需同步考虑 office-editor4ai（Add-In 端）的对齐。

## Step 5 差异：架构原则

- DTO/Handler 修改时，确保与 office-editor4ai 的 Schema/Handler 对齐
- Socket.IO 事件名和数据结构两端必须一致
- MCP 工具与 OASP 事件的映射关系需保持正确

## Step 7 差异：验证命令

```bash
uv run poe test       # 全量测试
uv run poe lint       # ruff + mypy
```
