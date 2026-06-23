#!/usr/bin/env node
const { spawnSync } = require('child_process');

function hasPlaywright() {
  try {
    require.resolve('@playwright/test');
    return true;
  } catch (_) {
    return false;
  }
}

if (!hasPlaywright()) {
  const strict = process.env.REQUIRE_PLAYWRIGHT_SMOKE === '1';
  const message = strict
    ? 'Playwright is required for this governed build but is not installed.'
    : 'Playwright is not installed in this sandbox; skipping smoke tests.';
  console.log(message);
  console.log('Install @playwright/test and browser binaries to run tests/playability.spec.js.');
  process.exit(strict ? 1 : 0);
}

const result = spawnSync('npx', ['playwright', 'test'], { stdio: 'inherit', shell: process.platform === 'win32' });
process.exit(result.status ?? 1);
