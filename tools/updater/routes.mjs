import { readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
// Only resources named by published catalogues are exposed; never directory browsing.
export function updateRoutes(exportRoot) {
  const cache = new Map();
  return async path => {
    if (path === '/updates/latest.json') return ['updates/latest.json', 'application/json'];
    const match = /^\/(update-files|update-payloads)\/(TrainGame-[A-Za-z0-9_-]+)\/(.+)$/.exec(path);
    if (!match) return null;
    const [, kind, version, encoded] = match;
    let manifest = cache.get(version);
    if (!manifest) {
      try {
        const signed = JSON.parse(await readFile(join(exportRoot, 'updates', version + '.json'), 'utf8'));
        manifest = JSON.parse(Buffer.from(signed.payload, 'base64'));
      } catch { return null; }
      if (manifest.version !== version) return null;
      cache.set(version, manifest);
    }
    let name;
    try { name = decodeURIComponent(encoded); } catch { return null; }
    if (name.includes('\\') || name.includes(':') || name.split('/').some(p => !p || p === '.' || p === '..')) return null;
    const payload = kind === 'update-payloads';
    const file = manifest.files.find(f => (payload ? f.path + '.blocks' : f.path) === name);
    if (!file) return null;
    if (payload && manifest.format !== 2) return null;
    const relative = (payload ? 'update-payloads/' : '') + version + '/' + name;
    try { if ((await stat(join(exportRoot, relative))).size !== (payload ? file.payloadSize : file.size)) return null; } catch { return null; }
    return [relative, 'application/octet-stream'];
  };
}
