#!/usr/bin/env bash
# smcp-env — manage A2C-SMCP troubleshoot environment configs
# Config location: ~/.a2c_smcp/{mode}-env.json
set -euo pipefail

SMCP_DIR="$HOME/.a2c_smcp"
KNOWN_PROJECTS=(python-sdk rust-sdk a2c-smcp-protocol office4ai ide4ai oasp-protocol office-editor4ai tfrobot-client)
KNOWN_DEPLOYMENTS=(supervisord docker k8s)

# --- helpers ---

die()  { echo "Error: $*" >&2; exit 1; }
env_file() { echo "$SMCP_DIR/${1}-env.json"; }
ensure_dir() { mkdir -p "$SMCP_DIR"; }

validate_mode() {
  [[ "$1" == "dev" || "$1" == "artifact" ]] || die "mode must be 'dev' or 'artifact', got '$1'"
}

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required. Install: brew install jq"
}

validate_deployment() {
  local d=$1
  for known in "${KNOWN_DEPLOYMENTS[@]}"; do
    [[ "$d" == "$known" ]] && return 0
  done
  die "deployment must be one of: ${KNOWN_DEPLOYMENTS[*]}, got '$d'"
}

# Ensure config file exists with base structure (version, agent, projects)
ensure_file() {
  local file=$1
  if [[ ! -f "$file" ]]; then
    echo '{"version": 2, "updated_at": "", "agent": null, "projects": {}}' > "$file"
  fi
  # Migrate v1 → v2: add agent field if missing
  if ! jq -e '.agent' "$file" >/dev/null 2>&1; then
    jq '.version = 2 | .agent = null' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

# --- commands ---

cmd_show() {
  local mode=$1
  validate_mode "$mode"
  local file
  file=$(env_file "$mode")
  if [[ ! -f "$file" ]]; then
    echo "Config not found: $file"
    echo "Run: smcp-env init $mode"
    return 1
  fi

  echo "=== $mode environment ($file) ==="
  echo ""

  local projects
  projects=$(jq -r '.projects | to_entries[] | "\(.key)\t\(.value.location)\t\(.value.path // "-")\t\(.value.ssh_connection // "-")\t\(.value.project_dir // "-")\t\(.value.log_path // "-")"' "$file")

  if [[ -z "$projects" ]]; then
    echo "(no projects configured)"
    return 0
  fi

  printf "%-20s %-8s %-35s %-15s %-25s %s\n" "PROJECT" "LOCATION" "PATH" "SSH_CONN" "PROJECT_DIR" "LOG_PATH"
  printf "%-20s %-8s %-35s %-15s %-25s %s\n" "-------" "--------" "----" "--------" "-----------" "--------"

  while IFS=$'\t' read -r name loc path ssh pdir lpath; do
    printf "%-20s %-8s %-35s %-15s %-25s %s\n" "$name" "$loc" "$path" "$ssh" "$pdir" "$lpath"
  done <<< "$projects"

  # Show agent info if configured
  local agent
  agent=$(jq -r '.agent // "null"' "$file" 2>/dev/null)
  if [[ "$agent" != "null" ]]; then
    echo ""
    echo "--- Agent ---"
    local atype adeploy aloc assh
    atype=$(jq -r '.agent.type' "$file")
    adeploy=$(jq -r '.agent.deployment' "$file")
    aloc=$(jq -r '.agent.location' "$file")
    assh=$(jq -r '.agent.ssh_connection // "-"' "$file")
    printf "%-15s %-12s %-8s %-15s" "$atype" "$adeploy" "$aloc" "$assh"
    # Show config keys inline
    local cfg
    cfg=$(jq -r '.agent.config // {} | to_entries | map("\(.key)=\(.value)") | join(" ")' "$file")
    [[ -n "$cfg" ]] && printf "  %s" "$cfg"
    echo ""
  fi

  echo ""
  echo "updated_at: $(jq -r '.updated_at' "$file")"
}

cmd_init() {
  local mode=$1
  validate_mode "$mode"
  ensure_dir
  local file
  file=$(env_file "$mode")

  if [[ -f "$file" ]]; then
    echo "Config already exists: $file"
    read -rp "Overwrite? [y/N]: " yn
    [[ "$yn" =~ ^[Yy] ]] || { echo "Aborted."; exit 0; }
  fi

  echo "Initializing $mode environment config..."
  echo "Config file: $file"
  echo ""
  echo "Projects: ${KNOWN_PROJECTS[*]}"
  echo "Press Enter to skip a project."
  echo ""

  local projects="{}"
  for project in "${KNOWN_PROJECTS[@]}"; do
    read -rp "Configure $project? [y/N]: " yn
    [[ "$yn" =~ ^[Yy] ]] || continue

    read -rp "  Location (local/remote) [local]: " location
    location=${location:-local}

    if [[ "$location" == "local" ]]; then
      read -rp "  Local path: " path
      if [[ -z "$path" ]]; then
        echo "  Skipped (no path)."
        continue
      fi
      projects=$(echo "$projects" | jq \
        --arg p "$project" --arg v "$path" \
        '.[$p] = {"location": "local", "path": $v}')

    elif [[ "$location" == "remote" ]]; then
      read -rp "  SSH connection name (SSH MCP): " ssh_conn
      read -rp "  Remote project dir: " project_dir
      read -rp "  Remote log path: " log_path
      if [[ -z "$ssh_conn" ]]; then
        echo "  Skipped (no ssh connection)."
        continue
      fi
      projects=$(echo "$projects" | jq \
        --arg p "$project" --arg sc "$ssh_conn" \
        --arg pd "$project_dir" --arg lp "$log_path" \
        '.[$p] = {"location": "remote", "ssh_connection": $sc, "project_dir": $pd, "log_path": $lp}')
    else
      echo "  Invalid location '$location', skipped."
    fi
  done

  local today
  today=$(date +%Y-%m-%d)
  echo "{}" | jq \
    --argjson projects "$projects" --arg date "$today" \
    '{"version": 1, "updated_at": $date, "projects": $projects}' > "$file"

  echo ""
  echo "Saved to $file"
  cmd_show "$mode"
}

cmd_set() {
  local mode=$1 project=$2 location=$3
  validate_mode "$mode"
  ensure_dir
  local file
  file=$(env_file "$mode")

  ensure_file "$file"

  local today
  today=$(date +%Y-%m-%d)

  if [[ "$location" == "local" ]]; then
    local path=${4:?"Usage: smcp-env set <mode> <project> local <path>"}
    jq --arg p "$project" --arg v "$path" --arg d "$today" \
      '.updated_at = $d | .projects[$p] = {"location": "local", "path": $v}' \
      "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  elif [[ "$location" == "remote" ]]; then
    local ssh_conn=${4:?"Usage: smcp-env set <mode> <project> remote <ssh_conn> <project_dir> <log_path>"}
    local project_dir=${5:?"Missing project_dir"}
    local log_path=${6:?"Missing log_path"}
    jq --arg p "$project" --arg sc "$ssh_conn" \
       --arg pd "$project_dir" --arg lp "$log_path" --arg d "$today" \
      '.updated_at = $d | .projects[$p] = {"location": "remote", "ssh_connection": $sc, "project_dir": $pd, "log_path": $lp}' \
      "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    die "location must be 'local' or 'remote', got '$location'"
  fi

  echo "Updated: $project ($location) in $file"
}

cmd_remove() {
  local mode=$1 project=$2
  validate_mode "$mode"
  local file
  file=$(env_file "$mode")
  [[ -f "$file" ]] || die "Config not found: $file"

  local today
  today=$(date +%Y-%m-%d)
  jq --arg p "$project" --arg d "$today" \
    '.updated_at = $d | del(.projects[$p])' \
    "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  echo "Removed: $project from $file"
}

cmd_verify() {
  local mode=$1
  validate_mode "$mode"
  local file
  file=$(env_file "$mode")
  [[ -f "$file" ]] || die "Config not found: $file"

  echo "=== Verifying $mode environment ==="
  echo ""

  local has_error=0
  local entries
  entries=$(jq -r '.projects | to_entries[] | "\(.key)\t\(.value.location)\t\(.value.path // "-")\t\(.value.ssh_connection // "-")"' "$file")

  while IFS=$'\t' read -r name loc path ssh; do
    if [[ "$loc" == "local" ]]; then
      if [[ "$path" != "-" && -d "$path" ]]; then
        echo "[OK]    $name  local  $path"
      else
        echo "[FAIL]  $name  local  $path  (directory not found)"
        has_error=1
      fi
    elif [[ "$loc" == "remote" ]]; then
      if [[ "$ssh" != "-" && -n "$ssh" ]]; then
        echo "[SSH]   $name  remote  ssh_connection=$ssh  (verify via SSH MCP list-servers)"
      else
        echo "[FAIL]  $name  remote  (missing ssh_connection)"
        has_error=1
      fi
    fi
  done <<< "$entries"

  # Verify agent
  local agent
  agent=$(jq -r '.agent' "$file" 2>/dev/null)
  if [[ "$agent" != "null" ]]; then
    local aloc assh adeploy
    aloc=$(jq -r '.agent.location' "$file")
    assh=$(jq -r '.agent.ssh_connection // "-"' "$file")
    adeploy=$(jq -r '.agent.deployment' "$file")
    if [[ "$aloc" == "local" ]]; then
      echo "[OK]    agent  local  deployment=$adeploy"
    elif [[ "$aloc" == "remote" && "$assh" != "-" ]]; then
      echo "[SSH]   agent  remote  ssh_connection=$assh  deployment=$adeploy  (verify via SSH MCP)"
    else
      echo "[FAIL]  agent  remote  (missing ssh_connection)"
      has_error=1
    fi
  fi

  echo ""
  if [[ $has_error -eq 1 ]]; then
    echo "Some checks failed. Use 'smcp-env set' or 'smcp-env set-agent' to fix."
    return 1
  else
    echo "All checks passed."
  fi
}

# --- agent commands ---

cmd_show_agent() {
  local mode=$1
  validate_mode "$mode"
  local file
  file=$(env_file "$mode")
  [[ -f "$file" ]] || die "Config not found: $file"

  local agent
  agent=$(jq -r '.agent' "$file")
  if [[ "$agent" == "null" ]]; then
    echo "No agent configured in $mode environment."
    echo "Run: smcp-env set-agent $mode <type> <deployment> <location> [key=value...]"
    return 1
  fi

  echo "=== $mode agent ==="
  local type deploy loc ssh
  type=$(jq -r '.agent.type' "$file")
  deploy=$(jq -r '.agent.deployment' "$file")
  loc=$(jq -r '.agent.location' "$file")
  ssh=$(jq -r '.agent.ssh_connection // "-"' "$file")

  echo "  Type:       $type"
  echo "  Deployment: $deploy"
  echo "  Location:   $loc"
  [[ "$ssh" != "-" ]] && echo "  SSH Conn:   $ssh"

  # Show deployment-specific config
  local config
  config=$(jq -r '.agent.config // {} | to_entries[] | "  \(.key): \(.value)"' "$file")
  [[ -n "$config" ]] && echo "$config"
}

# Usage: smcp-env set-agent <mode> <type> <deployment> local|remote [ssh_conn] [key=value...]
cmd_set_agent() {
  local mode=$1 agent_type=$2 deployment=$3 location=$4
  validate_mode "$mode"
  validate_deployment "$deployment"
  ensure_dir
  local file
  file=$(env_file "$mode")
  ensure_file "$file"

  local today ssh_conn="" config="{}"
  today=$(date +%Y-%m-%d)

  # Parse remaining args
  shift 4
  if [[ "$location" == "remote" ]]; then
    ssh_conn=${1:?"Usage: smcp-env set-agent <mode> <type> <deployment> remote <ssh_conn> [key=value...]"}
    shift
  elif [[ "$location" != "local" ]]; then
    die "location must be 'local' or 'remote', got '$location'"
  fi

  # Parse key=value pairs into config JSON
  for arg in "$@"; do
    local key="${arg%%=*}" val="${arg#*=}"
    config=$(echo "$config" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
  done

  # Build agent object
  local agent
  if [[ "$location" == "local" ]]; then
    agent=$(jq -n --arg t "$agent_type" --arg dep "$deployment" --argjson cfg "$config" \
      '{"type": $t, "deployment": $dep, "location": "local", "config": $cfg}')
  else
    agent=$(jq -n --arg t "$agent_type" --arg dep "$deployment" --arg ssh "$ssh_conn" --argjson cfg "$config" \
      '{"type": $t, "deployment": $dep, "location": "remote", "ssh_connection": $ssh, "config": $cfg}')
  fi

  jq --argjson agent "$agent" --arg d "$today" \
    '.updated_at = $d | .agent = $agent' \
    "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  echo "Updated agent ($agent_type/$deployment/$location) in $file"
}

cmd_remove_agent() {
  local mode=$1
  validate_mode "$mode"
  local file
  file=$(env_file "$mode")
  [[ -f "$file" ]] || die "Config not found: $file"

  local today
  today=$(date +%Y-%m-%d)
  jq --arg d "$today" '.updated_at = $d | .agent = null' \
    "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  echo "Removed agent from $file"
}

# --- main ---

require_jq

cmd=${1:-help}
shift || true

case "$cmd" in
  show)       cmd_show "${1:?Usage: smcp-env show <dev|artifact>}" ;;
  init)       cmd_init "${1:?Usage: smcp-env init <dev|artifact>}" ;;
  set)        cmd_set "${1:?}" "${2:?}" "${3:?}" "${@:4}" ;;
  remove)     cmd_remove "${1:?Usage: smcp-env remove <dev|artifact> <project>}" "${2:?}" ;;
  verify)     cmd_verify "${1:?Usage: smcp-env verify <dev|artifact>}" ;;
  show-agent)   cmd_show_agent "${1:?Usage: smcp-env show-agent <dev|artifact>}" ;;
  set-agent)    cmd_set_agent "${1:?}" "${2:?}" "${3:?}" "${4:?}" "${@:5}" ;;
  remove-agent) cmd_remove_agent "${1:?Usage: smcp-env remove-agent <dev|artifact>}" ;;
  help|*)
    cat <<'USAGE'
smcp-env — manage A2C-SMCP troubleshoot environment configs

Project commands:
  smcp-env show <dev|artifact>                            Show full config
  smcp-env set <mode> <project> local <path>              Set project as local
  smcp-env set <mode> <project> remote <ssh> <dir> <log>  Set project as remote
  smcp-env remove <mode> <project>                        Remove a project
  smcp-env verify <mode>                                  Verify paths & connections
  smcp-env init <dev|artifact>                            Interactive setup (user only)

Agent commands:
  smcp-env show-agent <mode>                              Show agent config
  smcp-env set-agent <mode> <type> <deploy> local [k=v…]  Set agent as local
  smcp-env set-agent <mode> <type> <deploy> remote <ssh> [k=v…]  Set agent as remote
  smcp-env remove-agent <mode>                            Remove agent config

Agent types: turingfocus (default), or custom
Deployments: supervisord, docker, k8s
Config keys (key=value): service, container, namespace, pod_selector, log_path, log_cmd

Projects:
  python-sdk  rust-sdk  a2c-smcp-protocol  office4ai
  ide4ai  oasp-protocol  office-editor4ai  tfrobot-client

Config files:
  ~/.a2c_smcp/dev-env.json       dev mode (local compile & debug)
  ~/.a2c_smcp/artifact-env.json  artifact mode (built packages / deploy)
USAGE
    ;;
esac
