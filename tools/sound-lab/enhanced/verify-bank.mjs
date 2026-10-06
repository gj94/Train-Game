import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import {synthesizeSqueal} from './public/squeal.js';
const game=process.argv[2]||'D:/ClaudeWS/train-game',results=[];
for(let variant=0;variant<4;variant++){
 const expected=synthesizeSqueal(variant,48000),wav=readFileSync(`${game}/assets/sounds/platform_enhanced/squeal-${variant}.wav`);
 assert.equal(wav.readUInt32LE(40)/2,expected.length);let error=0,energy=0,peak=0,maxStep=0;
 for(let i=0;i<expected.length;i++){const sample=wav.readInt16LE(44+2*i)/32768;error=Math.max(error,Math.abs(sample-expected[i]));energy+=sample*sample;peak=Math.max(peak,Math.abs(sample));if(i)maxStep=Math.max(maxStep,Math.abs(expected[i]-expected[i-1]));}
 assert.ok(error<=.5/32768+1e-9);assert.ok(peak<1);assert.ok(Math.abs(expected[0]-expected.at(-1))<=maxStep);
 results.push({variant,frames:expected.length,maxQuantizationError:error,rms:Math.sqrt(energy/expected.length),peak});
}
console.log(JSON.stringify(results,null,2));
