import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, mkdir, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { currentRelease, downloadRoutes, downloadPage } from './download-catalogue.mjs';

async function fixture(t) {
  const root = await mkdtemp(join(tmpdir(), 'train-download-'));
  t.after(() => rm(root, {recursive:true, force:true}));
  const release = {format:1,build:'TrainGame-Kerala-Coast-R26-Windows',incremental:false};
  await writeFile(join(root,'download-release.json'),JSON.stringify(release));
  await writeFile(join(root,release.build+'.zip'),'zip');
  await writeFile(join(root,release.build+'.zip.sha256'),'test checksum');
  await writeFile(join(root,'TrainGame-Kerala-Coast-R25-Windows.zip'),'old');
  await mkdir(join(root,'updates'));
  await mkdir(join(root,release.build));
  await writeFile(join(root,release.build,'TrainGame.pck'),'pack');
  const signed = JSON.stringify({payload:Buffer.from(JSON.stringify({version:release.build,files:[{path:'TrainGame.pck',size:4}]})).toString('base64'),signature:'test'});
  await writeFile(join(root,'updates/latest.json'),signed);
  await writeFile(join(root,'updates',release.build+'.json'),signed);
  return {root,release,route:downloadRoutes(root)};
}
test('full-only release exposes only current ZIP, checksum and guides',async t=>{
  const {root,release,route}=await fixture(t);
  assert.deepEqual(await currentRelease(root),release);
  assert.equal((await route('/'+release.build+'.zip',release))[0],release.build+'.zip');
  assert.equal((await route('/release/graphics',release))[0],release.build+'/guides/graphics-settings.md');
  for(const path of ['/TrainGame-Kerala-Coast-R25-Windows.zip','/updates/latest.json','/update-files/'+release.build+'/TrainGame.pck','/TrainGame-Updater.zip','/../.local/key','/download-release.json']) assert.equal(await route(path,release),null,path);
  const page=await downloadPage(root,release);
  assert(page.includes(release.build+'.zip'));assert(!page.includes('R25'));
  assert(page.includes('full download only'));assert(!page.includes('href="/TrainGame-Updater.zip"'));
});
test('next release can offer full ZIP and signed incremental endpoints together',async t=>{
  const {root,release,route}=await fixture(t);release.incremental=true;
  assert(await route('/updates/latest.json',release));
  assert(await route('/update-files/'+release.build+'/TrainGame.pck',release));
  assert(await route('/'+release.build+'.zip',release));
  assert.equal(await route('/update-files/'+release.build+'/%2e%2e/.local/key',release),null);
  assert.equal(await route('/update-files/TrainGame-Kerala-Coast-R25-Windows/TrainGame.pck',release),null);
  const page=await downloadPage(root,release);
  assert(page.includes('Download full Windows game'));assert(page.includes('Incremental updates'));
});
test('unfinished ZIPs, malformed policies and mismatched manifests fail closed',async t=>{
  const {root,release,route}=await fixture(t);
  await rm(join(root,release.build+'.zip.sha256'));
  assert.equal(await route('/'+release.build+'.zip',release),null);
  release.incremental=true;release.build='TrainGame-Next-Windows';
  assert.equal(await route('/updates/latest.json',release),null);
  await writeFile(join(root,'download-release.json'),JSON.stringify({format:1,build:'../secret',incremental:true}));
  assert.equal(await currentRelease(root),null);
});
