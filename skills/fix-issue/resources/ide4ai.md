# Fix Issue — IDE4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：A2C-SMCP/ide4ai
- **语言**：Python
- **架构**：高内聚低耦合，兼容 A2C-SMCP/MCP/Gymnasium 接口
- **核心能力**：代码导航（LSP）、精确编辑、终端执行、工作区管理
- **安全**：命令白名单机制

## 调用链路追踪

- **MCP 工具调用**：AI Agent → MCP Tool → 内部 API → LSP/终端/文件系统
- **LSP 集成**：工具函数 → LSP 客户端 → 语言服务器 → 结果解析
- **终端执行**：工具函数 → 命令白名单检查 → 子进程执行

## 独立演进与协议约束

ide4ai 为独立演进项目：
- 纯 MCP 工具部分不受 A2C 协议约束，可自由修复
- 但作为 SMCP Computer 的 MCP Server 时，工具定义需符合 MCP 规范
- 涉及 A2C 协议行为的部分（如 Computer 注册、工具列表上报），仍需遵守协议

## Step 5 差异：架构原则

- **命令白名单**：修改终端相关功能时，注意安全约束不可绕过
- **LSP 集成**：修改代码导航功能时，注意多语言 LSP 差异

## Step 7 差异：验证命令

```bash
# 具体命令视项目配置而定
uv run pytest          # 测试
uv run ruff check .    # Lint
```
