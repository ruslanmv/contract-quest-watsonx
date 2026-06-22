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
```

Do not commit API keys. The deployed game is static and does not need watsonx credentials at runtime.

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

`build.sh` supports four modes: `verify` for local npm/static checks, `design` for Matrix Designer validation and export, `generate` for design plus Matrix Builder/GitPilot/watsonx prerequisite checks, and `all` for design plus local verification.

The script reads environment variables from the shell or from `.env`. It accepts canonical watsonx names and local aliases without printing secret values:

```bash
PROJECT_ID=<your watsonx project id>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_API_KEY=<your IBM Cloud key>
# Legacy typo also accepted: WATSXON_API_KEY=<your IBM Cloud key>
```

To check governed generation prerequisites, run:

```bash
./build.sh generate
```

## Deployment

This project is configured for static hosting. Vercel should run:

```bash
npm run build
```

and publish the directory configured in `vercel.json`.

## Evidence policy

Do not claim production readiness, zero runtime errors, public deployment success, mobile support, or Matrix approval unless the relevant evidence is present in `EVIDENCE.md` and matches the current repository state.
