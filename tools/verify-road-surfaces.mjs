// Render-only release gate. No train movement, dispatcher or timetable replay.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFile, readdir} from 'node:fs/promises';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const normalized = (bytes, path) => path.endsWith('.bin') ? bytes : bytes.toString('utf8').replaceAll('\r\n', '\n');
export async function verifyRoadSurfaces(root, data, contextPath) {
  assert.equal(data.revision, 1);
  assert(data.inputs && Object.keys(data.inputs).length, 'Missing road-profile input hashes. Regenerate road surfaces.');
  const tileNames = (await readdir(join(root, 'data/routes/kerala_coast/tiles'))).filter(n => n.endsWith('.json')).sort();
  assert.equal(sha(tileNames.join('\n')), data.tile_names_sha256, 'Scenery tile inventory changed. Regenerate road surfaces.');
  const context = await readFile(contextPath);
  assert.equal(sha(normalized(context, contextPath)), data.context_sha256, 'Rendered railway/precinct geometry changed. Regenerate road surfaces.');
  for (const [path, hash] of Object.entries(data.inputs)) {
    assert(!path.includes('..') && !path.includes('\\') && !path.startsWith('/') && !path.includes(':'), `Invalid input path: ${path}`);
    let bytes;
    try { bytes = await readFile(join(root, path)); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    assert.equal(bytes ? sha(normalized(bytes, path)) : null, hash, `Road-profile input changed: ${path}. Regenerate road surfaces.`);
  }
  assert(data.segments.length > 0, 'Road profiles are empty.');
  for (const row of data.segments) {
    assert(row.length === 8 && typeof row[0] === 'string' && row.slice(1).every(Number.isFinite), 'Invalid road-profile segment.');
    assert(row[7] === 0 || row[7] === 1, 'Invalid bridge flag.');
  }
  return {segments:data.segments.length, inputs:Object.keys(data.inputs).length};
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = fileURLToPath(new URL('../', import.meta.url));
  const engine = join(root, '.local/godot/Godot_v4.7.2-stable_win64_console.exe');
  const result = spawnSync(engine, ['--headless','--path',root,'--script','res://tools/export_scenery_context.gd'], {encoding:'utf8',windowsHide:true});
  assert.equal(result.status, 0, result.error?.message || result.stderr || result.stdout);
  assert(!/^(SCRIPT ERROR:|ERROR:)/m.test(result.stdout + result.stderr), 'Cannot build rendering context: ' + result.stderr);
  const data = JSON.parse(await readFile(join(root, 'assets/models/scenery/road-surfaces.json'), 'utf8'));
  console.log('Road profiles current:', await verifyRoadSurfaces(root, data, join(root, '.local/scenery-context.json')));
}
