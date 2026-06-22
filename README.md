---
title: "Contract Quest: Building a Governed Arcade Game with Matrix Designer, Matrix Builder, GitPilot, and watsonx.ai"
excerpt: "A reproducible tutorial for creating Contract Quest from zero: Matrix Designer designs the game, Matrix Builder governs the batches, GitPilot writes the code, and openai/gpt-oss-120b on IBM watsonx.ai implements a static browser platformer for Vercel."
description: "Step-by-step tutorial for creating Contract Quest as a governed browser game with deterministic art, generated WebAudio, mobile controls, Playwright smoke tests, and release evidence."
date: 2026-06-21
permalink: /blog/contract-quest-watsonx/
tags:
  - matrix-designer
  - matrix-builder
  - gitpilot
  - watsonx
  - gpt-oss
  - game-dev
  - vercel
  - webaudio
  - qa
---

# Contract Quest

Contract Quest is a zero-backend browser arcade game and a reproducible AI production workflow. The game runs from `frontend/index.html`, but the important artifact is the pipeline:

```text
design the product
govern the implementation
generate the code
verify the result
publish with evidence
```

The workflow starts with **Matrix Designer**, converts the design into **Matrix Builder** batches, uses **GitPilot** with `openai/gpt-oss-120b` on **IBM watsonx.ai**, and verifies the static Vercel-ready game with npm and Playwright checks.

## What the game is

Contract Quest is a static canvas platformer where a robot hero runs through a contract-themed pixel world, collects Contract Coins and Validation Gems, reads RMD panels, activates checkpoints, uses Shield and Double Jump power-ups, fights Bug Bots and Prompt Slimes, and finally defeats the Rogue Architect before entering the Matrix Gate.

Production goals:

- original deterministic programmatic art;
- desktop keyboard and mobile/touch controls;
- logical viewport scaling for DPR 1 and DPR 2;
- checkpoints, Matrix Gates, power-ups, enemies, boss gating, win/game-over states;
- generated lazy WebAudio SFX/music with no MP3/WAV dependency;
- static deployment on Vercel with no backend credentials;
- local verification and Playwright smoke evidence.

## Repository layout

| Path | Purpose |
|---|---|
| `design/contract-quest-design-bundle.json` | Matrix Designer product contract: goals, architecture, entity contracts, acceptance criteria, batch roadmap, and repair policy. |
| `design/contract-quest-mb-export.json` | Matrix Builder-ready export used by `build.sh generate`. |
| `frontend/index.html` | Current static single-file canvas implementation. |
| `scripts/verify-static.js` | Fail-closed static verifier for design/export/Vercel/game markers. |
| `scripts/run-smoke.js` | Playwright smoke runner that skips safely when Playwright is not installed. |
| `tests/playability.spec.js` | DPR and gameplay smoke tests. |
| `MATRIX_*.md`, `MATRIX_BLUEPRINT.yaml` | Matrix Builder governance files. |
| `build.sh` | Reproducible workflow runner. |
| `EVIDENCE.md` | Evidence log for claims and release checks. |

## Reproduce locally

```bash
make install
make build
make run
```

The Makefile wraps the workflow for day-to-day use: `make install` installs npm dependencies and attempts to install the governed Python tooling, `make build` runs `./build.sh all`, and `make run` serves the already-created static game from `frontend/`. You can still call npm scripts directly:

```bash
npm install
npm run build
npm run verify
npm run smoke
```

`npm run smoke` runs Playwright when `@playwright/test` and browser binaries are installed. In a minimal sandbox, it prints a clear skip message instead of failing because browser tooling is absent.

## Configure watsonx/GitPilot

Do not commit secrets. `build.sh` reads variables from the shell or `.env` and accepts both canonical names and local aliases:

```bash
PROJECT_ID=<your watsonx project id>
WATSONX_PROJECT_ID=<your watsonx project id>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_API_KEY=<your IBM Cloud key>
WATSXON_API_KEY=<legacy typo also accepted>
GITPILOT_PROVIDER=watsonx
GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b
GITPILOT_MAX_TOKENS=24000
```

The deployed game does not need these variables. They are only for governed regeneration through GitPilot and watsonx.ai.

## build.sh modes

```bash
./build.sh verify
./build.sh design
GENERATE_DRY_RUN=1 ./build.sh generate
./build.sh generate
./build.sh all
```

| Mode | Behavior |
|---|---|
| `verify` | Installs npm dependencies, runs build/verify/smoke scripts when present. |
| `design` | Validates the Matrix Designer bundle with `mdesign` when available, otherwise validates the local JSON artifacts. |
| `generate` | Validates design, checks `mb`, `gitpilot`, `python3`, and watsonx environment variables, then runs every exported Matrix batch. |
| `all` | Runs design validation and local verification. |

Use `GENERATE_DRY_RUN=1 ./build.sh generate` to print the exported batch plan without invoking Matrix Builder or GitPilot. In a sandbox that does not have `mb` or `gitpilot`, `./build.sh generate` falls back to the checked-in design artifacts and static game so verification can still prove the reproducible local artifact; set `REQUIRE_GOVERNED_TOOLS=1` to fail instead of using that fallback.

## Matrix Designer-first workflow

1. Matrix Designer creates `design/contract-quest-design-bundle.json`.
2. Matrix Designer exports `design/contract-quest-mb-export.json`.
3. Matrix Builder uses the export to scope allowed files and validation.
4. GitPilot sends each scoped batch to `openai/gpt-oss-120b` on IBM watsonx.ai.
5. Each batch runs `npm run build`, `npm run verify`, optional `npm run smoke`, and `mb check`.
6. Evidence is recorded before any release claim is made.

## Batch roadmap

| # | Batch | Must validate |
|---|---|---|
| D-1 | Design Bundle | design validates and exports |
| 0 | Contract reset + scaffold | package scripts, Vercel config, static shell |
| 1 | Framework foundation | logical viewport and debug hooks |
| 2 | Art and asset pipeline | original deterministic visual target |
| 3 | Level and story model | three-level campaign metadata |
| 4 | Hero movement | jump edge/hold, collision, death/respawn semantics |
| 5 | Rewards, panels, HUD, gates | collectibles and Matrix Gate transitions |
| 6 | Enemies and power-ups | central damage path, Shield, Double Jump |
| 7 | Boss/finale | Rogue Architect cannot be skipped |
| 8 | Audio/atmosphere | lazy WebAudio, generated music/SFX |
| 9 | Mobile/accessibility | touch start/jump and responsive HUD |
| 10 | QA/evidence/release | claims match evidence |

The full machine-readable version lives in `design/contract-quest-design-bundle.json` and `design/contract-quest-mb-export.json`.

## Deployment

`vercel.json` publishes the static `frontend` directory after `npm run build`:

```bash
npm run build
npx vercel deploy --prod
```

No server, database, auth, runtime watsonx credential, or API key is required to play the deployed game.

## Evidence policy

Do not claim production readiness, public deployment success, zero runtime errors, Matrix approval, or mobile/desktop completeness unless current evidence exists in `EVIDENCE.md` and matches the repository state.

## Definition of done

Contract Quest is publishable only when all required evidence is current:

- design bundle exists and validates;
- Matrix export contains the governed batch plan;
- `npm run build` passes;
- `npm run verify` passes;
- `npm run smoke` passes in a Playwright-enabled environment or records a sandbox limitation;
- boss gate cannot be completed while `bossAlive` is true;
- audio initializes only after a user gesture;
- Vercel production URL returns HTTP 200 without authentication;
- screenshots and release notes are generated from the verified build.
