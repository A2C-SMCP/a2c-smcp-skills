# Troubleshoot — IDE4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

AI IDE 工具的 MCP Server，作为 SMCP Computer 的 MCP 服务提供者。

## dev 模式日志收集

```bash
# 运行 MCP Server
uv run python -m ide4ai --debug

# LSP 相关问题需额外收集语言服务器日志
```

## artifact 模式日志收集

> ide4ai 尚未正式发布，artifact 模式暂略。正式发布后请通过 `/enhance-skill` 提交补充需求。

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| LSP 连接失败 | 检查对应语言的 LSP Server 是否安装和运行 |
| 命令执行被拒绝 | 命令白名单机制，检查命令是否在允许列表中 |
| 文件操作失败 | 工作区路径权限、文件是否存在 |
| 工具未注册到 Computer | MCP Server 配置、stdio 通信是否正常 |
