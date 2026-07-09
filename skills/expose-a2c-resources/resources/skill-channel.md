# skill:// 通道 —— 通过 MCP Server 分发 SKILL 能力包

> 通用流程见 SKILL.md 主文件。本文件是 producer 侧 `skill://` 的契约与三种 source 模式规范。规范性定义以 a2c-smcp-protocol `docs/specification/skill.md` 为准。

## 心智模型

**SKILL = 文件夹**（`SKILL.md` + 可选 `scripts/` / `references/` / `assets/` / `.skillenv`），符合 [marketplace SKILL v1](https://github.com/A2C-SMCP/tfrobot-marketplace) 规范。你（MCP Server）把这个文件夹**通过 MCP Resource 暴露**，Computer 负责**物化（staging）到本地**并合成全局 name。A2C 不重新定义 SKILL 内容格式。

- **URI**（次要身份）：`skill://<host>/<skill-name>`，`<host>` 推荐反向域名。
- **合成 name**（协议主键）：Computer 生成 `mcp:<normalized-server>:<frontmatter.name>`；`source = mcp:<normalized-server>`。
- **server 名规范化**：非 `[A-Za-z0-9_-]` 字符 → `_`（如 `my.api` → `my_api`），大小写保留。规范化后长度为 0 或撞名的 server，其 SKILL 被拒绝注册。

## Producer 契约（由 Computer 消费方代码验证）

要被 Computer 物化，MCP Server **MUST**：

1. **声明 `resources` capability 并回应 `resources/list`**（否则 server 被跳过）。
2. **每个 SKILL 根**暴露为 `Resource`，`uri` 以 `skill://<host>/<leaf>` 开头（`<leaf>` **非空**），且 **带 `_meta.source` ∈ {`mounted`, `archive`, `resources`}**。
   > ⚠️ **`skill://` 资源没有 `_meta.source` → 被当作子资源，不注册为 SKILL 根**（这正是 `resources` 模式子文件的处理方式）。
3. 保证**物化后的包根含 `SKILL.md`**，其 YAML frontmatter **至少有 `name` 与 `description`**。`name` 会成为包目录名与合成 name 的 leaf。
4. 可选 `_meta.version`（→ `A2CSkillRef.version`；缺省则 Agent 不可假定存在）。

## 三种 source 模式

| 模式 | 必备 `_meta` | Computer 物化 | 验证程度 |
|---|---|---|---|
| **resources** | `source="resources"` | 枚举同 server 内 `skill://<host>/<leaf>/**` 兄弟资源，逐个 `resources/read` 按相对路径写盘 | ✅ **有可运行、集成测试验证的 producer** |
| **mounted** | `source="mounted"` + `mount_dir`（本地绝对路径，须为存在目录）| 把 `mount_dir` **拷贝**进 staging | ⚠️ 契约 + 单测 fixture 验证；**无committed 可运行样板** |
| **archive** | `source="archive"` + `archive_uri` + `archive_format`∈{`tar.gz`,`zip`} + 可选 `archive_sha256` | HTTP GET → （有则校验 sha256）→ 解包进 staging | ⚠️ 契约 + 单测 fixture 验证；**无committed 可运行样板** |

### `resources` 模式子文件布局（唯一有可运行 producer 的模式）

- **根**：`Resource(uri="skill://<host>/<leaf>", _meta={"source":"resources", ...})`。
- **子文件**：同一 `resources/list` 里的**兄弟资源**，URI = `skill://<host>/<leaf>/<相对路径>`（如 `.../SKILL.md`、`.../references/x.md`），**不带 `_meta.source`**，可经 `resources/read` 读取。
- 至少要有 `SKILL.md` 子资源，否则物化失败、不注册。

验证样板：python-sdk `tests/integration_tests/computer/mcp_servers/fastmcp_skill_stdio_server.py`（真机 stdio server，被 `test_fastmcp_skills_integration.py` 端到端驱动，产出 `mcp:fastmcp-skill-test:fastmcp-demo`）。

### mounted / archive（契约明确，样板为 fixture）

字段契约由 Python + Rust 两套 consumer 代码一致验证（python-sdk `a2c_smcp/computer/skills/staging.py`、rust-sdk `crates/smcp-computer/src/skills/staging.rs`），并有单测 fixture（`test_staging.py`）与官方 recipe（python-sdk `.claude/skills/uat-seed/resources/recipes/mcp.md`）。但**尚无 committed 的可运行 mounted/archive server**——落地时以上述契约字段为准，参考 recipe 构造。

## SKILL.md frontmatter（marketplace v1 §3.1）

Computer 在 staging 后**直接读本地 `SKILL.md` 的 YAML frontmatter** 作为权威元数据源，**不需要**镜像进 `_meta`。字段：

| 字段 | 必需 | 说明 |
|---|---|---|
| `name` | ✅ | 严格 kebab `[a-z0-9-]`，1–64，不以 `-` 始末、无连续 `--`；= 包目录名 |
| `description` | ✅ | 功能 + 触发场景 |
| `license` / `compatibility` / `metadata` / `allowed-tools` | ⬜ | 透传；`metadata`/`allowed-tools` A2C 不解释，仅跨工具 passthrough |

> **消费方实测只强制 `name` + `description`**（staging 校验）；其余可选。`version` **不在** frontmatter，来自 `_meta.version`。

## 安全约束（producer 必须知道）

- **`.skillenv` 永不外泄**：无论 `rel_path` 为何，`client:get_skill` 命中 `.skillenv` 即返回 `4017 forbidden`（且不泄漏存在性）。凭证放 `.skillenv`，Computer 注入子进程 env 时不写日志、不进 prompt。
- **scripts 可执行**：A2C 有意分叉 Claude Code——Computer-side SKILL 的 `scripts/` **可被执行**，权限继承其 MCP Server 的信任级别（source 信任继承）。
- **沙箱**：Computer 用 name→path 精确映射；`rel_path` 必须相对、无 `..`、无符号链接逃逸，越界 → `4017 traversal`。

## 生命周期（producer 视角）

- **首装**：server 首次连接即视为对其 SKILL 的安装授权（连接本身是显式动作），无需用户再 opt-in。
- **变更**：内容变 → `send_resource_updated(skill://...)`；集合增删 → `send_resource_list_changed()`（见 SKILL.md Step 4）。
- **孤儿**：server 断开 → 其 SKILL 标记孤儿（不删），从 `get_skills` 消失；重连恢复。

## spec 与实现的已知差异（勿被 spec 文字误导）

| spec 措辞 | 实际实现 | 影响 |
|---|---|---|
| mounted「symlink 或直接挂载」 | consumer **拷贝**（`copytree(symlinks=False)`）| 改 `mount_dir` 源不自动生效，**须发通知**触发重物化 |
| `_meta.etag`（推荐附加字段）| **未被任何 consumer 消费** | 设了也不影响 staging，别依赖其做缓存跳过 |
| §11.1 `subscribe: true`「必需」| consumer **不强制**——只要 `resources`/list 能用即可 staging | 但要推变更通知仍需 `subscribe=true`（SDK 默认 false，见 SKILL.md Step 0）|
| `annotations.audience=["assistant"]`（推荐）| staging **不读** annotations | 纯 advisory，不影响是否被注册 |
