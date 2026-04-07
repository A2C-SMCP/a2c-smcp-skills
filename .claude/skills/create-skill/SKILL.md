---
name: create-skill
description: 为 A2C-SMCP 项目线创建跨项目共享的 Claude Code Skill。收集各项目现有 Skill 并分析共性与差异，生成统一 SKILL.md 和按项目拆分的 resources 文件。当需要新建适用于多个 A2C-SMCP 项目的 Skill 时调用。
---

# Create Skill（跨项目统一版）

为 A2C-SMCP 项目线创建可在多个项目中共享使用的 Claude Code Skill。

核心职责：**收集 → 提炼共性 → 保留差异 → 生成统一 Skill + 按项目的 resources 文件**。

---

## Step 0：环境预检

### 0.1 项目权限检查

检查以下所有项目目录是否已通过 `/add-dir` 添加到当前会话，**缺一不可**：

| 项目 | 预期路径模式 | 类别 |
|------|-------------|------|
| python-sdk | `*/python-sdk` | Core SDK |
| rust-sdk | `*/rust-sdk` | Core SDK |
| a2c-smcp-protocol | `*/a2c-smcp-protocol` | Core Protocol |
| office4ai | `*/office4ai` | MCP 工具 |
| ide4ai | `*/ide4ai` | MCP 工具 |
| oasp-protocol | `*/oasp-protocol` | MCP 工具协议 |
| office-editor4ai | `*/office-editor4ai` | Office Add-In |
| tfrobot-client | `*/tfrobot-client` | Computer 客户端 |

**验证方式**：尝试读取每个项目的 `CLAUDE.md`。如有项目不可读，立即终止并告知用户缺少哪些项目权限。

### 0.2 gh CLI 检查

如果待创建的 Skill 涉及 GitHub Issue/PR/CI，检查 `gh` CLI 是否可用：

- 执行 `gh auth status` 验证认证状态
- 如不可用，引导用户安装并登录 `gh` CLI 后再继续

---

## Step 1：收集现有 Skill 版图

扫描所有 8 个项目的 `.claude/skills/` 和 `.claude/commands/` 目录，生成当前 Skill 版图。

**扫描方式**：
```bash
# 对每个项目执行
ls -d <project>/.claude/skills/*/SKILL.md 2>/dev/null
ls <project>/.claude/commands/*.md 2>/dev/null
```

**输出**：向用户展示矩阵表，标注每个项目有哪些 Skill：

```
| Skill           | python-sdk | rust-sdk | protocol | office4ai | ide4ai | oasp | editor4ai | client |
|-----------------|------------|----------|----------|-----------|--------|------|-----------|--------|
| <待创建的skill> | ?          | ?        | ?        | ?         | ?      | ?    | ?         | ?      |
```

如果待创建的 Skill 在某些项目中已存在，**必须先读取这些已有版本**。

### 缺失项目的相似实现搜索

对于没有同名 Skill/Command 的项目，按**功能语义**搜索相似实现，在矩阵表中标注实际名称。

---

## Step 2：需求澄清

使用 AskUserQuestion 确认以下信息（已足够清晰则跳过）：

1. **Skill 名称**：kebab-case，不超过 64 字符
2. **触发场景**：什么情况下调用？
3. **适用项目范围**：全部 8 个项目，还是部分？
4. **输入/输出**：参数？产物？
5. **是否涉及 CI/CD**：如涉及，需 `gh` CLI
6. **已有基础**：哪些项目中已有类似实践？

### 核心前提：实践基础验证

**至少在一个项目中已有经过验证的实践**，才具备创建跨项目统一 Skill 的条件。

> 参考 `{baseDir}/resources/common-patterns.md`。

---

## Step 3：跨项目分析

### 3.1 读取所有已有版本

逐个读取已有 SKILL.md 及其 resources，理解执行步骤、引用文件和项目特有约定。

### 3.2 提炼共性

提取所有项目都适用的通用流程、质量标准和输出格式。

### 3.3 标记差异

| 差异维度 | 示例 |
|----------|------|
| 语言/框架 | Python uv/pytest vs Rust cargo/clippy vs TS pnpm/Webpack |
| 架构模式 | SDK 三模块 vs Rust workspace crates vs MCP Server vs Office Add-In vs Tauri |
| 测试策略 | pytest 分层 vs cargo test + features vs Vitest |
| CI/CD | GitHub Actions workflow 差异 |
| 代码规范 | Python ruff/mypy vs Rust clippy vs TS/ESLint |
| 项目特有 | 协议文档 MkDocs、SDK 同步/异步一致性、Office.js API、Tauri IPC |

### 3.4 吸长补短

吸收各版本长处，泛化后纳入通用部分；补齐缺失步骤。

### 3.5 处理无实现的项目

使用 AskUserQuestion 逐个确认是否为无实现的项目补充 resource 文件。

---

## Step 4：设计 Skill 结构

### 4.1 规划文件结构

```
skills/<name>/
├── SKILL.md                    # 主文件：通用流程
└── resources/
    ├── python-sdk.md           # Python SDK 差异
    ├── rust-sdk.md             # Rust SDK 差异
    ├── a2c-smcp-protocol.md    # 协议文档差异
    ├── office4ai.md            # Office MCP Server 差异
    ├── ide4ai.md               # IDE MCP Server 差异
    ├── oasp-protocol.md        # OASP 协议差异
    ├── office-editor4ai.md     # Office Add-In 差异
    └── tfrobot-client.md       # Computer 客户端差异
```

**关键原则**：
- SKILL.md 只放通用内容，通过 `参见 {baseDir}/resources/<project>.md` 引用差异
- 仅创建确实有差异内容的 resource 文件
- resource 文件中嵌入跨项目内容

---

## Step 5：起草内容

### 5.1 SKILL.md 主文件

**Frontmatter**：
```yaml
---
name: <skill-name>
description: <功能 + 触发场景，不超过 1024 字符>
---
```

**正文结构**：分步执行模式，每步包含目标、可执行内容、差异分发点、输出。

**长度控制**：SKILL.md ≤ 200 行，resource ≤ 100 行。

### 5.2 Resource 文件

```markdown
# <Skill Name> — <Project> 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文
- 语言/框架：...
- 关键架构约定：...

## Step N 差异：<对应主文件的步骤>
<该项目在此步骤的特殊做法>
```

---

## Step 6：验证与创建

### 质量检查清单

- [ ] description 包含明确的触发场景
- [ ] 每一步都有具体的可执行内容
- [ ] 共性在 SKILL.md，差异在 resources/，无混杂
- [ ] 跨项目内容已嵌入 resource 文件
- [ ] 有实现的项目差异化内容完整无丢弃
- [ ] 无实现的项目已确认是否补充 resource
- [ ] 涉及 CI/CD 的步骤标注了 `gh` CLI 依赖
- [ ] 行数：SKILL.md ≤ 200 行，单个 resource ≤ 100 行

### 创建文件

```bash
mkdir -p skills/<name>/resources
# 写入 SKILL.md 和 resources/<project>.md
```

---

## 反模式警示

| 反模式 | 正确做法 |
|--------|---------|
| 把所有项目差异堆在 SKILL.md 里 | 差异拆到 resources/ |
| 跨项目引用文件路径 | 嵌入 resource 文件 |
| 无实践基础就创建 Skill | 至少一个项目已验证 |
| 因名称不同就判定"无实现" | 按功能语义搜索 |
| 未经确认就跳过无实现项目 | 使用 AskUserQuestion 确认 |
