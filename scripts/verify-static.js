#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const frontendDir = path.join(root, 'frontend');
const indexPath = path.join(frontendDir, 'index.html');
const vercelPath = path.join(root, 'vercel.json');

function fail(message) {
  console.error(`Static deploy verification failed: ${message}`);
  process.exitCode = 1;
}

if (!fs.existsSync(frontendDir) || !fs.statSync(frontendDir).isDirectory()) {
  fail('frontend directory is missing.');
}

if (!fs.existsSync(indexPath)) {
  fail('frontend/index.html is missing.');
} else {
  const html = fs.readFileSync(indexPath, 'utf8');
  if (!html.includes('<canvas id="game"')) {
    fail('frontend/index.html does not contain the game canvas.');
  }
  if (!html.trimEnd().endsWith('</html>')) {
    fail('frontend/index.html is not a complete HTML document.');
  }
  if (!html.includes('let viewW = window.innerWidth') || !html.includes('let viewH = window.innerHeight')) {
    fail('frontend/index.html must use logical viewport dimensions for gameplay.');
  }
  if (!html.includes('window.__cqDebug')) {
    fail('frontend/index.html must expose smoke-test debug state.');
  }
  if (/Math\.random\(\)\s*\*\s*p\.w/.test(html) || /Math\.random\(\)\s*\*\s*p\.h/.test(html)) {
    fail('platform drawing must not use per-frame random texture dots.');
  }
  if (!html.includes('function drawTitleMark') || !html.includes("fitFont('CONTRACT QUEST'")) {
    fail('title screen must use fitted title rendering instead of fixed offsets.');
  }
  if (!html.includes("ctx.textAlign='left';\n    ctx.fillStyle='#fff';\n    ctx.fillText('CONTRACT',16")) {
    fail('HUD title must reset left text alignment before drawing.');
  }
}


if (!fs.existsSync(vercelPath)) {
  fail('vercel.json is missing.');
} else {
  const config = JSON.parse(fs.readFileSync(vercelPath, 'utf8'));
  if (config.outputDirectory !== 'frontend') {
    fail('vercel.json must set outputDirectory to "frontend".');
  }
}

if (process.exitCode) {
  process.exit(process.exitCode);
}

console.log('Static deploy verification passed: Vercel will publish frontend/index.html.');
