# Issue Report — TFRobot Client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目信息

- **GitHub 仓库**：`A2C-SMCP/tfrobot-client`
- **语言/框架**：Rust（Tauri 2.x 后端）+ TypeScript（React 18 前端）
- **路径模式**：`*/tfrobot-client`

## 版本信息

- **版本文件**：
  - 前端：`package.json` → `version` 字段
  - 后端：`src-tauri/Cargo.toml` → `[package]` 段 `version` 字段
- **提取命令**：
  - `node -p "require('./package.json').version"`
  - `grep '^version' src-tauri/Cargo.toml`
- **运行时版本**：`node --version` + `rustc --version`

## 架构上下文

### 核心架构

- **双语言双层**：React 18 + Ant Design + Zustand（前端）+ Tokio async（后端）
- 前端调用链：组件 → Zustand store → `invoke()` IPC → Tauri command → service 层
- 后端调用链：Tauri command → service 层 → 外部依赖（文件系统/keychain/子进程）
- **上游依赖**：`smcp-computer` crate（来自 `A2C-SMCP/rust-sdk`）

### 问题层级

| 层级 | 前端 | 后端 |
|------|------|------|
| UI/交互层 | React 组件渲染/交互 | — |
| 状态层 | Zustand store | — |
| IPC 层 | invoke 参数传递 | Tauri command 签名 |
| 服务层 | — | Rust 业务逻辑 |
| 依赖层 | — | `smcp-computer` 等上游 crate |

### Bug Report 上下文收集要点

1. **判定问题层级**（前端/后端/IPC/上游依赖）
2. 如果涉及 IPC：检查 Rust serde 结构与 TypeScript 类型是否一致
3. 检查国际化：用户可见文本是否使用 `t()` 函数
4. **上游依赖判定**：如果根因在 `smcp-computer` crate，Issue 应提到上游仓库 `A2C-SMCP/rust-sdk`，并建议转发

### Feature / Improvement 上下文收集要点

1. 确认功能涉及前端/后端/双端
2. 前端：评估 store 设计（每个 store 一个领域）
3. 后端：commands/ 只做参数接收，业务在 services/ 中

### 上游依赖 Bug 的特殊处理

当问题根因在 `smcp-computer` crate 时，Issue 应包含：
- 明确标注根因在上游 `A2C-SMCP/rust-sdk` 的 `smcp-computer` crate
- 从 tfrobot-client 的调用入口描述复现路径
- 期望行为 vs 实际行为
- 引用 `smcp-computer` 中的具体代码
- 建议：同时向 `A2C-SMCP/rust-sdk` 提报关联 Issue

## 测试信息

- **前端构建检查**：`pnpm build`
- **前端测试**：`pnpm test`
- **后端编译检查**：`cd src-tauri && cargo check`
- **后端测试**：`cd src-tauri && cargo test`

## 环境信息收集

```bash
node --version
pnpm --version
rustc --version
node -p "require('./package.json').version"
grep '^version' src-tauri/Cargo.toml
```

## 跨项目影响

| 场景 | 关联仓库 |
|------|---------|
| 根因在 smcp-computer | `A2C-SMCP/rust-sdk`（上游，需转发 Bug Report） |
| 涉及 SMCP 协议行为 | `A2C-SMCP/a2c-smcp-protocol` |

## Label 建议

| Issue 类型 | Labels |
|-----------|--------|
| Bug | `bug` |
| Feature | `enhancement` |
| Improvement | `improvement` |
| 前端问题 | 追加 `frontend` |
| 后端问题 | 追加 `backend` |
| 根因在上游 | 追加 `upstream` |
| 涉及 IPC 边界 | 追加 `ipc` |
