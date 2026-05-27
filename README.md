# A2C-SMCP Skills

A2C-SMCP 开源项目的 Claude Code Plugin Marketplace。

## 前置条件

本仓库托管在 GitHub (`github.com/A2C-SMCP/a2c-smcp-skills`)，为公开仓库。

### 方式一：HTTPS（推荐）

```bash
# 直接使用 GitHub HTTPS URL
/plugin marketplace add https://github.com/A2C-SMCP/a2c-smcp-skills.git
```

### 方式二：SSH

```bash
/plugin marketplace add git@github.com:A2C-SMCP/a2c-smcp-skills.git
```

### 方式三：本地路径（开发/离线）

```bash
/plugin marketplace add /Users/<你的用户名>/claudes/a2c-smcp-skills
```

## 使用方式

```bash
# 1. 添加 marketplace
/plugin marketplace add https://github.com/A2C-SMCP/a2c-smcp-skills.git

# 2. 安装 a2c-smcp-toolkit（包含全部 skill）
/plugin install a2c-smcp-toolkit@a2c-smcp-skills

# 3. 重载插件使其生效
/reload-plugins
```

安装后所有 skill 会自动可用，可通过 `/skill-name` 调用。

### 自动更新（推荐）

```bash
claude config set --user autoUpdatesEnabled true
```

### 手动更新

```bash
/plugin update a2c-smcp-toolkit@a2c-smcp-skills
```

## 包含的 Skill

| Skill | 说明 |
|-------|------|
| `/enhance-skill` | 反馈 Marketplace Skill 的问题或改进建议，自动提交 GitHub Issue |

## 内置 MCP 服务器

插件通过根目录 `.mcp.json` 自带一个 MCP 服务器，安装并 `/reload-plugins` 后自动启用，无需手动配置（在 `/mcp` 列表中标注为来自插件）。

| Server | 命令 | 用途 |
|--------|------|------|
| `tmux` | `npx -y tmux-mcp` | 控制 tmux 终端复用器，管理长时运行的开发环境、e2e 测试进程等 |

**前置依赖**：本机需安装 [Node.js](https://nodejs.org)（提供 `npx`）和 [tmux](https://github.com/tmux/tmux)。

**Shell 类型**：默认不指定 `--shell-type`，由 [tmux-mcp](https://github.com/nickgnd/tmux-mcp) 自动检测。如需固定 shell 类型，可手动覆盖：

```bash
claude mcp add --transport stdio tmux -- npx -y tmux-mcp --shell-type=zsh
```

## Skill 不好用？帮我们改进

使用 Skill 过程中如果发现流程不合理、步骤遗漏、或需要手动校准才能完成任务，欢迎反馈：

1. 先手动校准，把任务完成（优先保证工作不被阻塞）
2. 任务完成后（最佳时机），或校准完成后，在同一会话中执行 `/enhance-skill`
3. 它会自动提取当前会话上下文，生成改进建议并提交 GitHub Issue

你的每一次反馈都会让 Skill 变得更好。

## 添加新 Skill

1. 在 `skills/<skill-name>/` 下创建目录
2. 添加 `SKILL.md`（含 `name` 和 `description` frontmatter）
3. 可选：添加 `resources/` 存放项目差异化资源
4. 提交并推送到 main 分支

## 目录结构

```
skills/
└── my-skill/
    ├── SKILL.md              # Skill 定义（必需）
    └── resources/            # 项目差异化资源（可选）
        ├── python-sdk.md
        ├── rust-sdk.md
        └── ...
```
