# Fix Issue — Office Editor4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：JIAQIA/office-editor4ai
- **语言**：TypeScript，pnpm workspace monorepo
- **架构**：两层 — 工具封装层（Office.js API → 语义化工具）+ 协议暴露层（OASP Socket.IO）
- **子项目**：Excel(3001)、Word(3002)、PPT(3003) 三个独立 Add-In
- **协议**：实现 OASP 协议 Add-In 端

## 调用链路追踪

- **事件处理**：Socket.IO 事件接收 → Schema 校验 → Handler 执行 → Office.js API → 结果返回
- **跨系统问题**：需区分根因在 office-editor4ai（Add-In 端）还是 office4ai（Server 端）
- **Office.js 限制**：部分操作受 Office.js API 能力限制（如 PPT 不支持视频/音频插入）

## 双端协调

修复涉及 OASP 事件时：
- Schema/Handler 修改需确保与 office4ai 的 DTO/Handler 对齐
- 事件名格式必须遵循 `{namespace}:{action}:{target}`
- 错误码使用对应范围（1xxx-5xxx）

## Step 5 差异：架构原则

- **共享代码**：`/src/shared/` 符号链接跨 Add-In 共享，修改时注意影响全部三个子项目
- **稳定性差异**：/word 事件为 Stable，修改门槛高；/ppt 和 /excel 为 Draft
- **Office.js API**：注意 API 可用性差异（Word/Excel/PPT 各有不同）

## Step 7 差异：验证命令

```bash
pnpm build        # 类型检查 + 构建
pnpm test         # 测试（如有）
pnpm lint         # ESLint
```
