// Download pinned, user-owned authoring sources; verify Git blob hashes before use.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
const manifest = JSON.parse(await fs.readFile(process.argv[2], 'utf8'));
const target = path.resolve(process.argv[3]);
let next = 0;
async function worker() {
  while (next < manifest.files.length) {
    const file = manifest.files[next++];
    const dest = path.resolve(target, file.path);
    if (!dest.startsWith(target + path.sep)) throw Error('Invalid source path');
    const hash = b => crypto.createHash('sha1').update(`blob ${b.length}\0`).update(b).digest('hex');
    let bytes;
    try { bytes = await fs.readFile(dest); } catch {}
    if (!bytes || hash(bytes) !== file.sha) {
      const url = `${manifest.repository.replace('github.com', 'raw.githubusercontent.com')}/${manifest.revision}/${file.path}`;
      const response = await fetch(url);
      if (!response.ok) throw Error(`${response.status}: ${file.path}`);
      bytes = Buffer.from(await response.arrayBuffer());
      if (hash(bytes) !== file.sha) throw Error(`Hash mismatch: ${file.path}`);
      await fs.mkdir(path.dirname(dest), {recursive: true});
      await fs.writeFile(dest, bytes);
    }
    console.log(`Verified ${file.path}`);
  }
}
await fs.mkdir(target, {recursive:true});
await fs.writeFile(path.join(target, '.gdignore'), '');
await Promise.all(Array.from({length:4}, worker));
