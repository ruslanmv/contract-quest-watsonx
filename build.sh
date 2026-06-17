#!/usr/bin/env bash
# =============================================================================
# Contract Quest :: reproducible build script (watsonx only)
# -----------------------------------------------------------------------------
# Rebuilds the entire game from scratch: 6 governed Matrix Builder batches,
# each coded by openai/gpt-oss-120b on IBM watsonx through GitPilot, validated
# by `mb check` before it is allowed to land.
#
# Prerequisites:
#   pip install agent-generator gitcopilot crewai
#   export WATSONX_API_KEY=...      # IBM Cloud API key
#   export WATSONX_PROJECT_ID=...   # watsonx project id
#
# Usage:  ./build.sh   ->  frontend/index.html
# No API keys are committed. This project is built with watsonx only.
# =============================================================================
set -euo pipefail

: "${WATSONX_API_KEY:?Set WATSONX_API_KEY}"
: "${WATSONX_PROJECT_ID:?Set WATSONX_PROJECT_ID}"
export GITPILOT_PROVIDER=watsonx
export WATSONX_URL="${WATSONX_URL:-https://us-south.ml.cloud.ibm.com}"
export WATSONX_BASE_URL="$WATSONX_URL"
export GITPILOT_WATSONX_MODEL="${GITPILOT_WATSONX_MODEL:-openai/gpt-oss-120b}"
export GITPILOT_MAX_TOKENS="${GITPILOT_MAX_TOKENS:-24000}"
export OTEL_SDK_DISABLED=true CREWAI_DISABLE_TELEMETRY=true LITELLM_LOG=ERROR

IDEA="Contract Quest — a premium original side-scrolling arcade platformer, single self-contained frontend/index.html, governed by the Ruslan Magana Definitions, watsonx-built"

GOALS=(
  "Foundation: world, platforms, robot hero, camera, HUD"
  "Controls, hero states, screens, richer world art"
  "Collectibles, contract panels, checkpoint, Matrix Gate"
  "Enemies, damage, lives, power-ups"
  "Levels, mini-boss, RMD governance"
  "Polish: particles, audio, transitions, title, responsive"
)
SPECS=(
"FOUNDATION of an ORIGINAL premium side-scroller (no Mario/Nintendo): warm SUNSET sky, layered PARALLAX skyline with lit windows, chunky PIXEL platforms with mossy tops, a cute ORIGINAL robot hero (blue visor, yellow helmet, backpack), gravity, side-scroll camera, a dark metallic top HUD (CONTRACT QUEST · COINS · SCORE · LIVES · RMD LOCKED), and a footer reading exactly: coded by GitPilot — under a Matrix Builder contract."
"Add run/jump with VARIABLE height, hero animation states (idle/run/jump/fall/land), a START title screen, PAUSE and RESTART, mobile on-screen buttons on touch devices, and richer art (windowed skyline, textured platforms, drifting embers, vignette). Keep the HUD and footer."
"Add COIN arcs (golden, </> glyph), a glowing blue RMD STAR, validation GEMS, the three decorative contract panels (// CONTRACT RULES; contract.yaml hologram; ACCESS LOG: GITPILOT/MATRIX BUILDER/ACTIVE), a CHECKPOINT flag, and the MATRIX GATE goal portal with a LEVEL COMPLETE — Contract validated overlay."
"Add ORIGINAL enemies (orange Bug Bot, purple Prompt Slime) that patrol and turn at edges; stomp-from-above defeats them, side hits damage the hero, cost a life, respawn at checkpoint, 0 lives = game over. Add SHIELD and DOUBLE JUMP power-ups with visible effects."
"Add three levels (Build Fields, Dependency Cavern, Validation Gate) advanced via the Matrix Gate, a ROGUE ARCHITECT mini-boss (spawns Bug Bots, shield drops, three stomps to defeat, 'Architecture restored. Contract validated.'), and RMD signs/tips (RMD-101, RMD-103, RMD-111)."
"Final POLISH: particles, screen-shake, WebAudio SFX + mute toggle, arcade transitions, a premium title splash with a rotating RMD tip, full responsive/DPR-aware layout, and a performance pass. Footer must read exactly: coded by GitPilot — under a Matrix Builder contract."
)

tailor() { python3 - "$1" "$2" <<'PY'
import json, sys
p = ".mb/batches/%s/batch.json" % sys.argv[1]
d = json.load(open(p)); f = ["frontend/index.html"]
d["plan"]["allowed_files"] = f; d["plan"]["tasks"][0]["allowed_files"] = f
d["plan"]["tasks"][0]["title"] = sys.argv[2]; d["plan"]["title"] = sys.argv[2]; d["title"] = sys.argv[2]
json.dump(d, open(p, "w"), indent=2)
PY
}
assemble() { python3 - "$2" <<'PY'
import os, sys
label = sys.argv[1]
contract = open("coder-prompts/gitpilot.md").read()
try:
    cur = open("frontend/index.html").read()
    body = ("\n\nYou are EXTENDING an existing single-file game (Contract Quest). Keep ALL "
            "existing functionality; only ADD this batch's features. Current full content "
            "between markers:\n<<<CURRENT_FILE>>>\n%s\n<<<END_FILE>>>\n" % cur)
except FileNotFoundError:
    body = "\n\nThis is the first batch; create the file from scratch.\n"
msg = (f"{contract}{body}\nTASK ({label}): {os.environ['SPEC']}\n\nOutput the COMPLETE "
       "frontend/index.html. Use EXACTLY this opening fence on its own line: three backticks "
       "then `html frontend/index.html`, then the full file, then a closing fence. Output ONLY "
       "that one code block — no diff markers, no explanations.")
open("/tmp/mb_msg.txt", "w").write(msg)
PY
}

echo "▶ Provider: watsonx · Model: $GITPILOT_WATSONX_MODEL"
mb init "$IDEA" --quality standard --title "Contract Quest"
for i in 1 2 3 4 5 6; do
  NN=$(printf "%02d" "$i"); GOAL="${GOALS[$((i-1))]}"; export SPEC="${SPECS[$((i-1))]}"
  echo "── Batch $i/6 — $GOAL"
  mb next "$GOAL" > /dev/null
  tailor "$NN" "$GOAL"
  mb prompt --coder gitpilot > /dev/null
  cp ".mb/batches/$NN/prompts/gitpilot.md" coder-prompts/gitpilot.md
  assemble "$NN" "Batch $i of 6"
  gitpilot generate -m "$(cat /tmp/mb_msg.txt)" -o .
  mb check frontend/index.html
done
echo "✅ frontend/index.html built. Run: python3 -m http.server -d frontend 8080"
