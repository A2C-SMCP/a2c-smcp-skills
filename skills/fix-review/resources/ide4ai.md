# Fix Review — IDE4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 架构原则（修复时强制遵守）

- **安全约束**：命令白名单机制不可绕过或降级（🔴 级别）
- **LSP 集成**：注意多语言 LSP 差异和边界处理
- **协议约束**：纯 MCP 部分不受 A2C 约束，但 Computer 注册等行为须遵守协议

## 验证命令

```bash
uv run pytest          # 测试
uv run ruff check .    # Lint
```
