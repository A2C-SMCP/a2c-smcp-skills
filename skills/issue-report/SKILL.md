---
name: issue-report
description: 按业界最佳实践向项目 GitHub 仓库提报 Issue（Bug Report / Feature Request / Improvement）。自动收集项目上下文、生成结构化 Issue 内容、通过 gh CLI 提交。当需要报告问题、提出新功能或改进建议时使用。
argument-hint: "<问题描述或需求概述>"
---

# Issue Report — 结构化 Issue 提报

自动收集项目上下文，按 GitHub Issue 最佳实践生成结构化内容，通过 `gh` CLI 提交到对应仓库。

---

## Step 0：环境检查

1. **gh CLI**：执行 `gh auth status`，确认已认证且有 `repo` scope
2. **识别当前项目**：根据工作目录判断当前所在项目，加载对应 resource 文件

> 项目识别规则参见 `{baseDir}/resources/<project>.md` 中的路径模式。

---

## Step 1：确定 Issue 类型

根据用户输入 `$ARGUMENTS` 判断 Issue 类型：

| 类型 | 判定信号 | GitHub Label |
|------|---------|-------------|
| **Bug Report** | 错误、异常、崩溃、不符合预期、regression | `bug` |
| **Feature Request** | 新功能、新增、支持 XXX、希望能 | `enhancement` |
| **Improvement** | 优化、改进、重构、性能、体验提升 | `improvement` |

如果类型不明确，使用 AskUserQuestion 确认。

---

## Step 2：自动收集项目上下文

根据 Issue 类型自动收集相关信息，减少手动填写。

### 2.1 基础信息（所有类型）

- **项目版本**：从版本文件中读取当前版本号
- **Git 状态**：当前分支、最近 5 条 commit（`git log --oneline -5`）
- **相关文件变更**：如果用户描述中提到文件/模块，读取相关代码

> 版本文件和提取方式按项目参见 `{baseDir}/resources/<project>.md` "版本信息"章节。

### 2.2 Bug Report 额外信息

- **错误日志/堆栈**：如果用户提供了错误信息，格式化整理
- **复现路径**：分析调用链，定位可能的触发路径
- **相关测试**：搜索是否已有相关测试覆盖（如有，说明测试未覆盖的边界）
- **环境信息**：语言/运行时版本、OS、关键依赖版本

> 调用链路和测试命令按项目参见 `{baseDir}/resources/<project>.md`。

### 2.3 Feature / Improvement 额外信息

- **现有实现**：搜索项目中是否有相关的部分实现或类似功能
- **架构影响面**：分析新功能/改进涉及哪些模块
- **跨项目影响**：检查是否涉及协议变更或跨仓库协调

> 架构和跨项目关系按项目参见 `{baseDir}/resources/<project>.md` "架构上下文"章节。

---

## Step 3：生成 Issue 内容

### 3.1 Bug Report 模板

```markdown
## Bug 描述

[一句话描述 Bug 的表象]

## 复现步骤

1. [具体操作步骤]
2. ...

## 期望行为

[应该发生什么]

## 实际行为

[实际发生了什么]

## 环境信息

- 项目版本：`vX.Y.Z`
- 语言/运行时：[如 Python 3.11, Rust 1.82, Node 22]
- 操作系统：[如 macOS 15.x, Ubuntu 24.04]
- 相关依赖：[如有]

## 分析

### 可能的根因

[基于代码分析的根因推断，引用具体文件和行号]

### 相关代码

[关键代码片段，用 permalink 或代码块引用]

### 影响范围

[受影响的功能/模块列表]

## 建议修复方向（可选）

[如果有初步思路，简述修复方向]
```

### 3.2 Feature Request 模板

```markdown
## 功能概述

[一句话描述期望的新功能]

## 动机与场景

[为什么需要这个功能？解决什么问题？]

## 详细描述

[功能的具体行为描述]

## 设计考量

### 架构影响

[涉及哪些模块，需要什么新增/修改]

### 跨项目影响

[是否涉及协议变更、是否需要其他仓库配合]

### 替代方案

[考虑过的其他实现方式及其优劣]

## 验收标准

- [ ] [具体的可验证条件 1]
- [ ] [具体的可验证条件 2]
```

### 3.3 Improvement 模板

```markdown
## 改进目标

[一句话描述要改进什么]

## 现状分析

[当前实现的问题或不足，引用具体代码]

## 改进方案

[具体的改进措施]

## 预期收益

[改进后的效果：性能提升/可维护性/用户体验等]

## 影响范围

[涉及的模块和可能的 breaking changes]

## 验收标准

- [ ] [具体的可验证条件 1]
- [ ] [具体的可验证条件 2]
```

---

## Step 4：用户确认与调整

使用 AskUserQuestion 向用户展示生成的 Issue 内容，确认：

1. **标题**是否准确简洁
2. **内容**是否完整且正确
3. **Labels** 是否合适
4. **是否需要调整**任何部分

> **未经用户确认，不得提交 Issue。**

---

## Step 5：提交 Issue

### 5.1 确定目标仓库

从当前项目的 resource 文件中获取 GitHub `owner/repo`（已内联，无需命令查询）。

### 5.2 提交

```bash
gh issue create \
  --repo <owner/repo> \
  --title "<Issue 标题>" \
  --label "<label1>,<label2>" \
  --body "$(cat <<'EOF'
<Issue 正文内容>
EOF
)"
```

### 5.3 确认结果

- 输出创建的 Issue URL
- 如果创建失败（如 label 不存在），自动去掉不存在的 label 重试

---

## Step 6：跨项目联动（如适用）

当 Issue 涉及跨仓库影响时：

| 场景 | 动作 |
|------|------|
| Bug 根因在上游依赖 | 向上游仓库也提一个 Issue，并在两个 Issue 中互相引用 |
| Feature 需要协议变更 | 先向协议仓库提 Issue/RFC，在本项目 Issue 中引用 |
| 影响配对项目（如 office4ai ↔ office-editor4ai） | 在关联项目创建对应 Issue，互相引用 |

使用 AskUserQuestion 确认是否需要跨项目联动，确认后才创建关联 Issue。

---

## 强制约束

- **禁止未确认提交** — Issue 内容必须经用户审阅
- **禁止空洞描述** — 每个 Issue 必须有具体的上下文和可操作的信息
- **禁止跳过上下文收集** — 自动收集步骤不可省略，这是 Issue 质量的保障
- **GitHub URL 内联** — 仓库地址从 resource 文件读取，不通过命令查询
