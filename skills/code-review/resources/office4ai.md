# Code Review — Office4AI 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **GitHub**：JIAQIA/office4ai
- **语言**：Python，uv 管理
- **架构**：MCP Server + Gymnasium 环境，LibreOffice UNO Bridge
- **协议**：实现 OASP 协议 Server 端

## 模块边界

分层方向严格单向：
```
office/mcp/server.py → a2c_smcp/tools/ → environment/workspace/socketio/ → dtos/
```
检查是否引入了反向依赖（如 DTO 层依赖 Tool 层）。

## DRY 重点检查

- **Tool 开发**：继承 `BaseTool`，声明六属性，不绕过 `BaseTool.execute()` 执行链
- **DTO 模型**：继承 `SocketIOBaseModel`（非裸 `BaseModel`）
- **MCP Input**：复用 DTO 层已有嵌套类型，不在 Tool Input 中重新定义
- **测试 Mock**：复用 `mock_workspace` fixture、`MockAddInClient`

## 项目特有审查维度

### DTO 规范（🔴 级别）

序列化不一致会导致 Add-In 端运行时崩溃：

| 规则 | 正确 | 违规 |
|------|------|------|
| Python 字段 snake_case | `font_size: int` | `fontSize: int` |
| Wire format camelCase alias | `Field(..., alias="fontSize")` | 无 alias |
| 可选字段有默认值 | `Field(default=None, alias="x")` | `Field(..., alias="x")` |
| 嵌套选项继承 SocketIOBaseModel | `class X(SocketIOBaseModel)` | `class X(BaseModel)` |

### 类型注解 + Ruff

mypy `disallow_untyped_defs = true`，函数签名必须完整注解。日志用 `loguru.logger`。

## 测试约定

| 约定 | 检查点 |
|------|--------|
| 组织 | unit_tests / integration_tests / contract_tests 三层 |
| 异步 | asyncio_mode = "auto" |
| Contract | MockAddInClient + factories 端到端验证 |

## 测试覆盖度

```bash
poe test-cov       # 带覆盖率的测试
```

新增 MCP Tool 必须有单元测试。新增 Socket.IO 事件必须有 Contract 测试。覆盖率不得下降。

## 验证命令

```bash
poe check          # lint + format-check + typecheck
poe test-unit      # 单元测试
poe test-contract  # 契约测试
```
