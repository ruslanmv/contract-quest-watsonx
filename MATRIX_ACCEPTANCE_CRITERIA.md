# Acceptance criteria (RMD-111: acceptance criteria are law)

Per batch:
- `frontend/index.html` exists and contains a `<canvas>`.
- The extracted `<script>` passes `node --check` (valid JavaScript).
- The file ends with a complete `</html>`.
- Features from earlier batches are preserved (no regressions).
- A headless smoke test reports zero runtime errors.

Final:
- Premium arcade composition (HUD, sunset world, contract panels, Matrix Gate).
- Run / jump / stomp / coins / score / lives / checkpoint / power-ups / levels / boss.
- Mobile + desktop. Footer credit: "coded by GitPilot — under a Matrix Builder contract".
- No copyrighted assets. watsonx only.
