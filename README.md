# Contract Quest: governed browser game workflow

Contract Quest is a static browser game repository used to demonstrate a governed AI production workflow:

```text
Matrix Designer -> Matrix Builder -> GitPilot -> IBM watsonx.ai -> verification evidence
```

The goal is to build a Vercel-ready arcade platformer from a validated design bundle instead of starting with an open-ended coding prompt.

## What this repo should contain

- `frontend/index.html` — the static browser game entry point.
- `design/contract-quest-design-bundle.json` — the Matrix Designer product contract when available.
- `design/contract-quest-mb-export.json` — the Matrix Builder export when available.
- `MATRIX_*.md` and `MATRIX_BLUEPRINT.yaml` — governance files for scoped implementation batches.
- `scripts/verify-static.js` — local structural verification.
- `tests/` — smoke and regression tests.
- `build.sh` — a sandbox-friendly script that runs the governed workflow checks and, when tools and credentials are present, can execute Matrix Builder/GitPilot batches.

## Target product

Contract Quest is intended to become a zero-backend platformer with:

- original deterministic art;
- desktop and mobile controls;
- Contract Coins, Validation Gems, RMD panels, checkpoints, power-ups, enemies, and Matrix Gates;
- a Rogue Architect boss that must be defeated before the final gate opens;
- generated WebAudio music and SFX initialized only after a user gesture;
- static deployment on Vercel;
- reproducible evidence from build, verify, smoke, and governance checks.

## Governed workflow

1. Create or update the Matrix Designer design bundle.
2. Validate the design bundle.
3. Export the design into a Matrix Builder-ready plan.
4. Run scoped Matrix Builder batches.
5. Generate code through GitPilot using IBM watsonx.ai.
6. Run local checks after every batch.
7. Record evidence before making release claims.

The generation provider for governed implementation is:

```bash
export GITPILOT_PROVIDER=watsonx
export WATSONX_API_KEY=<your IBM Cloud key>
export WATSONX_PROJECT_ID=<your watsonx project>
export WATSONX_URL=https://us-south.ml.cloud.ibm.com
export GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b
export GITPILOT_MAX_TOKENS=24000
```

Do not commit API keys. The deployed game is static and does not need watsonx credentials at runtime. Rotate any watsonx key that was pasted into chat or logs before running the final governed build.

## Local commands

```bash
npm install
npm run build
npm run verify
```

If Playwright smoke tests are added and dependencies are installed, run:

```bash
npm run smoke
```

## Sandbox script

Run the repository workflow script from the repo root:

```bash
./build.sh verify
```

`build.sh` supports `verify` for local npm/static checks, `design` for strict Matrix Designer blueprint/design/validate/export, and `from-zero` for the full strict blog pipeline: design → govern → generate → verify → optional publish with evidence. `generate` and `all` are aliases for `from-zero`. Use `make verify` when you only want to validate checked-in artifacts.

The script reads environment variables from the shell or from `.env`. It accepts canonical watsonx names and local aliases without printing secret values:

```bash
GITPILOT_PROVIDER=watsonx
WATSONX_PROJECT_ID=<your watsonx project id>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_API_KEY=<your IBM Cloud key>
GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b
GITPILOT_MAX_TOKENS=24000
# Legacy typo also accepted: WATSXON_API_KEY=<your IBM Cloud key>
```

Optional deployment variables are `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_ORG_ID`, and `PUBLIC_GAME_URL`. If `VERCEL_TOKEN` is absent, the from-zero script skips deployment and records that limitation in `EVIDENCE.md`.

To run strict governed generation, run:

```bash
make build
```

The from-zero build regenerates `design/blueprint.json`, `design/contract-quest-design-bundle.json`, and `design/contract-quest-mb-export.json`; resets `.mb`, generated frontend output, `dist`, and test reports; runs each Matrix Designer-exported batch through Matrix Builder and GitPilot/watsonx.ai with a full batch prompt; verifies each batch with `npm install`, `npm run build`, `npm run verify`, `npm run smoke`, and `mb check`; and writes `EVIDENCE.md` at the end.

## Deployment

This project is configured for static hosting. Vercel should run:

```bash
npm run build
```

and publish the directory configured in `vercel.json`.

## Evidence policy

Do not claim production readiness, zero runtime errors, public deployment success, mobile support, or Matrix approval unless the relevant evidence is present in `EVIDENCE.md` and matches the current repository state.
