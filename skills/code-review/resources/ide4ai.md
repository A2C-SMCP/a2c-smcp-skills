# Code Review — IDE4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：A2C-SMCP/ide4ai
- **语言**：Python
- **架构**：高内聚低耦合，兼容 A2C-SMCP/MCP/Gymnasium 接口
- **安全**：命令白名单机制

## 项目特有审查维度

### 安全约束（🔴 级别）

- 命令白名单机制不可绕过或降级
- 新增终端相关功能时，检查是否经过白名单校验
- 不允许引入未受限的命令执行路径

### LSP 集成

修改代码导航功能时，注意多语言 LSP 的差异和边界处理。

### 协议约束

纯 MCP 工具部分不受 A2C 协议约束。但涉及 Computer 注册、工具列表上报等 A2C 行为时，仍需遵守协议。

## 测试覆盖度

```bash
uv run pytest --cov     # 带覆盖率
```

新增工具函数必须有对应测试。安全相关变更（白名单）须有边界测试覆盖。

## 验证命令

```bash
uv run pytest          # 测试
uv run ruff check .    # Lint
```
