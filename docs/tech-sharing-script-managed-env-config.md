# 技术分享：用 Shell 脚本管理 Troubleshoot 环境配置

> 面向 turingfocus-skills 团队。背景与思路沉淀，供参考借鉴。

## 问题背景

在 A2C-SMCP 的 troubleshoot skill 中，一次排查往往**跨越多个项目**，每个项目可能运行在不同位置：

```
python-sdk  → 本地 /Users/dev/python-sdk
office4ai   → 本地 /Users/dev/office4ai
rust-sdk    → 远程 ssh:prod-server /opt/rust-sdk
tfrobot     → 远程 ssh:prod-server /opt/tfrobot
```

每个工程师的环境不同，每个问题涉及的项目子集也不同。排查时需要知道"去哪里采集日志"，这个信息必须持久化，否则每次排查都要重新问一遍。

## 最初方案：LLM 直接操作 JSON

最初设计是让 LLM 通过 Read/Write 工具直接读写 `~/.a2c_smcp/dev-env.json`：

```json
{
  "version": 1,
  "projects": {
    "python-sdk": { "location": "local", "path": "/Users/dev/python-sdk" },
    "rust-sdk": { "location": "remote", "ssh_connection": "prod", ... }
  }
}
```

### 遇到的问题

| 问题 | 影响 |
|------|------|
| **权限弹窗** | LLM 每次读写文件都触发用户授权确认，打断排查流程 |
| **路径暴露** | 配置中包含本地路径、SSH 连接名等，出现在 LLM 对话上下文中 |
| **格式风险** | LLM 生成 JSON 可能格式错误（缺逗号、类型不对） |
| **交互式初始化** | LLM 的 Bash tool 不支持 `read -rp` 等交互式输入 |

## 改进方案：Shell 脚本 + 子命令

用一个 `smcp-env.sh` 脚本封装所有配置操作，LLM 只通过 `bash smcp-env.sh <子命令>` 调用：

### 子命令设计

```
smcp-env init <dev|artifact>                            # 交互式初始化（用户自己跑）
smcp-env show <dev|artifact>                            # 展示配置（LLM 可调）
smcp-env set <mode> <project> local <path>              # 设置本地项目
smcp-env set <mode> <project> remote <ssh> <dir> <log>  # 设置远程项目
smcp-env remove <mode> <project>                        # 移除项目
smcp-env verify <mode>                                  # 验证路径和连接
```

### 关键设计决策

**1. 交互与非交互分离**

| 命令 | 交互性 | 执行者 |
|------|--------|--------|
| `init` | 交互式（`read -rp`） | 用户通过 `!` 前缀自行执行 |
| `show` / `verify` | 非交互 | LLM 通过 Bash tool |
| `set` / `remove` | 非交互（参数传入） | LLM 通过 Bash tool |

但实际使用中发现，**`init` 的交互式场景可以被 LLM 的 AskUserQuestion + `set` 替代**：

```
LLM: (AskUserQuestion) python-sdk 在本地还是远程运行？本地路径是什么？
用户: 本地，/Users/dev/python-sdk
LLM: (Bash) smcp-env.sh set dev python-sdk local /Users/dev/python-sdk
LLM: (AskUserQuestion) office4ai 在本地还是远程？
用户: 远程，SSH 连接名 prod-server，目录 /opt/office4ai，日志 /var/log/office4ai
LLM: (Bash) smcp-env.sh set dev office4ai remote prod-server /opt/office4ai /var/log/office4ai
```

这样每一步都经过用户确认，信息准确，格式由脚本保证。

**2. 两个配置文件对应两种模式**

```
~/.a2c_smcp/dev-env.json       # 本地开发调试
~/.a2c_smcp/artifact-env.json  # 构建制品/部署环境
```

同一个项目在 dev 和 artifact 模式下可能运行在不同位置（dev 在本地，artifact 在远程服务器）。

**3. jq 保证 JSON 格式正确**

脚本依赖 `jq` 做所有 JSON 读写，不手拼 JSON 字符串。每次 `set` 都是原子性的 read-modify-write：

```bash
jq --arg p "$project" --arg v "$path" --arg d "$today" \
  '.updated_at = $d | .projects[$p] = {"location": "local", "path": $v}' \
  "$file" > "$file.tmp" && mv "$file.tmp" "$file"
```

**4. 远程项目对接 SSH MCP**

配置中 `ssh_connection` 字段对应 SSH MCP Server 的 `connectionName`。排查时：

- 日志采集：`mcp__ssh-mcp-server__execute-command(connectionName, cmd, directory)`
- 日志下载：`mcp__ssh-mcp-server__download(connectionName, remotePath, localPath)`

`verify` 命令检查本地路径是否存在，远程连接则提示通过 SSH MCP `list-servers` 验证。

## 测试

32 个测试用例覆盖所有子命令、边界情况和模式隔离。关键测试技巧：

```bash
# 用临时 HOME 隔离测试，不影响真实配置
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"' EXIT
```

运行：`make test`

## 给 turingfocus-skills 的建议

如果你们也有类似的跨项目排查场景，建议：

1. **脚本化配置管理**：不让 LLM 直接操作配置文件，通过脚本的子命令封装
2. **AskUserQuestion + 非交互命令**：LLM 负责对话收集信息，脚本负责持久化，各司其职
3. **按排查模式拆分配置**：不同模式的环境拓扑往往不同，一个文件放不下
4. **`jq` 做 JSON 处理**：bash 脚本里永远不要手拼 JSON
5. **SSH MCP 对接远程**：`ssh_connection` 作为配置中的连接标识，运行时映射到 SSH MCP

参考实现：[a2c-smcp-skills/skills/troubleshoot/scripts/smcp-env.sh](https://github.com/A2C-SMCP/a2c-smcp-skills/blob/main/skills/troubleshoot/scripts/smcp-env.sh)
