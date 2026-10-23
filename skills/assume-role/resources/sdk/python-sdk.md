# SDK 差异：python-sdk（SMCP 参考实现）

| 项 | 值 |
|----|----|
| GitHub | `A2C-SMCP/python-sdk` |
| 分支 | 集成分支 `develop`，发布分支 `main` |
| 协议版本声明 | `a2c_smcp/__init__.py` 的 `PROTOCOL_VERSION`（X.Y 须与 `contract_version` 一致，`release` Step 1 校验） |
| 对称 SDK | rust-sdk（见 [rust-sdk.md](rust-sdk.md)） |

## 常用命令

```bash
uv sync --all-groups
uv run poe test                 # 全量单元测试
uv run poe test-e2e             # e2e
uv run poe lint && uv run poe typecheck
uv run pytest tests/unit_tests/path/to/test_file.py::test_name
```

## 一致性测试与向量

| 类别 | 位置 |
|------|------|
| 向量 vendored 副本 | `tests/unit_tests/utils/fixtures/*_conformance_vectors.json`（协议仓 `docs/specification/fixtures/` 的**逐字节副本**） |
| 向量对拍测试 | `tests/unit_tests/utils/test_*_conformance.py` |
| 协议行为一致性 | `tests/integration_tests/server/test_*_conformance.py` |

```bash
uv run pytest tests/unit_tests/utils -k conformance -q
uv run pytest tests/integration_tests -k conformance -q
```

## 对齐状态采集（sdk-architect / sdk-developer 的 save-status 使用）

```bash
P=<协议仓路径>; git -C "$P" fetch -q origin develop
# 1. vendored 副本与协议 develop 是否逐字节一致；协议有而本仓没有的向量
for f in $(git -C "$P" ls-tree --name-only origin/develop docs/specification/fixtures/ | xargs -n1 basename); do
  local_f="tests/unit_tests/utils/fixtures/$f"
  if [ ! -f "$local_f" ]; then echo "MISSING $f"
  elif git -C "$P" show "origin/develop:docs/specification/fixtures/$f" | cmp -s - "$local_f"; then echo "SAME $f"
  else echo "STALE $f"; fi
done
# 2. 本仓有而协议没有的向量（可能是未上收协议的共享约定）
ls tests/unit_tests/utils/fixtures/*_conformance_vectors.json
```

`STALE` → 按测试文件头注释从协议 develop 重新同步；`MISSING` → 数据向量：本仓尚未对拍，需建跟进 Issue；场景向量（如 `auth_error`，core-governance §6）不要求副本，改为核对每一景有映射用例（`grep -rn '<向量 desc 关键词>' tests/`）；本仓独有 → 交架构师判断是否应上收协议（`契约问询`）。
