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
      const r7Info = await ready('R7');
      const r6Info = await ready('R6');
      const r7 = r7Info ? `<h2>Latest: Kerala Coast R7</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R7-Windows.zip">Download latest build · ${(r7Info.size / 1048576).toFixed(1)} MiB</a></p><p>Automatic future-platform crossing plans: approach Kumbalam, wait for the VB to vacate P3, then enter while K2 waits on P2. Actual occupancy and signals still govern every move; the dispatcher protects the VB's escape and onward berth.</p><p>In dispatch, inspect a train and choose <b>Delete service…</b> to remove a blocking service for this run. Confirmation defaults to keeping it. Your assigned train is protected; restart restores the scenario.</p><p>Includes R6's 32 services, walking, next-stop HUD and restored engine audio. Start a fresh scenario.</p><p><a href="/kerala-r7/README.txt">Instructions</a> · <a href="/kerala-r7/dispatcher">Dispatcher guide</a> · <a href="/TrainGame-Kerala-Coast-R7-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const r6 = r6Info ? `<h2>Latest: Kerala Coast R6</h2><p><a class="download" href="/TrainGame-Kerala-Coast-R6-Windows.zip">Download latest build · ${(r6Info.size / 1048576).toFixed(1)} MiB</a></p><p>32 scheduled services with the slow K1 passenger selected. Next-stop metres and estimated world minutes replace the camera label. Dispatcher admission checks usable passenger platforms, opposing approaches and onward routes to prevent the reported Kumbalam trap.</p><p>Get up, leave through a platform-side doorway at a stop, walk along the platform and board another carriage. A / left-click uses the doorway prompt. Hold left-stick click + D-pad left to always select left head-out. Electric engine hum, traction and horn are restored alongside the approved joint and squeal sounds.</p><p>Start a fresh scenario in this build. Your driving assignment stays set when walking or viewing another train. The railway continues while you are on the platform. Animated door leaves and boarding other services are not included.</p><p><a href="/kerala-r6/README.txt">Instructions</a> · <a href="/kerala-r6/walking">Walking</a> · <a href="/kerala-r6/controllers">Xbox controls</a> · <a href="/kerala-r6/dispatcher">Dispatcher</a> · <a href="/TrainGame-Kerala-Coast-R6-Windows.zip.sha256">SHA-256 checksum</a></p>` : '';
      const sections = r7 + (r7Info ? r6.replace('Latest:', 'Fallback:').replace('Download latest build', 'Download R6 fallback') : r6);
      const body = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Train Game download</title><style>body{max-width:720px;margin:48px auto;padding:24px;font:18px/1.6 system-ui;background:#101c28;color:#e5edf4}a{color:#83cfff}h1{line-height:1.2}.download{display:inline-block;background:#83cfff;color:#101c28;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold}small{color:#afc0ce}</style><h1>Train Game</h1>${sections}<ol><li>Download and extract the entire ZIP.</li><li>Open <b>TrainGame.exe</b> and keep its PCK beside it.</li><li>Start a fresh scenario and press F1 for the briefing.</li></ol><p>No Godot or Blender installation is needed. The latest build and R6 fallback are retained; older downloads have been removed to free space.</p><small>Keep the host PC awake until your download finishes.</small></html>`;
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

