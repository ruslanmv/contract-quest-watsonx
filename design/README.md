# Contract Quest Design Artifacts

This directory contains the Matrix Designer product contract and the Matrix Builder export used by `build.sh` to reproduce the governed Contract Quest workflow.

- `contract-quest-design-bundle.json` defines the product target, contracts, acceptance criteria, batch roadmap, and repair policy.
- `contract-quest-mb-export.json` is the Matrix Builder-ready batch plan consumed by governed generation.

Regenerate these files with Matrix Designer before running a full `./build.sh generate` workflow.
