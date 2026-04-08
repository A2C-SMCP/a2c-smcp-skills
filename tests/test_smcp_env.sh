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

# ====================== Agent commands ======================

# 15. show-agent when no agent configured
echo "--- show-agent (not configured) ---"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1 || true)
assert_contains "show-agent shows no agent" "No agent configured" "$output"
assert_exit "show-agent exits 1 when empty" "1" bash "$SMCP_ENV" show-agent dev

# 16. set-agent local with supervisord
echo "--- set-agent local supervisord ---"
output=$(bash "$SMCP_ENV" set-agent dev turingfocus supervisord local service=tfrobot-server log_path=/var/log/tf 2>&1)
assert_contains "set-agent confirms" "Updated agent" "$output"
assert_contains "set-agent shows type" "turingfocus" "$output"

# 17. show-agent after set
echo "--- show-agent after set ---"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1)
assert_contains "show-agent has type" "turingfocus" "$output"
assert_contains "show-agent has deployment" "supervisord" "$output"
assert_contains "show-agent has location" "local" "$output"
assert_contains "show-agent has config key" "service" "$output"
assert_contains "show-agent has config value" "tfrobot-server" "$output"

# 18. show includes agent section
echo "--- show includes agent ---"
output=$(bash "$SMCP_ENV" show dev 2>&1)
assert_contains "show has Agent header" "Agent" "$output"
assert_contains "show has agent type" "turingfocus" "$output"

# 19. verify includes agent
echo "--- verify includes agent ---"
output=$(bash "$SMCP_ENV" verify dev 2>&1 || true)
assert_contains "verify shows agent" "agent" "$output"
assert_contains "verify agent local OK" "[OK]" "$output"

# 20. set-agent remote with k8s
echo "--- set-agent remote k8s ---"
output=$(bash "$SMCP_ENV" set-agent dev turingfocus k8s remote prod-server namespace=tf-prod pod_selector=app=tfrobot 2>&1)
assert_contains "set-agent remote confirms" "Updated agent" "$output"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1)
assert_contains "show-agent k8s deployment" "k8s" "$output"
assert_contains "show-agent has ssh" "prod-server" "$output"
assert_contains "show-agent has namespace" "tf-prod" "$output"
assert_contains "show-agent has pod_selector" "app=tfrobot" "$output"

# 21. verify agent remote
echo "--- verify agent remote ---"
output=$(bash "$SMCP_ENV" verify dev 2>&1 || true)
assert_contains "verify agent remote SSH" "[SSH]" "$output"
assert_contains "verify agent deployment" "k8s" "$output"

# 22. set-agent docker
echo "--- set-agent docker ---"
output=$(bash "$SMCP_ENV" set-agent dev turingfocus docker remote staging container=tf-server log_path=/var/log/tf 2>&1)
assert_contains "set-agent docker confirms" "Updated agent" "$output"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1)
assert_contains "show-agent docker" "docker" "$output"
assert_contains "show-agent container" "tf-server" "$output"

# 23. remove-agent
echo "--- remove-agent ---"
output=$(bash "$SMCP_ENV" remove-agent dev 2>&1)
assert_contains "remove-agent confirms" "Removed agent" "$output"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1 || true)
assert_contains "show-agent after remove" "No agent configured" "$output"

# 24. agent in artifact mode is independent
echo "--- agent mode isolation ---"
bash "$SMCP_ENV" set-agent artifact turingfocus k8s local namespace=tf-staging >/dev/null 2>&1
output=$(bash "$SMCP_ENV" show-agent artifact 2>&1)
assert_contains "artifact agent exists" "turingfocus" "$output"
output=$(bash "$SMCP_ENV" show-agent dev 2>&1 || true)
assert_contains "dev agent still empty" "No agent configured" "$output"

# 25. invalid deployment
echo "--- invalid deployment ---"
assert_exit "invalid deployment exits 1" "1" bash "$SMCP_ENV" set-agent dev turingfocus invalid local

# 26. set-agent remote missing ssh
echo "--- set-agent remote missing ssh ---"
assert_exit "set-agent remote without ssh exits 1" "1" bash "$SMCP_ENV" set-agent dev turingfocus k8s remote

# 27. JSON structure after agent operations
echo "--- JSON structure ---"
has_agent_field=$(jq 'has("agent")' "$HOME/.a2c_smcp/dev-env.json")
assert_eq "dev config has agent field" "true" "$has_agent_field"
has_version=$(jq '.version' "$HOME/.a2c_smcp/dev-env.json")
assert_eq "dev config version is 2" "2" "$has_version"

# -------------------------------------------------------------------
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
