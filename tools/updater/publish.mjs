// Signed 64 KiB block catalogue; payloads stay in the existing immutable export.
import { createHash, createPrivateKey, createPublicKey, generateKeyPairSync, sign } from 'node:crypto';
import { readFile, writeFile, mkdir, readdir, open, rename } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { gzipSync } from 'node:zlib';
import { createReadStream } from 'node:fs';
import { dirname } from 'node:path';
import { spawn } from 'node:child_process';
import { unlink } from 'node:fs/promises';

export const BLOCK = 65536;
const benchmarkFiles = ['Benchmark.ps1', 'Run Performance Benchmark.cmd'];
export async function describeFile(path, name, payloadPath) {
  const file = await open(path, 'r');
  let payload;
  try {
    if (payloadPath) {
      await mkdir(dirname(payloadPath), { recursive: true });
      payload = await open(payloadPath + '.tmp', 'w');
    }
    const size = (await file.stat()).size;
    const whole = createHash('sha256'), chunks = [], encodedSizes = [];
    const buffer = Buffer.alloc(BLOCK);
    for (let position = 0; position < size; position += BLOCK) {
      const length = Math.min(BLOCK, size - position);
      const { bytesRead } = await file.read(buffer, 0, length, position);
      if (bytesRead !== length) throw Error(`Short read: ${path}`);
      const bytes = buffer.subarray(0, length);
      whole.update(bytes);
      chunks.push(createHash('sha256').update(bytes).digest('hex'));
      if (payload) {
        const compressed = gzipSync(bytes, { level: 6 });
        const smaller = compressed.length < length;
        await payload.write(smaller ? compressed : bytes);
        encodedSizes.push(smaller ? compressed.length : -length);
      }
    }
    if (payload) { await payload.sync(); await payload.close(); payload = null; await rename(payloadPath + '.tmp', payloadPath); }
    return { path: name, size, sha256: whole.digest('hex'), chunks,
      ...(payloadPath ? { encodedSizes, payloadSize: encodedSizes.reduce((n, s) => n + Math.abs(s), 0) } : {}) };
  } finally { if (payload) await payload.close(); await file.close(); }
}
export async function catalogue(directory, build, sequence, options = {}) {
  const files = [];
  async function walk(relative = '') {
    for (const item of (await readdir(join(directory, relative), { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))) {
      const name = relative ? `${relative}/${item.name}` : item.name;
      if (item.isSymbolicLink()) throw Error(`Linked export file: ${name}`);
      if (item.isDirectory()) {
        if (!relative && !['guides', 'station-notices', 'packs'].includes(name)) continue;
        await walk(name);
      } else if (item.isFile() && (relative || ['TrainGame.exe', 'TrainGame.pck', 'README.txt', 'BUILD.txt', 'SHA256SUMS.txt', 'ENGINE-LICENSES.txt', 'ASSET-SOURCES.md', 'MAP-DATA-LICENSE.md', ...benchmarkFiles].includes(name))) {
        if (name.startsWith('packs/') && !/^packs\/(trains|scenery|audio|railway|route|resources)-[01][0-9a-f]\.pck$/.test(name))
          throw Error('Unexpected asset pack path: ' + name);
        files.push(await describeFile(join(directory, name), name, options.payloadDirectory ? join(options.payloadDirectory, name + '.blocks') : null));
      }
    }
  }
  await walk();
  if (!files.some(f => f.path === 'TrainGame.exe') || !files.some(f => f.path === 'TrainGame.pck')) throw Error('Missing game executable or pack.');
  const benchmarkCount = files.filter(f => benchmarkFiles.includes(f.path)).length;
  if (benchmarkCount !== 0 && benchmarkCount !== benchmarkFiles.length) throw Error('Incomplete benchmark launcher pair. Include both Benchmark.ps1 and Run Performance Benchmark.cmd.');
  const modern = !!options.payloadDirectory;
  if (!modern && files.some(f => f.path.startsWith('packs/'))) throw Error('Split packs require compressed launcher v3 publication');
  let archive;
  if (options.archivePath) {
    const sha = createHash('sha256'); let size = 0;
    for await (const bytes of createReadStream(options.archivePath)) { sha.update(bytes); size += bytes.length; }
    archive = { size, sha256: sha.digest('hex') };
  }
  return { format: modern ? 2 : 1, minimumLauncher: modern ? 3 : benchmarkCount ? 2 : 1, blockSize: BLOCK, sequence, version: build, files, ...(archive ? { archive } : {}) };
}
export function envelope(manifest, key) {
  const data = Buffer.from(JSON.stringify(manifest));
  return JSON.stringify({ payload: data.toString('base64'), signature: sign('sha256', data, key).toString('base64') });
}
export async function verifyArchive(archivePath, manifest, temporaryPath) {
  await writeFile(temporaryPath, JSON.stringify(manifest), { flag: 'wx' });
  try {
    await new Promise((done, reject) => {
      const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        fileURLToPath(new URL('verify-archive.ps1', import.meta.url)), '-ArchivePath', archivePath, '-ManifestPath', temporaryPath],
      { windowsHide: true });
      let output = ''; child.stdout.on('data', b => output += b); child.stderr.on('data', b => output += b);
      child.on('error', reject); child.on('close', code => code === 0 ? done() : reject(Error(output)));
    });
  } finally { await unlink(temporaryPath); }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { values } = parseArgs({ options: {
    build: { type: 'string' }, sequence: { type: 'string' }, 'init-key': { type: 'boolean', default: false },
    'no-archive': { type: 'boolean', default: false },
  } });
  const root = fileURLToPath(new URL('../../', import.meta.url));
  if (!/^TrainGame-[A-Za-z0-9_-]+$/.test(values.build ?? '') || !/^[1-9]\d*$/.test(values.sequence ?? '')) throw Error('Pass --build=TrainGame-... --sequence=<increasing integer>.');
  const keyPath = join(root, '.local/update-signing-private.pem');
  if (values['init-key']) {
    const keys = generateKeyPairSync('rsa', { modulusLength: 3072 });
    await writeFile(keyPath, keys.privateKey.export({ type: 'pkcs8', format: 'pem' }), { flag: 'wx', mode: 0o600 });
    const jwk = keys.publicKey.export({ format: 'jwk' });
    const xml = `<RSAKeyValue><Modulus>${Buffer.from(jwk.n, 'base64url').toString('base64')}</Modulus><Exponent>${Buffer.from(jwk.e, 'base64url').toString('base64')}</Exponent></RSAKeyValue>`;
    await writeFile(join(root, 'tools/updater/public-key.xml'), xml + '\n', { flag: 'wx' });
  }
  const key = createPrivateKey(await readFile(keyPath));
  const publicJwk = createPublicKey(key).export({ format: 'jwk' });
  const expectedKey = `<RSAKeyValue><Modulus>${Buffer.from(publicJwk.n, 'base64url').toString('base64')}</Modulus><Exponent>${Buffer.from(publicJwk.e, 'base64url').toString('base64')}</Exponent></RSAKeyValue>`;
  if ((await readFile(join(root, 'tools/updater/public-key.xml'), 'utf8')).trim() !== expectedKey) throw Error('Signing key does not match the public key pinned into the launcher.');
  const directory = join(root, 'export', values.build);
  // Never rewrite payloads belonging to an existing signed version.
  const immutablePath = join(root, 'export/updates', values.build + '.json');
  try { await readFile(immutablePath); throw Error('Already published. Use a new build name and sequence.'); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  const archivePath = join(root, 'export', values.build + '.zip');
  let hasArchive = false;
  if (!values['no-archive']) try { const f = await open(archivePath); await f.close(); hasArchive = true; } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const manifest = await catalogue(directory, values.build, Number(values.sequence), {
    payloadDirectory: join(root, 'export/update-payloads', values.build),
    ...(hasArchive ? { archivePath } : {}),
  });
  const output = join(root, 'export/updates');
  await mkdir(output, { recursive: true });
  if (hasArchive) await verifyArchive(archivePath, manifest, join(output, values.build + '.verify.tmp'));
  const signed = envelope(manifest, key);
  // Never reuse a published release identifier with different bytes.
  const immutable = join(output, values.build + '.json');
  try {
    if (await readFile(immutable, 'utf8') !== signed) throw Error('This release was published already with different contents. Use a new build name and sequence.');
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    await writeFile(immutable, signed, { flag: 'wx' });
  }
  try {
    const previous = JSON.parse(Buffer.from(JSON.parse(await readFile(join(output, 'latest.json'), 'utf8')).payload, 'base64'));
    if (previous.sequence > manifest.sequence || (previous.sequence === manifest.sequence && previous.version !== manifest.version)) throw Error('Update sequence must increase.');
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  await writeFile(join(output, 'latest.json.tmp'), signed);
  await rename(join(output, 'latest.json.tmp'), join(output, 'latest.json'));
  console.log(JSON.stringify({ version: manifest.version, files: manifest.files.length, catalogueBytes: Buffer.byteLength(signed), gameBytes: manifest.files.reduce((n, f) => n + f.size, 0) }));
}
