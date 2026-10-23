# SDK 差异：rust-sdk（SMCP 生产实现）

| 项 | 值 |
|----|----|
| GitHub | `A2C-SMCP/rust-sdk` |
| 分支 | 集成分支 `develop`，发布分支 `main` |
| 协议版本声明 | `crates/smcp/src/lib.rs` 的 `PROTOCOL_VERSION`（X.Y 须与 `contract_version` 一致，`release` Step 1 校验） |
| Workspace | `crates/{smcp, smcp-agent, smcp-computer, smcp-client-transport, smcp-server-core, smcp-server-hyper}` |
| 对称 SDK | python-sdk（见 [python-sdk.md](python-sdk.md)） |

## 常用命令

```bash
cargo test-ws              # 全 workspace（cargo-nextest）
cargo test-computer        # 只测 smcp-computer（--features cli）
cargo test-agent           # 只测 smcp-agent
cargo test-e2e             # e2e（--ignored）
cargo fmt-all && cargo clippy-workspace
cargo test --package <crate> <test_name>
```

## 一致性测试与向量

| 类别 | 位置 |
|------|------|
| 向量 vendored 副本 | `crates/smcp-computer/tests/fixtures/*_conformance_vectors.json`（协议仓 `docs/specification/fixtures/` 的**逐字节副本**，`include_str!` 编译期内嵌） |
| 向量对拍测试 | `crates/smcp-computer/tests/*_conformance.rs` |
| 协议行为一致性 | `crates/smcp-agent/tests/protocol_conformance.rs` |
| 与 python-sdk 的对拍 | `crates/smcp-computer/tests/python_rust_alignment.rs` |

```bash
cargo test --package smcp-computer --features cli conformance
cargo test --package smcp-computer --features cli --test python_rust_alignment
cargo test --package smcp-agent --test protocol_conformance
```

## 对齐状态采集（sdk-architect / sdk-developer 的 save-status 使用）

```bash
P=<协议仓路径>; git -C "$P" fetch -q origin develop
# 1. vendored 副本与协议 develop 是否逐字节一致；协议有而本仓没有的向量
for f in $(git -C "$P" ls-tree --name-only origin/develop docs/specification/fixtures/ | xargs -n1 basename); do
  local_f="crates/smcp-computer/tests/fixtures/$f"
  if [ ! -f "$local_f" ]; then echo "MISSING $f"
  elif git -C "$P" show "origin/develop:docs/specification/fixtures/$f" | cmp -s - "$local_f"; then echo "SAME $f"
  else echo "STALE $f"; fi
done
# 2. 本仓有而协议没有的向量（可能是未上收协议的共享约定）
ls crates/smcp-computer/tests/fixtures/*_conformance_vectors.json
```

`STALE` → 从协议 develop 重新同步（`include_str!` 内嵌，改后须重新编译测试）；`MISSING` → 数据向量：本仓尚未对拍，需建跟进 Issue；场景向量（如 `auth_error`，core-governance §6）不要求副本，改为核对每一景有映射用例（`grep -rn '<向量 desc 关键词>' crates/`）；本仓独有 → 交架构师判断是否应上收协议（`契约问询`）。
