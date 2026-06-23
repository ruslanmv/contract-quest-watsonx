#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MODE="${1:-verify}"
STRICT_GENERATION=0
IDEA="${IDEA:-Contract Quest: a premium static browser platformer rebuilt through Matrix Designer, Matrix Builder, GitPilot, and IBM watsonx.ai governance.}"
PROJECT_TITLE="${PROJECT_TITLE:-Contract Quest}"
DESIGN_BLUEPRINT="design/blueprint.json"
DESIGN_BUNDLE="design/contract-quest-design-bundle.json"
MATRIX_EXPORT="design/contract-quest-mb-export.json"
EVIDENCE_FILE="EVIDENCE.md"
EVIDENCE_DIR=".build/evidence"
MAX_REPAIR_ATTEMPTS="${MAX_REPAIR_ATTEMPTS:-2}"
PUBLISHED_URL=""
KNOWN_LIMITATIONS=()
BATCH_EVIDENCE=()
COMMAND_EVIDENCE=()
EVIDENCE_WRITTEN=0

section() {
  printf '\n==> %s\n' "$1"
}

record_command() {
  COMMAND_EVIDENCE+=("$1|$2|$3")
}

record_batch() {
  BATCH_EVIDENCE+=("$1|$2|$3|$4")
}

load_env_file() {
  if [ -f ".env" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*) continue ;;
        export\ *) line="${line#export }" ;;
      esac
      case "$line" in
        *=*) ;;
        *) continue ;;
      esac
      local key="${line%%=*}"
      case "$key" in
        ''|*[!A-Za-z0-9_]*) continue ;;
      esac
      if [ -z "${!key+x}" ]; then
        local value="${line#*=}"
        if [ "${value:0:1}" = '"' ] && [ "${value: -1}" = '"' ]; then
          value="${value:1:${#value}-2}"
        elif [ "${value:0:1}" = "'" ] && [ "${value: -1}" = "'" ]; then
          value="${value:1:${#value}-2}"
        fi
        export "$key=$value"
      fi
    done < ".env"
  fi

  # Canonical names are preferred. Compatibility aliases are accepted without
  # printing or otherwise exposing secret values.
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

ensure_evidence_dir() {
  mkdir -p "$EVIDENCE_DIR" design frontend
}

run_capture() {
  local label="$1"
  shift
  local slug log status
  slug="$(printf '%s' "$label" | tr '[:upper:] /:' '[:lower:]---' | tr -cd 'a-z0-9._-')"
  log="$EVIDENCE_DIR/${slug}.log"
  section "$label"
  set +e
  "$@" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  record_command "$label" "$status" "$log"
  return "$status"
}

run_shell_capture() {
  local label="$1"
  shift
  local slug log status
  slug="$(printf '%s' "$label" | tr '[:upper:] /:' '[:lower:]---' | tr -cd 'a-z0-9._-')"
  log="$EVIDENCE_DIR/${slug}.log"
  section "$label"
  set +e
  bash -lc "$*" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  record_command "$label" "$status" "$log"
  return "$status"
}

npm_install_if_needed() {
  if [ ! -f package.json ]; then
    KNOWN_LIMITATIONS+=("No package.json was present, so npm install was skipped.")
    return 0
  fi
  need_cmd npm
  if [ -f package-lock.json ]; then
    run_capture "npm install" npm install
  else
    run_capture "npm install" npm install --package-lock=false
  fi
}

run_npm_script_if_present() {
  local script="$1"
  [ -f package.json ] || return 1
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script'] ? 0 : 1)" 2>/dev/null
}

verify_existing_artifacts() {
  npm_install_if_needed
  if run_npm_script_if_present build; then
    run_capture "npm run build" npm run build
  fi
  if run_npm_script_if_present verify; then
    run_capture "npm run verify" npm run verify
  fi
  if run_npm_script_if_present smoke; then
    run_capture "npm run smoke" npm run smoke
  else
    KNOWN_LIMITATIONS+=("No npm smoke script is defined.")
  fi
}

require_governed_inputs() {
  section "Check governed build inputs"
  local missing=0
  need_cmd node || missing=1
  need_cmd npm || missing=1
  need_cmd mdesign || missing=1
  need_cmd mb || missing=1
  need_cmd gitpilot || missing=1
  need_env GITPILOT_PROVIDER || missing=1
  need_env WATSONX_API_KEY || missing=1
  need_env WATSONX_PROJECT_ID || missing=1
  need_env WATSONX_URL || missing=1
  need_env GITPILOT_WATSONX_MODEL || missing=1
  need_env GITPILOT_MAX_TOKENS || missing=1
  if [ "$missing" -ne 0 ]; then
    printf 'Strict governed build cannot continue until all commands and environment variables are available.\n' >&2
    return 1
  fi
  printf 'Provider: %s\n' "$GITPILOT_PROVIDER"
  printf 'watsonx URL: %s\n' "$WATSONX_URL"
  printf 'Model: %s\n' "$GITPILOT_WATSONX_MODEL"
  printf 'Max tokens: %s\n' "$GITPILOT_MAX_TOKENS"
  printf 'API key: configured (value hidden)\n'
  printf 'Project ID: configured (value hidden)\n'
  if [ -n "${WATSONX_API_KEY:-}" ]; then
    printf 'Reminder: rotate any watsonx API key that was pasted into chat or logs before using this final build.\n'
  fi
}

run_design_repair() {
  local attempt="$1" reason="$2" prompt_file="$EVIDENCE_DIR/repair-d-design-${attempt}.md"
  section "Repair D: design bundle/schema repair attempt $attempt"
  cat > "$prompt_file" <<EOF_REPAIR
Repair D: Matrix Designer design bundle/schema repair.

Reason:
$reason

Repair only these files if needed:
- $DESIGN_BUNDLE
- $MATRIX_EXPORT
- $DESIGN_BLUEPRINT

Do not print or request secrets. Make the design bundle validate with the installed Matrix Designer schema.
EOF_REPAIR
  gitpilot generate -m "$(cat "$prompt_file")" -o . || gitpilot generate --prompt-file "$prompt_file"
}

generate_design() {
  ensure_evidence_dir
  section "Matrix Designer: blueprint, design, validate, export"
  run_capture "mdesign blueprints" mdesign blueprints --idea "$IDEA" -o "$DESIGN_BLUEPRINT"
  run_capture "mdesign design" mdesign design --idea "$IDEA" --blueprint "$DESIGN_BLUEPRINT" -o "$DESIGN_BUNDLE"

  local attempt=0
  until run_capture "mdesign validate" mdesign validate "$DESIGN_BUNDLE"; do
    if [ "$attempt" -ge "$MAX_REPAIR_ATTEMPTS" ]; then
      return 1
    fi
    attempt=$((attempt + 1))
    run_design_repair "$attempt" "mdesign validate failed; see $EVIDENCE_DIR/mdesign-validate.log"
  done

  run_capture "mdesign export" mdesign export "$DESIGN_BUNDLE" -o "$MATRIX_EXPORT"
}

reset_matrix_builder_state() {
  section "Reset Matrix Builder state and generated outputs"
  rm -rf .mb
  rm -f frontend/index.html
  rm -rf dist test-results playwright-report
  run_capture "mb init" mb init "$IDEA" --quality standard --title "$PROJECT_TITLE"
}

batch_ids_from_export() {
  node -e "const fs=require('fs'); const plan=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const batches=plan.matrix_builder?.batches; if(!Array.isArray(batches)||!batches.length){throw new Error('Matrix export contains no batches')} for (const batch of batches) console.log(batch.id);" "$MATRIX_EXPORT"
}

batch_field() {
  local batch_id="$1" field="$2"
  node -e "const fs=require('fs'); const plan=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const b=plan.matrix_builder.batches.find(x=>x.id===process.argv[2]); if(!b) process.exit(2); const value=b[process.argv[3]]; if (Array.isArray(value)) console.log(value.join(process.argv[4] || '\n')); else if (value) console.log(value);" "$MATRIX_EXPORT" "$batch_id" "$field" "${3:-$'\n'}"
}

assemble_batch_prompt() {
  local batch_id="$1" prompt_file="$2" meta_file="$3"
  node - "$MATRIX_EXPORT" "$DESIGN_BUNDLE" "$batch_id" "$prompt_file" "$meta_file" <<'NODE'
const fs = require('fs');
const [exportPath, designPath, batchId, promptPath, metaPath] = process.argv.slice(2);
const plan = JSON.parse(fs.readFileSync(exportPath, 'utf8'));
const designText = fs.readFileSync(designPath, 'utf8');
const exportText = fs.readFileSync(exportPath, 'utf8');
const batch = plan.matrix_builder.batches.find((item) => item.id === batchId);
if (!batch) throw new Error(`Unknown batch ${batchId}`);
const allowed = Array.isArray(batch.allowed_files) ? batch.allowed_files : [];
const acceptance = Array.isArray(batch.acceptance) ? batch.acceptance : [batch.acceptance || 'Batch acceptance must pass.'];
const current = [];
for (const file of allowed) {
  if (file.includes('*')) continue;
  if (fs.existsSync(file) && fs.statSync(file).isFile()) {
    current.push(`\n## ${file}\n\`\`\`\n${fs.readFileSync(file, 'utf8')}\n\`\`\``);
  }
}
const prompt = `${plan.shared_prompt_header || 'You are implementing a Matrix Designer-designed Contract Quest production batch.'}

# Governed batch
Batch ID: ${batch.id}
Batch title: ${batch.title || batch.id}
Batch purpose: ${batch.purpose || batch.title || batch.id}

# Allowed files
${allowed.map((f) => `- ${f}`).join('\n')}

# Acceptance criteria
${acceptance.map((a) => `- ${a}`).join('\n')}

# Required verification commands
- npm install
- npm run build
- npm run verify
- npm run smoke
- mb check

# Output contract
- Output only files in the allowed files list.
- Do not modify files outside the batch allow-list.
- Preserve all previous working features.
- If frontend/index.html is allowed or being extended, output the complete frontend/index.html.
- Do not output partial code for single-file canvas changes.
- Do not print, request, or commit secrets.

# Design Bundle
\`\`\`json
${designText}
\`\`\`

# Matrix Builder export
\`\`\`json
${exportText}
\`\`\`

# Current allowed file content
${current.length ? current.join('\n') : 'No existing allowed file content is available for this batch.'}
`;
fs.writeFileSync(promptPath, prompt);
fs.writeFileSync(metaPath, JSON.stringify({id: batch.id, title: batch.title || batch.id, purpose: batch.purpose || '', allowed_files: allowed, acceptance}, null, 2));
console.log(`Title: ${batch.title || batch.id}`);
console.log(`Allowed files: ${allowed.join(', ')}`);
console.log(`Acceptance: ${acceptance.join('; ')}`);
NODE
}

start_matrix_batch() {
  local title="$1" prompt_file="$2" allowed_csv="$3"
  export MB_TITLE="$title"
  export MB_ALLOWED_FILES="$allowed_csv"
  export MB_PROMPT_FILE="$prompt_file"
  run_shell_capture "mb next ${title}" \
    "mb next --title \"\$MB_TITLE\" --allowed-files \"\$MB_ALLOWED_FILES\" --prompt-file \"\$MB_PROMPT_FILE\" || mb next --title \"\$MB_TITLE\" --prompt-file \"\$MB_PROMPT_FILE\" || mb next"
}

run_gitpilot_prompt() {
  local prompt_file="$1" title="$2"
  export GP_PROMPT_FILE="$prompt_file"
  run_shell_capture "gitpilot generate ${title}" \
    "gitpilot generate -m \"\$(cat \"\$GP_PROMPT_FILE\")\" -o . || gitpilot generate --prompt-file \"\$GP_PROMPT_FILE\" -o ."
}

run_batch_verification() {
  local batch_id="$1"
  npm_install_if_needed
  run_capture "npm run build ${batch_id}" npm run build
  run_capture "npm run verify ${batch_id}" npm run verify
  run_capture "npm run smoke ${batch_id}" npm run smoke
  run_capture "mb check ${batch_id}" mb check
}

repair_category_for_failure() {
  local failed_label="$1"
  case "$failed_label" in
    *mdesign*) printf 'Repair D = design bundle/schema repair' ;;
    *build*|*verify*) printf 'Repair A = runtime repair' ;;
    *smoke*) printf 'Repair B = viewport/layout repair' ;;
    *mb\ check*) printf 'Repair C = gameplay/audio progression repair' ;;
    *) printf 'Repair A = runtime repair' ;;
  esac
}

run_repair_batch() {
  local batch_id="$1" attempt="$2" failed_label="$3" prompt_file="$4"
  local category repair_prompt
  category="$(repair_category_for_failure "$failed_label")"
  repair_prompt="$EVIDENCE_DIR/${batch_id}-repair-${attempt}.md"
  section "$category for $batch_id (attempt $attempt)"
  cat > "$repair_prompt" <<EOF_REPAIR
$category

Original batch prompt:
$prompt_file

The previous batch failed at: $failed_label

Repair only within the original batch allow-list. Preserve all working features.
Do not print, request, or commit secrets. Record no invented Matrix commit IDs.
EOF_REPAIR
  run_gitpilot_prompt "$repair_prompt" "$batch_id repair $attempt"
}

run_exported_batch() {
  local batch_id="$1" prompt_file meta_file title allowed_csv attempt failed_label status
  prompt_file="$EVIDENCE_DIR/prompts/${batch_id}.md"
  meta_file="$EVIDENCE_DIR/prompts/${batch_id}.json"
  mkdir -p "$(dirname "$prompt_file")"
  assemble_batch_prompt "$batch_id" "$prompt_file" "$meta_file"
  title="$(node -e "const m=require('./' + process.argv[1]); console.log(m.title)" "$meta_file")"
  allowed_csv="$(node -e "const m=require('./' + process.argv[1]); console.log((m.allowed_files || []).join(','))" "$meta_file")"

  attempt=0
  while :; do
    start_matrix_batch "$title" "$prompt_file" "$allowed_csv"
    run_gitpilot_prompt "$prompt_file" "$title"
    status=0
    failed_label=""
    run_batch_verification "$batch_id" || { status=$?; failed_label="verification for $batch_id"; }
    if [ "$status" -eq 0 ]; then
      record_batch "$batch_id" "$title" "passed" "$prompt_file"
      return 0
    fi
    if [ "$attempt" -ge "$MAX_REPAIR_ATTEMPTS" ]; then
      record_batch "$batch_id" "$title" "failed after repairs" "$prompt_file"
      return "$status"
    fi
    attempt=$((attempt + 1))
    record_batch "$batch_id" "$title" "repair attempt $attempt after $failed_label" "$prompt_file"
    run_repair_batch "$batch_id" "$attempt" "$failed_label" "$prompt_file"
  done
}

run_all_batches() {
  section "Run Matrix Designer-exported governed batches"
  local batch_id
  while IFS= read -r batch_id; do
    [ -n "$batch_id" ] || continue
    run_exported_batch "$batch_id"
  done < <(batch_ids_from_export)
}

run_final_verification() {
  section "Final verification"
  npm_install_if_needed
  run_capture "final npm run build" npm run build
  run_capture "final npm run verify" npm run verify
  run_capture "final npm run smoke" npm run smoke
}

maybe_deploy() {
  section "Optional Vercel deploy"
  if [ -z "${VERCEL_TOKEN:-}" ]; then
    printf 'Skipping Vercel deploy: VERCEL_TOKEN not set\n'
    KNOWN_LIMITATIONS+=("Vercel deployment skipped because VERCEL_TOKEN was not set.")
    return 0
  fi
  need_cmd npx
  run_capture "vercel deploy" npx vercel deploy --prod --token "$VERCEL_TOKEN"
  if [ -n "${PUBLIC_GAME_URL:-}" ]; then
    PUBLISHED_URL="$PUBLIC_GAME_URL"
    run_capture "verify public URL" curl -I "$PUBLIC_GAME_URL"
  else
    KNOWN_LIMITATIONS+=("Vercel deploy ran, but PUBLIC_GAME_URL was not set for public URL verification.")
  fi
}

write_evidence() {
  section "Write evidence"
  local generated_at
  generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  {
    printf '# Contract Quest Governed Build Evidence\n\n'
    printf '- Generated at: `%s`\n' "$generated_at"
    printf '- Provider: `%s`\n' "${GITPILOT_PROVIDER:-unset}"
    printf '- Model: `%s`\n' "${GITPILOT_WATSONX_MODEL:-unset}"
    printf '- Matrix Designer bundle: `%s`\n' "$DESIGN_BUNDLE"
    printf '- Matrix Builder export: `%s`\n' "$MATRIX_EXPORT"
    if [ -n "$PUBLISHED_URL" ]; then
      printf '- Public game URL: `%s`\n' "$PUBLISHED_URL"
    else
      printf '- Public game URL: not recorded\n'
    fi
    printf '\n## Batch List\n\n'
    if [ -f "$MATRIX_EXPORT" ]; then
      node -e "const fs=require('fs'); const p=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); for (const b of p.matrix_builder?.batches || []) console.log('- `'+b.id+'` — '+(b.title || b.id));" "$MATRIX_EXPORT"
    else
      printf '- Matrix export not available.\n'
    fi
    printf '\n## Batch Outcomes\n\n'
    if [ "${#BATCH_EVIDENCE[@]}" -eq 0 ]; then
      printf '- No batch outcomes recorded.\n'
    else
      local item id title outcome prompt
      for item in "${BATCH_EVIDENCE[@]}"; do
        IFS='|' read -r id title outcome prompt <<< "$item"
        printf '- `%s` — %s — %s — prompt `%s`\n' "$id" "$title" "$outcome" "$prompt"
      done
    fi
    printf '\n## Command Evidence\n\n'
    if [ "${#COMMAND_EVIDENCE[@]}" -eq 0 ]; then
      printf '- No command output recorded.\n'
    else
      local cmd status log
      for item in "${COMMAND_EVIDENCE[@]}"; do
        IFS='|' read -r cmd status log <<< "$item"
        printf '- `%s` exited `%s`; output: `%s`\n' "$cmd" "$status" "$log"
      done
    fi
    printf '\n## Screenshots\n\n'
    if compgen -G "test-results/**/*.png" >/dev/null 2>&1 || compgen -G "playwright-report/**/*.png" >/dev/null 2>&1; then
      find test-results playwright-report -name '*.png' -print 2>/dev/null | sed 's/^/- `/; s/$/`/'
    else
      printf '- No screenshots were produced by the available checks.\n'
    fi
    printf '\n## Known Limitations\n\n'
    if [ "${#KNOWN_LIMITATIONS[@]}" -eq 0 ]; then
      printf '- None recorded.\n'
    else
      local limitation
      for limitation in "${KNOWN_LIMITATIONS[@]}"; do
        printf '- %s\n' "$limitation"
      done
    fi
  } > "$EVIDENCE_FILE"
  EVIDENCE_WRITTEN=1
  printf 'Evidence written to %s\n' "$EVIDENCE_FILE"
}

on_error() {
  local status=$?
  if [ "$STRICT_GENERATION" = "1" ] && [ "$EVIDENCE_WRITTEN" != "1" ]; then
    KNOWN_LIMITATIONS+=("Build stopped before completion with exit status $status.")
    write_evidence || true
  fi
  exit "$status"
}

from_zero() {
  STRICT_GENERATION=1
  ensure_evidence_dir
  require_governed_inputs
  generate_design
  reset_matrix_builder_state
  npm_install_if_needed
  run_all_batches
  run_final_verification
  maybe_deploy
  write_evidence
}

print_help() {
  cat <<'HELP'
Usage: ./build.sh [verify|design|from-zero|generate|all|help]

Modes:
  verify     Run local npm/static checks against checked-in artifacts.
  design     Strictly generate blueprint/design, validate, and export with mdesign.
  from-zero  Strict design -> govern -> generate -> verify -> publish/evidence pipeline.
  generate   Alias for from-zero.
  all        Alias for from-zero.
  help       Show this help message.

Canonical .env names:
  GITPILOT_PROVIDER=watsonx
  WATSONX_API_KEY=...
  WATSONX_PROJECT_ID=...
  WATSONX_URL=https://us-south.ml.cloud.ibm.com
  GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b
  GITPILOT_MAX_TOKENS=24000

Optional deployment names:
  VERCEL_TOKEN=...
  VERCEL_PROJECT_ID=...
  VERCEL_ORG_ID=...
  PUBLIC_GAME_URL=...

Secrets are never printed by this script. Rotate any watsonx key that was
pasted into chat or logs before using the final governed build.
HELP
}

load_env_file
trap on_error ERR

case "$MODE" in
  verify)
    ensure_evidence_dir
    verify_existing_artifacts
    ;;
  design)
    STRICT_GENERATION=1
    ensure_evidence_dir
    require_governed_inputs
    generate_design
    ;;
  from-zero|generate|all)
    from_zero
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
