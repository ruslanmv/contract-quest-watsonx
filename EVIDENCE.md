# Contract Quest Governed Build Evidence

- Generated at: `2026-06-24T16:52:02Z`
- Provider: `watsonx`
- Model: `openai/gpt-oss-120b`
- GitPilot config dir: `/mnt/data/contract-quest-generator-work/contract-quest-generator-clean/.build/gitpilot_config`
- Matrix Designer bundle: `design/contract-quest-design-bundle.json`
- Matrix Builder export: `design/contract-quest-mb-export.json`
- Public game URL: not recorded

## Batch List

- `D-1-design` — Design Bundle
- `00-contract-scaffold` — Contract reset and scaffold
- `01-framework` — Framework foundation and viewport invariant
- `02-art` — Art direction and deterministic asset pipeline
- `03-levels` — Level and story model
- `04-hero` — Hero movement, physics, death, and respawn
- `05-rewards-gates` — Rewards, panels, HUD, and Matrix Gates
- `06-enemies-powerups` — Enemies and power-ups
- `07-boss` — Rogue Architect boss and final validation
- `08-audio-polish` — WebAudio music, SFX, and atmosphere
- `09-mobile-a11y` — Mobile controls, accessibility, and UX polish
- `10-evidence-release` — QA, evidence, tutorial, and release package

## Batch Outcomes

- `D-1-design` — Design Bundle — passed — prompt `.build/evidence/prompts/D-1-design.md`
- `00-contract-scaffold` — Contract reset and scaffold — passed — prompt `.build/evidence/prompts/00-contract-scaffold.md`
- `01-framework` — Framework foundation and viewport invariant — passed — prompt `.build/evidence/prompts/01-framework.md`

## Command Evidence

- `gitpilot config` exited `0`; output: `.build/evidence/gitpilot-config.log`
- `gitpilot doctor offline` exited `0`; output: `.build/evidence/gitpilot-doctor-offline.log`
- `mdesign blueprints` exited `0`; output: `.build/evidence/mdesign-blueprints.log`
- `mdesign design` exited `0`; output: `.build/evidence/mdesign-design.log`
- `mdesign validate` exited `0`; output: `.build/evidence/mdesign-validate.log`
- `mdesign export` exited `0`; output: `.build/evidence/mdesign-export.log`
- `mb init` exited `0`; output: `.build/evidence/mb-init.log`
- `mdesign validate D-1-design` exited `0`; output: `.build/evidence/mdesign-validate-d-1-design.log`
- `mdesign export D-1-design` exited `0`; output: `.build/evidence/mdesign-export-d-1-design.log`
- `mb next Contract reset and scaffold` exited `0`; output: `.build/evidence/mb-next-contract-reset-and-scaffold.log`
- `gitpilot generate Contract reset and scaffold` exited `0`; output: `.build/evidence/gitpilot-generate-contract-reset-and-scaffold.log`
- `npm run build 00-contract-scaffold` exited `0`; output: `.build/evidence/npm-run-build-00-contract-scaffold.log`
- `npm run verify 00-contract-scaffold` exited `0`; output: `.build/evidence/npm-run-verify-00-contract-scaffold.log`
- `mb check 00-contract-scaffold` exited `0`; output: `.build/evidence/mb-check-00-contract-scaffold.log`
- `mb next Framework foundation and viewport invariant` exited `0`; output: `.build/evidence/mb-next-framework-foundation-and-viewport-invariant.log`
- `gitpilot generate Framework foundation and viewport invariant` exited `0`; output: `.build/evidence/gitpilot-generate-framework-foundation-and-viewport-invariant.log`
- `npm run build 01-framework` exited `0`; output: `.build/evidence/npm-run-build-01-framework.log`
- `npm run verify 01-framework` exited `0`; output: `.build/evidence/npm-run-verify-01-framework.log`
- `npm run smoke 01-framework` exited `0`; output: `.build/evidence/npm-run-smoke-01-framework.log`
- `mb check 01-framework` exited `0`; output: `.build/evidence/mb-check-01-framework.log`
- `final npm run build` exited `0`; output: `.build/evidence/final-npm-run-build.log`
- `final npm run verify` exited `0`; output: `.build/evidence/final-npm-run-verify.log`
- `final npm run smoke` exited `0`; output: `.build/evidence/final-npm-run-smoke.log`

## Screenshots

- No screenshots were produced by the available checks.

## Known Limitations

- mb check skipped for D-1-design because it is a design-only batch validated by mdesign.
- Vercel deployment skipped because VERCEL_TOKEN was not set.
