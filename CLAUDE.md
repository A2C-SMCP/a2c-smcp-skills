# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A2C-SMCP 开源项目的 Claude Code Plugin Marketplace。用户通过 `claude plugin add` 添加本仓库后，SKILL 会自动安装。托管在 GitHub (github.com/A2C-SMCP/a2c-smcp-skills)。

## Architecture

- `.claude-plugin/marketplace.json` — Marketplace 注册中心，定义单一插件 `a2c-smcp-toolkit`
- `.claude/skills/` — 本项目的开发工具 Skill（如 `create-skill`），不分发
- `skills/` — 分发给各项目的 Skill，每个子目录含 `SKILL.md`，通过 Claude Code 自动发现机制加载

## Skill 开发规范

本项目开发的 Skill 供所有 A2C-SMCP 项目共同使用，因此必须遵循跨项目设计原则：

- **共性放主文件**：SKILL.md 只放所有项目通用的流程和步骤
- **差异放 resources/**：按项目拆分 resource 文件（如 `resources/python-sdk.md`），记录语言/框架/架构差异
- **引用胜于嵌入**：当前项目内的文件用 Markdown 链接引用；跨项目内容必须嵌入 resource 文件
- **实践基础**：至少在一个项目中有经过验证的实践，才创建 Skill
- **gh CLI 依赖**：涉及 GitHub Issue/PR/CI 的 Skill 通过 `gh` 命令行操作，运行时检查可用性

使用 `/create-skill` 来创建新的跨项目 Skill。

## Marketplace 注册原则

`.claude/skills/` 下的 Skill（如 `create-skill`）是本项目的**开发工具**，不注册到 marketplace。`skills/` 目录下的 Skill 通过 `a2c-smcp-toolkit` 插件自动发现并分发，无需手动注册。

## Adding a Skill

1. 在 `skills/<skill-name>/` 下创建目录
2. 添加 `skills/<skill-name>/SKILL.md`（含 YAML frontmatter）
3. 可选：添加 `skills/<skill-name>/resources/` 存放项目差异化资源
4. 提交推送到 main 分支，用户通过 `/plugin update` 获取更新

## Related A2C-SMCP Repositories (GitHub)

开发 SKILL 时可能需要访问以下仓库。开发者必须在 Claude Code 中通过 `/add-dir` 添加所有仓库目录并授权，缺一不可：

### Core（SDK & Protocol）

| 仓库 | GitHub | 语言 | 说明 |
|------|--------|------|------|
| python-sdk | A2C-SMCP/python-sdk | Python | SMCP Python SDK（参考实现） |
| rust-sdk | A2C-SMCP/rust-sdk | Rust | SMCP Rust SDK（生产实现） |
| a2c-smcp-protocol | A2C-SMCP/a2c-smcp-protocol | Docs/Python | SMCP 协议规范 |

### Computer 官方内置 MCP 工具

| 仓库 | GitHub | 语言 | 说明 |
|------|--------|------|------|
| office4ai | JIAQIA/office4ai | Python | Office 文档 MCP Server（Word 工具集） |
| ide4ai | A2C-SMCP/ide4ai | Python | AI IDE 工具（代码导航/编辑/LSP/终端） |
| oasp-protocol | A2C-SMCP/oasp-protocol | Docs/Python | Office AddIn Socket Protocol 规范 |
| office-editor4ai | JIAQIA/office-editor4ai | TypeScript | Office 加载项（Word/Excel/PPT Add-Ins） |

### Computer 客户端

| 仓库 | GitHub | 语言 | 说明 |
|------|--------|------|------|
| tfrobot-client | A2C-SMCP/tfrobot-client | Rust/TS (Tauri) | Computer 跨平台桌面客户端 |

## Prerequisite Check

在开发任何 SKILL 之前，必须预检使用者是否已通过 permissions 授权了上述所有仓库目录。如有缺失则拒绝执行，并要求用户补全权限。
