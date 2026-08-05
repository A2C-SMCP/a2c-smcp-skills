# Clarify — rust-sdk 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **类型**：SMCP Rust SDK（协议生产实现）
- **语言/工具链**：Rust，Cargo workspace，cargo test/clippy
- **定位**：SMCP 协议的 Rust 生产实现——强调性能、类型安全、Cargo feature 编译灵活性。其 API 设计需与 python-sdk 保持语义一致性

## 影响视角定义

rust-sdk 使用**标准三视角**（终端用户 + 开发者 + SDK 消费者），且 Rust 生态特有的关注点需纳入分析：

| 视角 | 本项目中的含义 |
|------|---------------|
| **终端用户** | 使用 rust-sdk 构建的 AI Agent/Computer 应用的最终用户 |
| **开发者** | 用 rust-sdk 写代码的 Rust 开发者——他们面对 Cargo features、trait bounds、编译时间等 Rust 特有的开发体验 |
| **SDK 消费者** | 依赖 rust-sdk crate 的外部项目——它们关注 semver 兼容性、feature flags 变化、MSRV（最低支持的 Rust 版本） |

## 关键用户画像

### 画像 1：Rust AI 应用开发者
- 场景：在 Rust 项目中通过 Cargo 引入 SMCP SDK crate
- 敏感点：编译时间（每个 feature 都可能增加）、trait 约束是否合理、unsafe 范围
- 典型问题：「加了这个 trait bound 后，我的类型还能直接传吗？还是必须包一层？」

### 画像 2：SDK 消费者项目维护者
- 场景：项目 Cargo.toml 中依赖了 smcp crate，升级时评估 semver 兼容性
- 敏感点：semver breaking 变更、feature flag 默认开关变化、公开 API 的删除或重命名
- 典型问题：「0.4 → 0.5 的 `pub fn` 改了返回类型，我需要改多少处调用？」

### 画像 3：双实现对齐者（python-sdk 协作者）
- 场景：rust-sdk 和 python-sdk 的行为需保持语义一致
- 敏感点：协议层语义差异、两 SDK 行为不一致导致的跨语言互操作问题
- 典型问题：「py-sdk 的 Computer 端处理 timeout 是抛异常，rust-sdk 用的是 Result——语义等价吗？」

## Rust 特有的开发体验维度

分析技术决策的开发者影响时，额外关注：

| 维度 | 追问 |
|------|------|
| 编译时间 | 新增依赖/feature 会让全量编译慢多少？开发者等多久？ |
| Cargo features | feature 的交错组合是否引入了不明显的兼容性问题？ |
| 类型体操 | 新的泛型/关联类型设计会让编译错误信息变多难理解？ |
| 文档/IDE 体验 | cargo doc 生成质量？RA/rust-analyzer 的类型推断有退化吗？ |

## 典型决策场景

| 场景 | 核心影响维度 |
|------|-------------|
| Cargo feature 拆分/合并 | 开发者编译时间 + SDK 消费者 feature 选择困惑 |
| 公开 API 签名变更 | 开发者适配 + semver breaking 判定 |
| 内部实现重构（无 API 变更） | 编译时间 / 二进制大小变化 |
| 异步运行时选择/升级 | SDK 消费者（如果强制了 tokio 版本）+ 双实现对齐 |
