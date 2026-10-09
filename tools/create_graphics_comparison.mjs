// Preserve native screenshots without altering their pixels.
import { mkdir, copyFile, readFile, writeFile } from 'node:fs/promises';
const root = new URL('../', import.meta.url);
const dest = new URL('art/scenery/coastal-fidelity/', root);
await mkdir(dest, { recursive: true });
const views = ['kumbalam', 'pilot', 'passenger'];
for (const phase of ['before', 'verified']) {
  await copyFile(new URL(`.local/graphics-${phase}.json`, root), new URL(`${phase}.json`, dest));
  for (const view of views) await copyFile(new URL(`.local/graphics-${phase}-${view}.png`, root), new URL(`${phase}-${view}.png`, dest));
}
for (const view of ['station-close', 'neighbourhood']) await copyFile(new URL(`.local/graphics-verified-${view}.png`, root), new URL(`${view}.png`, dest));
const before = JSON.parse(await readFile(new URL('before.json', dest), 'utf8'));
const after = JSON.parse(await readFile(new URL('verified.json', dest), 'utf8'));
const rows = views.map(view => {
  const a = before.find(r => r.view === view).frame_ms.mean;
  const b = after.find(r => r.view === view).frame_ms.mean;
  return `<tr><th>${view}</th><td>${a.toFixed(2)} ms</td><td>${b.toFixed(2)} ms</td><td>+${((b/a-1)*100).toFixed(1)}%</td></tr>`;
}).join('');
await writeFile(new URL('index.html', dest), `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Coastal graphics — R15 / R16</title>
<style>
body{margin:32px auto;max-width:1280px;padding:0 20px;background:#101719;color:#e1e8e5;font:16px/1.6 system-ui}
h1{font-weight:650}p{max-width:850px}button,input{font:inherit}button{background:#253c39;color:white;border:1px solid #72958c;border-radius:6px;padding:8px 20px;margin:0 8px 12px 0;cursor:pointer}
.compare{position:relative;aspect-ratio:16/9;overflow:hidden;border-radius:8px;background:#192a29}.compare img{position:absolute;width:100%;height:100%;object-fit:contain}.after{clip-path:inset(0 50% 0 0)}input{width:100%;margin-top:20px;accent-color:#8ed1b7}.labels{display:flex;justify-content:space-between}table{border-collapse:collapse;margin:25px 0}th,td{padding:8px 22px;text-align:left;border-bottom:1px solid #49615a}.detail{width:100%;border-radius:8px}
</style>
<h1>Coastal graphics: native game comparison</h1>
<p>R16 adds fitted detailed houses, a new bungalow, varied vegetation and terrain, road shoulders, weathered station finishes and forecourt detail. The images below are unaltered Godot screenshots from the same paused seed, cameras and graphics settings.</p>
<nav>${views.map(v => `<button data-view="${v}">${v}</button>`).join('')}</nav>
<div class="compare"><img id="before" src="before-kumbalam.png" alt="Previous game graphics"><img id="after" class="after" src="verified-kumbalam.png" alt="R16 game graphics"></div>
<label for="slider">Drag to compare</label><input id="slider" type="range" min="0" max="100" value="50"><div class="labels"><span>R16 · left</span><span>R15 · right</span></div>
<h2>Performance</h2><p>Radeon 780M on the development PC; these are not RTX 4090 measurements. Forward+, 1280 × 720, VSync off, unchanged 8× MSAA + FXAA, 8K shadows and SSAO/SSIL. Tiles settled, 45 warmup frames then 120 measured frames per view. Short controlled samples; route-wide and long-duration performance will vary.</p>
<table><tr><th>View</th><th>Before</th><th>R16</th><th>Frame-time change</th></tr>${rows}</table>
<h2>Station frontage</h2><img class="detail" src="station-close.png" alt="Weathered paving, planted forecourt and marked parking bays at Kumbalam">
<h2>Reconstructed neighbourhood</h2><img class="detail" src="neighbourhood.png" alt="New bungalow with veranda, recessed windows, steps and supported foundation">
<p>The route remains a reconstruction with modular architecture and procedural vegetation. This pass improves detail and surface quality; it does not make every location photogrammetric or faithfully model every real house.</p>
<script>
const slider=document.querySelector('#slider'),after=document.querySelector('#after'),before=document.querySelector('#before');
slider.addEventListener('input',()=>after.style.clipPath='inset(0 '+(100-slider.value)+'% 0 0)');
document.querySelectorAll('[data-view]').forEach(button=>button.addEventListener('click',()=>{before.src='before-'+button.dataset.view+'.png';after.src='verified-'+button.dataset.view+'.png';}));
</script></html>`);
console.log('Native graphics comparison: art/scenery/coastal-fidelity/index.html');
