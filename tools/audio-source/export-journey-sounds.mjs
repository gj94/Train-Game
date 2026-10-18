import {readFileSync,writeFileSync,mkdirSync,copyFileSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {names,synthesize,wav} from '../src/journey-sounds.mjs';
const lab=resolve(dirname(fileURLToPath(import.meta.url)),'..'),game=resolve(process.argv[2]||join(lab,'../train-game'));
const out=join(game,'assets/sounds/journey');mkdirSync(out,{recursive:true});const hash=b=>createHash('sha256').update(b).digest('hex'),hashes={};
for(const name of names){const data=wav(synthesize(name));writeFileSync(join(out,name+'.wav'),data);hashes[name+'.wav']=hash(data);}
const source='src/journey-sounds.mjs';
writeFileSync(join(out,'provenance.json'),JSON.stringify({source:'railway-clang-simulator/'+source,source_sha256:hash(readFileSync(join(lab,source))),hashes,method:'Seeded 48 kHz mono PCM16 synthesis; fan, air, wake and interaction approximations, not field recordings. Approved rolling, joint and squeal PCM is unchanged.'},null,2)+'\n');
copyFileSync(join(lab,source),join(game,'tools/audio-source/journey-sounds.mjs'));
copyFileSync(fileURLToPath(import.meta.url),join(game,'tools/audio-source/export-journey-sounds.mjs'));
console.log('Exported '+names.length+' journey layers with provenance');
