# Troubleshoot — TFRobot Client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

Computer 的桌面客户端 GUI，封装 rust-sdk 的 smcp-computer crate。问题可能在前端（React）、后端（Rust/Tauri）或上游依赖（smcp-computer）。

## dev 模式日志收集

```bash
# 前端日志：浏览器 DevTools Console（Tauri 内置 WebView）
# 后端日志
cd src-tauri && RUST_LOG=debug cargo tauri dev

# Tauri IPC 调试
# 在 DevTools Console 观察 invoke() 调用和返回值
```

**断点调试**：
- 前端：Chrome/WebView DevTools
- 后端：rust-analyzer + IDE debugger attach 到 Tauri 进程

## artifact 模式日志收集

```bash
# macOS 应用日志
# Tauri 应用日志位置取决于 Tauri 的日志插件配置
# 通常：~/Library/Logs/<app-name>/

# 检查进程
ps aux | grep tfrobot
```

## 上游问题判定

如果问题在 smcp-computer API 调用层面：
- 用相同参数直接调用 smcp-computer API（绕过 Tauri），确认是否复现
- 如果复现 → 上游问题，提 Bug Report 到 rust-sdk
- 如果不复现 → 本项目 Tauri/IPC 层问题

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| IPC 调用无响应 | 检查 Tauri command 是否注册、参数序列化 |
| 前端状态不更新 | 检查 Zustand store action 是否正确触发 |
| 连接 Server 失败 | 区分是 smcp-computer 问题还是网络配置 |
