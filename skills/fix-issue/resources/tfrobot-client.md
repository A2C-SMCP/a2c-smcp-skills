# Fix Issue — TFRobot Client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Rust（Tauri 2.x 后端）+ TypeScript（React 前端）
- **架构**：Tauri 双层 — 前端 React 18 + Ant Design + Zustand，后端 Tokio 异步
- **上游依赖**：rust-sdk 的 smcp-computer crate

## 调用链路追踪

- **前端问题**：组件 → Zustand store → `invoke()` IPC → Tauri command → service 层
- **后端问题**：Tauri command → service 层 → 外部依赖（文件系统/keychain/子进程）
- **跨层问题**：前端 invoke 参数 → Rust 命令签名 → 序列化/反序列化边界
- **上游问题**：service → smcp-computer API → 判断根因在本项目还是上游

## Step 5 差异：架构原则

**Rust 后端**：
- commands/ 只做参数接收 + 调用 service + 格式化返回；业务逻辑在 services/
- 统一返回 `Result<T, String>`，service 层用具体错误类型

**TypeScript 前端**：
- 组件只负责 UI，业务逻辑放 Zustand store
- invoke() 调用集中在 store action 中，组件不直接调用
- 用户可见文本必须使用 `t()` 国际化

**上游依赖问题处理**（smcp-computer crate）：
1. **不修改上游代码** — 输出结构化 Bug Report 转给 rust-sdk 开发者
2. **保留失败测试** — 不 skip、不注释，标注 `// REGRESSION: upstream bug, see #xxx`
3. **升级路径**：上游修复发版 → 升级依赖版本 → 测试自动变绿

## Step 7 差异：验证命令

```bash
# 前端
pnpm build           # 类型检查 + 构建
pnpm test            # 测试

# 后端
cd src-tauri && cargo check    # 编译检查
cd src-tauri && cargo test     # 测试
```

修改涉及国际化时，确认 `src/locales/` 中英文翻译文件均已更新。
