# Python 示例 —— raw `mcp` low-level SDK

> 通用流程见 SKILL.md 主文件；字段语义见 `window-channel.md` / `skill-channel.md`。本文件是**可运行形态**的 Python 代码，蒸馏自生态内已验证的 producer（见文末「参考实现」）。生态内所有 producer 均用 raw `mcp` low-level `Server`（非 FastMCP）；其它语言的 MCP SDK 概念同构，照此映射即可。

依赖：`mcp>=1.15.0`。

## 0. 声明能力（关键陷阱）

低层 `mcp` SDK 默认把 `resources.subscribe` 硬编码为 `False`。要推送变更通知，**覆写 `get_capabilities`**：

```python
import mcp.types as types
from mcp.server.lowlevel.server import Server, NotificationOptions
from mcp.server.stdio import stdio_server
from pydantic import AnyUrl


class A2CServer(Server):
    """覆写以声明 resources.subscribe=True（低层 SDK 默认 False）。"""

    def get_capabilities(self, notification_options, experimental_capabilities):
        caps = super().get_capabilities(notification_options, experimental_capabilities)
        if caps.resources is not None:
            caps.resources = types.ResourcesCapability(
                subscribe=True,
                listChanged=caps.resources.listChanged,
            )
        return caps


server = A2CServer("com.example.app")

WINDOW_STATUS = "window://com.example.app/status"
SKILL_ROOT = "skill://com.example.app/csv-aggregator"
```

## 1. `resources/list` —— 同时暴露 window:// 与 skill://

用 `Resource.model_validate({...})` 构造，`_meta`/`annotations` 用字典键最稳妥：

```python
@server.list_resources()
async def list_resources() -> list[types.Resource]:
    return [
        # ── window://（Desktop 状态）──────────────────────────────
        types.Resource.model_validate({
            "uri": WINDOW_STATUS,
            "name": "app-status",
            "description": "当前服务运行状态",
            "mimeType": "text/plain",
            "annotations": {                 # MCP 标准字段
                "priority": 0.8,             # float [0.0, 1.0]，同 server 内排序
                "audience": ["assistant"],   # 面向 Agent
            },
            "_meta": {"fullscreen": False},  # A2C 扩展
        }),

        # ── skill://（resources 模式：根 + 子文件）─────────────────
        types.Resource.model_validate({
            "uri": SKILL_ROOT,               # 根：必须带 _meta.source
            "name": "csv-aggregator",
            "description": "把多个 CSV 按规则聚合并生成报告。",
            "mimeType": "inode/directory",
            "_meta": {"source": "resources", "version": "1.2.0"},
        }),
        types.Resource.model_validate({      # 子文件：无 _meta.source
            "uri": f"{SKILL_ROOT}/SKILL.md",
            "name": "SKILL.md",
            "mimeType": "text/markdown",
        }),
        types.Resource.model_validate({
            "uri": f"{SKILL_ROOT}/references/rules.md",
            "name": "rules.md",
            "mimeType": "text/markdown",
        }),
    ]
```

## 2. `resources/read` —— 返回文本，SDK 包装为 TextResourceContents

低层 read handler 返回 `str` 即被 SDK 包装为 `TextResourceContents`：

```python
@server.read_resource()
async def read_resource(uri: AnyUrl) -> str:
    u = str(uri)
    if u == WINDOW_STATUS:
        return render_status()          # 见下；纯文本、生成要快
    if u == f"{SKILL_ROOT}/SKILL.md":
        return SKILL_MD_TEXT            # 含 YAML frontmatter（name + description 必备）
    if u == f"{SKILL_ROOT}/references/rules.md":
        return RULES_TEXT
    # 注意：resources 模式下 SKILL_ROOT 本身（inode/directory）不被直接 read，
    # Computer 只 read 其子文件。
    raise ValueError(f"Resource not found: {u}")


def render_status() -> str:
    # 真实实现若要拉外部实时数据，务必加超时 + 降级兜底（参考 office4ai 的 3s 超时），
    # 避免慢 read 拖垮整个 desktop 组织。
    return "运行中 | 连接: 3 | 队列: 0"
```

`SKILL.md` 文本示例（frontmatter 至少 `name` + `description`）：

```markdown
---
name: csv-aggregator
description: 把多个 CSV 文件按规则聚合并生成报告。当用户上传 CSV 并要求聚合时触发。
---

# CSV Aggregator
...正文...
```

## 3. 变更通知

```python
# 某窗口状态更新 / 某 SKILL 内容更新
async def notify_status_changed():
    await server.request_context.session.send_resource_updated(AnyUrl(WINDOW_STATUS))

# 窗口或 SKILL 集合增删
async def notify_set_changed():
    await server.request_context.session.send_resource_list_changed()
```

## 4. 启动（stdio）—— 广告 listChanged

```python
async def main():
    async with stdio_server() as (read, write):
        await server.run(
            read,
            write,
            server.create_initialization_options(
                # 开启 listChanged 广告；subscribe 由上面的 get_capabilities 覆写声明
                notification_options=NotificationOptions(resources_changed=True),
            ),
        )
```

## 5. skill:// 的另外两种 source 模式（根 Resource 片段）

同机零拷贝用 `mounted`；远程整包用 `archive`。仅根 Resource 的 `_meta` 不同，`resources/list` 里**不再需要**子文件（Computer 自行物化）：

```python
# mounted：server 与 Computer 同机，SKILL 已在本地 FS（Computer 会拷贝进 staging，非 symlink）
types.Resource.model_validate({
    "uri": "skill://com.example.app/my-skill",
    "name": "my-skill",
    "mimeType": "inode/directory",
    "_meta": {"source": "mounted", "mount_dir": "/opt/skills/my-skill", "version": "1.0.0"},
})

# archive：远程 server，有打包能力（archive_format 仅支持 tar.gz / zip）
types.Resource.model_validate({
    "uri": "skill://com.example.app/my-skill",
    "name": "my-skill",
    "mimeType": "inode/directory",
    "_meta": {
        "source": "archive",
        "archive_uri": "https://cdn.example.com/my-skill-1.0.0.tar.gz",
        "archive_format": "tar.gz",
        "archive_sha256": "a3f8...",     # 可选；提供则 Computer 校验
        "version": "1.0.0",
    },
})
```

> `mounted` / `archive` 的字段契约由 Python + Rust 两套 consumer 一致验证，但生态内**尚无 committed 的可运行 mounted/archive server**——落地按此契约构造，参考 python-sdk `.claude/skills/uat-seed/resources/recipes/mcp.md`。

## 参考实现（生态内已验证，可对照）

| 文件（repo） | 用途 | 验证程度 |
|---|---|---|
| `.claude/skills/UAT/resources/seeds/mcp/server_with_window_resources.py`（python-sdk）| window v0.2 annotations+`_meta` 标准写法 | 已验证 seed |
| `tests/integration_tests/computer/mcp_servers/resources_subscribe_stdio_server.py`（python-sdk）| subscribe 覆写 + `send_resource_updated` | 集成测试 |
| `tests/integration_tests/computer/mcp_servers/notifications_stdio_server.py`（python-sdk）| `send_resource_list_changed` + `NotificationOptions(resources_changed=True)` | 集成测试 |
| `tests/integration_tests/computer/mcp_servers/fastmcp_skill_stdio_server.py`（python-sdk）| skill:// `resources` 模式根+子文件 | ✅ 端到端集成测试 |
| `office4ai/a2c_smcp/resources/*_window.py`（office4ai）| 实时 `read()`（超时降级）| ⚠️ 元数据仍 v0.1 query，勿照抄 |
