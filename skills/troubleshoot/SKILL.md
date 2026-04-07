---
name: troubleshoot
description: 跨项目问题排查与诊断。支持 dev（本地编译调试）和 artifact（制品运行）两种模式，引导从数据流全局视角定位问题归属项目，必要时联合 TuringFocus 系统排查。当遇到难以定位的运行时错误、连接失败、数据不通等问题时使用。
argument-hint: "<dev|artifact> <问题描述或错误日志>"
---

# Troubleshoot — 跨项目问题排查

A2C-SMCP 体系的问题往往跨越多个项目边界。本 Skill 从全局数据流视角出发，定位问题归属并引导排查。

> **核心工作方式**：排查过程中每次做方向判断时，必须使用 AskUserQuestion 与用户沟通——陈述判断理由，请用户确认或纠正。用户是这些项目的开发维护者，他们的经验能帮你少走弯路。不要独自猜测方向。

---

## 全局数据流架构

```
┌─────────────────────────── A2C-SMCP 协议 ───────────────────────────┐
│                                                                      │
│  [Agent]  ←─client:*/server:*/notify:*─→  [Server]  ←──→  [Computer] │
│  python-sdk / rust-sdk                    python-sdk      python-sdk │
│                                           rust-sdk        rust-sdk   │
│                                                           tfrobot    │
└──────────────────────────────────────────────────────┬───────────────┘
                                                       │ MCP Protocol
                                              ┌────────┼────────┐
                                          [office4ai] [ide4ai] [其他MCP]
                                              │ OASP Socket.IO
                                       [office-editor4ai]
                                              │ Office.js API
                                       [Microsoft Office]
```

**问题定位关键**：确定故障发生在哪两个节点之间的连接上。

---

## Step 0：解析参数与模式选择

**排查模式**（第一个 token）：

| 模式 | 场景 | 日志特点 |
|------|------|---------|
| `dev` | 本地编译调试运行 | 可设置日志级别、可断点、有完整 stdout/stderr |
| `artifact` | 运行构建制品/部署版本 | 日志文件收集、进程日志、系统日志 |
| 留空 | 默认 `dev` | |

模式确定后，对应的环境配置文件为 `~/.a2c_smcp/{mode}-env.json`（如 `dev-env.json`、`artifact-env.json`）。

---

## Step 1：问题分类与数据流定位

### 1.1 分析错误信息

从用户提供的错误日志/描述中提取关键信息：

| 信号 | 可能涉及的项目 |
|------|---------------|
| Socket.IO 连接失败/超时 | Server ↔ Agent/Computer 之间 |
| `client:tool_call` 错误 | Agent → Server → Computer 链路 |
| `Document not connected` | office4ai ↔ office-editor4ai（OASP 层） |
| MCP Server 启动失败 | Computer 的 MCP 配置 |
| 工具调用返回错误 | Computer → MCP Server 之间 |
| Office 操作失败 | office-editor4ai → Office.js API |
| IPC 错误 | tfrobot-client 前后端之间 |
| 序列化/反序列化错误 | 跨 SDK 兼容性（Python ↔ Rust） |

### 1.2 确定故障区间

使用 AskUserQuestion 与用户确认故障发生在数据流的哪个区间：

1. **Agent ↔ Server**：连接、加入房间、事件路由
2. **Server ↔ Computer**：工具调用、配置同步、Desktop/Finder 聚合
3. **Computer ↔ MCP Server**：MCP 启动、工具注册、工具执行
4. **office4ai ↔ office-editor4ai**：OASP Socket.IO 事件、文档连接
5. **office-editor4ai ↔ Office**：Office.js API 调用
6. **tfrobot-client 内部**：Tauri IPC、前后端通信
7. **不确定**：需要进一步收集日志

---

## Step 2：调试环境确认

根据 Step 0 的模式，加载 `~/.a2c_smcp/{mode}-env.json`。

### 环境配置格式

```json
{
  "version": 1,
  "updated_at": "2026-04-07",
  "projects": {
    "<project-name>": {
      "location": "local | remote",
      "path": "/local/project/path",
      "ssh_connection": "SSH MCP connectionName",
      "project_dir": "/remote/project/dir",
      "log_path": "/remote/log/dir"
    }
  }
}
```

- **local**：需提供 `path`（本地项目目录）
- **remote**：需提供 `ssh_connection`（SSH MCP 连接名）、`project_dir`、`log_path`

### 确认流程

1. **配置存在** → 展示当前配置，AskUserQuestion 确认是否需要更新
2. **配置不存在** → 根据 Step 1 识别的相关项目，AskUserQuestion 逐个征询运行位置（local/remote）
3. **remote 项目** → 调用 `mcp__ssh-mcp-server__list-servers` 验证 SSH 连接可用；不可用则提示用户配置 SSH MCP Server
4. 保存/更新配置文件，后续排查直接复用

---

## Step 3：日志收集（按模式分支）

### dev 模式（本地编译调试）

按项目收集诊断信息：

> 各项目的日志收集命令参见 `{baseDir}/resources/<project>.md` "dev 模式日志收集"章节。

通用步骤：
1. 设置日志级别为 DEBUG
2. 复现问题，收集完整日志输出
3. 检查相关进程是否正常运行

### artifact 模式（制品运行）

按项目收集诊断信息：

> 各项目的日志收集命令参见 `{baseDir}/resources/<project>.md` "artifact 模式日志收集"章节。

通用步骤：
1. 定位日志文件/系统日志位置
2. 提取问题时间段的日志
3. 检查进程状态和端口占用

### 远程项目日志收集

当环境配置中项目 `location` 为 `remote` 时，通过 SSH MCP 执行：

- **执行命令**：`mcp__ssh-mcp-server__execute-command`，`connectionName` 取自 `ssh_connection`，`directory` 设为 `project_dir`，命令与本地相同（参见各项目 resource）
- **下载日志**：大日志文件用 `mcp__ssh-mcp-server__download` 拉到本地分析，`remotePath` 基于 `log_path`

### 无法自动收集日志时

部分环境（如 Office WebView、远程部署制品）的日志无法通过命令行自动获取。此时**必须使用 AskUserQuestion 向用户求助**，说明需要什么日志、在哪里查看，请用户手动提供：

```
需要您帮助收集以下日志：
- 在 Office 应用中打开 DevTools Console（F12）
- 复现问题操作
- 将 Console 中的错误日志复制粘贴给我
```

---

## Step 4：跨项目关联排查

### 4.1 确认两端状态

故障区间确定后，分别检查区间两端的项目状态：

| 检查项 | 方法 |
|--------|------|
| 进程是否存活 | `ps aux | grep` / 任务管理器 |
| 端口是否监听 | `lsof -i :<port>` / `netstat` |
| 配置是否正确 | 读取配置文件，对比协议要求 |
| 版本是否兼容 | 检查依赖版本，确认 SDK 版本匹配 |

### 4.2 方向判断（与用户确认）

在初步检查后，使用 AskUserQuestion 向用户陈述当前判断：

- 目前怀疑的故障方向及理由
- 已排除的方向及依据
- 下一步计划检查什么

> 用户可能基于经验直接指出根因方向，或纠正错误判断，避免在错误方向上浪费时间。

### 4.3 协议一致性验证

跨项目问题的高频根因是**协议不一致**：

- A2C 协议：对照 a2c-smcp-protocol 规范，检查事件名/字段名/数据结构
- OASP 协议：对照 oasp-protocol 规范，检查事件格式/错误码
- 序列化兼容：Python SDK 和 Rust SDK 的 JSON 输出是否一致

### 4.4 跨项目日志关联

使用 `req_id`（A2C 协议）或 `requestId`（OASP 协议）在多个项目的日志中追踪同一请求的完整链路。

---

## Step 5：TuringFocus 系统联合排查

**当问题涉及 SDK 连接到 TuringFocus 系统时**（如通过 python-sdk/rust-sdk 连接远程 Server），A2C-SMCP 项目侧的排查可能不足以定位问题。

### 5.1 判断是否需要联合排查

| 信号 | 判定 |
|------|------|
| SDK 连接远程 Server 失败 | 可能需要 |
| 远程 Server 侧事件路由异常 | 需要 |
| 问题仅在连接 TuringFocus 时复现 | 需要 |
| 纯本地问题（本地 Server + 本地 Computer） | 不需要 |

### 5.2 引导安装 turingfocus-skills

如果需要联合排查，引导用户：

1. 安装 TuringFocus Skills Marketplace：
   ```bash
   claude plugin add turingfocus/turingfocus-skills
   ```
2. 使用 TuringFocus 侧的排查能力：
   ```
   /turingfocus-skills:troubleshoot <问题描述>
   ```
3. 将两侧的排查结果关联分析

---

## Step 6：定位结论与提报

输出诊断报告：问题概述、排查模式、故障区间、根因定位（归属项目 + 层级 + 证据）、修复建议（代码问题 → `/fix-issue`，协议问题 → `/add-feature`，配置问题 → 直接建议）。

使用 AskUserQuestion 确认是否提报 GitHub Issue。确认后按 `{baseDir}/resources/issue-report.md` 的模板，用 `gh issue create --repo <owner>/<repo>` 在根因归属仓库创建 Issue。跨项目问题在主归因项目建 Issue，body 中用 `Related: owner/repo#N` 关联其他项目。

---

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 独自猜测方向不与用户确认 | 每次方向判断用 AskUserQuestion 让用户确认 |
| 日志无法获取时自行放弃 | 向用户说明需要什么日志、在哪里查看，请求协助 |
| 只在一个项目内排查跨项目问题 | 从数据流全局定位故障区间 |
| dev 和 artifact 混用排查方式 | 明确模式，使用对应的日志收集手段 |
| 不检查协议一致性 | 跨项目问题优先检查协议对齐 |
| 不关联 req_id 追踪 | 用请求 ID 在多项目日志中追踪同一请求 |
| TuringFocus 问题在本地死磕 | 引导安装 turingfocus-skills 联合排查 |
| 假设所有项目都在本地 | 先确认环境配置，remote 项目走 SSH MCP |
| 每次排查都重新问环境 | 复用 `~/.a2c_smcp/{mode}-env.json`，仅确认是否需更新 |
