# A2C-SMCP 项目档案

> 跨项目嵌入信息。各项目详细信息记录于此，供跨项目 Skill 开发参考。
> 部分仓库在 A2C-SMCP 组织下，部分在个人账号（JIAQIA）下。

---

## python-sdk

- **语言**：Python 3.11+，uv 管理（也支持 Poetry）
- **定位**：SMCP 协议参考实现，Python SDK
- **架构**：三模块系统 — Agent（客户端）、Server（信令）、Computer（MCP 管理）
- **核心概念**：
  - MCP 客户端状态机（transitions 库），支持 stdio/SSE/HTTP 传输
  - 同步/异步双实现（namespace.py + sync_namespace.py、client.py + sync_client.py）
  - 桌面窗口聚合（window:// 资源）
  - 协议定义双文件：smcp.py（TypedDict）+ model.py（Pydantic）
- **测试**：三层 — unit_tests / integration_tests（Mock Server）/ e2e（pexpect）
- **代码规范**：ruff lint + format，mypy strict，type hints 必须
- **CI/CD**：GitHub Actions
- **CLI 入口**：`a2c-computer run`
- **GitHub Issue 标签**：python-sdk
- **现有 Skills**：待扫描
- **独有模式**：事件前缀约定（client:*/server:*/notify:*）、Socket.IO 命名空间隔离

---

## rust-sdk

- **语言**：Rust，Cargo workspace，Tokio 异步运行时
- **定位**：SMCP 协议生产实现，Rust SDK
- **架构**：Workspace crates — smcp（协议类型）、smcp-agent、smcp-computer、smcp-server-core、smcp-server-hyper
- **核心概念**：
  - HTTP 承载层可插拔（Tower Layer/Service 模式，默认 Hyper）
  - Feature flags 控制模块启用（agent/computer/server/full/e2e）
  - Socket.IO 客户端用自研 tf-rust-socketio，服务端用 socketioxide
  - 工具注册与去重（ToolMeta.alias）
- **测试**：cargo test（单元）+ --ignored（e2e，需 e2e feature）
- **代码规范**：clippy strict（clippy-workspace）+ rustfmt
- **CI/CD**：GitHub Actions
- **构建**：`cargo build --workspace --all-features`
- **GitHub Issue 标签**：rust-sdk
- **现有 Skills**：待扫描
- **独有模式**：与 Python SDK 的核心模块一一对应、仅 JSON 序列化、异步优先

---

## a2c-smcp-protocol

- **类型**：文档仓库（MkDocs）
- **定位**：SMCP 协议规范，定义 Agent-Server-Computer 通信标准
- **当前版本**：0.1.2-rc1
- **架构**：三角色模型 — Agent（1/room max）、Server（信令中枢）、Computer（多个/room）
- **文档结构**：specification/（architecture、events、data-structures、room-model、error-handling、security）+ appendix/
- **构建部署**：`inv docs.serve`（本地预览）、`inv docs.deploy`（GitHub Pages + doc.turingfocus.cn）
- **版本管理**：pyproject.toml 单一来源 + bump-my-version + mike 多版本
- **GitHub Issue 标签**：protocol
- **独有模式**：Room 隔离规则、req_id 消息关联、零凭证传播安全模型

---

## oasp-protocol

- **类型**：文档仓库（MkDocs）
- **定位**：Office AddIn Socket Protocol，AI Agent 控制 Office 文档的通信规范
- **架构**：三层 — AI Agent → Server（Office4AI）→ Office AddIn → Microsoft Office
- **命名空间隔离**：/word（稳定）、/ppt（草案）、/excel（草案）
- **协议约定**：
  - JSON 字段 camelCase，事件名 kebab-with-colon
  - 事件格式：`{namespace}:{action}:{target}`
  - 错误码范围：1xxx 通用、2xxx 连接、3xxx 文档、4xxx 校验
- **构建部署**：同 protocol 仓库（uv + inv docs.*）
- **GitHub Issue 标签**：oasp
- **独有模式**：requestId/documentUri/timestamp 三要素、Office.js API 交互

---

## office4ai

- **GitHub**：JIAQIA/office4ai
- **语言**：Python，uv 管理
- **定位**：AI Agent 专用 Office 文档 MCP Server
- **架构**：对齐 ide4ai 分层架构，LibreOffice UNO Bridge 双层
- **核心概念**：
  - MCP (Model Context Protocol) Server 接口
  - Gymnasium 环境接口
  - Word 工具集（9 个工具：get/insert/replace text、insert images/tables/equations/TOC）
  - PowerPoint、Excel 工具开发中
- **工具链**：uv + poethepoet + ruff + mypy + pytest
- **GitHub Issue 标签**：office4ai
- **独有模式**：LibreOffice UNO Bridge 集成、MCP + Gymnasium 双接口

---

## ide4ai

- **GitHub**：A2C-SMCP/ide4ai
- **语言**：Python
- **定位**：AI Agent 专用 IDE 工具环境
- **架构**：高内聚低耦合，兼容 A2C-SMCP/MCP/Gymnasium 接口
- **核心能力**：
  - 代码导航（跳转/符号搜索/引用查找，基于 LSP）
  - 精确编辑（位置级 undo/redo）
  - LSP 集成（Python 及其他语言）
  - 终端执行（本地/Docker 命令）
  - 工作区/文件管理
- **安全**：命令白名单机制
- **GitHub Issue 标签**：ide4ai
- **独有模式**：LSP 深度集成、命令白名单安全模型

---

## office-editor4ai

- **GitHub**：JIAQIA/office-editor4ai
- **语言**：TypeScript，pnpm workspace monorepo
- **定位**：Office 加载项（Word/Excel/PPT），通过 Socket.IO 连接 AI 后端
- **架构**：两层 — 工具封装层（Office JS API → 语义化工具）+ 协议暴露层（OASP Socket.IO）
- **核心概念**：
  - 三个独立 Add-In：Excel(3001)、Word(3002)、PPT(3003)
  - React 18 + FluentUI + Webpack 5 + Socket.IO
  - `/src/shared/` 符号链接共享代码
- **设计理念**：易用性优先，高频场景封装，能力损失与易用性平衡
- **GitHub Issue 标签**：office-editor4ai
- **独有模式**：OASP 协议实现、Office.js API 封装、monorepo 共享架构

---

## tfrobot-client

- **GitHub**：A2C-SMCP/tfrobot-client
- **语言**：Rust（Tauri 2.x 后端）+ TypeScript（React 前端）
- **定位**：A2C-SMCP Computer 跨平台桌面客户端
- **架构**：Tauri 2.x — 前端 React 18 + Ant Design 5 + Zustand + i18next；后端 Tokio 异步
- **核心概念**：
  - 封装 smcp-computer Rust 库的 GUI
  - MCP 服务器管理界面
  - SMCP Server 连接管理
- **工具链**：pnpm（前端）+ Cargo（后端）+ Vite（构建）
- **GitHub Issue 标签**：tfrobot-client
- **独有模式**：Tauri IPC 通信、前后端双语言架构
