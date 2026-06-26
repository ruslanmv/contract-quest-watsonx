#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = process.cwd();
const required = [
  'frontend/index.html',
  'package.json',
  'vercel.json',
  'MATRIX_BLUEPRINT.yaml',
  'MATRIX_TASKS.md',
  'MATRIX_ACCEPTANCE_CRITERIA.md',
  'MATRIX_VALIDATION.md',
  'MATRIX_ALLOWED_CHANGES.md'
];
const missing = required.filter(f => !fs.existsSync(path.join(root, f)));
if (missing.length) { console.error('Missing required files:', missing.join(', ')); process.exit(1); }
const html = fs.readFileSync(path.join(root, 'frontend/index.html'), 'utf8');
const markers = ['Contract Quest','bossAlive','jumpPressed','jumpHeld','AudioContext','Validation Gems','MATRIX GATE','__CONTRACT_QUEST_DEBUG__'];
const absent = markers.filter(m => !html.includes(m));
if (absent.length) { console.error('Missing frontend markers:', absent.join(', ')); process.exit(1); }
const envLeak = ['WATSONX_API_KEY','WATSXON_API_KEY','WATSONX_APIKEY'].some(k => html.includes(k));
if (envLeak) { console.error('Credential variable leaked into frontend'); process.exit(1); }
fs.mkdirSync('dist', { recursive: true });
fs.copyFileSync('frontend/index.html', 'dist/index.html');
console.log('verify-static passed');
