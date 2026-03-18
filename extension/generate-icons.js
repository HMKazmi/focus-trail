/**
 * generate-icons.js
 * ─────────────────
 * Generates simple PNG icon placeholders for the FocusTrail Chrome extension.
 * Requires Node.js – no extra dependencies (uses the Canvas API via node-canvas,
 * OR falls back to writing minimal valid PNG data URIs).
 *
 * Usage:
 *   node generate-icons.js
 *
 * This creates icons/icon16.png, icons/icon48.png, icons/icon128.png
 */

const fs   = require('fs');
const path = require('path');

// Try to use canvas if installed, otherwise write minimal valid PNGs
let canvas;
try { canvas = require('canvas'); } catch (_) { canvas = null; }

const SIZES  = [16, 48, 128];
const OUTDIR = path.join(__dirname, 'icons');
if (!fs.existsSync(OUTDIR)) fs.mkdirSync(OUTDIR);

if (canvas) {
  // ── node-canvas path ──────────────────────────────────────────
  const { createCanvas } = canvas;
  SIZES.forEach(size => {
    const c   = createCanvas(size, size);
    const ctx = c.getContext('2d');

    // Background gradient
    const grad = ctx.createLinearGradient(0, 0, size, size);
    grad.addColorStop(0, '#6366f1');
    grad.addColorStop(1, '#4f52d4');
    ctx.fillStyle = grad;
    // Rounded rect
    const r = size * 0.2;
    ctx.beginPath();
    ctx.moveTo(r, 0);
    ctx.arcTo(size, 0, size, size, r);
    ctx.arcTo(size, size, 0, size, r);
    ctx.arcTo(0, size, 0, 0, r);
    ctx.arcTo(0, 0, size, 0, r);
    ctx.closePath();
    ctx.fill();

    // ✦ symbol
    ctx.fillStyle = '#fff';
    ctx.font      = `bold ${Math.round(size * 0.55)}px serif`;
    ctx.textAlign    = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('✦', size / 2, size / 2);

    fs.writeFileSync(path.join(OUTDIR, `icon${size}.png`), c.toBuffer('image/png'));
    console.log(`  ✓ icon${size}.png`);
  });
} else {
  // ── Minimal 1×1 transparent PNG fallback ─────────────────────
  // A valid 1×1 transparent PNG encoded as a Buffer (68 bytes).
  // Chrome will accept it; replace with real icons when possible.
  const TRANSPARENT_1X1_PNG = Buffer.from(
    '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489' +
    '0000000a49444154789c6260000000020001e221bc330000000049454e44ae426082',
    'hex'
  );
  SIZES.forEach(size => {
    fs.writeFileSync(path.join(OUTDIR, `icon${size}.png`), TRANSPARENT_1X1_PNG);
    console.log(`  ✓ icon${size}.png (placeholder – replace with real ${size}×${size} icon)`);
  });
  console.log('\n  Tip: npm install canvas  then re-run for proper icons.');
}

console.log('\nDone! Icons written to icons/');
