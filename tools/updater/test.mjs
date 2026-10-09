// End-to-end updater fixtures: run the same native core used by the GUI.
import { catalogue, envelope, BLOCK } from './publish.mjs';
import { updateRoutes } from './routes.mjs';
import { createServer } from 'node:http';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { mkdir, writeFile, readFile, cp, stat } from 'node:fs/promises';
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
const compile = await run('C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\csc.exe', ['/nologo', '/target:exe', '/r:System.Web.Extensions.dll', '/r:System.Core.dll', `/out:${exe}`, join(root, 'tools/updater/UpdateCore.cs').replaceAll('/', '\\'), join(root, 'tools/updater/TestClient.cs').replaceAll('/', '\\')]);
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
const server = createServer(async (req, res) => {
  if (fail === 'offline') { res.writeHead(503); return res.end(); }
  if (req.url === '/updates/latest.json') { res.end(signed); return; }
  const name = decodeURIComponent(req.url.split('/').slice(3).join('/'));
  if (!manifest.files.some(f => f.path === name)) { res.writeHead(404); return res.end(); }
  const range = /^bytes=(\d+)-(\d+)$/.exec(req.headers.range ?? '');
  if (!range) { res.writeHead(416); return res.end(); }
  const all = await readFile(join(target, name));
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
  signed = envelope({ ...manifest, minimumLauncher: 3 }, keys.privateKey);
  assert.match((await client(normal)).err, /Download the latest launcher/);
  assert.equal((await stat(join(normal, 'TrainGame.pck'))).mtimeMs, gameBefore);
  signed = supportedSigned; pass('future launcher requirement rejected before touching game data');
  await mkdir(join(temp, 'updates')); await writeFile(join(temp, 'updates/TrainGame-Test.json'), signed);
  const route = updateRoutes(temp);
  assert.deepEqual(await route('/update-files/TrainGame-Test/TrainGame.pck'), ['TrainGame-Test/TrainGame.pck', 'application/octet-stream']);
  for (const path of ['../key.xml', '%2e%2e/key.xml', 'secret.txt', 'guides%5c..%5csecret', '%zz']) assert.equal(await route('/update-files/TrainGame-Test/' + path), null);
  pass('server only exposes published files; encoded traversal rejected');
  console.log(JSON.stringify({ checks, fixtureDirectory: temp }));
} finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
