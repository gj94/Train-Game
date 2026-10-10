// Explicit current-release policy; old exports are never implicitly advertised.
import { readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { updateRoutes } from './updater/routes.mjs';

export async function currentRelease(root) {
  try {
    const release = JSON.parse(await readFile(join(root, 'download-release.json'), 'utf8'));
    if (release.format !== 1 || !/^TrainGame-[A-Za-z0-9_-]+$/.test(release.build) || typeof release.incremental !== 'boolean') return null;
    return release;
  } catch { return null; }
}
export async function fullArchive(root, release) {
  if (!release) return null;
  try {
    await stat(join(root, release.build + '.zip.sha256'));
    const info = await stat(join(root, release.build + '.zip'));
    return info.isFile() && info.size > 0 ? info : null;
  } catch { return null; }
}
async function matchingManifest(root, release) {
  try {
    const signed = JSON.parse(await readFile(join(root, 'updates/latest.json'), 'utf8'));
    return JSON.parse(Buffer.from(signed.payload, 'base64')).version === release.build;
  } catch { return false; }
}
export function downloadRoutes(root) {
  const updates = updateRoutes(root);
  return async (path, release) => {
    if (!release) return null;
    const archive = release.build + '.zip';
    if (path === '/' + archive || path === '/' + archive + '.sha256') {
      if (!await fullArchive(root, release)) return null;
      return [path.slice(1), path.endsWith('.zip') ? 'application/zip' : 'text/plain; charset=utf-8'];
    }
    const guides = {'/release/README.txt':'README.txt', '/release/graphics':'guides/graphics-settings.md', '/release/performance':'guides/performance.md'};
    if (Object.hasOwn(guides, path)) return [release.build + '/' + guides[path], 'text/plain; charset=utf-8'];
    if (!release.incremental) return null;
    if (path === '/updates/latest.json') return await matchingManifest(root, release) ? updates(path) : null;
    if (path.startsWith('/update-files/' + release.build + '/')) return updates(path);
    if (path === '/TrainGame-Updater.zip' || path === '/TrainGame-Updater.zip.sha256') return [path.slice(1), path.endsWith('.zip') ? 'application/zip' : 'text/plain; charset=utf-8'];
    if (path === '/updater/instructions') return ['updater/UPDATER-README.txt', 'text/plain; charset=utf-8'];
    return null;
  };
}
export async function downloadPage(root, release) {
  const info = await fullArchive(root, release);
  const full = info ? `<h2>Latest full download</h2><p><b>${release.build}</b></p><p><a class="download" href="/${release.build}.zip">Download full Windows game · ${(info.size / 1073741824).toFixed(2)} GiB</a></p><p><a href="/${release.build}.zip.sha256">SHA-256 checksum</a> · <a href="/release/README.txt">Release instructions</a> · <a href="/release/graphics">Graphics settings</a> · <a href="/release/performance">Benchmark guide</a></p><ol><li>Download and extract the entire ZIP into a game folder on your SSD.</li><li>Open <b>TrainGame.exe</b>. Keep its PCK and other files beside it.</li><li>Open <b>Menu → Graphics settings</b> to tune image quality and performance.</li></ol><p>No Godot or Blender installation is needed. Saved journeys and graphics preferences live separately in your Windows user profile.</p>` : '<p>The next full download is being prepared.</p>';
  let updates = '';
  if (release?.incremental && await matchingManifest(root, release)) {
    updates = '<h2>Incremental updates</h2><p>Already installed? Run <b>Update and Play.exe</b> in your game folder to download changed blocks.</p><p><a href="/TrainGame-Updater.zip">Get the updater separately</a> · <a href="/updater/instructions">Updater instructions</a></p>';
  } else if (info) {
    updates = '<p>This release is available as a full download only. The included updater is ready for the next release, when full downloads and incremental updates will both be available.</p>';
  }
  return `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Train Game download</title><style>body{max-width:760px;margin:48px auto;padding:24px;font:18px/1.6 system-ui;background:#101c28;color:#e5edf4}a{color:#83cfff}h1{line-height:1.2}.download{display:inline-block;background:#83cfff;color:#101c28;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold}small{color:#afc0ce}</style><h1>Train Game</h1>${full}${updates}<small>Keep the host PC awake until your download finishes. Only the current release is offered.</small></html>`;
}
