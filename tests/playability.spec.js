const { test, expect } = require('@playwright/test');
const path = require('path');

const gameUrl = `file://${path.resolve(__dirname, '..', 'frontend', 'index.html')}`;

async function bootGame(page) {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });
  await page.goto(gameUrl);
  await page.keyboard.press('Enter');
  await page.keyboard.down('ArrowRight');
  await page.keyboard.press('Space');
  await page.waitForTimeout(800);
  await page.keyboard.up('ArrowRight');
  expect(errors).toEqual([]);
}

for (const scaleFactor of [1, 2]) {
  test(`gameplay smoke test at DPR ${scaleFactor}`, async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 960, height: 540 },
      deviceScaleFactor: scaleFactor,
      hasTouch: scaleFactor === 2,
      isMobile: scaleFactor === 2
    });
    const page = await context.newPage();
    await bootGame(page);

    const state = await page.evaluate(() => window.__cqDebug());
    expect(state.gameState).toBe('play');
    expect(state.viewW).toBe(960);
    expect(state.viewH).toBe(540);
    expect(state.canvasWidth).toBe(960 * scaleFactor);
    expect(state.canvasHeight).toBe(540 * scaleFactor);
    expect(state.hero.y).toBeGreaterThan(0);
    expect(state.hero.y + state.hero.h).toBeLessThanOrEqual(state.viewH);
    expect(state.ground.y).toBeLessThan(state.viewH);
    expect(state.hudVisible).toBe(true);
    expect(state.cameraX).toBeGreaterThanOrEqual(0);

    await page.evaluate(() => window.__cqDebugWarpToGate());
    const gateState = await page.evaluate(() => window.__cqDebug());
    expect(gateState.gateOnScreen).toBe(true);
    expect(gateState.matrixGate.y).toBeGreaterThan(0);
    expect(gateState.matrixGate.y).toBeLessThan(gateState.viewH);

    await context.close();
  });
}
