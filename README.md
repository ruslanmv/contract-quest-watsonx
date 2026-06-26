# Contract Quest

A static HTML5 Canvas platformer generated end-to-end by the governed
**Matrix Designer → Matrix Builder → GitPilot → IBM watsonx.ai** workflow.

This repository is intentionally minimal: it contains only the source needed to
**generate the game from zero**. The playable game, design bundles, contract
files, evidence, and packaging are all produced by `build.sh` and are therefore
not committed (see `.gitignore`).

## Repository layout

| Path | Purpose |
| --- | --- |
| `build.sh` | The orchestrator. Designs, governs, generates, verifies, and writes evidence — the executable summary of the whole workflow. |
| `Makefile` | Sets up an isolated `.venv` with `uv`, installs the governed tools, and exposes the build targets. |
| `.github/workflows/` | Contract gate + GitHub Pages deploy of the generated `frontend/`. |
| `README.md` | This file. |

Everything else — `frontend/`, `design/`, `scripts/`, `tests/`, `package.json`,
`vercel.json`, `EVIDENCE.md`, and the `MATRIX_*` contract files — is generated.

## Generate from zero

```bash
make install   # create .venv with uv and install the governed tools
make build     # run the strict from-zero governed generation (build.sh from-zero)
```

After a successful build, the generated game ships its own npm scripts:

```bash
npm run build  # rebuild/verify the static bundle
npm run verify # verify the static game
npm run smoke  # run the smoke tests
```

Required watsonx environment before `make build`:

```bash
GITPILOT_PROVIDER=watsonx
WATSONX_API_KEY=...
WATSONX_PROJECT_ID=...
WATSONX_URL=https://us-south.ml.cloud.ibm.com
GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b
```

The generated static game does not require runtime credentials. The local `.env`
is only used by the build workflow and must never be committed.

## Walkthrough

The full step-by-step reproduction guide is published here:
<https://ruslanmv.com/blog/contract-quest-watsonx/>
