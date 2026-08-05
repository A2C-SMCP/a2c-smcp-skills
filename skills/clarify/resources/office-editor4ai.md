# Clarify — office-editor4ai 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：Office 加载项（Word/Excel/PowerPoint Add-Ins）
- **语言/工具链**：TypeScript，pnpm workspace monorepo，Webpack 打包
- **定位**：运行在 Office 应用内的 JavaScript 加载项——通过 Socket.IO 接收 AI 指令，通过 Office.js API 操控 Office 文档

## 影响视角定义

office-editor4ai 处于链路末端——一端是 AI 的指令（通过 Socket.IO），另一端是 Office 文档（通过 Office.js）。使用**定制二视角**：

| 视角 | 本项目中的含义 |
|------|---------------|
| **终端用户** | 在 Office 应用中使用 AI 功能的用户——他们看到的是加载项面板和文档的实时变化 |
| **加载项开发者** | 开发和维护这些 Office Add-In 的开发者——面对 Office.js API 限制、WebView 兼容性、打包部署流程 |

## 关键用户画像

### 画像 1：Office 终端用户
- 场景：在 Word/Excel/PPT 中使用 AI 操作文档——比如「把选中的表格数据生成柱状图」「把所有正文改成宋体」
- 敏感点：操作响应速度（Office.js API 本身有延迟，AI 操作链路更长）、操作结果是否正确、加载项面板会不会卡住
- 典型问题：「AI 说操作完成了但 Excel 里没变化——是加载项断连了还是操作被 Office 安全策略拦住了？」

### 画像 2：加载项开发者
- 场景：维护 office-editor4ai 的三个加载项，处理 Office.js API 兼容性、打包配置、侧载部署
- 敏感点：Office.js API 的平台差异（Windows vs Mac vs Online）、WebView 兼容性、打包体积
- 典型问题：「Office.js 的新版本改了 `Range.insertTable` 的行为——我们的代码在旧的 Office 版本上还能跑吗？」

## 加载项特有影响维度

| 维度 | 追问 |
|------|------|
| 加载项启动速度 | 用户点开加载项面板到看到界面要等多久？变长还是变短？ |
| Office.js API 兼容性 | 这个变更在 Windows/Mac/Online 上都能正常工作吗？有没有平台特有行为？ |
| 连接恢复体验 | Socket.IO 断连后自动重连——用户会感觉到断连吗？重连后还在原来的文档位置吗？ |
| 部署流程 | 变更后用户需要手动更新加载项还是自动推送？部署过程中服务中断多久？ |

## 典型决策场景

| 场景 | 核心影响维度 |
|------|-------------|
| Office.js API 升级 | 跨平台兼容性 + 终端用户的功能可用性 |
| Socket.IO 连接策略变更 | 加载项响应实时性 + 断连恢复体验 |
| 打包/构建配置调整 | 加载项启动速度 + 开发者构建体验 |
| 加载项 UI 面板交互变更 | 终端用户的操作流程和直观感受 |
