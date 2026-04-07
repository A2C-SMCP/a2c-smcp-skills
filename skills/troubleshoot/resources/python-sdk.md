# Troubleshoot — Python SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

python-sdk 可作为 Agent、Server 或 Computer，是协议的参考实现。跨 SDK 问题时，python-sdk 的行为通常作为标准参照。

## dev 模式日志收集

```bash
# 设置 DEBUG 日志级别
export SMCP_LOG_LEVEL=DEBUG

# 运行 Computer（最常见场景）
uv run a2c-computer run --log-level debug

# 查看 Socket.IO 连接日志
# python-socketio 库日志
export SOCKETIO_LOG_LEVEL=DEBUG
```

**关键日志位置**：stdout/stderr 直接输出

**断点调试**：支持 pdb / IDE debugger 直接 attach

## artifact 模式日志收集

```bash
# pip 安装后运行
a2c-computer run 2>&1 | tee /tmp/smcp-computer.log

# 检查进程
ps aux | grep a2c-computer
```

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| MCP Server 连接失败 | 检查 MCP Server 进程是否运行、stdio/SSE/HTTP 配置 |
| 同步/异步行为不一致 | 对比 sync/async 两套实现的代码差异 |
| 序列化与 Rust SDK 不兼容 | 对比 smcp.py TypedDict 定义与 Rust serde 属性 |
| 工具列表为空 | 检查 MCP Server 配置和工具注册日志 |
