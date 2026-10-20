// End-to-end updater fixtures: run the same native core used by the GUI.
import { catalogue, envelope, verifyArchive, BLOCK } from './publish.mjs';
import { updateRoutes } from './routes.mjs';
import { createServer } from 'node:http';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { mkdir, writeFile, readFile, cp, stat } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';
import { spawn } from 'node:child_process';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const root = fileURLToPath(new URL('../../', import.meta.url));
const temp = join(root, '.local', `updater-tests-${Date.now()}`);
await mkdir(temp, { recursive: true });
const exe = join(temp, 'TestClient.exe');
async function run(command, args) {
  return await new Promise((resolve, reject) => {
    const child = spawn(command, args, { windowsHide: true }); let out = '', err = '';
    child.stdout.on('data', d => out += d); child.stderr.on('data', d => err += d);
    child.on('error', reject); child.on('close', code => resolve({ code, out, err }));
  });
}
const compile = await run('C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\csc.exe', ['/nologo', '/target:exe', '/r:System.Web.Extensions.dll', '/r:System.Core.dll', '/r:System.IO.Compression.dll', `/out:${exe}`, join(root, 'tools/updater/UpdateCore.cs').replaceAll('/', '\\'), join(root, 'tools/updater/TestClient.cs').replaceAll('/', '\\')]);
assert.equal(compile.code, 0, compile.out + compile.err);
const keys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = keys.publicKey.export({ format: 'jwk' });
const keyFile = join(temp, 'key.xml');
await writeFile(keyFile, `<RSAKeyValue><Modulus>${Buffer.from(jwk.n, 'base64url').toString('base64')}</Modulus><Exponent>${Buffer.from(jwk.e, 'base64url').toString('base64')}</Exponent></RSAKeyValue>`);
const base = join(temp, 'base'), target = join(temp, 'TrainGame-Test');
await mkdir(base); await mkdir(target);
const pack = randomBytes(BLOCK * 6 + 111);
await writeFile(join(base, 'TrainGame.exe'), randomBytes(BLOCK + 13));
await writeFile(join(base, 'TrainGame.pck'), pack);
await cp(base, target, { recursive: true });
const changed = Buffer.from(pack); changed[BLOCK + 20] ^= 0xff; changed[BLOCK * 4 + 50] ^= 0xff;
await writeFile(join(target, 'TrainGame.pck'), changed);
await writeFile(join(target, 'README.txt'), 'small updated guide\n');
let manifest = await catalogue(target, 'TrainGame-Test', 20);
assert.equal(manifest.minimumLauncher, 1, 'Older game-only releases remain compatible with launcher v1');
let signed = envelope(manifest, keys.privateKey), fail = '', ranges = 0, bytes = 0;
const payloadDirectory = join(temp, 'payloads');
const archivePath = join(temp, 'TrainGame-Test.zip');
// A tiny ZIP writer used only for fixtures. The production full ZIP is built
// by .NET; this independently exercises the native ZIP reader and its hashes.
async function makeArchive(duplicateAlias = false) {
  const local = [], central = []; let offset = 0;
  const entries = duplicateAlias ? [...manifest.files, manifest.files.find(f => f.path === 'TrainGame.pck')] : manifest.files;
  for (const [index, f] of entries.entries()) {
    const input = await readFile(join(target, f.path)), gzip = gzipSync(input);
    const data = gzip.subarray(10, -8), crc = gzip.readUInt32LE(gzip.length - 8);
    const name = Buffer.from(index === manifest.files.length
      ? ('TrainGame-Test/' + f.path).replaceAll('/', '\\') : 'TrainGame-Test/' + f.path);
    const h = Buffer.alloc(30); h.writeUInt32LE(0x04034b50); h.writeUInt16LE(20, 4); h.writeUInt16LE(8, 8);
    h.writeUInt32LE(crc, 14); h.writeUInt32LE(data.length, 18); h.writeUInt32LE(input.length, 22); h.writeUInt16LE(name.length, 26);
    local.push(h, name, data);
    const c = Buffer.alloc(46); c.writeUInt32LE(0x02014b50); c.writeUInt16LE(20, 4); c.writeUInt16LE(20, 6); c.writeUInt16LE(8, 10);
    c.writeUInt32LE(crc, 16); c.writeUInt32LE(data.length, 20); c.writeUInt32LE(input.length, 24); c.writeUInt16LE(name.length, 28); c.writeUInt32LE(offset, 42);
    central.push(c, name); offset += h.length + name.length + data.length;
  }
  const directory = Buffer.concat(central), end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50); end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(directory.length, 12); end.writeUInt32LE(offset, 16);
  await writeFile(archivePath, Buffer.concat([...local, directory, end]));
}
const server = createServer(async (req, res) => {
  if (fail === 'offline') { res.writeHead(503); return res.end(); }
  if (req.url === '/updates/latest.json') { res.end(signed); return; }
  const isZip = req.url === '/TrainGame-Test.zip', isPayload = req.url.startsWith('/update-payloads/');
  const name = decodeURIComponent(req.url.split('/').slice(3).join('/'));
  if (!isZip && !manifest.files.some(f => (isPayload ? f.path + '.blocks' : f.path) === name)) { res.writeHead(404); return res.end(); }
  const range = /^bytes=(\d+)-(\d+)$/.exec(req.headers.range ?? '');
  if (!range) { res.writeHead(416); return res.end(); }
  const all = await readFile(isZip ? archivePath : join(isPayload ? payloadDirectory : target, name));
  const start = +range[1], end = +range[2]; ranges++;
  let data = Buffer.from(all.subarray(start, end + 1)); bytes += data.length;
  if (fail === 'corrupt') data[0] ^= 0xff;
  if (fail === 'drop' && ranges >= 2) { req.socket.destroy(); return; }
  if (fail !== 'no-range') res.writeHead(206, { 'Content-Range': `bytes ${start}-${end}/${all.length}` });
  res.end(data);
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/`;
let checks = 0;
async function client(directory, checkpoint = '', serverUrl = url) { return run(exe, [directory, serverUrl, keyFile, checkpoint]); }
async function fixture(name) { const path = join(temp, name); await cp(base, path, { recursive: true }); return path; }
async function same(directory) {
  for (const file of manifest.files) assert.deepEqual(await readFile(join(directory, file.path)), await readFile(join(target, file.path)), file.path);
}
function pass(name) { checks++; console.log('PASS ' + name); }
try {
  const normal = await fixture('normal');
  const first = await client(normal); assert.equal(first.code, 0, first.err);
  const info = JSON.parse(first.out); assert.equal(info.writtenBytes, BLOCK * 2 + 20); assert.equal(info.downloadedBytes, info.writtenBytes);
  await same(normal); pass('changed blocks only; untouched EXE; missing guide; exact output hashes');
  const before = (await stat(join(normal, 'TrainGame.pck'))).mtimeMs;
  ranges = 0; const noop = await client(normal); assert.equal(noop.code, 0, noop.err);
  assert.equal(JSON.parse(noop.out).writtenBytes, 0); assert.equal(ranges, 0); assert.equal((await stat(join(normal, 'TrainGame.pck'))).mtimeMs, before);
  pass('already current: zero block downloads and zero game writes');
  const damaged = Buffer.from(changed); damaged[BLOCK * 2 + 7] ^= 0xff;
  await writeFile(join(normal, 'TrainGame.pck'), damaged);
  const repair = await client(normal); assert.equal(repair.code, 0, repair.err); assert.equal(JSON.parse(repair.out).writtenBytes, BLOCK); await same(normal);
  pass('repair one damaged installed block without downloading the rest');
  for (const checkpoint of ['download', 'prepared', 'pending', 'write', 'verified', 'installed']) {
    const directory = await fixture('interrupt-' + checkpoint);
    const stopped = await client(directory, checkpoint); assert.equal(stopped.code, 1); assert.match(stopped.err, /Injected interruption/);
    if (['download', 'prepared'].includes(checkpoint)) assert.deepEqual(await readFile(join(directory, 'TrainGame.pck')), pack);
    else {
      const blocked = await client(directory, 'play'); assert.equal(blocked.code, 1); assert.match(blocked.err, /interrupted update/);
      fail = 'offline';
    }
    const recovered = await client(directory); assert.equal(recovered.code, 0, recovered.err); await same(directory);
    if (fail === 'offline') assert.equal(JSON.parse(recovered.out).downloadedBytes, 0);
    fail = ''; pass('interruption recovery at ' + checkpoint + (['pending', 'write', 'verified', 'installed'].includes(checkpoint) ? ' (offline)' : ''));
  }
  for (const fault of ['corrupt', 'drop', 'no-range']) {
    const directory = await fixture('network-' + fault); fail = fault; ranges = 0;
    const rejected = await client(directory); assert.equal(rejected.code, 1);
    assert.deepEqual(await readFile(join(directory, 'TrainGame.pck')), pack);
    fail = ''; const recovered = await client(directory); assert.equal(recovered.code, 0, recovered.err); await same(directory);
    pass('reject ' + fault + ' response before mutation; retry succeeds');
  }
  const locked = await fixture('running');
  assert.equal((await client(locked, 'locked')).code, 1); assert.deepEqual(await readFile(join(locked, 'TrainGame.pck')), pack);
  pass('open game file prevents all updates');
  const cleanSigned = signed;
  const bad = JSON.parse(signed); bad.signature = Buffer.alloc(256).toString('base64'); signed = JSON.stringify(bad);
  const badSignature = await client(normal); assert.equal(badSignature.code, 1); assert.match(badSignature.err, /signature/); signed = cleanSigned;
  pass('reject untrusted signature');
  for (const path of ['../outside.txt', 'C:/outside.txt', 'guides/../../outside.txt', 'guides/con.txt', 'guides/test.txt:stream', 'Update and Play.exe', 'Other.ps1', 'Other.cmd']) {
    signed = envelope({ ...manifest, files: [...manifest.files, { ...manifest.files[0], path }] }, keys.privateKey);
    const rejected = await client(normal); assert.equal(rejected.code, 1, path);
  }
  signed = cleanSigned; pass('reject traversal, absolute, ADS, reserved and unmanaged paths');
  signed = envelope({ ...manifest, sequence: 19 }, keys.privateKey);
  assert.match((await client(normal)).err, /older update/); signed = cleanSigned;
  pass('reject signed downgrade after successful update');
  // Additional releases cover resizing, existing empty files and missing folders.
  await writeFile(join(target, 'TrainGame.pck'), changed.subarray(0, BLOCK * 3 + 3));
  await mkdir(join(target, 'guides')); await writeFile(join(target, 'guides/empty.txt'), '');
  manifest = await catalogue(target, 'TrainGame-Test', 21); signed = envelope(manifest, keys.privateKey);
  const shrink = await client(normal); assert.equal(shrink.code, 0, shrink.err); await same(normal); pass('shrink pack and create empty file / directory');
  await writeFile(join(target, 'TrainGame.pck'), Buffer.concat([changed, randomBytes(BLOCK + 9)]));
  manifest = await catalogue(target, 'TrainGame-Test', 22); signed = envelope(manifest, keys.privateKey);
  const grow = await client(normal); assert.equal(grow.code, 0, grow.err); await same(normal); pass('grow pack with partial final block');
  await writeFile(join(target, 'Benchmark.ps1'), '# synthetic benchmark fixture\n');
  await assert.rejects(catalogue(target, 'TrainGame-Test', 23), /Incomplete benchmark launcher pair/);
  await writeFile(join(target, 'Run Performance Benchmark.cmd'), '@rem synthetic benchmark fixture\r\n');
  await writeFile(join(target, 'Other.ps1'), '# excluded from the published catalogue\n');
  manifest = await catalogue(target, 'TrainGame-Test', 23);
  assert.equal(manifest.minimumLauncher, 2);
  assert(!manifest.files.some(f => f.path === 'Other.ps1'));
  signed = envelope(manifest, keys.privateKey);
  const benchmarkBytes = manifest.files.filter(f => ['Benchmark.ps1', 'Run Performance Benchmark.cmd'].includes(f.path)).reduce((n, f) => n + f.size, 0);
  const gameBefore = (await stat(join(normal, 'TrainGame.pck'))).mtimeMs;
  const benchmark = await client(normal); assert.equal(benchmark.code, 0, benchmark.err);
  assert.equal(JSON.parse(benchmark.out).downloadedBytes, benchmarkBytes);
  await same(normal);
  assert.equal((await stat(join(normal, 'TrainGame.pck'))).mtimeMs, gameBefore);
  pass('upgrade v1 installation: exact benchmark pair added, unrelated scripts excluded, game untouched');
  ranges = 0; const benchmarkNoop = await client(normal); assert.equal(benchmarkNoop.code, 0, benchmarkNoop.err);
  assert.equal(JSON.parse(benchmarkNoop.out).writtenBytes, 0); assert.equal(ranges, 0);
  pass('benchmark release repeat check downloads and writes zero game blocks');
  const interruptedBenchmark = await fixture('interrupt-benchmark');
  assert.match((await client(interruptedBenchmark, 'write')).err, /Injected interruption/);
  fail = 'offline';
  const recoveredBenchmark = await client(interruptedBenchmark); assert.equal(recoveredBenchmark.code, 0, recoveredBenchmark.err);
  assert.equal(JSON.parse(recoveredBenchmark.out).downloadedBytes, 0); await same(interruptedBenchmark); fail = '';
  pass('new benchmark files recover after an interrupted apply while offline');
  const supportedSigned = signed;
  signed = envelope({ ...manifest, minimumLauncher: 4 }, keys.privateKey);
  assert.match((await client(normal)).err, /Download the latest launcher/);
  assert.equal((await stat(join(normal, 'TrainGame.pck'))).mtimeMs, gameBefore);
  signed = supportedSigned; pass('future launcher requirement rejected before touching game data');
  await mkdir(join(temp, 'updates')); await writeFile(join(temp, 'updates/TrainGame-Test.json'), signed);
  const route = updateRoutes(temp);
  assert.deepEqual(await route('/update-files/TrainGame-Test/TrainGame.pck'), ['TrainGame-Test/TrainGame.pck', 'application/octet-stream']);
  for (const path of ['../key.xml', '%2e%2e/key.xml', 'secret.txt', 'guides%5c..%5csecret', '%zz']) assert.equal(await route('/update-files/TrainGame-Test/' + path), null);
  pass('server only exposes published files; encoded traversal rejected');
  // New protocol must retain the same transaction/recovery guarantees.
  await mkdir(join(target, 'packs'));
  await writeFile(join(target, 'packs/audio-00.pck'), Buffer.alloc(BLOCK * 4, 11));
  const modern = async (sequence = 30, archive = false) => {
    manifest = await catalogue(target, 'TrainGame-Test', sequence, { payloadDirectory, ...(archive ? { archivePath } : {}) });
    signed = envelope(manifest, keys.privateKey);
  };
  await modern();
  assert.equal(manifest.minimumLauncher, 3);
  const v3 = await fixture('v3-migration'); const migrated = await client(v3); assert.equal(migrated.code, 0, migrated.err); await same(v3);
  assert.equal(JSON.parse(migrated.out).method, 'compressed-blocks');
  assert(JSON.parse(migrated.out).downloadedBytes < JSON.parse(migrated.out).writtenBytes);
  pass('legacy install to split packs: compressed and raw blocks, duplicate reuse, exact hashes');
  const stableTime = (await stat(join(v3, 'packs/audio-00.pck'))).mtimeMs;
  await writeFile(join(target, 'README.txt'), 'A revised UI guide, no asset changes.\n'); await modern(31);
  const tiny = await client(v3); assert.equal(tiny.code, 0, tiny.err); await same(v3);
  assert(JSON.parse(tiny.out).downloadedBytes < 100);
  assert.equal((await stat(join(v3, 'packs/audio-00.pck'))).mtimeMs, stableTime);
  pass('code/guide-only change leaves stable asset pack untouched');
  for (const checkpoint of ['download', 'pending', 'write', 'installed']) {
    const directory = await fixture('v3-interrupt-' + checkpoint);
    assert.match((await client(directory, checkpoint)).err, /Injected interruption/);
    if (checkpoint !== 'download') fail = 'offline';
    const recovered = await client(directory); assert.equal(recovered.code, 0, recovered.err); await same(directory); fail = '';
    pass('v3 compressed interruption recovery: ' + checkpoint);
  }
  for (const fault of ['corrupt', 'no-range', 'drop']) {
    const directory = await fixture('v3-network-' + fault); fail = fault; ranges = 0;
    assert.equal((await client(directory)).code, 1);
    assert.deepEqual(await readFile(join(directory, 'TrainGame.pck')), pack); fail = '';
    assert.equal((await client(directory)).code, 0); await same(directory);
    pass('v3 rejects ' + fault + ' before mutation and resumes');
  }
  // Repetition spans block boundaries: whole-file deflate beats independently
  // compressed 64 KiB blocks even after repeated-block deduplication.
  const pattern = randomBytes(24000), periodic = Buffer.alloc(BLOCK * 20 + 17);
  for (let i = 0; i < periodic.length; i++) periodic[i] = pattern[i % pattern.length];
  await writeFile(join(target, 'TrainGame.pck'), periodic);
  await modern(32); await makeArchive(); await modern(32, true);
  await verifyArchive(archivePath, manifest, join(temp, 'verify.json'));
  const staleArchive = structuredClone(manifest); staleArchive.files[0].sha256 = '0'.repeat(64);
  await assert.rejects(verifyArchive(archivePath, staleArchive, join(temp, 'verify.json')), /ZIP differs/);
  pass('publisher verifies all ZIP entries and rejects stale archive bytes');
  const full = await fixture('v3-full'); const fullResult = await client(full); assert.equal(fullResult.code, 0, fullResult.err); await same(full);
  assert.equal(JSON.parse(fullResult.out).method, 'full-archive');
  assert.equal(JSON.parse(fullResult.out).downloadedBytes, manifest.archive.size);
  pass('automatically chooses smaller signed full ZIP; stages only missing blocks');
  // Exercise the production Windows writer as well as the independent fixture.
  // Framework ZipArchive reports DOS-created names differently from the fixture.
  const nativeArchive = archivePath + '.native';
  const quotePS = value => "'" + value.replaceAll("'", "''") + "'";
  const nativeZip = await run('powershell.exe', ['-NoProfile', '-Command',
    "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.IO.Compression.FileSystem; " +
    "[IO.Compression.ZipFile]::CreateFromDirectory(" + quotePS(target) + ',' +
    quotePS(nativeArchive) + ',[IO.Compression.CompressionLevel]::Optimal,$true)']);
  assert.equal(nativeZip.code, 0, nativeZip.err);
  await cp(nativeArchive, archivePath); await modern(32, true);
  await verifyArchive(archivePath, manifest, join(temp, 'verify.json'));
  const nativeInstall = await fixture('v3-native-windows-zip'), nativeResult = await client(nativeInstall);
  assert.equal(nativeResult.code, 0, nativeResult.err); await same(nativeInstall);
  assert.equal(JSON.parse(nativeResult.out).method, 'full-archive');
  pass('production Windows ZIP verifies and installs through native Framework reader');
  await makeArchive(true); await modern(32, true);
  await assert.rejects(verifyArchive(archivePath, manifest, join(temp, 'verify.json')), /Duplicate archive entry/);
  const aliasInstall = await fixture('v3-duplicate-zip-alias');
  assert.match((await client(aliasInstall)).err, /duplicate/);
  assert.deepEqual(await readFile(join(aliasInstall, 'TrainGame.pck')), pack);
  pass('reject duplicate slash/backslash ZIP aliases before mutation');
  await cp(nativeArchive, archivePath); await modern(32, true);
  const partial = await fixture('v3-partial-zip'); await mkdir(join(partial, '.train-update'));
  const archiveBytes = await readFile(archivePath);
  await writeFile(join(partial, '.train-update', manifest.archive.sha256 + '.zip.partial'), archiveBytes.subarray(0, 128));
  const resumed = await client(partial); assert.equal(resumed.code, 0, resumed.err); await same(partial);
  assert.equal(JSON.parse(resumed.out).downloadedBytes, manifest.archive.size - 128);
  pass('partial full ZIP resumes at exact byte offset');
  for (const checkpoint of ['archive-download', 'download', 'pending', 'write', 'verified']) {
    const directory = await fixture('zip-interrupt-' + checkpoint);
    assert.match((await client(directory, checkpoint)).err, /Injected interruption/);
    if (['pending', 'write', 'verified'].includes(checkpoint)) fail = 'offline';
    const recovered = await client(directory); assert.equal(recovered.code, 0, recovered.err); await same(directory); fail = '';
    pass('full ZIP interruption recovery: ' + checkpoint);
  }
  const badZip = await fixture('bad-zip'); fail = 'corrupt';
  assert.equal((await client(badZip)).code, 1); fail = '';
  assert.deepEqual(await readFile(join(badZip, 'TrainGame.pck')), pack);
  assert.equal((await client(badZip)).code, 0); await same(badZip);
  pass('bad full ZIP rejected before mutation; retry repairs download');
  const badCachedZip = await fixture('bad-cached-zip'); await mkdir(join(badCachedZip, '.train-update'));
  await writeFile(join(badCachedZip, '.train-update', manifest.archive.sha256 + '.zip'), 'damaged interrupted cache');
  const repairedCache = await client(badCachedZip); assert.equal(repairedCache.code, 0, repairedCache.err); await same(badCachedZip);
  pass('damaged cached ZIP is automatically discarded and fetched again');
  for (const change of [
    m => m.files[0].encodedSizes.pop(),
    m => m.files[0].encodedSizes[0] = 2147483647,
    m => m.files[0].payloadSize++,
    m => m.archive.sha256 = 'bad',
    m => m.files[0].path = 'packs/../../user-save.pck',
  ]) {
    const invalid = structuredClone(manifest); change(invalid); signed = envelope(invalid, keys.privateKey);
    assert.equal((await client(full)).code, 1);
  }
  signed = envelope(manifest, keys.privateKey);
  pass('reject invalid compressed indices, payload sizes, archive hashes and pack paths');
  const zipNoop = await client(full); assert.equal(zipNoop.code, 0, zipNoop.err);
  assert.equal(JSON.parse(zipNoop.out).downloadedBytes, 0); assert.equal(JSON.parse(zipNoop.out).writtenBytes, 0);
  pass('v3 repeat update downloads and writes zero game bytes');
  await mkdir(join(temp, 'update-payloads/TrainGame-Test'), { recursive: true });
  await cp(payloadDirectory, join(temp, 'update-payloads/TrainGame-Test'), { recursive: true });
  await writeFile(join(temp, 'updates/TrainGame-Test.json'), signed);
  const v3Routes = updateRoutes(temp);
  assert.deepEqual(await v3Routes('/update-payloads/TrainGame-Test/packs/audio-00.pck.blocks'),
    ['update-payloads/TrainGame-Test/packs/audio-00.pck.blocks', 'application/octet-stream']);
  assert.equal(await v3Routes('/update-payloads/TrainGame-Test/Other.ps1.blocks'), null);
  pass('server exposes only signed compressed payloads');
  console.log(JSON.stringify({ checks, fixtureDirectory: temp }));
} finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
