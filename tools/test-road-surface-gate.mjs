import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
import {verifyRoadSurfaces} from './verify-road-surfaces.mjs';
const sha = text => createHash('sha256').update(text).digest('hex');
async function fixture(t) {
  const root = await mkdtemp(join(tmpdir(), 'train-road-gate-'));
  t.after(() => rm(root, {recursive:true, force:true}));
  await mkdir(join(root,'data/routes/kerala_coast/tiles'), {recursive:true});
  await mkdir(join(root,'game'));
  await writeFile(join(root,'data/routes/kerala_coast/tiles/0_0.json'), '{}');
  const context = join(root,'context.json');
  await writeFile(context,'{"rails":[1]}');
  await writeFile(join(root,'game/ground.gd'),'line1\r\nline2\r\n');
  const data = {
    revision:1, context_sha256:sha('{"rails":[1]}'), tile_names_sha256:sha('0_0.json'),
    inputs:{'game/ground.gd':sha('line1\nline2\n'),'data/routes/kerala_coast/tiles/0_0.json':sha('{}')},
    segments:[['w1',0,0,3,5,0,3,1]]
  };
  return {root,data,context};
}
test('road gate accepts current inputs across Windows line endings', async t => {
  const f = await fixture(t);
  assert.deepEqual(await verifyRoadSurfaces(f.root,f.data,f.context), {segments:1,inputs:2});
});
test('road gate rejects changed rendering geometry and stale source data', async t => {
  const f = await fixture(t);
  await writeFile(f.context,'{"rails":[2]}');
  await assert.rejects(verifyRoadSurfaces(f.root,f.data,f.context), /geometry changed/);
  await writeFile(f.context,'{"rails":[1]}');
  await writeFile(join(f.root,'game/ground.gd'),'changed');
  await assert.rejects(verifyRoadSurfaces(f.root,f.data,f.context), /input changed/);
});
test('road gate detects newly added tiles and missing elevations becoming available', async t => {
  const f = await fixture(t);
  await writeFile(join(f.root,'data/routes/kerala_coast/tiles/1_0.json'),'{}');
  await assert.rejects(verifyRoadSurfaces(f.root,f.data,f.context), /inventory changed/);
  await rm(join(f.root,'data/routes/kerala_coast/tiles/1_0.json'));
  f.data.inputs['new-elevation.bin']=null;
  await verifyRoadSurfaces(f.root,f.data,f.context);
  await writeFile(join(f.root,'new-elevation.bin'),'DEM');
  await assert.rejects(verifyRoadSurfaces(f.root,f.data,f.context), /input changed/);
});
test('road gate rejects malformed generated profiles', async t => {
  const f = await fixture(t);
  f.data.segments[0][3]=null;
  await assert.rejects(verifyRoadSurfaces(f.root,f.data,f.context), /Invalid road-profile/);
});
