// Small read-only LAN download service. No dependencies or directory browsing.
import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { updateRoutes } from './updater/routes.mjs';

const { values } = parseArgs({ options: {
  host: { type: 'string' }, port: { type: 'string', default: '8765' },
  prefix: { type: 'string', default: '24' },
} });
const ipv4 = value => {
  const parts = value.split('.');
  if (parts.length !== 4 || parts.some(p => !/^\d{1,3}$/.test(p) || +p > 255)) throw Error('Invalid IPv4 address');
  return parts.reduce((n, p) => ((n << 8) | +p) >>> 0, 0);
};
const host = values.host;
const port = Number(values.port);
const prefix = Number(values.prefix);
if (!host || !Number.isInteger(port) || port < 1024 || port > 65535 || !Number.isInteger(prefix) || prefix < 8 || prefix > 32) {
  throw Error('Pass --host=<LAN IPv4> and optional --port / --prefix.');
}
const address = ipv4(host);
if (!host.startsWith('192.168.') && !host.startsWith('10.') && (address >>> 20) !== (ipv4('172.16.0.0') >>> 20)) {
  throw Error('Bind to a private LAN IPv4 address.');
}
const mask = (0xffffffff << (32 - prefix)) >>> 0;
const exportRoot = fileURLToPath(new URL('../export/', import.meta.url));
const updateEntry = updateRoutes(exportRoot);
const files = new Map([
  ['/TrainGame-Updater.zip', ['TrainGame-Updater.zip', 'application/zip']],
  ['/TrainGame-Updater.zip.sha256', ['TrainGame-Updater.zip.sha256', 'text/plain; charset=utf-8']],
  ['/updater/instructions', ['updater/UPDATER-README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R18-Windows.zip', ['TrainGame-Kerala-Coast-R18-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R18-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R18-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r18/README.txt', ['TrainGame-Kerala-Coast-R18-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r18/controllers', ['TrainGame-Kerala-Coast-R18-Windows/guides/controllers.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R17-Windows.zip', ['TrainGame-Kerala-Coast-R17-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R17-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R17-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r17/README.txt', ['TrainGame-Kerala-Coast-R17-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r17/audio', ['TrainGame-Kerala-Coast-R17-Windows/guides/enhanced-audio.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R16-Windows.zip', ['TrainGame-Kerala-Coast-R16-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R16-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R16-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r16/README.txt', ['TrainGame-Kerala-Coast-R16-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r16/graphics', ['TrainGame-Kerala-Coast-R16-Windows/guides/visual-fidelity.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R15-Windows.zip', ['TrainGame-Kerala-Coast-R15-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R15-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R15-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r15/README.txt', ['TrainGame-Kerala-Coast-R15-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r15/station-models', ['TrainGame-Kerala-Coast-R15-Windows/guides/station-model-port.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R14-Windows.zip', ['TrainGame-Kerala-Coast-R14-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R14-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R14-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r14/README.txt', ['TrainGame-Kerala-Coast-R14-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r14/save-load', ['TrainGame-Kerala-Coast-R14-Windows/guides/save-load.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R13-Windows.zip', ['TrainGame-Kerala-Coast-R13-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R13-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R13-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r13/README.txt', ['TrainGame-Kerala-Coast-R13-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r13/dispatcher', ['TrainGame-Kerala-Coast-R13-Windows/guides/dispatcher-overhaul.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R12-Windows.zip', ['TrainGame-Kerala-Coast-R12-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R12-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R12-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r12/README.txt', ['TrainGame-Kerala-Coast-R12-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r12/passengers', ['TrainGame-Kerala-Coast-R12-Windows/guides/passengers.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R11-Windows.zip', ['TrainGame-Kerala-Coast-R11-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R11-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R11-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r11/README.txt', ['TrainGame-Kerala-Coast-R11-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r11/depots', ['TrainGame-Kerala-Coast-R11-Windows/guides/depot-workings.md', 'text/plain; charset=utf-8']],
  ['/kerala-r11/station-models', ['TrainGame-Kerala-Coast-R11-Windows/guides/station-model-port.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R10-Windows.zip', ['TrainGame-Kerala-Coast-R10-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R10-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R10-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r10/README.txt', ['TrainGame-Kerala-Coast-R10-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r10/rakes', ['TrainGame-Kerala-Coast-R10-Windows/guides/rakes.md', 'text/plain; charset=utf-8']],
  ['/kerala-r10/walking', ['TrainGame-Kerala-Coast-R10-Windows/guides/walking.md', 'text/plain; charset=utf-8']],
  ['/kerala-r10/stations', ['TrainGame-Kerala-Coast-R10-Windows/guides/kerala-station-audit.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R9-Windows.zip', ['TrainGame-Kerala-Coast-R9-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R9-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R9-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r9/README.txt', ['TrainGame-Kerala-Coast-R9-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r9/ride', ['TrainGame-Kerala-Coast-R9-Windows/guides/ride-dynamics.md', 'text/plain; charset=utf-8']],
  ['/kerala-r9/audio', ['TrainGame-Kerala-Coast-R9-Windows/guides/enhanced-audio.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R8-Windows.zip', ['TrainGame-Kerala-Coast-R8-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R8-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R8-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r8/README.txt', ['TrainGame-Kerala-Coast-R8-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r8/controllers', ['TrainGame-Kerala-Coast-R8-Windows/guides/controllers.md', 'text/plain; charset=utf-8']],
  ['/kerala-r8/walking', ['TrainGame-Kerala-Coast-R8-Windows/guides/walking.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R7-Windows.zip', ['TrainGame-Kerala-Coast-R7-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R7-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R7-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r7/README.txt', ['TrainGame-Kerala-Coast-R7-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r7/dispatcher', ['TrainGame-Kerala-Coast-R7-Windows/guides/dispatcher-overhaul.md', 'text/plain; charset=utf-8']],
  ['/kerala-r7/walking', ['TrainGame-Kerala-Coast-R7-Windows/guides/walking.md', 'text/plain; charset=utf-8']],
  ['/kerala-r7/controllers', ['TrainGame-Kerala-Coast-R7-Windows/guides/controllers.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R6-Windows.zip', ['TrainGame-Kerala-Coast-R6-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R6-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R6-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r6/README.txt', ['TrainGame-Kerala-Coast-R6-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala-r6/dispatcher', ['TrainGame-Kerala-Coast-R6-Windows/guides/dispatcher-overhaul.md', 'text/plain; charset=utf-8']],
  ['/kerala-r6/walking', ['TrainGame-Kerala-Coast-R6-Windows/guides/walking.md', 'text/plain; charset=utf-8']],
  ['/kerala-r6/controllers', ['TrainGame-Kerala-Coast-R6-Windows/guides/controllers.md', 'text/plain; charset=utf-8']],
]);
for (const name of ['index.html', 'before-kumbalam.png', 'verified-kumbalam.png', 'before-pilot.png', 'verified-pilot.png', 'before-passenger.png', 'verified-passenger.png', 'station-close.png', 'neighbourhood.png']) {
  files.set('/kerala-r16/preview/' + name, ['TrainGame-Kerala-Coast-R16-Windows/guides/coastal-fidelity/' + name, name.endsWith('.png') ? 'image/png' : 'text/html; charset=utf-8']);
}
const text = (res, status, body, method) => {
  res.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8', 'Content-Length': Buffer.byteLength(body) });
  res.end(method === 'HEAD' ? undefined : body);
};
const server = http.createServer(async (req, res) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Cache-Control', 'no-store');
  try {
    const remote = ipv4((req.socket.remoteAddress ?? '').replace(/^::ffff:/, ''));
    if ((remote & mask) !== (address & mask)) return text(res, 403, 'Local subnet only.\n', req.method);
    if (!['GET', 'HEAD'].includes(req.method)) {
      res.setHeader('Allow', 'GET, HEAD');
      return text(res, 405, 'Downloads only.\n', req.method);
    }
    const path = new URL(req.url, 'http://localhost').pathname;
    if (path === '/') {
      const ready = async revision => {
        const base = `TrainGame-Kerala-Coast-${revision}-Windows.zip`;
        try { await stat(join(exportRoot, base + '.sha256')); return await stat(join(exportRoot, base)); }
        catch { return null; }
      };
      const r18Info = await ready('R18');
      const r18 = r18Info ? `<h2>Latest: Kerala Coast R18</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R18-Windows.zip">Download latest build · ${(r18Info.size / 1048576).toFixed(1)} MiB</a></p><p>Pilot by default. D-pad right/left first enters the matching head-out; repeat to cycle. Down goes back one coach, Up moves toward the pilot. Left stick moves around inside the cab; left-stick click returns to pilot.</p><p>Right-stick click starts free camera at eye height on the nearest open platform. LS moves, RS looks, RT/LT zoom and RB/LB raise/lower. Hold RS for 0.65 s to switch triggers between zoom and train control, then release controls to arm. R14–R17 saves remain compatible.</p><p><a href="/kerala-r18/README.txt">Instructions</a> · <a href="/kerala-r18/controllers">Controller guide</a> · <a href="/TrainGame-Kerala-Coast-R18-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r17Info = await ready('R17');
      const r17 = r17Info ? `<h2>Latest: Kerala Coast R17</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R17-Windows.zip">Download latest build · ${(r17Info.size / 1048576).toFixed(1)} MiB</a></p><p>Free-camera audio now follows your actual viewpoint. Approach a moving train to hear its rolling, joints and squeal at the correct distance, matching engine and horn positioning. The approved sounds and speed response are unchanged.</p><p>Right-stick click selects free exterior; move near the wheels, then away. Left-stick click returns to pilot. R14–R16 saves remain compatible.</p><p><a href="/kerala-r17/README.txt">Instructions</a> · <a href="/kerala-r17/audio">Audio fix and checks</a> · <a href="/TrainGame-Kerala-Coast-R17-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r16Info = await ready('R16');
      const r16 = r16Info ? `<h2>Latest: Kerala Coast R16</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R16-Windows.zip">Download latest build · ${(r16Info.size / 1048576).toFixed(1)} MiB</a></p><p>Improved coastal graphics: detailed houses with window recesses, verandas, balconies and roof fittings, a new Kerala bungalow, more varied vegetation and grass/laterite terrain, dusty road shoulders, weathered platform paving and canopy sheets, planted forecourts and parking bays. More neutral daylight and reduced surface washout.</p><p>R14/R15 saves remain compatible. Visit Kumbalam from the dispatcher and inspect the station frontage and surrounding houses with the external free camera. Compare cab and passenger views at your usual resolution.</p><p><a href="/kerala-r16/preview/index.html">Before / after screenshots</a> · <a href="/kerala-r16/README.txt">Instructions</a> · <a href="/kerala-r16/graphics">Graphics scope and measurements</a> · <a href="/TrainGame-Kerala-Coast-R16-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r15Info = await ready('R15');
      const r15 = r15Info ? `<h2>Latest: Kerala Coast R15</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R15-Windows.zip">Download latest build · ${(r15Info.size / 1048576).toFixed(1)} MiB</a></p><p>New coastal station architecture at 52 active stops: station-specific facades, roofs, furnished rooms and original signs, ported from the reviewed Blender masters with full visible geometry. Viranialur uses its photographed open shelters. Streamed scenery keeps the buildings and forecourts clear of generic houses and trees.</p><p>Operating tracks and platforms retain the CSV layout. The source's static yards are not overlaid. Includes R14 Save/Load; R14 saves retain the same track topology. Use the dispatcher station visitor and external free camera to inspect Kumbalam, Turavur, Kollam and Neyyattinkara.</p><p><a href="/kerala-r15/README.txt">Instructions</a> · <a href="/kerala-r15/station-models">Station port and scope</a> · <a href="/TrainGame-Kerala-Coast-R15-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r14Info = await ready('R14');
      const r14 = r14Info ? `<h2>Latest: Kerala Coast R14</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R14-Windows.zip">Download latest build · ${(r14Info.size / 1048576).toFixed(1)} MiB</a></p><p>Save and load the whole railway: trains, active routes and dispatch commitments, timetables, passengers and depot workings. Restore your assigned service, driving controls, camera and walking position inside a coach or on a platform.</p><p><b>Esc / controller Menu → Save journey / Load journey</b>. Five manual slots plus Quick save. <b>Ctrl+S</b> quick-saves; <b>Ctrl+L</b> opens Load. Overwrites keep the previous backup, and loads start paused. Saves live outside the game folder; Open saves folder lets you transfer them to another PC. No autosave. Includes R13's overtake fix.</p><p><a href="/kerala-r14/README.txt">Instructions</a> · <a href="/kerala-r14/save-load">Save/Load guide</a> · <a href="/TrainGame-Kerala-Coast-R14-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r13Info = await ready('R13');
      const r13 = r13Info ? `<h2>Latest: Kerala Coast R13</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R13-Windows.zip">Download latest build · ${(r13Info.size / 1048576).toFixed(1)} MiB</a></p><p>Fixes the Turavur overtake departure order after long waits. Once the VB arrives alongside for an overtake, a routine crossing delay preserves its departure ahead of the passenger. Earlier signal waits no longer expire a fresh overtake plan. Existing route, occupancy and full-tail protection remain active; unavailable trains and circular dependencies can still trigger replanning.</p><p>Includes R12 passengers and fullscreen. Start a fresh scenario.</p><p><a href="/kerala-r13/README.txt">Instructions</a> · <a href="/kerala-r13/dispatcher">Dispatcher guide</a> · <a href="/TrainGame-Kerala-Coast-R13-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r12Info = await ready('R12');
      const r12 = r12Info ? `<h2>Latest: Kerala Coast R12</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R12-Windows.zip">Download latest build · ${(r12Info.size / 1048576).toFixed(1)} MiB</a></p><p>Travelling passengers in ICF, LHB and Vande Bharat: visible seated riders, alighting and boarding through platform-side doors at scheduled stops. Traction waits for boarding and closed doors; F12 shows passenger totals. Everyone alights before the depot working. Local crowd rendering has a fixed performance budget while every journey stays simulated.</p><p><b>F11 / Alt+Enter</b> toggles fullscreen; controller Menu has the same option. The preference is saved, and new portable installations default to fullscreen. Start a fresh scenario.</p><p><a href="/kerala-r12/README.txt">Instructions</a> · <a href="/kerala-r12/passengers">Passengers, fullscreen and scope</a> · <a href="/TrainGame-Kerala-Coast-R12-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r11Info = await ready('R11');
      const r11 = r11Info ? `<h2>Latest: Kerala Coast R11</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R11-Windows.zip">Download latest build · ${(r11Info.size / 1048576).toFixed(1)} MiB</a></p><p>Completed services unload and run as empty stock to reserved depot berths. Signals, route locks and full-tail clearance remain active. Passenger results stay recorded; the desk shows unloading, depot workings and stabled trains.</p><p>Detailed ERS west/east halls, TVC heritage frontage, Nagercoil buildings/interiors and furnished depot workshops, ported from the pinned station models with full visible geometry. Operating platforms/tracks retain the CSV game layout; depot approaches are reconstructions.</p><p>Includes full-length homogeneous ICF/LHB rakes, 8/16-car VB, moving passenger-coach access and coach-body rattles. Start a fresh scenario.</p><p><a href="/kerala-r11/README.txt">Instructions</a> · <a href="/kerala-r11/depots">Depot workings</a> · <a href="/kerala-r11/station-models">Station port and scope</a> · <a href="/TrainGame-Kerala-Coast-R11-Windows.zip.sha256">SHA-256</a></p>` : '';
      const r10Info = await ready('R10');
      const r10 = r10Info ? `<h2>Latest: Kerala Coast R10</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R10-Windows.zip">Download latest build · ${(r10Info.size / 1048576).toFixed(1)} MiB</a></p><p>Full-length trains: K1 has 20 seated ICF coaches; WAP expresses have 22. Homogeneous blue ICF or red/grey LHB rakes, with matching mass, acceleration, axle audio and occupied length. Vande Bharat remains 8/16 cars. Platforms and sidings now use clear lengths between signals and points, with longer yard ladders and properly positioned starters. Intermittent metallic body rattles add movement sounds, strongest in ICF coaches.</p><p>Rake profiles can be selected and exported in the Service Designer. WAP-7 has no passenger gangway: at a platform stop, stand with Y/E, use A/left-click at the cab side door, walk along the platform and board coach 1. While moving, Pause/Start &gt; Go to passenger coach selects any carriage; Y/E stands inside and left-stick click returns to pilot. Your service and driving controls stay set.</p><p>All 56 platform totals follow the supplied CSV. K1 has 55 calls because Tirunettur is closed. Kumbalam has one passenger platform and two through roads; dispatch forecasts the VB vacating that platform.</p><p>Representative formations; dedicated utility/guard cars are not yet modelled. Start a fresh scenario.</p><p><a href="/kerala-r10/README.txt">Instructions</a> · <a href="/kerala-r10/rakes">Rakes and research</a> · <a href="/kerala-r10/walking">Walking</a> · <a href="/kerala-r10/stations">Station register audit</a> · <a href="/TrainGame-Kerala-Coast-R10-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const r9Info = await ready('R9');
      const r9 = r9Info ? `<h2>Latest: Kerala Coast R9</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R9-Windows.zip">Download latest build · ${(r9Info.size / 1048576).toFixed(1)} MiB</a></p><p>Feel joint and point jolts, vibration, curve sway and pitch under power/braking. The cab and coach body move together while the wheels stay on the rails. Head-out audio no longer uses the enclosed-cab filter; walking in a coach retains passenger acoustics.</p><p>The dispatcher prepares a free home route from the preceding automatic block, retaining occupancy, conflict and stop protection. All 32 services completed the rehearsal safely. Start a fresh scenario.</p><p><a href="/kerala-r9/README.txt">Instructions</a> · <a href="/kerala-r9/ride">Ride motion</a> · <a href="/kerala-r9/audio">Audio comparison</a> · <a href="/TrainGame-Kerala-Coast-R9-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const r8Info = await ready('R8');
      const r8 = r8Info ? `<h2>Latest: Kerala Coast R8</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R8-Windows.zip">Download latest build · ${(r8Info.size / 1048576).toFixed(1)} MiB</a></p><p><b>D-pad left/right</b> cycles every camera. <b>Left-stick click</b> returns to pilot; <b>right-stick click</b> selects external FREE camera. Both controller layouts use these shortcuts, including on foot. Free camera stays detached from the train.</p><p>On foot: B crouches and D-pad up controls the headlamp. Default layout: X+Y horn. Includes R7's future-clearance dispatcher and confirmed train deletion.</p><p><a href="/kerala-r8/README.txt">Instructions</a> · <a href="/kerala-r8/controllers">Xbox controls</a> · <a href="/TrainGame-Kerala-Coast-R8-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const r7Info = await ready('R7');
      const r6Info = await ready('R6');
      const r7 = r7Info ? `<h2>Latest: Kerala Coast R7</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R7-Windows.zip">Download latest build · ${(r7Info.size / 1048576).toFixed(1)} MiB</a></p><p>Automatic future-platform crossing plans: approach Kumbalam, wait for the VB to vacate P3, then enter while K2 waits on P2. Actual occupancy and signals still govern every move; the dispatcher protects the VB's escape and onward berth.</p><p>In dispatch, inspect a train and choose <b>Delete service…</b> to remove a blocking service for this run. Confirmation defaults to keeping it. Your assigned train is protected; restart restores the scenario.</p><p>Includes R6's 32 services, walking, next-stop HUD and restored engine audio. Start a fresh scenario.</p><p><a href="/kerala-r7/README.txt">Instructions</a> · <a href="/kerala-r7/dispatcher">Dispatcher guide</a> · <a href="/TrainGame-Kerala-Coast-R7-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const r6 = r6Info ? `<h2>Latest: Kerala Coast R6</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R6-Windows.zip">Download latest build · ${(r6Info.size / 1048576).toFixed(1)} MiB</a></p><p>32 scheduled services with the slow K1 passenger selected. Next-stop metres and estimated world minutes replace the camera label. Dispatcher admission checks usable passenger platforms, opposing approaches and onward routes to prevent the reported Kumbalam trap.</p><p>Get up, leave through a platform-side doorway at a stop, walk along the platform and board another carriage. A / left-click uses the doorway prompt. Hold left-stick click + D-pad left to always select left head-out. Electric engine hum, traction and horn are restored alongside the approved joint and squeal sounds.</p><p>Start a fresh scenario in this build. Your driving assignment stays set when walking or viewing another train. The railway continues while you are on the platform. Animated door leaves and boarding other services are not included.</p><p><a href="/kerala-r6/README.txt">Instructions</a> · <a href="/kerala-r6/walking">Walking</a> · <a href="/kerala-r6/controllers">Xbox controls</a> · <a href="/kerala-r6/dispatcher">Dispatcher</a> · <a href="/TrainGame-Kerala-Coast-R6-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const prior = r11 + (r11Info ? r10.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R10 fallback') : r10) + (r11Info || r10Info ? r9.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R9 fallback') : r9) + (r11Info || r10Info || r9Info ? r8.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R8 fallback') : r8) + (r11Info || r10Info || r9Info || r8Info ? r7.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R7 fallback') : r7) + (r11Info || r10Info || r9Info || r7Info || r8Info ? r6.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R6 fallback') : r6);
      const previous = r12 + (r12Info ? prior.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : prior);
      const earlier = r13 + (r13Info ? previous.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : previous);
      const saved = r14 + (r14Info ? earlier.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : earlier);
      const stations = r15 + (r15Info ? saved.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : saved);
      const scenery = r16 + (r16Info ? stations.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : stations);
      const audio = r17 + (r17Info ? scenery.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : scenery);
      let updater = '';
      let updateVersion = '';
      try {
        const info = await stat(join(exportRoot, 'TrainGame-Updater.zip'));
        await stat(join(exportRoot, 'updates/latest.json'));
        await stat(join(exportRoot, 'TrainGame-Updater.zip.sha256'));
        const signed = JSON.parse(await readFile(join(exportRoot, 'updates/latest.json'), 'utf8'));
        const release = JSON.parse(Buffer.from(signed.payload, 'base64'));
        if (!/^TrainGame-[A-Za-z0-9_-]+$/.test(release.version)) throw Error('Invalid update version');
        updateVersion = release.version;
        updater = `<h2>Already installed? Update only what changed</h2><p><a class="download" href="/TrainGame-Updater.zip">Get Update &amp; Play · ${(info.size / 1024).toFixed(0)} KiB</a></p><p>One-time setup: extract this tiny ZIP beside your existing <b>TrainGame.exe</b> and <b>TrainGame.pck</b>. Open <b>Update and Play.exe</b> for future releases. It keeps unchanged data in place and downloads only changed blocks. No fresh full ZIP or reinstall required.</p><p>R17 → R18 changes about 17 MB of the main game pack. Interrupted updates resume through the launcher. Saved journeys stay in place. Use <b>Play installed</b> when the host is offline.</p><p><a href="/updater/instructions">Setup and recovery guide</a> · <a href="/TrainGame-Updater.zip.sha256">Launcher SHA-256</a></p><h2>First installation / full downloads</h2>`;
      } catch { /* The existing ZIP downloads remain available before updater publication. */ }
      const fullDownloads = r18 + (r18Info ? audio.replaceAll('Latest:', 'Fallback:').replaceAll('Download latest build', 'Download fallback') : audio);
      const sections = updater + (updateVersion ? `<p>Current updater release: <b>${updateVersion}</b></p>` + fullDownloads.replaceAll('Latest:', 'Full install:').replaceAll('Download latest build', 'Download full build') : fullDownloads);
      const body = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Train Game download</title><style>body{max-width:720px;margin:48px auto;padding:24px;font:18px/1.6 system-ui;background:#101c28;color:#e5edf4}a{color:#83cfff}h1{line-height:1.2}.download{display:inline-block;background:#83cfff;color:#101c28;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold}small{color:#afc0ce}</style><h1>Train Game</h1>${sections}<ol><li>Download and extract the entire ZIP.</li><li>Open <b>TrainGame.exe</b> and keep its PCK beside it.</li><li>Start a fresh scenario and press F1 for the briefing.</li></ol><p>No Godot or Blender installation is needed. Recent fallback builds are retained below the latest download; much older builds have been removed to free space.</p><small>Keep the host PC awake until your download finishes.</small></html>`;
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Length': Buffer.byteLength(body) });
      return res.end(req.method === 'HEAD' ? undefined : body);
    }
    const entry = files.get(path) ?? await updateEntry(path);
    if (!entry) return text(res, 404, 'Not found.\n', req.method);
    const file = join(exportRoot, entry[0]);
    const info = await stat(file);
    const etag = `"${info.size}-${Math.floor(info.mtimeMs)}"`;
    let start = 0, end = info.size - 1, status = 200;
    const range = req.headers.range;
    if (range && (!req.headers['if-range'] || req.headers['if-range'] === etag)) {
      const match = /^bytes=(\d*)-(\d*)$/.exec(range);
      if (!match || (!match[1] && !match[2])) {
        res.setHeader('Content-Range', `bytes */${info.size}`);
        return text(res, 416, 'Invalid byte range.\n', req.method);
      }
      if (match[1]) { start = Number(match[1]); end = match[2] ? Math.min(Number(match[2]), end) : end; }
      else { start = Math.max(0, info.size - Number(match[2])); }
      if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start > end || start >= info.size) {
        res.setHeader('Content-Range', `bytes */${info.size}`);
        return text(res, 416, 'Unsatisfiable byte range.\n', req.method);
      }
      status = 206;
      res.setHeader('Content-Range', `bytes ${start}-${end}/${info.size}`);
    }
    res.writeHead(status, { 'Content-Type': entry[1], 'Content-Length': end - start + 1,
      'Accept-Ranges': 'bytes', ETag: etag, 'Last-Modified': info.mtime.toUTCString(),
      ...(path.endsWith('.zip') ? { 'Content-Disposition': `attachment; filename="${entry[0]}"` } : {}) });
    if (req.method === 'HEAD') return res.end();
    const stream = createReadStream(file, { start, end });
    stream.on('error', () => res.destroy());
    res.on('close', () => stream.destroy());
    stream.pipe(res);
  } catch (error) {
    console.error(new Date().toISOString(), error.message);
    if (!res.headersSent) text(res, 500, 'Download unavailable.\n', req.method);
    else res.destroy();
  }
});
server.on('error', error => { console.error(error.message); process.exit(1); });
server.listen(port, host, () => console.log(`Serving build on http://${host}:${port}/ (PID ${process.pid}, subnet /${prefix})`));
