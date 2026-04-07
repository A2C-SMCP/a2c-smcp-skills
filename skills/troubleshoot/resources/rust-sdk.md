# Troubleshoot — Rust SDK 专属指南

> 通用流程参见 SKILL.md 主文件。
> **GitHub**: A2C-SMCP/rust-sdk

## 角色

rust-sdk 是协议的生产实现，包含 Agent、Server、Computer。tfrobot-client 依赖其 smcp-computer crate。

## dev 模式日志收集

```bash
# 设置日志级别（使用 tracing）
RUST_LOG=debug cargo run --example <example_name>

# 更精细的日志过滤
RUST_LOG=smcp_agent=debug,smcp_computer=trace,smcp_server_core=debug

# 运行测试时查看日志
RUST_LOG=debug cargo test <test_name> -- --nocapture

# E2E 测试
RUST_LOG=debug cargo test --features e2e -- --ignored --nocapture
```

**断点调试**：rust-analyzer + IDE debugger，或 `rust-gdb` / `rust-lldb`

## artifact 模式日志收集

```bash
# 查看构建制品运行日志
RUST_LOG=debug ./target/release/<binary> 2>&1 | tee /tmp/smcp.log

# 检查进程和端口
lsof -i :<port>
```

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| Socket.IO 连接断开 | 检查 tf-rust-socketio 重连逻辑、网络超时配置 |
| serde 反序列化失败 | 对比 JSON 实际内容与 Rust 结构体定义 |
| Feature 编译错误 | 确认 feature flags 组合正确（agent/computer/server） |
| 与 Python SDK 互操作失败 | JSON 序列化格式对比（字段名、Optional 处理、枚举标记） |
| 工具调用超时 | 检查 timeout 配置、MCP Server 响应时间 |
