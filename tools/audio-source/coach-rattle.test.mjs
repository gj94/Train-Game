import test from 'node:test';
import assert from 'node:assert/strict';
import {synthesizeRattle, wav, COUNT, RATE} from './coach-rattle.mjs';
test('rattle cues are repeatable, short, varied, finite and unclipped',()=>{
  const signatures=new Set();
  for(let i=0;i<COUNT;i++){
    const s=synthesizeRattle(i), b=wav(s);
    assert.deepEqual(s,synthesizeRattle(i));
    assert.equal(b.readUInt32LE(24),RATE);assert.equal(b.readUInt16LE(22),1);
    assert.equal(s.length,Math.round(RATE*.38));assert.ok(s[0]===0 && s.at(-1)===0);
    const peak=Math.max(...s.map(Math.abs));assert.ok(peak>.1 && peak<.95);
    const rms=Math.sqrt(s.reduce((sum,x)=>sum+x*x,0)/s.length);assert.ok(rms>.015 && rms<.2);
    signatures.add(b.subarray(44).toString('base64'));
  }
  assert.equal(signatures.size,COUNT);
  assert.throws(()=>synthesizeRattle(-1));
});
