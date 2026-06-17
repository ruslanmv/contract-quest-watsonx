# GitPilot controlled prompt

You are implementing MATRIX task **TASK-002** only. AI coders are workers, not architects (RMD-101).

This is **Batch 05**. It builds on commit mc-a9d39d15b1b5. Implement only what this batch requires — nothing else.

Work Matrix-native and repository-scoped: create a feature branch for the task and make one focused commit. Do not touch files outside the allowlist. (RMD-113)

## Read the contract first

- MATRIX_BLUEPRINT.yaml
- MATRIX_STANDARDS.lock
- MATRIX_ALLOWED_CHANGES.md
- MATRIX_ACCEPTANCE_CRITERIA.md

## Task TASK-002: Levels, mini-boss, RMD governance

Allowed files — edit ONLY these (RMD-002, RMD-107):
- frontend/index.html

Acceptance criteria:
- Change implemented
- Tests pass
- No Matrix control files changed

## Hard constraints
- Do not modify MATRIX_BLUEPRINT.yaml or MATRIX_STANDARDS.lock (RMD-103).
- Do not add dependencies, services, or auth not in the blueprint (RMD-105).
- Do not edit files outside the allowlist (RMD-107).
- Keep your change patch-scoped to this one task (RMD-108).

## Validate before finishing (RMD-119)

- `pytest -q`
- `ruff check .`
- `npm run build`

## Output

Output the branch name, the commit diff (allowed files only), and pass/fail for each acceptance criterion.

Governing rules: RMD-101, RMD-102, RMD-103, RMD-105, RMD-107, RMD-108, RMD-109, RMD-110, RMD-111, RMD-112, RMD-113, RMD-114, RMD-115, RMD-116, RMD-117, RMD-118, RMD-119, RMD-120.

End your response with a stop condition (RMD-118):
```
MATRIX_STATUS: approved | needs_repair | rejected
```
