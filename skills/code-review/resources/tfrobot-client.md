# Code Review — TFRobot Client 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Rust（Tauri 2.x 后端）+ TypeScript（React 前端）
- **架构**：Tauri 双层 — React 18 + Ant Design + Zustand / Tokio 异步

## 模块边界

**Rust 后端**：`commands/` 只做参数接收 → 调用 service → 返回；业务逻辑在 `services/`
**TypeScript 前端**：组件只负责 UI，业务逻辑放 Zustand store，invoke() 集中在 store action

检查：
- commands/ 是否混入了业务逻辑？
- 组件是否直接调用了 `invoke()` 绕过 store？
- store 之间是否有不合理的直接引用？

## DRY 重点检查

搜索 `src/hooks/`、`src/stores/`、`src-tauri/src/services/` 确认是否有可复用的已有封装。

## 项目特有审查维度

### 上游依赖问题零容忍（关键）

`smcp-computer`（rust-sdk 仓库）由团队同事维护，严格检查：
- 是否有因上游 bug 而 `#[ignore]` / `skip` 的测试？（不可接受）
- 是否有 workaround 但没有 Bug Report 编号？
- 是否有 rust-sdk 的直接源码修改？（绝不应出现）

### Tauri IPC 边界

- Rust serde 结构与 TypeScript 类型是否同步？
- 是否出现了 `any`、`as unknown` 等类型逃逸？
- 命名一致性：snake_case 贯穿 IPC 调用

### 国际化完整性

用户可见文本必须使用 `t()`，不允许硬编码。涉及 UI 变更时检查 `src/locales/`。

## 测试覆盖度

```bash
# 前端
pnpm test -- --coverage        # 带覆盖率
# 后端
cd src-tauri && cargo test     # 全量测试通过
```

前端 Store/Hook 变更必须有对应测试。后端 Service 层新增逻辑须有单元测试。

## 验证命令

```bash
# 前端
pnpm build && pnpm test
# 后端
cd src-tauri && cargo check && cargo test
```
