# Fix Issue — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：JIAQIA/office4ai
- **语言**：Python，uv 管理
- **架构**：MCP Server + Gymnasium 环境，LibreOffice UNO Bridge 双层
- **协议**：实现 OASP 协议（office4ai 作为 Server 端），同时作为 SMCP Computer 的 MCP Server

## 调用链路追踪

- **MCP 工具调用**：AI Agent → MCP Tool → Socket.IO 事件发送 → Office Add-In 执行 → 结果返回
- **UNO 直接操作**：AI Agent → MCP Tool → LibreOffice UNO API → 文档操作
- **跨系统问题**：需区分根因在 office4ai（Server 端）还是 office-editor4ai（Add-In 端）

## 服务端生产能力工具双路径排查（Step 2.2 / Step 5 差异）

少数工具（图表 `insert_chart` / `get_chart` / `update_chart`）在 MCP Python 层直接生产/修改 OOXML，按文档连接态走**双路径**；其余工具是纯中转。改这类 bug 前必做：

1. **先判工具类型**：导入 `chart_engine` / `chart_router`（服务端生产工具）→ 两条路径都查；仅 `emit_to_document`（纯中转）→ 单路径即可。
2. **双路径都要复现/修复**：Path A（DISCONNECTED，python-pptx 离线读写盘）+ Path B（CONNECTED，服务端内存生成 OOXML → 驱动 Add-In 事件 `ppt:get:slideOoxml` / `ppt:insert:slidesOoxml` 应用到打开态文档），不可只修一条。
3. **降级分类正确性**（`chart_router._emit`）：`TimeoutError` / `ValueError` / `RuntimeError` / 非 dict 响应 / `3016`（`_DEGRADE_CODES`）→ `PathBUnavailable`（反应式降级）；其它业务码 → `ChartEngineError`（上抛，**不得**降级或静默回退盘读）。改降级逻辑务必核对此分类。
4. **守卫不可削弱**：`_require_base64` / `_require_slide_id`（缺失即降级，防重复页损坏）；`document_lock_manager.acquire` 跨 round-trip 持锁（防 lost-update）；`requiresReload = not connected`；写后 `notify_resource_updated`。
5. **回归测试矩阵**：`test_chart_router.py`（_emit 全分类 + 守卫）、`test_ppt_tools.py`（业务错误上抛 / lock 串行化 / 双路径路由）、`test_chart_engine.py`、`manual_tests/ppt/test_chart_e2e.py`（`--mode pathb` 模拟 / `--mode pathb-live` 真机）。

> 样板实现：`services/chart_engine.py`、`chart_router.py`、`a2c_smcp/tools/ppt/{insert,get,update}_chart.py`；验收稿 `docs/manual_tests/ppt_chart_v0.3.0.md`。错误码 3003 / 3016 / 2006。

## 双协议注意

office4ai 处于两条协议线的交叉点：
- **作为 OASP Server**：事件名/数据结构必须符合 OASP 协议（`{namespace}:{action}:{target}` 格式）
- **作为 SMCP Computer 的 MCP Server**：工具定义必须符合 MCP 规范

涉及 OASP 事件修改时，需同步考虑 office-editor4ai（Add-In 端）的对齐。

## Step 5 差异：架构原则

- DTO/Handler 修改时，确保与 office-editor4ai 的 Schema/Handler 对齐
- Socket.IO 事件名和数据结构两端必须一致
- MCP 工具与 OASP 事件的映射关系需保持正确

## Step 7 差异：验证命令

```bash
uv run poe test       # 全量测试
uv run poe lint       # ruff + mypy
```
