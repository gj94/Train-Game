// Small read-only LAN download service. No dependencies or directory browsing.
import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join, basename } from 'node:path';
import { parseArgs } from 'node:util';
import { currentRelease, downloadRoutes, downloadPage } from './download-catalogue.mjs';

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
const downloadEntry = downloadRoutes(exportRoot);
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
    const release = await currentRelease(exportRoot);
    if (path === '/') {
      const body = await downloadPage(exportRoot, release);
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Length': Buffer.byteLength(body), 'Cache-Control': 'no-store' });
      return res.end(req.method === 'HEAD' ? undefined : body);
    }
    const entry = await downloadEntry(path, release);
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
      ...(path.endsWith('.zip') || entry[2] ? { 'Content-Disposition': `attachment; filename="${entry[2] ?? basename(entry[0])}"` } : {}) });
    if (req.method === 'HEAD') return res.end();
    const stream = createReadStream(file, { start, end });
    stream.on('error', () => res.destroy());
    res.on('close', () => stream.destroy());
    stream.pipe(res);
  } catch (error) {
    console.error(new Date().toISOString(), error.message);
    if (!res.headersSent) text(res, error.code === 'ENOENT' ? 404 : 500, 'Download unavailable.\n', req.method);
    else res.destroy();
  }
});
server.on('error', error => { console.error(error.message); process.exit(1); });
server.listen(port, host, () => console.log(`Serving build on http://${host}:${port}/ (PID ${process.pid}, subnet /${prefix})`));
