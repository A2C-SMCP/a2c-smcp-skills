---
name: teach-me
description: 交互式教学 Skill。当用户在学习新技术/框架/语言/开源产品，或遇到不理解的概念、进行技术选型需要深入了解时调用。核心理念：从用户已熟悉的领域出发，用类比建立初步认知，用实证（WebSearch）确保准确性，用差异分析揭示设计精髓，用多领域交叉建立系统理解。支持传入概念/关键字/代码片段，或从当前会话上下文自动识别学习目标。
argument-hint: "[<要学习的概念|技术|代码片段>]"
---

# Teach-Me — 类比驱动、实证支撑的交互式教学

核心价值：**用你已有的知识做脚手架，搭建新领域的系统认知**——不是翻译文档，是帮你建立心智模型。

---

## 教学哲学

### 三条铁律

1. **无实证不教学**：每个关键论断必须有 WebSearch 找到的真实来源支撑，禁止凭训练记忆作答。训练记忆可能过时、不准确、缺乏上下文。
2. **类比是桥梁不是终点**：类比帮你快速建立初步认知，但两条技术栈几乎不可能严格映射——**差异点才是理解的核心**。
3. **单一参照系危险**：只用 A 类比 B 会造成盲区。引入 C、D 做交叉参照，才能在差异中看清 B 的设计逻辑。

### 什么情况下拒绝

- 学习主题你自己也不确定基本概念 → 诚实告知，建议查阅官方文档
- 问题过于宽泛（"教我 Rust"）→ 引导缩小到具体概念或场景

---

## Step 0：发现用户的知识背景

**目标**：不直接问「你熟悉什么」，而是从以下来源**主动推断**：

| 来源 | 获取方式 |
|------|---------|
| 当前会话上下文 | 用户提到的技术栈、项目路径、代码片段中的语言/框架 |
| Memory 文件 | Read 项目 memory 目录和用户 memory 目录，找技术背景、角色、过往反馈 |
| 项目 CLAUDE.md | 当前工作目录 CLAUDE.md 中可能有的用户画像段落 |
| 用户术语精确度 | 用户用了哪些技术术语？精确度如何？暴露了专业领域 |

**输出**：构建「用户知识地图」（在心里，不在回答中罗列）：

- **精通领域**（≥2 个，用于类比）：能深入讨论、做过大型项目的技术栈
- **了解领域**（可选，用于第三参照系）：知道基本概念但不算专家
- **学习目标**：当前要学的新领域

**纪律**：

- 不要在回答中罗列用户背景（"我注意到你熟悉 Python…"），直接用类比
- 背景不足时（新用户、无 memory），从提问中的术语和对比推断
- 不确定时，在第一个类比后问「这个类比对你有用吗？你更熟悉 Python 还是 Java 生态？」校准

---

## Step 1：明确学习目标

### 1.1 提取核心概念

从用户输入中提取**一个核心概念**作为本次教学焦点：

- 关键字（`lifetime`、`async runtime`、`protobuf`）→ 直接以此为主题
- 代码片段/聊天历史 → 先指出最可能困惑的那一处，围绕它展开
- 宽泛问题（"Rust 的所有权怎么回事"）→ 拆解为可教学的具体概念

> 原则：每次聚焦**一个核心概念**。不要同时解释五个东西。

### 1.2 确认范围

用一句话向用户确认学习目标：「我们要搞清楚的是：xxx 是什么、为什么这么设计、和你知道的 yyy 有什么本质不同？」

---

## Step 2：实证研究

**目标**：为接下来的教学收集真实、准确、有来源的证据。

### 2.1 搜索策略分层

不是所有论断都需要搜索。先分层判断，再按需执行：

| 层级 | 触发条件 | 示例 |
|------|---------|------|
| **必须搜** | 涉及版本差异/性能数据/选型对比/最佳实践/API 用法 | "Rust 2024 edition 的 lifetime 变更"、"React 19 vs 18 性能对比" |
| **建议搜** | 设计缘由/历史背景/社区共识/概念定义（不确定细节时） | "为什么 Go 这么久才加泛型"、"async/await 的设计起源" |
| **可不搜** | 语言基础语法/普适定义/纯逻辑推导/你确信无误的常识 | "if 语句的作用"、"什么是变量" |

**纪律**：
- 涉及「X 比 Y 快/好」「X 在 Z 版本后变了」「官方推荐做法」→ **必须搜**
- 不确定属于哪层 → 往上一级靠（「建议搜」升为「必须搜」）
- 搜索结果与训练记忆冲突 → **以搜索结果为准**

对「必须搜」和「建议搜」层级，从以下角度执行至少 2 次独立搜索（交叉验证）：

| 搜索角度 | 示例查询 |
|----------|---------|
| 官方定义 | `"<concept>" official documentation` |
| 设计缘由 | `why does <tech> use <concept> instead of <alternative>` |
| 社区对比 | `"<concept>" vs "<familiar concept>" comparison` |
| 历史背景 | `"<concept>" history design rationale RFC` |
| 常见误区 | `"<concept>" common misconceptions pitfalls` |

### 2.2 证据标准与引用

- 优先：官方文档 → 核心维护者博客/演讲 → 权威技术媒体深度分析
- **内联引用**：在 Step 3-4 的每个关键论断后，用 `([来源描述](URL))` 标注，让用户可随时追溯到原文
- 找不到可靠来源支撑的论断 → 标注「存疑」，不当作事实陈述

---

## Step 3：构建类比链条

**目标**：用用户已知的领域知识作为认知脚手架。

### 3.1 选择主类比

从用户最强的已知领域中选择最匹配的概念做类比。**三条标准**：

1. 结构相似（机制层面，不是名词表面相似）
2. 用户确实精通（不是"听说过"）
3. 差异足够清晰（方便 Step 4 展开）

### 3.2 构建教学叙事

```
1. 一句话直觉定义
   "Rust 的 ownership 就像你写 Python 时只有一个变量持有 dict 引用，
    但 Rust 把这个检查从运行时移到了编译期"

2. 在用户知识体系中定位
   "你写 Python 时可能遇到过：两个函数修改同一个 list，
   你不知道谁先谁后导致 bug。Rust 的 borrow checker 就是
   防止这个——但编译时就拦住了，不等到运行时崩溃"

3. 引入实证
   "Rust Book 第一章：ownership is Rust's most unique feature
   and has deep implications for the rest of the language"
   → 引用 Step 2 收集的来源 URL

4. 最小示例（≤15 行）
   用用户熟悉的语言写对照版 + 目标语言版
```

### 3.3 引入第二、第三参照系

主类比建立初步认知后，引入其他领域视角：

> "如果你还了解 C++，Rust 的 ownership 更像是 C++11 的 move semantics，
> 但关键区别是：C++ 允许你继续使用被 move 的变量（未定义行为），
> 而 Rust 编译器直接禁止——这个差异恰恰是 Rust 安全承诺的来源。"

**第二参照系选择原则**：
- 优先选用户「了解」但不一定精通的领域
- 选和主类比有**不同设计哲学**的领域（GC vs RAII vs ownership）
- 交叉参照让用户看到**设计空间的全貌**，而不只是单向映射

---

## Step 4：差异即关键 — 解释「为什么不同」

**目标**：这是整个教学最重要的环节。类比的边界才是真正的理解。

### 4.1 找断裂点

对每个类比，明确找出**映射断裂的地方**：

```
类比：Rust trait ≈ Python ABC
断裂点：
- Python ABC 运行时检查（isinstance），Rust trait 编译期单态化
- Python 可以 monkey-patch，Rust trait 实现必须在类型定义时完成
- Rust trait 用于泛型约束（static dispatch），Python Protocol 只是类型提示
```

### 4.2 三问解释法

对每个断裂点，回答：

| 问题 | 示例 |
|------|------|
| **为什么这个领域这么做？** | "Rust 选编译期单态化因为 zero-cost abstraction 是核心目标——最初要替代 C++ 写浏览器引擎" |
| **为什么另一个领域不那么做？** | "Python 选运行时 duck typing 因为设计目标是用最少代码完成最多事——从来没打算做系统编程" |
| **这个差异导致了什么连锁反应？** | "编译期单态化 → 无运行时反射 → serde 必须用 derive macro 生成代码；而 Python 的 pickle 可以运行时检查对象" |

### 4.3 引用历史背景

差异通常有历史原因，引用：
- 设计文档 / RFC / PEP 中的原始讨论
- 核心作者的公开陈述
- 社区演进中的关键转折

> 原则：**差异不是 bug，是 feature**。每个差异背后都有完整的约束条件和设计取舍。帮用户理解这套逻辑，他们就获得了独立判断力。

---

## Step 5：交互验证

### 5.1 检查理解

用**具体场景问题**验证，不问「懂了吗」：

- ❌ 「你理解 ownership 了吗？」
- ✅ 「如果我要写一个函数，接收两个 &str，返回较长的那个——返回值应该是什么生命周期？编译器为什么强制你标注？」

### 5.2 收尾

给用户一个**最小下一步**：
- 在当前项目中找到相关代码，用刚学的概念重新读一遍
- 推荐 1-2 个高质量下一步资源（官方文档的**具体章节**，不是「去看 Rust Book」）

---

## 输出格式

```markdown
## 我们要搞清楚的是
[一句话：核心概念 + 为什么值得理解]

## 你已知的锚点
[用熟悉的概念建立直觉 → 一句话类比定义]

## 深入：它到底怎么工作的
[实证支撑的解释，引用 Step 2 来源 URL]
[最小示例：熟悉语言写法 vs 目标语言写法]

## 从另一个角度看
[第二参照系的类比和差异]

## 关键差异 — 为什么不一样
[表格：类比概念 vs 实际概念 | 断裂点 | 原因 | 连锁影响]

## 检验一下
[一个场景问题，帮用户验证自己真的理解了]

## 下一步
[项目中实践建议 + 推荐深入阅读资源（具体章节）]
```

---

## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 凭训练记忆下论断 | 每个关键论断附带 WebSearch 来源 URL |
| 只用一个类比 | 至少引入第二参照系，展示设计空间全貌 |
| 说「和 X 一样」不指出差异 | 类比之后必须指出断裂点和原因 |
| 堆砌概念 | 每次聚焦一个核心概念 |
| 问「懂了吗」 | 用场景问题验证理解 |
| 把差异当缺陷 | 差异是设计取舍结果，解释「为什么这么选」 |
| 罗列用户背景 | 直接在类比中使用，不陈述「你是 Python 专家」 |
| 教学范围过大 | 一次一个概念，给最小下一步 |
| 不引用来源 | 每条实证信息附 URL，让用户可自己深入 |
| 忽略历史背景 | 设计决策通常有历史原因，RFC/PEP/设计文档比代码注释更有解释力 |
| 对不同背景用户用同一套类比 | 从 context/memory 推断知识地图后定制类比 |

---

## 附录：完整 Worked Example

以下展示 teach-me 在真实场景中的完整执行。**假设场景**：Python 专家在学习 Rust SDK 开发，遇到 borrow checker 报错。

### Step 0 → 背景推断

**从会话上下文获取**：
- 当前工作目录 `/Users/jqq/RustroverProjects/rust-sdk`，`crates/` 目录结构
- 用户消息：「这个 borrow checker 报错我看不懂，为什么不能同时借给两个地方？」

**从 Memory 获取**：
- Python 深度：LangChain Contributor，熟悉 asyncio/Protocol/ABC
- C/C++ 背景：大学 C，后续 WebRTC C++ 实时系统
- Rust 现状：借助 Claude Code 驾驭项目，语言细节学习中

→ **知识地图**：精通 Python（主类比）| 了解 C++（第二参照系）| 目标：Rust ownership + borrowing

### Step 1 → 明确目标

用户粘贴了 `error[E0499]: cannot borrow `*` as mutable more than once` 错误。

→ **确认**：「我们要搞清楚的是：Rust 为什么不允许同时两个可变借用？这和你熟悉的 Python 多引用有什么本质不同？」

### Step 2 → 实证研究

**分层判断**：涉及「设计缘由」→ **建议搜**（但考虑到是核心概念，升为「必须搜」）

搜索 1：`"why does Rust forbid multiple mutable references" design rationale`
  → 找到 Rust Book §4.2, StackOverflow 高票回答，Niko Matsakis 博客
搜索 2：`Rust borrow checker vs Python reference counting comparison`
  → 找到 fasterthanli.me: "From Python to Rust: Ownership"

**来源记录**：
- [The Rust Book §4.2 — References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)
- [Niko Matsakis — Borrow Checker design rationale](https://smallcultfollowing.com/babysteps/blog/2016/04/27/non-lexical-lifetimes-introduction/)
- [fasterthanli — From Python to Rust: Ownership](https://fasterthanli.me/articles/from-python-to-rust-1)

### Step 3 → 类比链条

**主类比（Python）**：

> Rust 的可变借用规则就像 Python 里你在遍历 list 时不能修改它——`for x in lst: lst.append(x)` 会直接抛 `RuntimeError`。但 Rust 把这个检查从运行时移到了编译期，而且更严格：任何时候只要有一个可变引用在手里，就不能再有其他引用。

**代码对照**：
```python
# Python：运行时检查，只在特定场景生效
lst = [1, 2, 3]
for x in lst:
    lst.append(x)  # RuntimeError: list changed size during iteration
# 其他场景不检查：
a = lst
b = lst  # 完全没问题，a 和 b 指向同一个 list
a.append(4)  # b 也会看到变化 — 这可能导致 bug
```

```rust
// Rust：编译期检查，覆盖所有场景
let mut v = vec![1, 2, 3];
let a = &mut v;  // 可变借用
let b = &mut v;  // 编译错误！error[E0499]: cannot borrow `v` as mutable more than once
// 但不可变借用可以多个：
let a = &v;
let b = &v;  // OK — 只读共享
```

**第二参照系（C++）**：

> 如果你了解 C++，这更像 unique_ptr 的语义——同一时间只有一个所有者。但关键区别：C++ 的 unique_ptr 是运行时概念（你可以用 `std::move` 转移所有权后继续用原变量，未定义行为），Rust 编译器直接禁止 use-after-move（[Niko Matsakis 博客](https://smallcultfollowing.com/babysteps/blog/2016/04/27/non-lexical-lifetimes-introduction/)）。

### Step 4 → 差异分析

| 断裂点 | 为什么 Rust 这么做 | 为什么 Python 不那么做 | 连锁反应 |
|--------|-------------------|----------------------|---------|
| 编译期 vs 运行时检查 | Zero-cost abstraction 是核心目标——Rust 最初要替代 C++ 写 Servo 浏览器引擎，性能必须接近 C++（[Rust RFC 0001](https://github.com/rust-lang/rfcs/blob/master/text/0001-rfc-process.md)） | Python 设计目标是最少代码完成最多事，Guido 从来没打算让 Python 做系统编程（[PEP 20 — Zen of Python](https://peps.python.org/pep-0020/)） | Rust 无运行时 GC/反射 → serde 必须用 derive macro 生成序列化代码；Python 的 pickle 可以直接运行时检查对象 |
| 可变借用唯一性 | 防止 data race + 让编译器做别名分析优化——LLVM 可以利用「无别名」假设生成更快的代码（[The Rust Book §4.2](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)） | Python 有 GIL，天然线程安全——多线程不会同时执行 Python 字节码（[Python GIL 文档](https://wiki.python.org/moin/GlobalInterpreterLock)） | Rust 能安全地多线程并发，Python 靠 GIL 牺牲多核性能；但 Python 的并发模型对 I/O 密集型任务更友好（asyncio） |

### Step 5 → 验证

**检验问题**：
> 「如果我想写一个函数，接收两个 `&str`，返回较长的那个——返回值应该标注什么生命周期？编译器为什么强制你标注，而不像 Python 那样自动推断？」

**答案方向**：需要标注 `'a` 生命周期让编译器知道返回值借用的是一样长的两个引用——因为 Rust 编译器不做跨函数分析，它只看函数签名。Python 有 GC，所有对象活在堆上，自然没有这个问题。

**最小下一步**：
1. 在项目 `crates/smcp-computer/src/mcp_clients/stdio_client.rs` 里找所有 `&self` 方法，重新读一遍——这些就是不可变借用
2. 接着读 [The Rust Book §10.3 — Validating References with Lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)，只看这一节，不要跳章

