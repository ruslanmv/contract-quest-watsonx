#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MODE="${1:-verify}"
DESIGN_BUNDLE="${DESIGN_BUNDLE:-design/contract-quest-design-bundle.json}"
MATRIX_EXPORT="${MATRIX_EXPORT:-design/contract-quest-mb-export.json}"
BATCH_STATE_DIR="${BATCH_STATE_DIR:-.mb}"

section() { printf '\n==> %s\n' "$1"; }
info() { printf '%s\n' "$1"; }

load_env_file() {
  if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "./.env"
    set +a
  fi

  # Accept short and legacy names from local shells or .env files without
  # printing secrets. WATSXON_API_KEY is intentionally supported because some
  # older local notes used that misspelling.
  if [ -n "${PROJECT_ID:-}" ] && [ -z "${WATSONX_PROJECT_ID:-}" ]; then
    export WATSONX_PROJECT_ID="$PROJECT_ID"
  fi
  if [ -n "${WATSXON_API_KEY:-}" ] && [ -z "${WATSONX_API_KEY:-}" ]; then
    export WATSONX_API_KEY="$WATSXON_API_KEY"
  fi

  export GITPILOT_PROVIDER="${GITPILOT_PROVIDER:-watsonx}"
  export WATSONX_URL="${WATSONX_URL:-https://us-south.ml.cloud.ibm.com}"
  export WATSONX_BASE_URL="${WATSONX_BASE_URL:-$WATSONX_URL}"
  export GITPILOT_WATSONX_MODEL="${GITPILOT_WATSONX_MODEL:-openai/gpt-oss-120b}"
  export GITPILOT_MAX_TOKENS="${GITPILOT_MAX_TOKENS:-24000}"
  export OTEL_SDK_DISABLED="${OTEL_SDK_DISABLED:-true}"
  export CREWAI_DISABLE_TELEMETRY="${CREWAI_DISABLE_TELEMETRY:-true}"
  export LITELLM_LOG="${LITELLM_LOG:-ERROR}"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    return 1
  fi
}

need_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    printf 'Missing required environment variable: %s\n' "$name" >&2
    return 1
  fi
}

run_npm_script_if_present() {
  local script="$1"
  [ -f package.json ] || return 1
  need_cmd node >/dev/null
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script'] ? 0 : 1)" 2>/dev/null
}

npm_install_if_needed() {
  if [ ! -f package.json ]; then
    section "Skip npm install"
    info "No package.json found."
    return 0
  fi

  need_cmd npm
  section "Install npm dependencies"
  if [ -f package-lock.json ]; then
    npm install
  else
    npm install --package-lock=false
  fi
}

validate_json_artifacts() {
  section "Validate reproducibility JSON artifacts"
  need_cmd node
  node - <<'NODE'
const fs = require('fs');
const required = [
  'design/contract-quest-design-bundle.json',
  'design/contract-quest-mb-export.json'
];
for (const file of required) {
  if (!fs.existsSync(file)) throw new Error(`${file} is missing`);
  JSON.parse(fs.readFileSync(file, 'utf8'));
}
const design = JSON.parse(fs.readFileSync(required[0], 'utf8'));
const exported = JSON.parse(fs.readFileSync(required[1], 'utf8'));
if (!Array.isArray(design.batch_roadmap) || design.batch_roadmap.length < 12) {
  throw new Error('design bundle must define the full D-1 through Batch 10 roadmap');
}
if (!exported.matrix_builder || !Array.isArray(exported.matrix_builder.batches)) {
  throw new Error('Matrix export must contain matrix_builder.batches');
}
console.log('Design bundle and Matrix export JSON are present and parseable.');
NODE
}

validate_design() {
  section "Validate Matrix Designer bundle"
  if [ ! -f "$DESIGN_BUNDLE" ]; then
    printf 'Design bundle not found: %s\n' "$DESIGN_BUNDLE" >&2
    printf 'Create it with Matrix Designer before running design, generate, or all mode.\n' >&2
    return 1
  fi

  if command -v mdesign >/dev/null 2>&1; then
    mkdir -p "$(dirname "$MATRIX_EXPORT")"
    mdesign validate "$DESIGN_BUNDLE"
    mdesign export "$DESIGN_BUNDLE" -o "$MATRIX_EXPORT"
  else
    info "mdesign is not installed; falling back to local JSON artifact validation."
    validate_json_artifacts
  fi
}

verify_static() {
  npm_install_if_needed

  if run_npm_script_if_present build; then
    section "Run npm build"
    npm run build
  else
    section "Skip npm build"
    info "No npm build script is defined."
  fi

  if run_npm_script_if_present verify; then
    section "Run npm verify"
    npm run verify
  else
    section "Skip npm verify"
    info "No npm verify script is defined."
  fi

  if run_npm_script_if_present smoke; then
    section "Run npm smoke"
    npm run smoke
  else
    section "Skip smoke"
    info "No npm smoke script is defined yet. Add one after Playwright is configured."
  fi
}

print_generation_summary() {
  section "Generation configuration"
  printf 'Provider: %s\n' "$GITPILOT_PROVIDER"
  printf 'watsonx URL: %s\n' "$WATSONX_URL"
  printf 'Model: %s\n' "$GITPILOT_WATSONX_MODEL"
  printf 'Max tokens: %s\n' "$GITPILOT_MAX_TOKENS"
  if [ -n "${WATSONX_API_KEY:-}" ]; then
    printf 'API key: configured (value hidden)\n'
  else
    printf 'API key: not configured\n'
  fi
  if [ -n "${WATSONX_PROJECT_ID:-}" ]; then
    printf 'Project ID: configured (value hidden)\n'
  else
    printf 'Project ID: not configured\n'
  fi
}

governed_tools_available() {
  command -v mb >/dev/null 2>&1 && command -v gitpilot >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1
}

run_local_generation_fallback() {
  section "Sandbox local game fallback"
  info "Matrix Builder/GitPilot commands are not installed in this sandbox."
  info "Using the checked-in Matrix Designer artifacts and static frontend game as the reproducible local artifact."
  info "Set REQUIRE_GOVERNED_TOOLS=1 to fail instead of using this fallback."
  print_generation_summary
  verify_static
}

prepare_generate() {
  validate_design

  section "Check governed generation prerequisites"
  need_cmd mb
  need_cmd gitpilot
  need_cmd python3
  need_env GITPILOT_PROVIDER
  need_env WATSONX_API_KEY
  need_env WATSONX_PROJECT_ID
  need_env WATSONX_URL
  need_env GITPILOT_WATSONX_MODEL
  print_generation_summary
}

batch_rows() {
  python3 - "$MATRIX_EXPORT" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding='utf-8'))
for batch in data.get('matrix_builder', {}).get('batches', []):
    bid = batch.get('id', '').replace('\t', ' ')
    title = batch.get('title', '').replace('\t', ' ')
    print(f"{bid}\t{title}")
PY
}

run_batch() {
  local id="$1"
  local title="$2"
  section "Running Matrix Designer-designed batch: $id — $title"

  if [ ! -d "$BATCH_STATE_DIR" ]; then
    mb init "Contract Quest governed browser game" --quality standard --title "Contract Quest" || true
  fi

  mb next "$title" || true
  mb prompt --coder gitpilot
  gitpilot generate
  if run_npm_script_if_present build; then npm run build; fi
  if run_npm_script_if_present verify; then npm run verify; fi
  if run_npm_script_if_present smoke; then npm run smoke; fi
  mb check
}

run_generate_loop() {
  validate_design

  if [ "${GENERATE_DRY_RUN:-0}" = "1" ]; then
    :
  elif ! governed_tools_available; then
    if [ "${REQUIRE_GOVERNED_TOOLS:-0}" = "1" ]; then
      prepare_generate
    else
      run_local_generation_fallback
      return 0
    fi
  else
    prepare_generate
    npm_install_if_needed
  fi

  section "Execute governed Matrix Builder/GitPilot batches"
  local count=0
  while IFS=$'\t' read -r id title; do
    [ -n "$id" ] || continue
    count=$((count + 1))
    if [ "${GENERATE_DRY_RUN:-0}" = "1" ]; then
      printf 'DRY RUN batch %s: %s\n' "$id" "$title"
    else
      run_batch "$id" "$title"
    fi
  done < <(batch_rows)

  if [ "$count" -eq 0 ]; then
    printf 'No batches found in %s\n' "$MATRIX_EXPORT" >&2
    return 1
  fi

  section "Final local verification"
  verify_static
}

print_help() {
  cat <<'HELP'
Usage: ./build.sh [verify|design|generate|all|help]

Modes:
  verify    Run local npm/static checks available in this repository. Default.
  design    Validate the Matrix Designer bundle and export/check the Matrix plan.
  generate  Validate design, check watsonx/GitPilot/Matrix prerequisites, then run every exported batch.
  all       Run design validation and local verification.
  help      Show this help message.

Environment:
  The script reads environment variables from the shell first and from .env when
  .env exists. It accepts both canonical and local legacy names:

  WATSONX_PROJECT_ID or PROJECT_ID
  WATSONX_API_KEY or WATSXON_API_KEY
  WATSONX_URL defaults to https://us-south.ml.cloud.ibm.com
  GITPILOT_PROVIDER defaults to watsonx
  GITPILOT_WATSONX_MODEL defaults to openai/gpt-oss-120b
  GITPILOT_MAX_TOKENS defaults to 24000

Set GENERATE_DRY_RUN=1 with generate mode to print the exported batch plan
without calling Matrix Builder or GitPilot. If mb/gitpilot are unavailable, generate
uses the checked-in static game as a sandbox fallback unless REQUIRE_GOVERNED_TOOLS=1
is set. Secrets are never printed.
HELP
}

load_env_file

case "$MODE" in
  verify)
    verify_static
    ;;
  design)
    validate_design
    ;;
  generate)
    run_generate_loop
    ;;
  all)
    validate_design
    verify_static
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    printf 'Unknown mode: %s\n' "$MODE" >&2
    printf 'Run ./build.sh help for usage.\n' >&2
    exit 2
    ;;
esac
