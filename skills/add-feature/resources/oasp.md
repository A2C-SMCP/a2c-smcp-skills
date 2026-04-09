# Add Feature — OASP 协议线

> 通用流程参见 SKILL.md 主文件。

## 协议线概况

- **协议仓库**：A2C-SMCP/oasp-protocol
- **代码仓库**：office4ai（MCP Server / AI 后端）、office-editor4ai（Office Add-In 前端）
- **当前版本**：0.1.8
- **架构**：AI Agent →[MCP/API]→ Server →[Socket.IO]→ Office AddIn →[Office.js]→ Microsoft Office

## 命名空间与事件现状

| 命名空间 | 应用 | 状态 | 事件数 | 分类数 |
|---------|------|------|--------|--------|
| /word | Word | Stable | 23 | 6（事件上报/内容获取/文本操作/多媒体/高级功能/批注） |
| /ppt | PowerPoint | Draft | 22 | 7（事件上报/内容获取/内容操作/样式/布局/幻灯片管理等） |
| /excel | Excel | Draft | 37 | 10（状态感知/区域操作/格式样式/合并/工作表/表格/图表/透视表/查找/公式） |

总计 82 个事件，40 个错误码。

**错误码体系**：
- 1xxx 通用（UNKNOWN ~ RATE_LIMITED，6 个）
- 2xxx 连接/认证（UNAUTHORIZED ~ CONNECTION_LOST，6 个）
- 3xxx 文档/操作（DOCUMENT_ERROR ~ SEARCH_NO_MATCH，13 个）
- 4xxx 参数校验（VALIDATION_ERROR ~ PARAM_OUT_OF_RANGE，5 个）
- 5xxx Excel 专用（WORKSHEET_NOT_FOUND ~ NOT_SUPPORTED，10 个）

## Step 2 差异：协议合规检查

OASP 协议规范文档位于 `docs/specification/`：

| 文档 | 关注场景 |
|------|---------|
| events-word.md | Word 事件（Stable，变更门槛高） |
| events-ppt.md | PPT 事件（Draft，变更门槛较低） |
| events-excel.md | Excel 事件（Draft，变更门槛较低） |
| data-structures.md | 公共数据结构（BaseRequest/BaseResponse/SelectionInfo/TextFormat 等） |
| error-handling.md | 错误码体系 |
| connection.md | 连接握手与生命周期 |
| conventions.md | 通用约定（时间戳/编码/单位等） |

**OASP 不可违反的约束**：
- 三层架构（AI Agent → Server → Office Add-In → Microsoft Office）不可绕过
- 事件命名格式：`{namespace}:{action}:{target}`（如 word:insert:text）
- JSON 字段统一 camelCase，错误码 SCREAMING_SNAKE
- BaseRequest 三要素：requestId + documentUri + timestamp（可选）
- 时间戳 Unix 毫秒 UTC，图片 Base64 编码，全文 UTF-8
- 单文档单 AddIn 客户端，指数退避重连
- Office.js API 限制（如 PPT 不支持视频/音频插入）

**Stable vs Draft 变更门槛差异**：
- /word（Stable）：变更必须严格评审，向后兼容为强制要求
- /ppt、/excel（Draft）：变更门槛较低，但仍需走协议评审流程
- 新增命名空间需同时定义事件分类体系和专用错误码范围

**超时约定**（新增事件需分类）：
- 简单查询：10s
- 复杂查询/修改：30s
- 批量操作：60s

## Step 3 差异：向后兼容评估

新增事件需确认：
- 新字段是否为 Optional？已部署的 AddIn 能否忽略？
- 是否修改了已有 BaseRequest/BaseResponse 的结构？（**高风险**）
- 新增错误码是否落在正确的范围段？（1xxx/2xxx/3xxx/4xxx/5xxx）
- 新命名空间是否需要分配独立错误码范围？

## Step 5 差异：代码仓库关联

**实现顺序建议**：
1. office4ai（Server 端先实现 DTO + Handler + MCP Tool 封装）
2. office-editor4ai（Add-In 端跟进 Schema + Handler + Office.js API 调用）

**双端协调**：
- office4ai 的 DTO/Handler 与 office-editor4ai 的 Schema/Handler 必须事件名和数据结构完全对齐
- office4ai 负责 MCP Tool → Socket.IO 事件的映射
- office-editor4ai 负责 Socket.IO 事件 → Office.js API 的映射
- 两端需同步更新，避免版本不一致导致运行时错误
