// Small read-only LAN download service. No dependencies or directory browsing.
import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { parseArgs } from 'node:util';

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
const files = new Map([
  ['/TrainGame-Kerala-Coast-R3-Windows.zip', ['TrainGame-Kerala-Coast-R3-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R3-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R3-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala-r3/dispatcher', ['TrainGame-Kerala-Coast-R3-Windows/guides/dispatcher-overhaul.md', 'text/plain; charset=utf-8']],
  ['/kerala-r3/station-audit', ['TrainGame-Kerala-Coast-R3-Windows/guides/kerala-station-audit.md', 'text/plain; charset=utf-8']],
  ['/kerala-r3/README.txt', ['TrainGame-Kerala-Coast-R3-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-R2-Windows.zip', ['TrainGame-Kerala-Coast-R2-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-R2-Windows.zip.sha256', ['TrainGame-Kerala-Coast-R2-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/TrainGame-Kerala-Coast-Windows.zip', ['TrainGame-Kerala-Coast-Windows.zip', 'application/zip']],
  ['/TrainGame-Kerala-Coast-Windows.zip.sha256', ['TrainGame-Kerala-Coast-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/kerala/README.txt', ['TrainGame-Kerala-Coast-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/kerala/guide', ['TrainGame-Kerala-Coast-Windows/guides/kerala-coast.md', 'text/plain; charset=utf-8']],
  ['/kerala/licence', ['TrainGame-Kerala-Coast-Windows/MAP-DATA-LICENSE.md', 'text/plain; charset=utf-8']],
  ['/TrainGame-Services-Windows.zip', ['TrainGame-Services-Windows.zip', 'application/zip']],
  ['/TrainGame-Services-Windows.zip.sha256', ['TrainGame-Services-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/services/README.txt', ['TrainGame-Services-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Fidelity-Windows.zip', ['TrainGame-Fidelity-Windows.zip', 'application/zip']],
  ['/TrainGame-Fidelity-Windows.zip.sha256', ['TrainGame-Fidelity-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/fidelity/README.txt', ['TrainGame-Fidelity-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-WAP7-Detail-Windows.zip', ['TrainGame-WAP7-Detail-Windows.zip', 'application/zip']],
  ['/TrainGame-WAP7-Detail-Windows.zip.sha256', ['TrainGame-WAP7-Detail-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/wap7/README.txt', ['TrainGame-WAP7-Detail-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Windows.zip', ['TrainGame-Windows.zip', 'application/zip']],
  ['/TrainGame-Windows.zip.sha256', ['TrainGame-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/README.txt', ['TrainGame-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Controller-Windows.zip', ['TrainGame-Controller-Windows.zip', 'application/zip']],
  ['/TrainGame-Controller-Windows.zip.sha256', ['TrainGame-Controller-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/controller/README.txt', ['TrainGame-Controller-Windows/README.txt', 'text/plain; charset=utf-8']],
  ['/TrainGame-Scenery-Windows.zip', ['TrainGame-Scenery-Windows.zip', 'application/zip']],
  ['/TrainGame-Scenery-Windows.zip.sha256', ['TrainGame-Scenery-Windows.zip.sha256', 'text/plain; charset=utf-8']],
  ['/scenery/README.txt', ['TrainGame-Scenery-Windows/README.txt', 'text/plain; charset=utf-8']],
]);
await stat(join(exportRoot, 'TrainGame-Windows.zip'));
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
      const info = await stat(join(exportRoot, 'TrainGame-Windows.zip'));
      const controllerInfo = await stat(join(exportRoot, 'TrainGame-Controller-Windows.zip')).catch(() => null);
      const sceneryInfo = await stat(join(exportRoot, 'TrainGame-Scenery-Windows.zip')).catch(() => null);
      const wap7Info = await stat(join(exportRoot, 'TrainGame-WAP7-Detail-Windows.zip')).catch(() => null);
      const fidelityInfo = await stat(join(exportRoot, 'TrainGame-Fidelity-Windows.zip')).catch(() => null);
      const servicesInfo = await stat(join(exportRoot, 'TrainGame-Services-Windows.zip')).catch(() => null);
      const keralaInfo = await stat(join(exportRoot, 'TrainGame-Kerala-Coast-R3-Windows.zip')).catch(() => null);
      const kerala = keralaInfo ? `<h2>Latest: Kerala Coast R3 — new dispatch engine and control desk</h2><p>Ernakulam Junction to Nagercoil via Alappuzha and TVC. About 277 km at full scale, 56 stations and seven passenger services.</p><p><a class="download" href="/TrainGame-Kerala-Coast-R3-Windows.zip">Download latest build · ${(keralaInfo.size / 1048576).toFixed(1)} MiB</a></p><p>Press D for the rebuilt control desk: continuous zoom, pan, real occupied train lengths, service inspection, timetable and route controls. View another train without giving up your service; taking control requires confirmation. Xbox LS pans, LT/RT zoom and D-pad selects targets. Dynamic dispatch checks receiving capacity, priorities and circular waits. All seven services completed the full rehearsal safely, with three crossings and two overtakes of the stopping passenger.</p><p>Station boards now use regional, Hindi and English text. All 56 stations have a linked infrastructure audit; unresolved track/platform counts and reconstructed terminal bays are documented. Southern commissioned double lines are corrected. Starts in K1. PROGRESS/F12 tracks stops; T fast-forwards up to ×32. Detailed WAP-7 + ICF/LHB and enhanced Vande Bharat 8/16 are included.</p><p><a href="/kerala-r3/dispatcher">Dispatcher guide</a> · <a href="/kerala-r3/station-audit">Station audit</a> · <a href="/kerala-r3/README.txt">Instructions</a> · <a href="/kerala/licence">Map attribution</a> · <a href="/TrainGame-Kerala-Coast-R3-Windows.zip.sha256">SHA-256 checksum</a></p><p><a href="/TrainGame-Kerala-Coast-R2-Windows.zip">Previous R2 build</a></p>` : '';
      const services = kerala + (servicesInfo ? `<h2>${keralaInfo ? 'Previous' : 'Latest'}: services and driving cameras</h2><p>Design services, import/export timetables and rehearse AI traffic.</p><p><a class="download" href="/TrainGame-Services-Windows.zip">Download services build · ${(servicesInfo.size / 1048576).toFixed(1)} MiB</a></p><p><a href="/services/README.txt">Instructions</a> · <a href="/TrainGame-Services-Windows.zip.sha256">SHA-256 checksum</a></p>` : '');
      const fidelity = fidelityInfo ? `<h2>${servicesInfo ? 'Previous' : 'Latest'}: visual fidelity update</h2><p>Fuller textured trees, irregular trackside ground cover, weathered station materials, refined buildings and platform passengers. Includes the detailed WAP-7, corrected website audio and 39 m rail joints.</p><p><a class="download" href="/TrainGame-Fidelity-Windows.zip">Download ${servicesInfo ? 'previous' : 'latest'} build · ${(fidelityInfo.size / 1048576).toFixed(1)} MiB</a></p><p>Use Tab for the exterior, Alt+1/2/3 for passenger views and F10 to compare performance.</p><p><a href="/fidelity/README.txt">Instructions</a> · <a href="/TrainGame-Fidelity-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const wap7 = wap7Info ? `<h2>${fidelityInfo ? 'Previous' : 'Latest'}: detailed WAP-7</h2><p>Full furnished cabs, machinery aisle, detailed running gear and original surface artwork. Includes scenery and Xbox controller support.</p><p><a class="download" href="/TrainGame-WAP7-Detail-Windows.zip">Download ${fidelityInfo ? 'previous' : 'latest'} build · ${(wap7Info.size / 1048576).toFixed(1)} MiB</a></p><p>F2 light engine, F3 mixed LHB. Home cycles cab positions and the machinery aisle. Right-drag look stays on release; middle-click recenters.</p><p><a href="/wap7/README.txt">Instructions</a> · <a href="/TrainGame-WAP7-Detail-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const scenery = sceneryInfo ? `<h2>${wap7Info ? 'Previous' : 'Latest'}: rebuilt scenery</h2><p>Detailed station towns and villages, shops, apartments, mills, bus stops, road traffic, tropical trees, paddy fields and canal banks. Includes the controller and interior performance updates.</p><p><a class="download" href="/TrainGame-Scenery-Windows.zip">Download ${wap7Info ? 'previous' : 'latest'} build · ${(sceneryInfo.size / 1048576).toFixed(1)} MiB</a></p><p>Press A to let AI drive, then Alt+1/2/3 to ride in the first, middle or last coach. F10 shows performance readings.</p><p><a href="/scenery/README.txt">Latest instructions</a> · <a href="/TrainGame-Scenery-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const controller = scenery + (controllerInfo ? `<h2>${sceneryInfo ? 'Previous' : 'Latest'}: performance + controllers</h2><p>Fixes the growing cab/passenger audio workload and reduces scenery rendering cost. Includes Xbox 360 / One / Series / Elite controls. Press F10 for performance readings.</p><p><a class="download" href="/TrainGame-Controller-Windows.zip">Download ${sceneryInfo ? 'previous' : 'latest'} build · ${(controllerInfo.size / 1048576).toFixed(1)} MiB</a></p><p><a href="/controller/README.txt">Controller build instructions</a> · <a href="/TrainGame-Controller-Windows.zip.sha256">SHA-256 checksum</a></p><h2>Earlier build for comparison</h2>` : '');
      const body = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Train Game download</title><style>body{max-width:640px;margin:60px auto;padding:24px;font:18px/1.6 system-ui;background:#101c28;color:#e5edf4}a{color:#83cfff}h1{line-height:1.2}.download{display:inline-block;background:#83cfff;color:#101c28;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold}small{color:#afc0ce}</style><h1>Train Game</h1>${services}${fidelity}${wap7}${controller}<p>Windows portable build. Drive a randomly assigned passenger service among six trains, with AI traffic and automatic dispatch.</p><p><a class="download" href="/TrainGame-Windows.zip">Download game · ${(info.size / 1048576).toFixed(1)} MiB</a></p><ol><li>Download and extract the entire ZIP.</li><li>Open <b>TrainGame.exe</b> inside the extracted folder. Keep the PCK beside it.</li><li>Press F1 for your scenario briefing. W/S drive, A enables AI, and Alt+1/2/3 enter the first/middle/last passenger coach.</li></ol><p>No Godot or Blender installation is needed.</p><p><a href="/README.txt">Full instructions</a> · <a href="/TrainGame-Windows.zip.sha256">SHA-256 checksum</a></p><small>Build archive updated ${info.mtime.toISOString()}. Keep the host PC awake until the download finishes.</small></html>`;
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Length': Buffer.byteLength(body) });
      return res.end(req.method === 'HEAD' ? undefined : body);
    }
    const entry = files.get(path);
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

