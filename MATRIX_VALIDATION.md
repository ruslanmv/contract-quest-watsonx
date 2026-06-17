# Validation

Each batch is validated with `mb check frontend/index.html`, which is **fail-closed**:

- exit 0 — `MATRIX_STATUS: approved` → matured into an immutable Matrix Commit
- exit 1 — `needs-repair`
- exit 2 — `rejected` (blocked)

The same `mb check` runs in CI (`.github/workflows/contract.yml`) and gates deployment.
