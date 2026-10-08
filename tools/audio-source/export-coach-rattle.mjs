// Canonical location: railway-clang-simulator/tools/export-coach-rattle.mjs.
import {readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync} from 'node:fs';
import {resolve, dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {synthesizeRattle, wav, COUNT} from '../src/coach-rattle.mjs';
const lab=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const game=resolve(process.argv[2] || join(lab,'../train-game'));
const out=join(game,'assets/sounds/coach_rattle');mkdirSync(out,{recursive:true});
const hash=b=>createHash('sha256').update(b).digest('hex');
const hashes={};
for(let i=0;i<COUNT;i++){
  const name=`rattle-${i}.wav`,data=wav(synthesizeRattle(i));
  writeFileSync(join(out,name),data);hashes[name]=hash(data);
  const settings=join(out,name+'.import');
  if(existsSync(settings))writeFileSync(settings,readFileSync(settings,'utf8').replace(/compress\/mode=\d+/,'compress/mode=0'));
}
const source='src/coach-rattle.mjs';
writeFileSync(join(out,'provenance.json'),JSON.stringify({source:'railway-clang-simulator/'+source,source_sha256:hash(readFileSync(join(lab,source))),hashes,method:'Eight seeded modal loose-panel/latch cues, 48 kHz mono PCM16. Synthesised approximation, not recorded or reference-fitted ICF sound. No alteration to approved joint/rolling/squeal banks.'},null,2)+'\n');
mkdirSync(join(game,'tools/audio-source'),{recursive:true});
copyFileSync(join(lab,source),join(game,'tools/audio-source/coach-rattle.mjs'));
copyFileSync(fileURLToPath(import.meta.url),join(game,'tools/audio-source/export-coach-rattle.mjs'));
console.log('Exported eight coach-body cues; source and provenance preserved.');
