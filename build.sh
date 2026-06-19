#!/usr/bin/env bash
# =============================================================================
# Contract Quest (watsonx) :: reproducible build — v2, higher quality
# -----------------------------------------------------------------------------
# Rebuilds the whole single-file game from scratch in 8 governed Matrix Builder
# batches, each coded by openai/gpt-oss-120b on IBM watsonx through GitPilot and
# validated by `mb check` before it lands. The batch specs are tuned for a
# CINEMATIC look (parallax lit-window city, sun glow, pixel tiles, bloom,
# embers, lanterns, vignette) — a clear step up from the flat v1.
#
#   pip install agent-generator gitcopilot crewai
#   export WATSONX_API_KEY=...  WATSONX_PROJECT_ID=...
#   ./build.sh        ->  frontend/index.html      (no keys committed)
# =============================================================================
set -euo pipefail

: "${WATSONX_API_KEY:?Set WATSONX_API_KEY}"
: "${WATSONX_PROJECT_ID:?Set WATSONX_PROJECT_ID}"
export GITPILOT_PROVIDER=watsonx
export WATSONX_URL="${WATSONX_URL:-https://us-south.ml.cloud.ibm.com}"
export WATSONX_BASE_URL="$WATSONX_URL"
export GITPILOT_WATSONX_MODEL="${GITPILOT_WATSONX_MODEL:-openai/gpt-oss-120b}"
export GITPILOT_MAX_TOKENS="${GITPILOT_MAX_TOKENS:-28000}"
export OTEL_SDK_DISABLED=true CREWAI_DISABLE_TELEMETRY=true LITELLM_LOG=ERROR

IDEA="Contract Quest — a premium original cinematic side-scrolling arcade platformer, single self-contained frontend/index.html, governed by the Ruslan Magana Definitions, watsonx-built"

GOALS=(
  "World foundation: parallax sunset city, pixel tiles, robot hero, camera, metallic HUD"
  "Hero controls and feel, animations, mobile, title screen"
  "Collectibles with glow, contract panels, checkpoint, Matrix Gate"
  "Enemies and power-ups"
  "Atmosphere and juice: particles, light-rays, lanterns, vignette, sound"
  "Levels and Rogue Architect mini-boss, RMD governance"
  "Meta: title, pause, game-over, high score, transitions"
  "Polish, responsive, performance"
)

SPECS=(
"Build the FOUNDATION of CONTRACT QUEST, an ORIGINAL premium side-scrolling arcade platformer, in ONE self-contained frontend/index.html (inline CSS+JS, no external libraries, runs on GitHub Pages, mobile + desktop). All art ORIGINAL programmatic canvas (do NOT imitate Mario/Nintendo). Make it look CINEMATIC and warm, NOT flat. Required: a LAYERED PARALLAX background — (1) a warm SUNSET gradient sky (deep blue at top to amber near the horizon) with a soft GLOWING SUN disc and a few light wispy clouds; (2) a FAR city skyline silhouette in dusk tones; (3) a NEAR city skyline with MANY warm LIT WINDOWS (small glowing squares) and antennae; the two city layers scroll at different speeds as the camera moves. Chunky PIXEL-ART platforms: brick ground tiles with a mossy green top, shaded sides and highlights; metal platforms with rivets and a cyan top edge; a side-scrolling level with a smooth follow-camera. A small ORIGINAL ROBOT HERO (rounded body, glowing blue visor with two eyes, yellow helmet, small backpack) under gravity, resting on platforms. A dark METALLIC top HUD bar showing CONTRACT QUEST (CONTRACT white, QUEST orange), COINS, SCORE, LIVES and an RMD LOCKED badge with a lock, plus a thin glowing underline. A footer line reading exactly: coded by GitPilot - under a Matrix Builder contract. Keep functions modular so later batches extend without rewrites."

"Add hero CONTROLS, feel and a START screen. Run left/right with acceleration; JUMP with VARIABLE height; gravity and platform collisions; the hero faces travel direction with a subtle idle bob, a simple run animation and a jump pose. Support keyboard (arrows, A/D, Space/W/Up) AND on-screen mobile buttons (left/right/jump) shown only on touch or small screens. Add a premium START/title screen (big CONTRACT QUEST, subtitle A governed arcade platformer, Press Enter / Tap to Start) over the parallax world, plus Pause (P) and Restart (R). Keep the parallax background, tiles, HUD and footer intact."

"Add COLLECTIBLES with GLOW, CONTRACT PANELS, a CHECKPOINT and the MATRIX GATE. Contract COINS are golden coins with an original code glyph in graceful ARCS, each wrapped in a soft additive GLOW; collecting one bumps COINS and SCORE with a sparkle. An RMD STAR is a glowing blue star labelled RMD that pulses (special pickup). VALIDATION GEMS worth points. Three holographic CONTRACT PANELS in the world: a LEFT CONTRACT RULES sign (Clarity, Compliance, Performance, Security, Reliability with green checks); a CENTER cyan contract.yaml panel (version 1.0; parties Builder, Client; terms deliver_quality, uphold_integrity, ship_value); a RIGHT ACCESS LOG panel (USER GITPILOT, CONTRACT MATRIX BUILDER, STATUS ACTIVE). A CHECKPOINT flag with a checkmark that flashes Checkpoint saved. A large GLOWING animated blue MATRIX GATE portal at the level end in a stone and metal frame with shield emblems; reaching it shows LEVEL COMPLETE - Contract validated. Keep all prior features."

"Add ENEMIES and POWER-UPS. BUG BOT is an original orange mechanical beetle (shaded shell, antennae, glowing eyes, legs) that patrols and turns at edges. PROMPT SLIME is a glossy purple blob with a face that hops. Landing on one from ABOVE stomps it (squash, particle puff, points); a side or below hit without protection hurts the hero (flash, knockback, brief invulnerability), costs a LIFE; zero lives is game over; respawn at the last checkpoint. POWER-UPS are floating glowing pickups with clear icons, timers and active indicators: SHIELD (a glowing bubble, temporary invincibility) and DOUBLE JUMP (a second mid-air jump), both with visible effects on the hero. Keep all prior features."

"Add cinematic ATMOSPHERE and JUICE — this is what makes it premium. Add drifting warm EMBER and dust particles floating upward across the screen; soft LIGHT RAYS emanating from the sun; glowing LANTERNS hung on some platforms as warm point lights, and small FOLIAGE tufts on ledges; particle BURSTS on coin pickup, enemy stomp and power-up; SCREEN-SHAKE on hits and big events; a subtle VIGNETTE darkening the edges and a warm COLOR-GRADE overlay for a cohesive cinematic tone. Add WebAudio SOUND effects (jump, coin, stomp, power-up, checkpoint, level-complete) with a MUTE toggle in the HUD. Honor prefers-reduced-motion. Keep ALL gameplay intact."

"Add LEVELS and a MINI-BOSS. Structure THREE levels advanced via the Matrix Gate with a LEVEL COMPLETE - Contract validated transition: Level 1 Build Fields (intro coins, first platforms, a Bug Bot, a checkpoint); Level 2 Dependency Cavern (moving platforms, Prompt Slimes, a hazard gap, a Double Jump power-up); Level 3 Validation Gate (tougher enemies, a Shield power-up, the boss). MINI-BOSS ROGUE ARCHITECT on Level 3: a larger original boss that patrols, periodically spawns Bug Bots, and has a shield that drops for a few seconds at a time; it takes THREE stomps while the shield is down to defeat, then shows Architecture restored. Contract validated. and opens the final gate. Weave RMD signs and loading tips: RMD-101 AI coders are workers not architects; RMD-103 Control files are protected; RMD-111 Acceptance criteria are law. Keep all prior features."

"Add META and screens. A premium TITLE splash with a rotating RMD tip; a PAUSE overlay; a GAME OVER overlay with final score and restart; LEVEL COMPLETE screens; a HIGH SCORE saved in localStorage and shown in the HUD; a difficulty ramp; smooth arcade fade or wipe TRANSITIONS between screens and levels; clean restart that resets state. Keep ALL gameplay, atmosphere, levels and boss intact."

"Final POLISH and performance. Make the canvas fully RESPONSIVE and DPR-aware so it fills the window and scales crisply on mobile (with the on-screen buttons), cap particle counts and reuse objects for a steady 60fps, ensure the dark metallic HUD reads clearly and never overlaps, ensure the footer reads exactly: coded by GitPilot - under a Matrix Builder contract, and do a final color and contrast pass so it looks like a cohesive premium arcade release. Keep ALL features intact and ensure there are NO runtime errors."
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
assemble() { python3 - "$1" <<'PY'
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
       "that one code block - no diff markers, no triple-dash lines, no explanations.")
open("/tmp/mb_msg.txt", "w").write(msg)
PY
}

# Verify the file is complete and well-formed. Exit 0 = good, 1 = retry.
verify() { python3 - <<'PY'
import sys
try:
    h = open("frontend/index.html").read()
except FileNotFoundError:
    print("   ! no file produced"); sys.exit(1)
if not h.rstrip().endswith("</html>"):
    print("   ! TRUNCATED (%d bytes) — will retry with more tokens" % len(h)); sys.exit(1)
if "<canvas" not in h or "coded by GitPilot" not in h:
    print("   ! missing required canvas/footer — will retry"); sys.exit(1)
print("   ok %d bytes" % len(h)); sys.exit(0)
PY
}

echo "Provider: watsonx · Model: $GITPILOT_WATSONX_MODEL"
mb init "$IDEA" --quality standard --title "Contract Quest"
mkdir -p coder-prompts
N=${#GOALS[@]}
for i in $(seq 1 "$N"); do
  NN=$(printf "%02d" "$i"); GOAL="${GOALS[$((i-1))]}"; export SPEC="${SPECS[$((i-1))]}"
  echo "-- Batch $i/$N — $GOAL"
  mb next "$GOAL" > /dev/null
  tailor "$NN" "$GOAL"
  mb prompt --coder gitpilot > /dev/null
  cp ".mb/batches/$NN/prompts/gitpilot.md" coder-prompts/gitpilot.md

  # Snapshot the last-good file so a bad attempt can never corrupt the build.
  [ -f frontend/index.html ] && cp frontend/index.html /tmp/cq_lastgood.html

  # Self-repair loop: gpt-oss-120b is a reasoning model and can sporadically
  # truncate or emit a malformed block. Retry up to 3 times, raising the token
  # budget each pass, before giving up — one flaky batch no longer aborts the
  # whole governed run (this was the v1 failure mode).
  ok=0
  for attempt in 1 2 3; do
    export GITPILOT_MAX_TOKENS=$(( 28000 + (attempt - 1) * 6000 ))
    echo "   attempt $attempt (max_tokens=$GITPILOT_MAX_TOKENS)"
    [ -f /tmp/cq_lastgood.html ] && cp /tmp/cq_lastgood.html frontend/index.html
    assemble "Batch $i of $N"
    if gitpilot generate -m "$(cat /tmp/mb_msg.txt)" -o . && verify; then
      if mb check frontend/index.html; then ok=1; break; fi
      echo "   ! mb check needs-repair — retrying"
    fi
  done
  if [ "$ok" -ne 1 ]; then
    echo "ERROR: batch $i did not pass after 3 attempts. Last-good file is preserved." >&2
    exit 1
  fi
done
echo "BUILD COMPLETE -> frontend/index.html"
