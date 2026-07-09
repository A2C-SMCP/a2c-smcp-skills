---
name: expose-a2c-resources
description: 指导第三方 MCP Server 开发者通过标准 MCP Resource 协议暴露 window://（桌面状态）与 skill://（能力包）资源，接入 A2C-SMCP Desktop / SKILL 通道。当为 MCP Server 增加 A2C-SMCP 集成、把服务实时状态暴露给 Desktop、或通过 MCP 分发 SKILL 时使用。
argument-hint: "[window|skill]"
---

# Expose A2C Resources — 让 MCP Server 接入 A2C-SMCP Desktop / SKILL

A2C-SMCP 的 **Desktop** 与 **SKILL** 两个通道都建立在**标准 MCP `resources/list` + `resources/read`** 之上，按 URI scheme 路由：`window://` 归 Desktop，`skill://` 归 SKILL。

> **核心理念**：MCP Server 只需按 **MCP 标准**暴露 Resource，**无需任何 SMCP 私有改动**——Computer 自动完成聚合 / 物化。本指南面向**第三方 MCP Server 开发者（producer 侧）**：你不实现 Computer / Server，只需产出正确的 Resource。

## 两个通道对照

| 维度 | `window://`（Desktop 状态） | `skill://`（SKILL 能力包） |
|---|---|---|
| 用途 | 把服务**实时状态**暴露给 Agent 桌面视图 | 分发**可执行能力包**（`SKILL.md` + 可选 scripts/references）|
| 关键元数据 | `annotations.priority/audience` + `_meta.fullscreen` | `_meta.source` ∈ mounted / archive / resources |
| `resources/read` | 返回状态文本（`TextResourceContents`）| 按 source 物化（archive 拉包 / resources 逐子文件）|
| Computer 处理 | 组织：按 server 分组 → priority 排序 → fullscreen → size 截断 | staging 物化 + 合成 name `mcp:<server>:<skill>` |
| 何时实现 | 想让 Desktop 看到服务状态 | 想通过本 server 分发 SKILL |

两通道**正交**：可只实现其一，也可都实现（同一 server 同时暴露两种 scheme 的 Resource）。深入细节分发到 resource 文件。

---

## Step 0：前提 —— 声明 `resources` capability

两个通道都要求 server 声明 `resources` 能力并能回应 `resources/list`。**未声明 `resources` 的 server 会被 Computer 直接跳过**，其窗口 / SKILL 均不可见。

```python
"capabilities": {
    "resources": {
        "subscribe": True,      # 想推送变更通知则必需（见 Step 4）
        "listChanged": True,    # SKILL/窗口集合会增删时开启
    }
}
```

> ⚠️ **低层 `mcp` SDK 陷阱**：`mcp.server.lowlevel.Server` 默认把 `resources.subscribe` 硬编码为 `False`。要推送变更，**必须覆写** `get_capabilities` / `create_initialization_options` 显式声明 `subscribe=True`（做法见 `{baseDir}/resources/python-mcp-examples.md`）。注意：只做只读状态、不推送通知也能工作（Agent 轮询），但体验差。

---

## Step 1：判定要实现哪个通道

| 你的需求 | 实现通道 |
|---|---|
| 让 A2C-SMCP Desktop / Agent 看到本服务的**实时运行状态**（如连接数、当前文档、日志） | **window://** → Step 2 |
| 通过本 MCP Server **分发 SKILL 能力包**给 Agent | **skill://** → Step 3 |
| 两者都要 | 都做（互不干扰）|

参数 `[window|skill]` 可指定只处理一个通道；缺省则按需求两个都覆盖。

---

## Step 2：实现 `window://` —— 暴露服务状态

目标：把服务状态做成一个（或几个）`window://` 资源，Desktop 会自动聚合展示给 Agent。

1. **在 `resources/list` 暴露 `window://<host>/<path>` 资源**，用 `annotations` 声明 MCP 标准字段、`_meta` 声明 A2C 扩展字段：
   - `annotations.priority`：**float `[0.0, 1.0]`**，越大越靠前（**同一 server 内**排序）
   - `annotations.audience`：**SHOULD** 显式 `["assistant"]`（面向 Agent）
   - `_meta.fullscreen`：bool，同一 server 内仅首个 `true` 生效、排他其余窗口
2. **实现 `resources/read`**：返回 `TextResourceContents`（状态文本）。内容保持**简洁、纯文本、生成要快**——它会被拼进 LLM 上下文。
3. **状态变化时推送通知**（Step 4）。

> 🚫 **不要**把 `priority` / `fullscreen` 写进 URI query（如 `?priority=50`）。这是 v0.1 旧写法，**当前 Computer 已不再解析**、一律按 `0.0` / `false` 处理。生态里 office4ai / ide4ai 仍用旧写法但已失效，**勿照抄**。

> URI 规则、annotations/`_meta` 逐字段语义、Computer 组织算法（分组/排序/fullscreen/截断）、内容最佳实践、v0.1→v0.2 迁移细节见 `{baseDir}/resources/window-channel.md`。Python 代码见 `{baseDir}/resources/python-mcp-examples.md`。

---

## Step 3：实现 `skill://` —— 分发能力包

目标：把 SKILL 目录包做成 `skill://` 资源，Computer 会物化到本地并合成 `mcp:<server>:<skill>` 暴露给 Agent。

1. **每个 SKILL 根**暴露为一个 `Resource`，`uri = skill://<host>/<leaf>`（`<leaf>` 非空），**必须**带 `_meta.source`：
   | source | 必备 `_meta` | 何时选 |
   |---|---|---|
   | `mounted` | `mount_dir`（本地绝对路径，须存在）| server 与 Computer 同机 |
   | `archive` | `archive_uri` + `archive_format`（`tar.gz`/`zip`）+ 可选 `archive_sha256` | 远程、有打包能力 |
   | `resources` | 无（子文件作为兄弟资源暴露）| 远程、无打包能力 |
2. **物化后的包根须含 `SKILL.md`**，其 YAML frontmatter **至少有 `name` + `description`**（`name` 会成为包目录名与合成 name 的 leaf）。
3. 可选 `_meta.version` → `A2CSkillRef.version`。变更时推送通知（Step 4）。

> ⚠️ `skill://` 资源**没有 `_meta.source` 会被当作子资源、不注册为 SKILL 根**。三种 source 模式的字段契约、name 合成规则、frontmatter 规范、`resources` 模式子文件布局、`.skillenv` 安全约束，以及 spec 与实现的差异（如 mounted 实际是**拷贝**非 symlink）见 `{baseDir}/resources/skill-channel.md`。

---

## Step 4：变更通知（两通道共用）

Computer 靠 MCP 标准通知感知变化，Agent 收到后自动重新拉取：

- **内容变化**（某窗口状态更新 / 某 SKILL 内容更新）→ `send_resource_updated(uri)`
- **集合变化**（新增 / 删除窗口或 SKILL）→ `send_resource_list_changed()`

```python
await server.request_context.session.send_resource_updated(AnyUrl("window://com.example.app/status"))
await server.request_context.session.send_resource_list_changed()
```

无通知也能用（Agent 可随时主动拉取），但状态不会及时刷新。

---

## Step 5：验证被正确接入

1. **能力**：`initialize` 响应里 `capabilities.resources` 存在（推送场景 `subscribe=true`）。
2. **列举**：`resources/list` 能列出你的 `window://` / `skill://` 资源，URI scheme 正确。
3. **读取**：`resources/read` 对每个 URI 返回预期内容（window 为文本；skill 按 source 物化）。
4. **接入验证**：用 A2C-SMCP Computer SDK（python-sdk / rust-sdk）连接本 server —— window 走 `client:get_desktop` 应看到你的状态；skill 走 `client:get_skills` 应看到 `mcp:<server>:<skill>`。
5. **元数据生效**：确认 window 的 `priority`/`fullscreen` 来自 annotations/`_meta`（非 URI query），排序符合预期。

---

## 反模式警示

| 反模式 | 正确做法 |
|--------|---------|
| 未声明 `resources` capability | 声明后 Computer 才会枚举本 server |
| 低层 SDK 默认 `subscribe=false` 却想推通知 | 覆写 capabilities 显式 `subscribe=true` |
| `priority`/`fullscreen` 塞进 URI query | 用 `annotations.priority`(float 0–1) + `_meta.fullscreen` |
| `priority` 用 0–100 整数 | v0.2 是 **float `[0.0,1.0]`** |
| window 内容返回大段 HTML / 二进制 | 简洁纯文本；`BlobResourceContents` 不被渲染 |
| `skill://` 根漏了 `_meta.source` | 会被当子资源丢弃；根必须带 `source` |
| 以为 `mounted` 是 symlink 保持联动 | 实现是**拷贝**到 staging；改源目录不自动生效，需发通知 |
| 在 `_meta` 重复 SKILL.md frontmatter | Computer 以本地 `SKILL.md` 为权威源，不必镜像 |
