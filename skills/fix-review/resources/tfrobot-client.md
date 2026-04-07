# Fix Review — TFRobot Client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

**Rust 后端**：
- `commands/` 只做参数接收 → 调用 service → 返回 `Result<T, String>`
- 业务逻辑在 `services/`，无 unwrap（非测试代码）

**TypeScript 前端**：
- 组件职责单一，业务逻辑在 Zustand store
- invoke() 集中在 store action，组件不直接调用
- 国际化完整：`t()` 函数，中英文翻译同步更新

**跨层**：
- Rust serde 结构与 TypeScript 类型同步
- IPC 命名 snake_case 一致

## 上游依赖问题（Step 3 特有）

验证结论增加 🔼 上游问题（smcp-computer crate）：
- 不修改上游代码，输出 Bug Report
- 仅在 service 层添加临时适配（标注 `// WORKAROUND: see #xxx`）
- 保留失败测试作为上游修复验收标准

## 修改顺序

Rust service → Tauri command → store → hooks → 组件 → i18n

## 验证命令

```bash
# 前端
pnpm build && pnpm test
# 后端
cd src-tauri && cargo check && cargo test
```
