# Troubleshoot — Office Editor4AI 专属指南

> 通用流程参见 SKILL.md 主文件。
> **GitHub**: JIAQIA/office-editor4ai

## 角色

OASP 协议 Add-In 端。运行在 Microsoft Office 内的 WebView 中，通过 Socket.IO 连接 office4ai。

## dev 模式日志收集

```bash
# 启动开发服务器
pnpm start:word    # Word Add-In (localhost:3002)
pnpm start:ppt     # PPT Add-In (localhost:3003)
pnpm start:excel   # Excel Add-In (localhost:3001)

# 日志在 Office 应用内的 WebView DevTools Console
# macOS: 通过 Safari Web Inspector 连接
# Windows: 通过 Edge DevTools
```

**关键日志关注点**：
- Socket.IO 连接状态（connect/disconnect/reconnect 事件）
- 事件发送/接收日志
- Office.js API 调用错误

## artifact 模式日志收集

部署后的 Add-In 运行在 Office 的沙箱中：
- 日志通过 Office 的开发者工具查看
- 网络请求通过 Office 内置网络面板查看

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| Add-In 无法连接 Server | 检查 Server URL 配置、CORS、网络连通性 |
| 事件发送但无响应 | 对比事件名是否与 office4ai 的 Handler 注册一致 |
| Office.js API 报错 | 检查 API 可用性（Word/Excel/PPT 各有差异） |
| 文档操作无效果 | Office.js 上下文是否正确、是否在正确的文档上执行 |
