import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { splitPack, readPack, writePack } from './split-packs.mjs';

const root = join('.local', `pack-tests-${Date.now()}`);
await mkdir(root, { recursive: true });
const engine = Buffer.alloc(12); engine.writeUInt32LE(4); engine.writeUInt32LE(7, 4); engine.writeUInt32LE(2, 8);
const entry = (path, bytes) => {
  bytes = Buffer.from(bytes);
  return { path, bytes, size: bytes.length, md5: createHash('md5').update(bytes).digest() };
};
const imported = '.godot/imported/coach.glb-abc.scn';
const entries = [
  entry('project.binary', 'project'),
  entry('game/example.gdc', 'original compiled script'),
  entry('assets/models/ported/lhb/coach.glb.import', `[remap]\npath="res://${imported}"\n`),
  entry(imported, 'unchanged detailed geometry'),
  entry('assets/sounds/body_v2/joint.wav', 'unchanged audio'),
  entry('data/railway_times/0800.bin', 'unchanged railway'),
  entry('data/routes/kerala_coast/tiles/0.json', 'unchanged route'),
];
async function build(name, list) {
  const source = join(root, name + '.pck'), output = join(root, name);
  await writePack(source, list, engine);
  const report = await splitPack(source, output);
  const resources = new Map(), files = new Map();
  for (const group of report.groups) {
    const path = join(output, group.path); files.set(group.path, await readFile(path));
    const pack = await readPack(path);
    for (const e of pack.entries) {
      assert(!resources.has(e.path)); resources.set(e.path, await pack.read(e.offset, e.size));
    }
    await pack.file.close();
  }
  for (const e of list) assert.deepEqual(resources.get(e.path), e.bytes, e.path);
  assert.equal(resources.size, list.length + 1);
  return { report, files, resources };
}
const first = await build('first', entries), repeat = await build('repeat', [...entries].reverse());
for (const [path, bytes] of first.files) assert.deepEqual(repeat.files.get(path), bytes);
const code = await build('code', entries.map(e => e.path.endsWith('.gdc') ? entry(e.path, 'script grows and changes its size substantially') : e));
assert(!first.files.get('TrainGame.pck').equals(code.files.get('TrainGame.pck')));
for (const [path, bytes] of first.files) if (path.startsWith('packs/')) assert.deepEqual(code.files.get(path), bytes);
const model = await build('model', entries.map(e => e.path === imported ? entry(e.path, 'changed geometry with extra detail') : e));
const differences = [...first.files].filter(([path, bytes]) => !bytes.equals(model.files.get(path))).map(([path]) => path);
assert.equal(differences.length, 1); assert.match(differences[0], /^packs\/trains-/);
const corrupted = await readFile(join(root, 'first.pck')); corrupted[corrupted.length - 16] ^= 1;
await writeFile(join(root, 'bad.pck'), corrupted);
await assert.rejects(splitPack(join(root, 'bad.pck'), join(root, 'bad-output')), /checksum/);
await assert.rejects(splitPack(join(root, 'first/TrainGame.pck'), join(root, 'resplit')), /already been partitioned/);
console.log(JSON.stringify({ checks: 6, exactResources: entries.length, stablePacksAfterScriptChange: first.report.packs,
  checksCovered: ['exact resource bytes', 'deterministic export ordering', 'script growth isolation', 'one model pack changes', 'corrupt input rejection', 'double partition rejection'], fixtureDirectory: root }));
