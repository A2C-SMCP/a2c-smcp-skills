# Cross Ask — office-editor4ai 问卷模板

> 当其他项目工程师需要向 Office Add-In 工程师提问时，使用此模板。

## 项目职责

office-editor4ai 是 pnpm monorepo，包含 3 个 Office Add-In（Word / Excel / PPT），使用 React 18 + FluentUI + Socket.IO。共享代码通过 `/src/shared/` symlinks。遵循 OASP 协议实现 Socket.IO 客户端，Word 已实现 31 个工具。

## 问卷必填字段

### 1. 涉及的 Add-In 和模块

| Add-In | 端口 | 状态 |
|--------|------|------|
| **Word** | 3002 | 已实现 Socket.IO 客户端（31 工具） |
| **Excel** | 3001 | 待实现 |
| **PPT** | 3003 | 待实现 |

**功能层**：

| 层 | 说明 |
|----|------|
| **工具封装层** | 语义化 Office JS API 封装，降低 AI 使用门槛 |
| **协议暴露层** | 通过 OASP/Socket.IO 暴露工具能力 |
| **共享层** | `/src/shared/` 跨 Add-In 复用代码 |

### 2. Office JS API 相关

如问题涉及 Office 操作：
- 涉及的 Office JS API（如 `Word.Run`、`Excel.Range`）
- 操作是同步还是异步（Office JS 的 `context.sync()`）
- 操作的副作用和撤销支持

### 3. Socket.IO 客户端相关

如涉及与 MCP Server（office4ai）的通信：
- OASP 事件名和 payload 结构
- 连接管理（重连策略、超时处理）
- 事件处理函数和 DTO 映射逻辑

### 4. 设计三原则

office-editor4ai 遵循三原则，问询时需考虑：
- **易用性**：降低 AI 使用门槛的工具封装方式
- **可组合性**：返回足够上下文以支持工具链、保持正交性
- **持续演进**：向后兼容、渐进增强

### 5. 期望回答格式

| 问题类型 | 期望回答 |
|---------|---------|
| 工具实现 | Office JS API 调用链 + 参数 + 返回值 |
| Socket.IO | 事件处理函数 + payload 映射 + OASP 对应关系 |
| 构建/部署 | Webpack 配置 + 开发/生产模式差异 + Sideloading 步骤 |

## 常见问询场景

| 发起方 | 典型问题 |
|--------|---------|
| office4ai | **Add-In 端某个工具的 Office JS 实现细节？** |
| office4ai | **Socket.IO 事件处理和 DTO 映射逻辑？** |
| oasp | Add-In 对某个 OASP 事件的实现方式？ |
| client | Add-In 的部署方式和 Sideloading 步骤？ |
