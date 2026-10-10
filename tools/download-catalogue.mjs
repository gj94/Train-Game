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
export async function currentTimetable(root, release) {
  if (!release) return null;
  try {
    const data = JSON.parse(await readFile(join(root, 'timetables/catalogue.json'), 'utf8'));
    if (data.format !== 1 || data.build !== release.build || !/^Kerala-Coast-[A-Za-z0-9-]+\.json$/.test(data.file) || !['validating','verified'].includes(data.status)) return null;
    if (data.status === 'verified' && data.requires_update) return null;
    const info = await stat(join(root, 'timetables', data.file));
    await stat(join(root, 'timetables', data.file + '.sha256'));
    await stat(join(root, 'timetables/README.txt'));
    return info.isFile() && info.size > 0 && info.size <= 2097152 ? {...data, size:info.size} : null;
  } catch { return null; }
}
export function downloadRoutes(root) {
  const updates = updateRoutes(root);
  return async (path, release) => {
    if (!release) return null;
    if (['/timetables/current.json','/timetables/current.json.sha256','/timetables/instructions'].includes(path)) {
      const timetable = await currentTimetable(root, release);
      if (!timetable) return null;
      if (path.endsWith('/instructions')) return ['timetables/README.txt', 'text/plain; charset=utf-8'];
      if (path.endsWith('.sha256')) return ['timetables/' + timetable.file + '.sha256', 'text/plain; charset=utf-8'];
      return ['timetables/' + timetable.file, 'application/json; charset=utf-8', timetable.file];
    }
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
  const timetable = await currentTimetable(root, release);
  const timetableCard = timetable ? `<h2>100-service coastal timetable</h2><p>24 full Ernakulam–Nagercoil services, including one Vande Bharat in each direction; plus intercity and regional trains. ${timetable.requires_update ? "A game update is required for the changed map or dispatcher; this is a preview download." : "For your existing <b>" + release.build + "</b> installation."}</p><p><a class="download" href="/timetables/current.json" download="${timetable.file}">Download timetable only · ${Math.ceil(timetable.size / 1024)} KiB</a></p><p><b>${timetable.status === 'verified' ? 'Validated: full operating day and late-start simulation completed.' : 'Preview: full-day simulation checks are still running.'}</b></p><ol><li>Save this small JSON file on the PC where you play.</li><li>Open the Kerala route, press <b>F5</b>, then <b>Import</b> and select the file. Export your current draft first if you want to keep it.</li><li>Select <b>K1</b> and click <b>Play</b>, then confirm the new scenario. The designer may say it has not been rehearsed locally.</li></ol><p>Import starts a new scenario. Changed track geometry can make older saves incompatible; check the release instructions. ${timetable.requires_update ? "Install the upcoming game update before using the validated timetable." : "If you already have this game release, only the timetable JSON is needed."}</p><p><a href="/timetables/instructions">Timetable instructions</a> · <a href="/timetables/current.json.sha256">SHA-256 checksum</a></p>` : '';
  const full = info ? `<h2>Latest full download</h2><p><b>${release.build}</b></p><p><a class="download" href="/${release.build}.zip">Download full Windows game · ${(info.size / 1073741824).toFixed(2)} GiB</a></p><p><a href="/${release.build}.zip.sha256">SHA-256 checksum</a> · <a href="/release/README.txt">Release instructions</a> · <a href="/release/graphics">Graphics settings</a> · <a href="/release/performance">Benchmark guide</a></p><ol><li>Download and extract the entire ZIP into a game folder on your SSD.</li><li>Open <b>TrainGame.exe</b>. Keep its PCK and other files beside it.</li><li>Open <b>Menu → Graphics settings</b> to tune image quality and performance.</li></ol><p>No Godot or Blender installation is needed. Saved journeys and graphics preferences live separately in your Windows user profile.</p>` : '<p>The next full download is being prepared.</p>';
  let updates = '';
  if (release?.incremental && await matchingManifest(root, release)) {
    updates = '<h2>Incremental updates</h2><p>Already installed? Run <b>Update and Play.exe</b> in your game folder to download changed blocks.</p><p><a href="/TrainGame-Updater.zip">Get the updater separately</a> · <a href="/updater/instructions">Updater instructions</a></p>';
  } else if (info) {
    updates = '<p>This release is available as a full download only. The included updater is ready for the next release, when full downloads and incremental updates will both be available.</p>';
  }
  return `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Train Game download</title><style>body{max-width:760px;margin:48px auto;padding:24px;font:18px/1.6 system-ui;background:#101c28;color:#e5edf4}a{color:#83cfff}h1{line-height:1.2}.download{display:inline-block;background:#83cfff;color:#101c28;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold}small{color:#afc0ce}</style><h1>Train Game</h1>${timetableCard}${full}${updates}<small>Keep the host PC awake until your download finishes. Only the current release is offered.</small></html>`;
}
