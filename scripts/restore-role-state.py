#!/usr/bin/env python3
"""SessionStart hook：/clear、/compact、--resume 后按团队登记恢复 assume-role 角色状态。

只处理 assume-role 写下的登记（$A2C_SMCP_HOME/roles/sessions/<仓库名>/<会话 ID>.md，默认 ~/.a2c-smcp）：
- clear：同一进程换了新会话 ID，按 CLAUDE_PID 找到前身，改写为新会话 ID 后注入状态；
- compact：会话 ID 不变，直接注入状态；
- resume：新进程，按会话 ID 找到登记并更新 pid 后注入状态。
注入的是「先执行 assume-role 再核实」的提示与状态正文，不注入角色卡本身——角色卡与治理规则可能已更新，
由 assume-role 重新读取最新版本。找不到登记或出现任何异常都静默退出，绝不阻断会话启动。
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

MAX_CONTEXT = 9000  # additionalContext 单条上限 10,000 字符，留出说明文字的余量
FIELD = re.compile(r"^([A-Za-z_]+):[ \t]*(.*?)[ \t]*(?:#.*)?$")

REASONS = {
    "clear": "上下文已被 /clear 清空",
    "compact": "上下文已被压缩，角色卡与规则可能只剩摘要",
    "resume": "会话从历史恢复，状态可能已过时",
}


def registry_root() -> Path:
    home = os.environ.get("A2C_SMCP_HOME") or str(Path.home() / ".a2c-smcp")
    return Path(home) / "roles" / "sessions"


def parse(path: Path) -> tuple[dict[str, str], list[str], str] | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    head = text[4:end].split("\n")
    fields = {}
    for line in head:
        m = FIELD.match(line)
        if m:
            fields[m.group(1)] = m.group(2)
    return fields, head, text[end + 5:]


def set_fields(head: list[str], updates: dict[str, str]) -> list[str]:
    out, seen = [], set()
    for line in head:
        m = FIELD.match(line)
        if m and m.group(1) in updates:
            out.append(f"{m.group(1)}: {updates[m.group(1)]}")
            seen.add(m.group(1))
        else:
            out.append(line)
    out += [f"{k}: {v}" for k, v in updates.items() if k not in seen]
    return out


def find(root: Path, key: str, value: str) -> tuple[Path, dict, list, str] | None:
    if not value or not root.is_dir():
        return None
    for path in sorted(root.glob("*/*.md")):
        try:
            parsed = parse(path)
        except (OSError, UnicodeDecodeError):
            continue
        if parsed and parsed[0].get(key) == value:
            return (path, *parsed)
    return None


def main() -> None:
    event = json.load(sys.stdin)
    source = event.get("source")
    session_id = event.get("session_id") or ""
    pid = os.environ.get("CLAUDE_PID", "")
    root = registry_root()

    if source == "clear":
        hit = find(root, "pid", pid)
        if hit and hit[1].get("session_id") == session_id:
            hit = None
    elif source in ("compact", "resume"):
        hit = find(root, "session_id", session_id)
    else:
        return
    if not hit:
        return

    path, fields, head, body = hit
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    updates = {"session_id": session_id, "pid": pid or fields.get("pid", "")}
    if source in ("clear", "compact"):
        updates["last_reset"] = f"{now} {source}"
        updates["tasks_since_reset"] = "0"
    head = set_fields(head, updates)
    target = path.with_name(f"{session_id}.md")
    target.write_text("---\n" + "\n".join(head) + "\n---\n" + body, encoding="utf-8")
    if target != path:
        path.unlink()

    role = fields.get("role", "?")
    state = body.strip() or "（登记中没有保存状态）"
    if len(state) > MAX_CONTEXT:
        state = state[:MAX_CONTEXT] + f"\n……（已截断，完整内容见 {target}）"
    context = (
        f"【assume-role 恢复】本会话在团队登记中的角色是 `{role}`（仓库 {fields.get('repo', '?')}，"
        f"契约 {fields.get('contract_version') or '?'}，上级 {fields.get('manager') or '无'}）。{REASONS[source]}。\n"
        f"处理下一条消息前，先调用 `assume-role {role}` 恢复角色（它会读回下面的状态），"
        "并对照 Git、GitHub 与一致性测试核实状态中的分支、PR、Issue 与对齐状态是否仍然如此；以实际情况为准，"
        "不要直接执行状态里记录的未完成写操作。登记文件："
        f"{target}\n\n{state}"
    )
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:  # noqa: BLE001 - 恢复失败不能阻断会话启动
        pass
    sys.exit(0)
