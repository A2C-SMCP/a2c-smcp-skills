# Troubleshoot — Issue 提报模板

> 排查完成后，用此模板在根因归属项目的 GitHub 仓库提报 Issue。

## 仓库映射

| 项目名 | GitHub 仓库 |
|--------|------------|
| python-sdk | A2C-SMCP/python-sdk |
| rust-sdk | A2C-SMCP/rust-sdk |
| a2c-smcp-protocol | A2C-SMCP/a2c-smcp-protocol |
| office4ai | JIAQIA/office4ai |
| ide4ai | A2C-SMCP/ide4ai |
| oasp-protocol | A2C-SMCP/oasp-protocol |
| office-editor4ai | JIAQIA/office-editor4ai |
| tfrobot-client | A2C-SMCP/tfrobot-client |

## 提报命令

```bash
gh issue create --repo <owner>/<repo> \
  --title "[Troubleshoot] <问题简述>" \
  --label "bug" \
  --body "$(cat <<'EOF'
## 问题概述

<一句话描述问题现象>

## 环境信息

- 排查模式：dev / artifact
- 环境配置：`~/.a2c_smcp/{mode}-env.json`
- 涉及项目运行位置：local / remote

## 排查过程

### 故障区间

<数据流中哪两个节点之间，如 Computer ↔ MCP Server>

### 关键日志

```
<关键日志片段，只保留核心部分>
```

### 已排除的方向

- <方向 1>：<排除依据>
- <方向 2>：<排除依据>

## 根因定位

- **归属项目**：<project-name>
- **层级**：协议 / 配置 / 代码逻辑 / 依赖版本
- **证据**：<具体的日志、代码位置或配置证据>

## 修复建议

<建议的修复方向和方案>

## 关联项目

<跨项目问题时，列出其他相关项目及角色>

- Related: owner/repo#N

EOF
)"
```

## 注意事项

- Issue title 以 `[Troubleshoot]` 前缀标识来源
- 日志片段只保留关键部分，避免 Issue 过长
- 跨项目问题：主 Issue 建在根因项目，用 `Related: owner/repo#N` 关联
- 注意 owner 区分：office4ai 和 office-editor4ai 在 JIAQIA 组织下，其余在 A2C-SMCP 下
