#!/usr/bin/env python3
"""Tests for scripts/restore-role-state.py (assume-role SessionStart hook)."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/restore-role-state.py"
HOOKS = ROOT / "hooks/hooks.json"

RECORD = """---
role: sdk-developer          # protocol-owner / sdk-architect / sdk-developer
platform: claude-code
session_id: {sid}
pid: {pid}
repo: python-sdk
root: /repo
contract_version: v0.5
manager: arch-1
managed: []
tasks_since_reset: 2
updated: 2026-10-23 09:00
---
## 状态
- 当前任务：python-sdk#120
"""


class RestoreRoleStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.dir = self.home / "roles/sessions/python-sdk"
        self.dir.mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write(self, sid: str, pid: str) -> Path:
        path = self.dir / f"{sid}.md"
        path.write_text(RECORD.format(sid=sid, pid=pid), encoding="utf-8")
        return path

    def run_hook(self, source: str, session_id: str, pid: str, stdin: str | None = None) -> str:
        env = dict(os.environ, A2C_SMCP_HOME=str(self.home), CLAUDE_PID=pid)
        result = subprocess.run(
            [sys.executable, str(SCRIPT)],
            input=stdin if stdin is not None else json.dumps({"source": source, "session_id": session_id}),
            capture_output=True, text=True, env=env, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def context(self, stdout: str) -> str:
        return json.loads(stdout)["hookSpecificOutput"]["additionalContext"]

    def test_clear_moves_record_to_new_session_id_by_pid(self) -> None:
        old = self.write("old-id", "100")
        ctx = self.context(self.run_hook("clear", "new-id", "100"))
        self.assertIn("assume-role sdk-developer", ctx)
        self.assertIn("python-sdk#120", ctx)
        self.assertIn("契约 v0.5", ctx)
        self.assertFalse(old.exists())
        moved = (self.dir / "new-id.md").read_text(encoding="utf-8")
        self.assertIn("session_id: new-id", moved)
        self.assertIn("manager: arch-1", moved)
        self.assertIn("tasks_since_reset: 0", moved)
        self.assertIn("clear", moved.split("last_reset:")[1].splitlines()[0])
        self.assertIn("## 状态", moved)

    def test_compact_keeps_session_id(self) -> None:
        self.write("same-id", "100")
        self.assertIn("压缩", self.context(self.run_hook("compact", "same-id", "100")))
        self.assertTrue((self.dir / "same-id.md").exists())

    def test_resume_updates_pid_without_resetting_counter(self) -> None:
        self.write("same-id", "100")
        self.run_hook("resume", "same-id", "200")
        text = (self.dir / "same-id.md").read_text(encoding="utf-8")
        self.assertIn("pid: 200", text)
        self.assertIn("tasks_since_reset: 2", text)

    def test_silent_when_unregistered_or_startup(self) -> None:
        self.write("other-id", "100")
        self.assertEqual(self.run_hook("clear", "new-id", "999"), "")
        self.assertEqual(self.run_hook("startup", "other-id", "100"), "")

    def test_never_fails_on_bad_input(self) -> None:
        (self.dir / "broken.md").write_text("no frontmatter", encoding="utf-8")
        self.assertEqual(self.run_hook("", "", "1", stdin="not json"), "")

    def test_hook_registered_for_reset_sources(self) -> None:
        entry = json.loads(HOOKS.read_text(encoding="utf-8"))["hooks"]["SessionStart"][0]
        self.assertEqual(set(entry["matcher"].split("|")), {"clear", "compact", "resume"})
        self.assertIn("scripts/restore-role-state.py", entry["hooks"][0]["command"])


if __name__ == "__main__":
    unittest.main()
