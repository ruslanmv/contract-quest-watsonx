#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const frontendDir = path.join(root, 'frontend');
const indexPath = path.join(frontendDir, 'index.html');
const vercelPath = path.join(root, 'vercel.json');
const designPath = path.join(root, 'design', 'contract-quest-design-bundle.json');
const matrixExportPath = path.join(root, 'design', 'contract-quest-mb-export.json');
const smokePath = path.join(root, 'tests', 'playability.spec.js');

const failures = [];
function required(label, condition) {
  if (!condition) failures.push(label);
}
function read(file) {
  return fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
}
function parseJson(file, label) {
  try {
    return JSON.parse(read(file));
  } catch (error) {
    failures.push(`${label} is not valid JSON: ${error.message}`);
    return null;
  }
}

required('frontend directory exists', fs.existsSync(frontendDir) && fs.statSync(frontendDir).isDirectory());
required('frontend/index.html exists', fs.existsSync(indexPath));
required('vercel.json exists', fs.existsSync(vercelPath));
required('design bundle exists', fs.existsSync(designPath));
required('Matrix export exists', fs.existsSync(matrixExportPath));
required('Playwright smoke test exists', fs.existsSync(smokePath));

const html = read(indexPath);
if (html) {
  required('game canvas exists', html.includes('<canvas id="game"'));
  required('complete HTML document', html.trimEnd().endsWith('</html>'));
  required('logical viewport markers exist', html.includes('viewW') && html.includes('viewH'));
  required('debug hook exists', html.includes('__cqDebug'));
  required('jump edge detection exists', html.includes('jumpPressed') && html.includes('prevJump'));
  required('checkpoint marker exists', html.includes('checkpoint'));
  required('Matrix Gate marker exists', html.includes('matrixGate'));
  required('boss gate lock marker exists', html.includes('bossAlive'));
  required('Rogue Architect marker exists', html.includes('Rogue Architect'));
  required('Shield power-up marker exists', html.includes('shieldTimer'));
  required('Double Jump marker exists', html.includes('doubleJump'));
  required('lazy AudioContext marker exists', html.includes('function initAudio') && html.includes('function resumeAudio'));
  required('music system marker exists', html.includes('musicGain') && html.includes('startMusic'));
  required('audio debug state exists', html.includes('audio: { initialized'));
}

if (fs.existsSync(vercelPath)) {
  const config = parseJson(vercelPath, 'vercel.json');
  if (config) required('vercel outputDirectory is frontend', config.outputDirectory === 'frontend');
}

if (fs.existsSync(designPath)) {
  const design = parseJson(designPath, 'design bundle');
  if (design) {
    required('design bundle names Contract Quest', design.project === 'Contract Quest');
    required('design bundle has full batch roadmap', Array.isArray(design.batch_roadmap) && design.batch_roadmap.length >= 12);
    required('design bundle has functional acceptance criteria', !!design.acceptance && Array.isArray(design.acceptance.functional) && design.acceptance.functional.length >= 5);
  }
}

if (fs.existsSync(matrixExportPath)) {
  const exported = parseJson(matrixExportPath, 'Matrix export');
  if (exported) {
    required('Matrix export has batches', Array.isArray(exported.matrix_builder?.batches) && exported.matrix_builder.batches.length >= 12);
    required('Matrix export uses watsonx model', exported.matrix_builder?.model === 'openai/gpt-oss-120b');
  }
}

if (failures.length) {
  for (const failure of failures) console.error(`Static deploy verification failed: ${failure}`);
  process.exit(1);
}

console.log('Static deploy verification passed: design, Matrix export, Vercel config, and frontend markers are reproducible.');
