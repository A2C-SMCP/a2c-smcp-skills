# window:// 通道 —— 把服务状态暴露给 Desktop

> 通用流程见 SKILL.md 主文件。本文件是 producer 侧 `window://` 的逐字段规范与行为契约。规范性定义以 a2c-smcp-protocol `docs/specification/desktop.md` 为准（本文件与其对齐）。

## URI 规范

```
window://host/path1/path2
```

| 组件 | 必需 | 约束 |
|---|---|---|
| `scheme` | 是 | 固定 `window`，否则解析失败 |
| `host` | 是 | 非空；单 server 内由 `resources/list` 保证唯一；跨 server **SHOULD** 唯一；推荐反向域名 `com.example.app` |
| `path` | 否 | 0..N 段，每段 URL 编码；`c%2Fd` 保持单段、解码为 `c/d` |

- **URI 是纯标识符**，不承载任何元数据；**禁止**携带 query（Computer 检测到 query 会告警并丢弃）。
- host 跨 server 冲突不阻塞注册，Computer 记 WARN（组织算法按 server 名分组，不强依赖 host 唯一）。

## 元数据字段分工（v0.2）

**语义与 MCP 标准对齐的字段放 `annotations`；A2C 自定义字段放 `_meta`。**

### `annotations`（MCP 标准）

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `priority` | float `[0.0, 1.0]` | `0.0` | 布局排序，**仅同一 server 内**比较；越大越靠前 |
| `audience` | `["assistant"]` / `["user"]` / 二者 | — | **SHOULD** 显式 `["assistant"]`；声明为 `["user"]`（不含 assistant）v0.2 仅记 WARN 不过滤（v0.3+ 可能硬过滤）|
| `lastModified` | ISO 8601 字符串 | — | 透传，不参与排序 |

### `_meta`（A2C 扩展）

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `fullscreen` | bool | `false` | 同一 server 内**仅首个 `true`** 生效，其余窗口被排除 |

**缺失值同义**：`annotations is None` ≡ `annotations.priority is None` → `0.0`；`_meta is None` ≡ `_meta.fullscreen is None` → `false`。越界 priority / 非 bool fullscreen → 记警告并回落默认。

## ⚠️ v0.1 → v0.2：不要把元数据写进 URI query

v0.1 曾用 `window://host/x?priority=50&fullscreen=false`（priority 为 **0–100 整数**）。**自 v0.2 起废弃**：

- 当前 Computer（python-sdk）**只读 `Resource.annotations.priority`（float 0–1）与 `_meta.fullscreen`**；URI query 的 priority/fullscreen 一律返回 `None`，即按 `0.0` / `false` 处理（见 python-sdk `a2c_smcp/utils/window_uri.py`）。
- 生态里 **office4ai / ide4ai 仍用 v0.1 query 写法**，其 priority/fullscreen 在当前 Computer 上**已失效**——它们是历史遗留，**新 server 勿照抄**。

新实现**只用** annotations + `_meta`，URI 保持纯净。

## `resources/read`：提供窗口内容

返回 `TextResourceContents`（低层 `mcp` SDK 中，read handler 返回 `str` 即被包装为 `TextResourceContents`）：

- **多个文本内容**按 `\n\n` 连接。
- **`BlobResourceContents` 不被渲染**——遇到会告警并跳过。
- **空内容窗口**在组织阶段即被过滤，不出现在结果里。

渲染格式：有文本 → `{URI}\n\n{body}`；无文本 → 仅 `{URI}`。

## Computer 组织算法（producer 需预期的行为）

Agent 调 `client:get_desktop` 时，Computer 对所有 server 的窗口做组织，producer 应据此设计：

1. **过滤**：丢弃空内容 / 非法 URI / 仅 Blob 的窗口。
2. **按 server 分组**，server 顺序 = 最近工具调用历史（近的在前）+ 其余按名字母序。
3. **组内按 `annotations.priority` 降序**。
4. **fullscreen（per-server）**：某 server 内若有 `_meta.fullscreen=true`，**只保留第一个**全屏窗口，该 server 其余窗口全排除；其它 server 不受影响。
5. **size 截断**：跨所有 server 累计全局上限（`size=None` 不限；`size≤0` 空列表）。

> 含义：priority 只在你自己的 server 内决定顺序，跨 server 顺序由**工具调用热度**决定——producer 无法跨 server 抢占。fullscreen 是「本 server 只露一个主窗口」的开关，别对多个窗口都设 `true`。

## 定向获取

Agent 可在 `client:get_desktop` 传 `window=<完整 URI>` 定向取单窗口（**字符串完全相等**匹配 `Resource.uri`，非前缀/模式）。未命中返回空 `desktops`（非错误）。故 producer 的 URI **必须稳定、可预测**，Agent 才能定向命中。

## 最佳实践

1. **host 反向域名**（`com.example.app`），跨 server 天然隔离。
2. **合理分配 priority**（别全用默认 `0.0`）；`fullscreen` 只给需要完整展示的**主**窗口。
3. **`audience` 显式 `["assistant"]`**。
4. **内容简洁、纯文本、生成要快**——它进 LLM 上下文。参考 office4ai：`read()` 通过 Socket.IO 拉实时数据但带 **3s 超时 + 降级兜底**，避免慢 read 拖垮 desktop。
5. **及时发变更通知**（见 SKILL.md Step 4）：状态变化 `send_resource_updated`；窗口增删 `send_resource_list_changed`。

## 已验证参考实现

| 文件（repo） | 承载 |
|---|---|
| `.claude/skills/UAT/resources/seeds/mcp/server_with_window_resources.py`（python-sdk）| v0.2 标准写法：annotations(priority float/audience/lastModified) + `_meta.fullscreen` |
| `tests/integration_tests/computer/mcp_servers/resources_subscribe_stdio_server.py`（python-sdk）| subscribe 覆写 + `send_resource_updated` |
| `office4ai/a2c_smcp/resources/*_window.py`（office4ai）| 实时状态 `read()`（Socket.IO + 超时降级）；⚠️ 元数据仍为 v0.1 query，勿照抄 |
