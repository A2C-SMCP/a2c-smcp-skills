# Add Feature — office4ai 实现模式判定（OASP 线）

> OASP 通用流程见 SKILL.md 主文件；协议合规见 `{baseDir}/resources/oasp.md`。本文件承载 office4ai（MCP Server，GitHub JIAQIA/office4ai）**实现阶段（Step 6）的实现模式判定**与服务端生产工具落地清单。

## 判定维度：服务端生产能力工具 vs 纯中转

OASP 0.3.0 把 Python MCP Server 从「纯中转」升级为「**具备生产能力**」：Server 可在 MCP Python 层用工具集（如 python-pptx）直接生产 / 修改文档内容。动代码前先判定本 feature 属于哪类：

| 模式 | 特征 | 落地 |
|------|------|------|
| **纯中转** | Server 仅把 MCP 调用转成 Socket.IO 事件（`emit_to_document`），断连即失败 | 现有 ~45 个工具的默认模式，无需本清单 |
| **服务端生产能力工具** | Server 在 Python 层**直接生产 / 修改文档内容**（OOXML / python-pptx） | **走下方双路径落地清单** |

> 现状：仅 3 个图表工具（`ppt insert/get/update_chart`）走服务端生产模式；把 Path A 泛化成「任意内容类型可复用的通用 Python 工具集」是已规划后续工作。图表三件套是**已真机验证的落地样板（pattern to replicate）**。

## 服务端生产工具落地清单

按文档连接状态（`DocumentStatus`）双路径落地：

1. **双路径路由**：`connected = get_document_status(uri) == DocumentStatus.CONNECTED`。
   - **Path B（CONNECTED）**：Server 内存生成 OOXML（base64），驱动 Add-In 的**通用搬运事件** `ppt:get:slideOoxml` / `ppt:insert:slidesOoxml`，把生产物落进打开态文档。Add-In 只搬运幻灯片、不碰内容语义。
   - **Path A（DISCONNECTED）**：python-pptx 离线读写盘（0.2.0 即有的行为）。
2. **反应式降级**（不预先按能力位 gate，而是尝试 Path B 后对失败反应）：
   - **写降级**：path B 的 `_emit` 遇 `TimeoutError` / `ValueError` / `RuntimeError` / 非 dict 响应 / `3016 API_NOT_SUPPORTED` → `PathBUnavailable` → 上抛翻转后的 `3003`「关闭文档后重试」引导（`DEGRADE_MESSAGE_WRITE`）。
   - **读降级**：get 回退 Path A 读盘（读盘无覆盖风险，最坏返回陈旧数据）。
   - **业务错误不降级**：working Add-In 的真实业务码（如 3010 图表未找到）→ `ChartEngineError` 上抛，绝不静默降级。
3. **持 `document_lock` 跨网络 round-trip**：整个 Path B round-trip 包在 `document_lock_manager.acquire(uri)` 内，防 lost-update。
4. **`requiresReload = not connected`**：离线改盘需重开渲染；打开态 round-trip 已就地更新。
5. **写后 `notify_resource_updated`**：改动后通知 MCP resource 订阅方（如 `window://office4ai/ppt`）。
6. **就地替换契约**（Path B 写）：export 拿 `base64` + 不透明 `slideId`（`_require_base64` / `_require_slide_id` 守卫，缺失即降级，防重页 corruption）；`_apply_payload` 用 `replaceSlideId` + `finalSlideIndex` 在原位替换旧页。

## 测试矩阵

- **router 单测**：`_emit` 全分类（timeout / ValueError / RuntimeError / 非 dict / 3016 → 降级；业务码 → 上抛）+ `_require_base64` / `_require_slide_id` 守卫。
- **业务错误上抛不降级** 单测。
- **`document_lock` 串行化** 单测。
- **E2E**：进程内 FakeAddIn 模拟（`--mode pathb`）+ 真机（`--mode pathb-live`）。

## 已验证落地样板（pattern to replicate）

> 路径相对 office4ai 仓库根（注意仓库内包目录为 `office4ai/`）。

| 文件 | 承载 |
|------|------|
| `office4ai/environment/workspace/services/chart_engine.py` | 服务端 OOXML 生产 + base64 单页助手 |
| `office4ai/environment/workspace/services/chart_router.py` | 双路径路由 + 反应式降级（`_emit` 分类 / `_require_*` 守卫 / `_apply_payload` 就地替换契约） |
| `office4ai/a2c_smcp/tools/ppt/insert_chart.py`（及 `get_chart.py` / `update_chart.py`） | 翻转 3003 守卫、`document_lock`、`requiresReload`、`notify_resource_updated` |
| `tests/unit_tests/office4ai/environment/workspace/services/test_chart_router.py`（及 `test_chart_engine.py`） | router / engine 单测 |
| `manual_tests/ppt/test_chart_e2e.py` | E2E（`--mode pathb` 模拟 / `--mode pathb-live` 真机） |
| `docs/manual_tests/ppt_chart_v0.3.0.md` | 验收手册 |

## 错误码锚点

- **3003**（写降级 / 文档打开）：Path B 不可用时翻转返回，保留「关闭文档后重试」语义。
- **3016 API_NOT_SUPPORTED**（能力不可用 → 降级）：Add-In 无对应 handler / requirement set 不支持。
- **3015 INVALID_CHART_DATA**：图表数据维度不匹配（业务校验，上抛不降级）。
