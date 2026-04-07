# 跨项目 Skill 编写共性模式

> 从 A2C-SMCP 项目群的 Skill 实践中提炼的共性最佳实践。

---

## 实践基础原则

**Skill = 固化已验证的工作流，而非描述抽象最佳实践。**

至少在一个项目中完整走通过，每一步都有实际的文件/命令/查询作为支撑。

---

## Frontmatter 规范

```yaml
---
name: kebab-case-name        # 小写+连字符，≤64 字符
description: 功能描述 + 触发场景。≤1024 字符
---
```

`description` 是 Claude 决定是否调用的唯一依据——必须包含"做什么"和"什么时候调用"。

---

## 内容组织：分步执行模式

```markdown
## Step N：<动作名>

**目标**：一句话说明这步要达成什么
**动作**：具体命令/查询/检查
**参考**：`链接到项目文件`（当前项目内）或 嵌入内容（跨项目）
**输出**：这步完成后的产物或状态
```

---

## 引用 vs 嵌入

| 场景 | 方式 | 示例 |
|------|------|------|
| 当前项目内文件 | Markdown 链接 | `参见 [config.py](src/config.py)` |
| 跨项目的代码/模式 | 嵌入到 resource 文件 | 在 `resources/python-sdk.md` 中写明 |
| 可直接执行的命令 | 在 SKILL 中内联 | `uv run poe test`, `cargo test-ws` |

**代码胜于文档**：能链接到真实文件的，不在 SKILL 中摘录。

---

## 跨项目差异分发

统一 Skill 在步骤中通过"分发点"导向 resource 文件：

```markdown
## Step 3：运行测试

**按项目类型**：
- Python SDK/MCP 工具 → 参见 `{baseDir}/resources/python-sdk.md` 或 `office4ai.md`/`ide4ai.md` "测试"章节
- Rust SDK → 参见 `{baseDir}/resources/rust-sdk.md` "测试"章节
- TypeScript 项目 → 参见 `{baseDir}/resources/office-editor4ai.md` 或 `tfrobot-client.md`
- 协议文档 → 参见 `{baseDir}/resources/a2c-smcp-protocol.md` "验证"章节
```

---

## 关键差异维度

| 维度 | python-sdk | rust-sdk | protocol/oasp | office4ai/ide4ai | office-editor4ai | tfrobot-client |
|------|-----------|----------|---------------|-----------------|-----------------|---------------|
| 包管理 | uv/poetry | cargo | uv (docs) | uv | pnpm | pnpm + cargo |
| 测试 | pytest 三层 | cargo test + features | mkdocs build | pytest | - | - |
| Lint | ruff + mypy | clippy + rustfmt | - | ruff + mypy | ESLint | clippy + ESLint |
| 架构 | 三模块双实现 | workspace crates | MkDocs 文档 | MCP Server | monorepo Add-Ins | Tauri 双语言 |
| CI/CD | GitHub Actions | GitHub Actions | GitHub Pages | GitHub Actions | - | - |

---

## 质量门控

1. **架构一致性** — 符合项目模块/crate 边界
2. **类型安全** — Python type hints / Rust 强类型
3. **同步/异步一致性** — 双实现项目需同步更新
4. **协议一致性** — SDK 变更需与 protocol 文档保持同步
5. **测试覆盖** — 单元/集成/e2e 分层

---

## 命名规范

```
# ✅
code-review, add-feature, fix-issue, protocol-sync

# ❌
CodeReview, add_feature, skill-fix-issue
```

## 语言选择

- 用户交互语言为中文 → description 中文
- SKILL.md 正文：中文（跟随团队习惯）
- 代码注释/命令：保持原项目语言
