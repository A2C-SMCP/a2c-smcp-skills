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

## Step 3.5 差异：Event 字段 cross-ask 验证清单

新增 OASP 事件 / 数据结构时，**必须**通过 `/cross-ask office-editor4ai` 与 Add-In 工程师逐项核对，必要时级联 `/cross-ask office4ai` 评估 Server 离线路径。

### A. 字段与 Office.js API 的映射
- 每个字段对应的 `Word.*` / `Excel.*` / `PowerPoint.*` API 路径（精确到属性名）
- 每个枚举值是否在 Office.js 对应 enum 中（注意大小写、过去分词形：`Centered` 而非 `Center`、`Justified` 而非 `Justify`）
- 字段作用粒度（单元格 / 行 / 表 / 工作表）与 API 粒度是否对齐

### B. 响应字段的可达性
- 响应字段能直接从 Office.js 拿到，还是需要 Add-In 计算？
- 计算字段在边界场景下是否准确（如已合并表格的 `cellCount`、含跨页段落的 `paragraphCount`）

### C. 错误码命中
- 每个新错误码是否与 `error-handling.md` 既有定义冲突（号段、语义）
- 每种 Office.js 异常映射到哪个错误码（特别是 `GeneralException` 的细分）

### D. 跨命名空间一致性
- 同语义字段在 /word /ppt /excel 命名是否对齐（如 `horizontalAlignment` vs `alignment`）
- 共享数据结构（如 `CellFormat` / `TableSummary`）是否值得提到 `data-structures.md`

### E. 实现路径回退（OASP 级联）

office-editor4ai 反馈某字段为「Office.js 完全不支持」时，**必须**继续 `/cross-ask office4ai` 评估能否通过 OOXML 离线修改（python-docx / openpyxl / python-pptx）实现：

```
协议字段草案
    │
    ▼
cross-ask office-editor4ai (Add-In / Office.js)
    ├── A 直接支持        → 进入 Step 4
    ├── B 需 hack         → 评估 hack 成本，必要时调整字段语义
    └── C 完全不支持
        ▼
        cross-ask office4ai (Server / OOXML 离线)
        ├── 可实现        → 协议保留字段，事件文档标注「实现路径：Server 离线」
        └── 也无法实现    → 移除字段，changelog 说明取舍理由
```

**实现路径标注**：若字段最终走 Server 离线实现，对应事件文档（events-word.md 等）必须加：

````markdown
!!! note "实现路径：Server 离线修改"
    本字段在 Office.js 中无对应 API，由 office4ai 通过 OOXML 离线修改实现。
    - 端到端延迟较纯 Add-In 路径高（Add-In 暂存 → Server 处理 → Add-In 重载）
    - 重载期间用户编辑会被回滚
    - 不支持在 unsaved 文档上执行
````

> **门控**：任一 cross-ask 反馈含 P0（cast 不过 / API 不存在 / 错误码冲突），禁止合并到 main，必须 round-N 修订后再次 cross-ask 验证通过。
