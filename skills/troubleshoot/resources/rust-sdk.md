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

## 验证加速：绕开 IDE build 锁争抢

**根因**：RustRover/VS Code 的 rust-analyzer 后台 `cargo check` 与命令行 cargo 共用同一 `target/`，Cargo 文件锁串行化 ⇒ 抢锁卡顿（rust-analyzer#4616/#12707）。征兆：`cargo test` 长时间 0 产出、CPU≈0，`lsof target/debug` 见 `rust-analyzer` 持锁。

**根治（用户一次性配置，推荐）**：IDE 设 `rust-analyzer.targetDir: true` ⇒ rust-analyzer 用独立 target 子目录，不再抢锁（官方最佳实践，原始需求 #6007）。

**Skill 侧（保证覆盖 + 不干等）**：

1. **先 lib 后集成**：`cargo test --lib` 先跑拿绿/红信号，集成/全量套件随后台。
2. **全量套件后台跑 + 轮询输出文件**：`run_in_background` 启动，`Read` 输出文件查进度，勿阻塞回合；**勿 `tail -N` 截断**（漏看失败列表），用 `grep` 取全量 result/FAILED 行。
3. **跳过已知环境 flake**：`-- --skip test_http_client_connection_timeout`（环境性网络超时）并注明。
4. **别一条命令跑两次 cargo**（如 `grep`+`awk` 各跑一次）——翻倍编译。
5. **争锁降级**：lib 全绿 + 隔离审查子代理通常已足够，全量集成留给 CI，勿干等。
6. **极端需要时**：给 Claude 自己的 cargo 单独 `CARGO_TARGET_DIR`（如 `target-claude`）彻底隔离（rust-analyzer#12760 该 env var 对 rust-analyzer 自身有 bug，但 Claude 的 cargo 不受影响）。

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
