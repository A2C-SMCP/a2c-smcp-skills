# Code Review — Python SDK 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- **语言**：Python 3.11+，uv 管理
- **架构**：三模块（Agent/Server/Computer）同步/异步双实现
- **协议定义**：smcp.py（TypedDict）+ model.py（Pydantic）双文件

## 模块边界

分层方向严格单向。检查变更是否引入违反依赖方向的导入。

## DRY 重点检查

- **同步/异步双实现**：修改异步版本时，同步版本必须同步更新（反之亦然）
- **协议双文件**：smcp.py（TypedDict）↔ model.py（Pydantic）必须字段一致
- 检查 `a2c_smcp/utils/` 下已有工具是否被忽略

## 项目特有审查维度

### 类型注解完整性

mypy strict 模式，所有变更必须检查：
- 函数签名有完整类型注解（参数 + 返回值）
- 使用 `str | None` 而非 `Optional[str]`（Python 3.10+ 风格）

### Ruff 规则

规则集 `["E", "W", "F", "I", "B", "C4", "UP"]`，关注：
- `I`（isort）：导入顺序
- `UP`：现代 Python 语法
- `B`：bugbear 检查

## 测试约定

| 约定 | 检查点 |
|------|--------|
| 测试组织 | unit_tests / integration_tests / e2e 三层 |
| 异步测试 | `asyncio_mode = "auto"`，无需手动标记 |
| 测试命名 | `Test<Subject>` 类 + `test_<scenario>` 方法 |

## 测试覆盖度

```bash
uv run poe test-cov    # 带覆盖率的测试（如可用）
uv run pytest --cov=a2c_smcp --cov-report=term-missing
```

变更不得导致覆盖率下降。新增模块须有对应的单元测试文件。

## 验证命令

```bash
uv run poe test     # 全量测试
uv run poe lint     # ruff + mypy
```
