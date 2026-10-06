// Run from railway-clang-simulator/tools; the lab owns every generated sample.
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const lab=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const source=join(lab,'profiles/platform-enhanced');
const game=resolve(process.argv[2]||join(lab,'../train-game'));
const {synthesizeSqueal}=await import(pathToFileURL(join(source,'public/squeal.js')));
const dest=join(game,'assets/sounds/platform_enhanced');mkdirSync(dest,{recursive:true});
const sha=b=>createHash('sha256').update(b).digest('hex');
const hashes={},inputs={},envelopes=[];
const expected=JSON.parse(readFileSync(join(lab,'profiles/platform-body-v2/provenance.json'),'utf8')).hashes;
for(let i=0;i<8;i++){
 const name=`impact-${i}.wav`,wav=readFileSync(join(lab,'profiles/platform-body-v2',name));
 if(sha(wav)!==expected[name])throw Error('Original BODY V2 bank changed');
 const n=wav.readUInt32LE(40)/2;
 envelopes.push(Array.from({length:32},(_,b)=>{const start=Math.floor(b*n/32),end=Math.floor((b+1)*n/32);let energy=0;for(let s=start;s<end;s++)energy+=(wav.readInt16LE(44+2*s)/32768)**2;return [(start+end)/2/48000-.0213333,energy/n];}));
}
function wav(samples,channel){const n=samples.length,channels=channel===undefined?1:2,b=Buffer.alloc(44+n*channels*2);b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(channels,22);b.writeUInt32LE(48000,24);b.writeUInt32LE(48000*channels*2,28);b.writeUInt16LE(channels*2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(n*channels*2,40);for(let i=0;i<n;i++)b.writeInt16LE(Math.round(samples[i]*32768),44+(i*channels+(channel??0))*2);return b;}
for(let i=0;i<4;i++)for(const [suffix,channel] of [['',undefined],['-left',0],['-right',1]]){
 const name=`squeal-${i}${suffix}.wav`,data=wav(synthesizeSqueal(i,48000),channel),file=join(dest,name);writeFileSync(file,data);hashes[name]=sha(data);
 let settings=existsSync(file+'.import')?readFileSync(file+'.import','utf8'):'[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\ncompress/mode=0\nedit/trim=false\nedit/normalize=false\n';
 writeFileSync(file+'.import',settings.replace(/compress\/mode=\d+/,'compress/mode=0'));
}
for(const name of ['Acoustics.md','TURNOUT-MODEL.md','public/audio.js','public/model.js','public/turnouts.js','public/squeal.js','public/squeal-profile.js'])inputs[name]=sha(readFileSync(join(source,name)));
writeFileSync(join(dest,'provenance.json'),JSON.stringify({source:'platform-squeal-benchmark-src-md-20261006-221237',inputs,hashes,method:'Original random-phase synthesizeSqueal/profile at 48000 Hz; nearest 16-bit PCM, no normalization. Unchanged BODY V2 impacts measured into 32 energy bins.',calibration:'Squeal spectrum is fitted to the supplied benchmark. Turnout strengths, curvature response and onboard balances remain perceptual models, not absolute SPL or surveyed-radius calibration.'},null,2)+'\n');
writeFileSync(join(game,'game/platform_enhanced_data.gd'),`extends RefCounted\n## GENERATED in sibling sound lab by export-platform-enhanced.mjs.\nconst ROOT := "res://assets/sounds/platform_enhanced/"\nconst SQUEAL_FRAMES := 262144\nconst SQUEAL_SECONDS := 262144.0/48000.0\nconst ENVELOPES := ${JSON.stringify(envelopes)}\nconst HASHES := ${JSON.stringify(hashes)}\n`);
console.log('Exported four exact-formula squeal banks, routed copies, energy bins and source provenance.');
