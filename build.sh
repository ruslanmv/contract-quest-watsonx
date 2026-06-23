#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MODE="${1:-verify}"
STRICT_GENERATION=0
DESIGN_BUNDLE="design/contract-quest-design-bundle.json"
MATRIX_EXPORT="design/contract-quest-mb-export.json"

section() {
  printf '\n==> %s\n' "$1"
}

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

npm_install_if_needed() {
  if [ ! -f package.json ]; then
    section "Skip npm install"
    printf 'No package.json found.\n'
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

run_npm_script_if_present() {
  local script="$1"
  [ -f package.json ] || return 1
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script'] ? 0 : 1)" 2>/dev/null
}

validate_design() {
  section "Validate Matrix Designer bundle"
  if [ ! -f "$DESIGN_BUNDLE" ]; then
    printf 'Design bundle not found: %s\n' "$DESIGN_BUNDLE" >&2
    printf 'Create it with Matrix Designer before running design, generate, or all mode.\n' >&2
    return 1
  fi

  mkdir -p "$(dirname "$MATRIX_EXPORT")"
  if command -v mdesign >/dev/null 2>&1; then
    mdesign validate "$DESIGN_BUNDLE"
    mdesign export "$DESIGN_BUNDLE" -o "$MATRIX_EXPORT"
  else
    if [ "$STRICT_GENERATION" = "1" ]; then
      printf 'Matrix Designer CLI (mdesign) is required for governed generation.\n' >&2
      printf 'Install Matrix Designer or run ./build.sh verify for checked-in artifact validation only.\n' >&2
      return 1
    fi
    printf 'Matrix Designer CLI (mdesign) not found; validating checked-in design JSON and Matrix export JSON.\n'
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')); JSON.parse(require('fs').readFileSync(process.argv[2], 'utf8'));" "$DESIGN_BUNDLE" "$MATRIX_EXPORT"
    printf 'Using checked-in Matrix Builder export: %s\n' "$MATRIX_EXPORT"
  fi
}

verify_static() {
  npm_install_if_needed

  if run_npm_script_if_present build; then
    section "Run npm build"
    npm run build
  else
    section "Skip npm build"
    printf 'No npm build script is defined.\n'
  fi

  if run_npm_script_if_present verify; then
    section "Run npm verify"
    npm run verify
  else
    section "Skip npm verify"
    printf 'No npm verify script is defined.\n'
  fi

  if run_npm_script_if_present smoke; then
    section "Run npm smoke"
    npm run smoke
  else
    section "Skip smoke"
    printf 'No npm smoke script is defined yet. Add one after Playwright is configured.\n'
  fi
}

prepare_generate() {
  validate_design

  section "Check governed generation prerequisites"
  need_cmd mb
  need_cmd gitpilot
  need_env GITPILOT_PROVIDER
  need_env WATSONX_API_KEY
  need_env WATSONX_PROJECT_ID
  need_env WATSONX_URL
  need_env GITPILOT_WATSONX_MODEL

  printf 'Generation prerequisites are present.\n'
  printf 'Provider: %s\n' "$GITPILOT_PROVIDER"
  printf 'watsonx URL: %s\n' "$WATSONX_URL"
  printf 'Model: %s\n' "$GITPILOT_WATSONX_MODEL"
  printf 'API key: configured (value hidden)\n'
  printf 'Project ID: configured (value hidden)\n'
  printf 'Matrix export: %s\n' "$MATRIX_EXPORT"
}

run_governed_generation() {
  section "Run Matrix Builder / GitPilot governed generation"

  local batch_ids
  batch_ids="$(node -e "const fs=require('fs'); const plan=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const batches=plan.matrix_builder?.batches; if(!Array.isArray(batches)||!batches.length){process.exit(1)} for (const batch of batches) console.log(batch.id);" "$MATRIX_EXPORT")"

  local batch_id
  while IFS= read -r batch_id; do
    [ -n "$batch_id" ] || continue
    section "Matrix Designer-designed batch: $batch_id"
    node -e "const fs=require('fs'); const plan=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const b=plan.matrix_builder.batches.find(x=>x.id===process.argv[2]); console.log('Title: '+(b.title||b.id)); console.log('Allowed files: '+(b.allowed_files||[]).join(', ')); console.log('Acceptance: '+(b.acceptance||'not specified'));" "$MATRIX_EXPORT" "$batch_id"

    mb next || true
    mb prompt --coder gitpilot
    gitpilot generate

    verify_static
    mb check
  done <<< "$batch_ids"
}

print_help() {
  cat <<'HELP'
Usage: ./build.sh [verify|design|generate|all|help]

Modes:
  verify    Run local npm/static checks against checked-in artifacts. Default.
  design    Validate design/contract-quest-design-bundle.json and export the Matrix plan.
  generate  Strict Matrix Designer -> Matrix Builder -> GitPilot/watsonx batch generation.
  all       Alias for the full governed generation workflow.
  help      Show this help message.

Environment:
  The script reads environment variables from the shell first and from .env when
  .env exists. It accepts both canonical and local legacy names:

  WATSONX_PROJECT_ID or PROJECT_ID
  WATSONX_API_KEY or WATSXON_API_KEY
  WATSONX_URL defaults to https://us-south.ml.cloud.ibm.com
  GITPILOT_PROVIDER defaults to watsonx
  GITPILOT_WATSONX_MODEL defaults to openai/gpt-oss-120b

Secrets are never printed by this script.

Strict generation:
  generate/all require mdesign, mb, gitpilot, WATSONX_API_KEY, and
  WATSONX_PROJECT_ID. Use ./build.sh verify when you only want to validate the
  existing static game artifacts without calling AI generation tools.
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
    STRICT_GENERATION=1
    export REQUIRE_PLAYWRIGHT_SMOKE="${REQUIRE_PLAYWRIGHT_SMOKE:-1}"
    prepare_generate
    run_governed_generation
    ;;
  all)
    STRICT_GENERATION=1
    export REQUIRE_PLAYWRIGHT_SMOKE="${REQUIRE_PLAYWRIGHT_SMOKE:-1}"
    prepare_generate
    run_governed_generation
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
