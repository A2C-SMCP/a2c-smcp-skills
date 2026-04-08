#!/usr/bin/env bash
# Tests for smcp-env.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SMCP_ENV="$SCRIPT_DIR/skills/troubleshoot/scripts/smcp-env.sh"

# Use temp dir to isolate tests from real config
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"' EXIT

PASS=0
FAIL=0

assert_eq() {
  local desc=$1 expected=$2 actual=$3
  if [[ "$expected" == "$actual" ]]; then
    echo "[PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc=$1 pattern=$2 actual=$3
  if echo "$actual" | grep -q "$pattern"; then
    echo "[PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $desc"
    echo "  expected to contain: $pattern"
    echo "  actual: $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit() {
  local desc=$1 expected_code=$2
  shift 2
  local actual_code=0
  "$@" >/dev/null 2>&1 || actual_code=$?
  assert_eq "$desc" "$expected_code" "$actual_code"
}

# -------------------------------------------------------------------
echo "=== smcp-env.sh tests ==="
echo ""

# 1. help
echo "--- help ---"
output=$(bash "$SMCP_ENV" help 2>&1)
assert_contains "help shows usage" "smcp-env" "$output"
assert_contains "help lists projects" "python-sdk" "$output"
assert_contains "help lists config files" "dev-env.json" "$output"

# 2. show on non-existent config
echo "--- show (not found) ---"
output=$(bash "$SMCP_ENV" show dev 2>&1 || true)
assert_contains "show dev returns not found" "Config not found" "$output"
assert_exit "show dev exits 1 when missing" "1" bash "$SMCP_ENV" show dev

# 3. set local project
echo "--- set local ---"
local_dir="$HOME/fake-project"
mkdir -p "$local_dir"
output=$(bash "$SMCP_ENV" set dev python-sdk local "$local_dir" 2>&1)
assert_contains "set local confirms update" "Updated: python-sdk" "$output"

# 4. show after set
echo "--- show after set ---"
output=$(bash "$SMCP_ENV" show dev 2>&1)
assert_contains "show displays project" "python-sdk" "$output"
assert_contains "show displays local" "local" "$output"
assert_contains "show displays path" "$local_dir" "$output"

# 5. set remote project
echo "--- set remote ---"
output=$(bash "$SMCP_ENV" set dev office4ai remote test-server /opt/office4ai /var/log/office4ai 2>&1)
assert_contains "set remote confirms update" "Updated: office4ai" "$output"

# 6. show both projects
echo "--- show both ---"
output=$(bash "$SMCP_ENV" show dev 2>&1)
assert_contains "show has python-sdk" "python-sdk" "$output"
assert_contains "show has office4ai" "office4ai" "$output"
assert_contains "show has remote" "remote" "$output"
assert_contains "show has ssh connection" "test-server" "$output"

# 7. verify — local dir exists
echo "--- verify ---"
output=$(bash "$SMCP_ENV" verify dev 2>&1)
assert_contains "verify local OK" "[OK]" "$output"
assert_contains "verify remote SSH" "[SSH]" "$output"
assert_contains "verify all passed" "All checks passed" "$output"

# 8. verify — local dir missing
echo "--- verify (dir missing) ---"
rmdir "$local_dir"
output=$(bash "$SMCP_ENV" verify dev 2>&1 || true)
assert_contains "verify detects missing dir" "[FAIL]" "$output"
assert_contains "verify shows failure message" "directory not found" "$output"
assert_exit "verify exits 1 on failure" "1" bash "$SMCP_ENV" verify dev
mkdir -p "$local_dir"  # restore for subsequent tests

# 9. remove project
echo "--- remove ---"
output=$(bash "$SMCP_ENV" remove dev office4ai 2>&1)
assert_contains "remove confirms" "Removed: office4ai" "$output"
output=$(bash "$SMCP_ENV" show dev 2>&1)
assert_contains "show after remove still has python-sdk" "python-sdk" "$output"
# office4ai should be gone
if echo "$output" | grep -q "office4ai"; then
  echo "[FAIL] remove: office4ai still present"
  FAIL=$((FAIL + 1))
else
  echo "[PASS] remove: office4ai gone"
  PASS=$((PASS + 1))
fi

# 10. artifact mode is independent
echo "--- artifact mode isolation ---"
output=$(bash "$SMCP_ENV" show artifact 2>&1 || true)
assert_contains "artifact config independent" "Config not found" "$output"
bash "$SMCP_ENV" set artifact rust-sdk local "$local_dir" >/dev/null 2>&1
output=$(bash "$SMCP_ENV" show artifact 2>&1)
assert_contains "artifact has rust-sdk" "rust-sdk" "$output"
# dev config should be unchanged
output=$(bash "$SMCP_ENV" show dev 2>&1)
if echo "$output" | grep -q "rust-sdk"; then
  echo "[FAIL] mode isolation: rust-sdk leaked to dev"
  FAIL=$((FAIL + 1))
else
  echo "[PASS] mode isolation: dev unaffected"
  PASS=$((PASS + 1))
fi

# 11. invalid mode
echo "--- invalid mode ---"
assert_exit "invalid mode exits 1" "1" bash "$SMCP_ENV" show invalid

# 12. set missing args
echo "--- set missing args ---"
assert_exit "set without path exits 1" "1" bash "$SMCP_ENV" set dev python-sdk local
assert_exit "set remote missing args exits 1" "1" bash "$SMCP_ENV" set dev python-sdk remote ssh-conn /dir

# 13. JSON format validation
echo "--- JSON validity ---"
jq_valid=0
jq '.' "$HOME/.a2c_smcp/dev-env.json" >/dev/null 2>&1 && jq_valid=1
assert_eq "dev-env.json is valid JSON" "1" "$jq_valid"
jq_valid=0
jq '.' "$HOME/.a2c_smcp/artifact-env.json" >/dev/null 2>&1 && jq_valid=1
assert_eq "artifact-env.json is valid JSON" "1" "$jq_valid"

# 14. updated_at is set
echo "--- updated_at ---"
updated=$(jq -r '.updated_at' "$HOME/.a2c_smcp/dev-env.json")
today=$(date +%Y-%m-%d)
assert_eq "updated_at is today" "$today" "$updated"

# -------------------------------------------------------------------
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
