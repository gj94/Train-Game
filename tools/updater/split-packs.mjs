// Deterministic partitioning of the *exported* resources: no reimport, decimation
// or recompression. PCK layout follows Godot core/io/file_access_pack.cpp.
import { open, mkdir, rename, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const hash = (bytes, algorithm = 'sha256') => createHash(algorithm).update(bytes).digest();
const align = (n, a = 16) => Math.ceil(n / a) * a;
export async function readPack(path) {
  const file = await open(path, 'r');
  try {
    const size = (await file.stat()).size;
    async function read(position, length) {
      if (position < 0 || length < 0 || position + length > size) throw Error('PCK range outside file');
      const b = Buffer.alloc(length);
      if ((await file.read(b, 0, length, position)).bytesRead !== length) throw Error('Short PCK read');
      return b;
    }
    const header = await read(0, 100);
    const version = header.readUInt32LE(4), flags = header.readUInt32LE(20);
    if (header.toString('ascii', 0, 4) !== 'GDPC' || ![2, 3, 4].includes(version) || flags & ~2)
      throw Error('Only standalone, non-bundled, unencrypted PCK v2/v3/v4 is supported');
    const base = Number(header.readBigUInt64LE(24));
    let position = version === 2 ? 96 : Number(header.readBigUInt64LE(32));
    const count = (await read(position, 4)).readUInt32LE(); position += 4;
    if (count > 100000) throw Error('Too many PCK entries');
    const entries = [], names = new Set();
    for (let i = 0; i < count; i++) {
      const n = (await read(position, 4)).readUInt32LE(); position += 4;
      if (n < 1 || n > 4096) throw Error('Invalid PCK path');
      const name = (await read(position, n)).toString('utf8').replace(/\0+$/, ''); position += n;
      const info = await read(position, 36); position += 36;
      const offset = base + Number(info.readBigUInt64LE()), length = Number(info.readBigUInt64LE(8));
      const path = name.replace(/^res:\/\//, '');
      if (names.has(path) || path.split('/').some(s => s === '..') || info.readUInt32LE(32) !== 0 || offset + length > size)
        throw Error('Duplicate, flagged or invalid PCK resource: ' + path);
      names.add(path); entries.push({ path, offset, size: length, md5: info.subarray(16, 32), source: file });
    }
    return { file, entries, engine: header.subarray(8, 20), read };
  } catch (error) { await file.close(); throw error; }
}

export async function writePack(path, entries, engine) {
  entries = [...entries].sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  const names = entries.map(e => {
    const n = Buffer.from('res://' + e.path); const b = Buffer.alloc(align(n.length, 4)); n.copy(b); return b;
  });
  const headerSize = align(100 + names.reduce((n, b) => n + 40 + b.length, 0));
  const header = Buffer.alloc(headerSize);
  header.write('GDPC'); header.writeUInt32LE(2, 4); engine.copy(header, 8);
  header.writeBigUInt64LE(BigInt(headerSize), 24); header.writeUInt32LE(entries.length, 96);
  let cursor = 100, offset = 0;
  for (let i = 0; i < entries.length; i++) {
    const e = entries[i], name = names[i];
    header.writeUInt32LE(name.length, cursor); cursor += 4; name.copy(header, cursor); cursor += name.length;
    header.writeBigUInt64LE(BigInt(offset), cursor); header.writeBigUInt64LE(BigInt(e.size), cursor + 8);
    e.md5.copy(header, cursor + 16); cursor += 36; offset += align(e.size);
  }
  await mkdir(dirname(path), { recursive: true });
  const out = await open(path + '.tmp', 'wx');
  try {
    await out.write(header);
    const buffer = Buffer.alloc(1024 * 1024);
    for (const e of entries) {
      const md5 = createHash('md5');
      for (let pos = 0; pos < e.size;) {
        const n = Math.min(buffer.length, e.size - pos);
        if (e.bytes) e.bytes.copy(buffer, 0, pos, pos + n);
        else if ((await e.source.read(buffer, 0, n, e.offset + pos)).bytesRead !== n) throw Error('Short resource read');
        md5.update(buffer.subarray(0, n)); await out.write(buffer.subarray(0, n)); pos += n;
      }
      if (!md5.digest().equals(e.md5)) throw Error('Resource checksum failed: ' + e.path);
      if (align(e.size) !== e.size) await out.write(Buffer.alloc(align(e.size) - e.size));
    }
    await out.sync();
  } finally { await out.close(); }
  await rename(path + '.tmp', path);
}
function family(path) {
  // Keep alternate days separate from the standard railway buckets, using
  // the generic family already accepted by the installed R36/R37 v3 clients.
  // New family names would require replacing those launchers first.
  const day = path.match(/^data\/timetables\/([a-z0-9_-]+)\/.*\.bin$/);
  if (day) return 'resources';
  if (/^data\/(railway_times|service_starts)\/.*\.bin$/.test(path)) return 'railway';
  if (/^data\/(routes|interiors)\//.test(path)) return 'route';
  if (path.startsWith('assets/sounds/')) return 'audio';
  if (/^assets\/models\/ported\/(wap|lhb|icf|vande|vb_)/.test(path)) return 'trains';
  if (path.startsWith('assets/')) return 'scenery';
  if (path.startsWith('.godot/imported/')) return 'resources';
  return 'core';
}
export async function splitPack(input, output) {
  if (resolve(input) === resolve(join(output, 'TrainGame.pck'))) throw Error('Use a separate source pack');
  const pack = await readPack(input);
  try {
    const owners = new Map();
    // Exported remap/import metadata associates imported blobs with source assets.
    for (const e of pack.entries.filter(e => /\.(import|remap)$/.test(e.path))) {
      const data = (await pack.read(e.offset, e.size)).toString('utf8');
      for (const m of data.matchAll(/res:\/\/(\.godot\/imported\/[^"\r\n]+)/g)) {
        const owner = e.path.replace(/\.(import|remap)$/, '');
        if (!owners.has(m[1]) || owner < owners.get(m[1])) owners.set(m[1], owner);
      }
    }
    const groups = new Map();
    for (const e of pack.entries) {
      const owner = owners.get(e.path) ?? e.path, kind = family(owner);
      // Hash the path, never content or iteration order: insertions cannot
      // reshuffle all the other buckets.
      const bucket = kind === 'core' ? 'TrainGame.pck' : `packs/${kind}-${(hash(owner)[0] % 32).toString(16).padStart(2, '0')}.pck`;
      if (!groups.has(bucket)) groups.set(bucket, []);
      groups.get(bucket).push(e);
    }
    if (!groups.has('TrainGame.pck')) throw Error('Missing core resources');
    if (pack.entries.some(e => e.path === 'pack-index.json')) throw Error('Input has already been partitioned');
    const index = { format: 1, packs: [...groups.keys()].filter(p => p !== 'TrainGame.pck').sort() };
    const bytes = Buffer.from(JSON.stringify(index));
    groups.get('TrainGame.pck').push({ path: 'pack-index.json', bytes, size: bytes.length, md5: hash(bytes, 'md5') });
    for (const [name, entries] of groups) await writePack(join(output, name), entries, pack.engine);
    return { resources: pack.entries.length, packs: index.packs.length,
      groups: [...groups].map(([path, entries]) => ({ path, resources: entries.length, bytes: entries.reduce((n, e) => n + e.size, 0) })) };
  } finally { await pack.file.close(); }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = await splitPack(process.argv[2], process.argv[3]);
  if (process.argv[4]) await writeFile(process.argv[4], JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report));
}
