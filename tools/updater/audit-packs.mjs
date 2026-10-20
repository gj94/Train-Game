// Read-only full-size packaging/reuse audit. No gameplay or public publication.
import { readPack } from './split-packs.mjs';
import { describeFile, BLOCK } from './publish.mjs';
import { writeFile, open } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { join } from 'node:path';

const [source, base, current, output] = process.argv.slice(2);
const original = await readPack(source);
const expected = new Map(original.entries.map(e => [e.path, e]));
await original.file.close();
async function packNames(directory) {
  const core = await readPack(join(directory, 'TrainGame.pck'));
  try {
    const entry = core.entries.find(e => e.path === 'pack-index.json');
    const index = JSON.parse(await core.read(entry.offset, entry.size));
    return ['TrainGame.pck', ...index.packs];
  } finally { await core.file.close(); }
}
const names = await packNames(current), oldNames = new Set(await packNames(base));
const seen = new Set(), groups = [];
let verifiedBytes = 0, changedBytes = 0, compressedBytes = 0, reusedBytes = 0;
const transfers = new Map();
for (const name of names) {
  const pack = await readPack(join(current, name));
  try {
    const buffer = Buffer.alloc(1024 * 1024);
    for (const entry of pack.entries) {
      if (entry.path === 'pack-index.json') continue;
      if (seen.has(entry.path)) throw Error('Duplicate exported resource: ' + entry.path);
      seen.add(entry.path);
      const reference = expected.get(entry.path);
      if (!reference || reference.size !== entry.size || !reference.md5.equals(entry.md5)) throw Error('Resource differs: ' + entry.path);
      const hash = createHash('md5');
      for (let position = 0; position < entry.size;) {
        const length = Math.min(buffer.length, entry.size - position);
        const { bytesRead } = await pack.file.read(buffer, 0, length, entry.offset + position);
        if (bytesRead !== length) throw Error('Truncated resource: ' + entry.path);
        hash.update(buffer.subarray(0, length)); position += length;
      }
      if (!hash.digest().equals(reference.md5)) throw Error('Output bytes differ: ' + entry.path);
      verifiedBytes += entry.size;
    }
  } finally { await pack.file.close(); }
  const now = await describeFile(join(current, name), name);
  const before = oldNames.has(name) ? await describeFile(join(base, name), name) : null;
  let changed = 0;
  const file = await open(join(current, name), 'r');
  try {
    for (let i = 0; i < now.chunks.length; i++) {
      const length = Math.min(BLOCK, now.size - i * BLOCK);
      if (before?.chunks[i] === now.chunks[i]) { reusedBytes += length; continue; }
      changed += length;
      if (!transfers.has(now.chunks[i])) {
        const bytes = Buffer.alloc(length); await file.read(bytes, 0, length, i * BLOCK);
        const encoded = Math.min(length, gzipSync(bytes, { level: 6 }).length);
        transfers.set(now.chunks[i], encoded); compressedBytes += encoded;
      }
    }
  } finally { await file.close(); }
  changedBytes += changed;
  groups.push({ path: name, bytes: now.size, unchanged: before?.sha256 === now.sha256, changedBytes: changed, sha256: now.sha256 });
}
if (seen.size !== expected.size) throw Error('Resources lost during partitioning');
const report = { resources: seen.size, verifiedResourceBytes: verifiedBytes,
  stableAssetPacks: groups.filter(g => g.path !== 'TrainGame.pck' && g.unchanged).length,
  totalAssetPacks: names.length - 1, changedPackBytes: changedBytes,
  estimatedCompressedBlockPayloadBytes: compressedBytes, reusedPackBytes: reusedBytes,
  note: 'Compares partitioned R35 with current private export. Excludes catalogue, EXE, documentation and one-time monolithic migration. No target-PC network measurement.',
  groups };
await writeFile(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ ...report, groups: undefined }));
