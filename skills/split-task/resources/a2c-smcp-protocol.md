# Split Task — a2c-smcp-protocol 专属指南

> 通用流程参见 SKILL.md 主文件。本文件是协议仓库执行 split-task 的差异化内容。

## 项目上下文

- 语言/框架：Docs-first（MkDocs），规范性内容在 `docs/specification/`
- 角色：**协议先行的源头**——协议子任务是下游多仓（python-sdk / rust-sdk / office4ai / 客户端）代码子任务的**依赖图根**
- 特殊性：协议子任务的"完成"= 评审 + 合并 + **发布**（SemVer），非仅 main 可消费

---

## 模块边界识别（Phase 1 引用）

协议切刀沿**规范文档 / 事件族**落：

| 文档 | 边界含义 |
|------|---------|
| `data-structures.md` | 公共数据结构（TypedDict 定义）——**跨所有事件共享，改动置最早一刀** |
| `events.md` | 核心事件族（client:* / server:* / notify:*）|
| `desktop.md` / `skill.md` | Desktop（window://）/ SKILL（skill://）通道 |
| `room-model.md` / `computer.md` | 房间模型 / Computer 管理 |
| `error-handling.md` | 错误码体系 |
| `blob-transfer.md` | 通用二进制传输 |
| `versioning.md` / `security.md` | 版本策略 / 安全模型 |
| `computer-management/` | Computer 运行时契约子规范 |

**切刀启发**：
- 公共数据结构（`data-structures.md`）改动 → **单独成第一刀**，其余事件文档依赖它
- 按事件族/通道切（desktop vs skill vs room）
- 错误码新增 → 与对应事件同刀或紧随，避免号段冲突
- **A2C vs OASP 双协议线**：分属 a2c-smcp-protocol 与 oasp-protocol，**不混切**

### 跨文档"先后顺序"硬约束

- 公共数据结构变更在最早一刀；引用它的事件文档不可在其之前合并
- 每个协议子任务必须走 `/add-feature`：**Step 3.5 消费方 cross-ask 双向验证**（P0 全消化）→ **Step 4 评审/合并/发布门控**
- 向后兼容按 `versioning.md` SemVer 评估；破坏性变更须显式确认

---

## 关键架构能力守护清单（Phase 6 引用）

协议拆分的"集成守护"是**规范一致性 + 消费方可实现性**，而非代码测试：

### 1. 向后兼容 / 版本策略
**为什么是不变量**：已部署的 Agent/Computer/Server 依赖既有协议；破坏性变更无版本协商即运行时失联。
**守护**：按 `versioning.md` 逐条核对新增字段 Optional、语义未破坏；破坏性变更配版本协商机制。

### 2. 消费方实现可行性（cross-ask 闭环）
**为什么是不变量**：协议先行 ≠ 盲目先行；草案须经 python-sdk / rust-sdk / office-editor4ai 等消费方验证可实现。
**守护**：每个新增事件/字段/错误码经至少一轮 `/cross-ask`，P0 反馈全部消化后才进发布门控。

### 3. 双 SDK 落地一致性
**为什么是不变量**：同一协议须在 python-sdk（参考）与 rust-sdk（生产）落地且行为一致。
**守护**：协议子任务发布后，下游 python-sdk / rust-sdk 实现子任务在依赖图中**平行 blocked-by** 它，末端跨 SDK 序列化兼容测试守护。

### 4. 规范内部引用一致性
**为什么是不变量**：文档间交叉引用（事件↔数据结构↔错误码）漂移会误导实现者。
**守护**：`mkdocs build` 无死链；改动文档的所有反向引用同步更新。

---

## a2c-smcp-protocol 拆分实操约定

- **产物形态**：协议子任务产出 spec 文档变更 + 版本号更新（非代码）
- **验证命令**：`mkdocs build`（文档构建 / 死链检查）；规范样例逐字段自校
- **依赖图定位**：协议子任务恒在**跨仓依赖图的根**，代码子任务全部 blocked-by 其**发布**
- **GitHub 子任务命名**：`[protocol] <一句话职责>`，如 `[protocol] SKILL 通道新增 _meta.source` / `[protocol] 错误码 4017 细分`
- **协议子任务的驱动**：不用本 skill 直接实现，交 `/add-feature` 走协议先行全流程
