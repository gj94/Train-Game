// One LHB coach crossing 1 km. Default: 26 m jointed rail at 100 km/h.
// --welded selects the earlier panel-end illustration; --speed=60 changes speed.
// Reads the exported game sound; never changes generated sound assets.
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { wavHeader, pcm16 } from '../../railway-clang-simulator/src/wav.js';

const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const data = read('game/physical_model_data.gd');
const constant = name => +data.match(new RegExp(`const ${name} := ([\\d.+-]+)`))[1];
const gains = JSON.parse(data.match(/const WHEEL_GAIN := (\[[^\]]+\])/)[1]);
const rate = constant('RATE');
function wav(path) {
  const bytes = readFileSync(new URL(path, root));
  assert.equal(bytes.toString('ascii',0,4),'RIFF');
  let payload;
  for(let at=12;at+8<=bytes.length;) {
    const size=bytes.readUInt32LE(at+4), tag=bytes.toString('ascii',at,at+4);
    if(tag==='fmt ') {
      assert.equal(bytes.readUInt16LE(at+8),1);
      assert.equal(bytes.readUInt16LE(at+10),2);
      assert.equal(bytes.readUInt32LE(at+12),rate);
      assert.equal(bytes.readUInt16LE(at+22),16);
    }
    if(tag==='data') payload=bytes.subarray(at+8,at+8+size);
    at+=8+size+(size%2);
  }
  assert(payload);
  return [0,1].map(channel=>Float32Array.from({length:payload.length/4},(_,i)=>payload.readInt16LE(i*4+channel*2)/32768));
}
const kernels=[1,2].map(k=>wav(`assets/sounds/lab/physical_icf_wheel${k}.wav`));
const rolling=wav('assets/sounds/lab/physical_icf_rolling.wav');
const geometry=read('sim/stock/ported_stock.gd').match(/if model\.begins_with\("lhb_"\):\s*return \{[^\n]+/)[0];
const halfBogie=+geometry.match(/bogie = ([\d.]+)/)[1];
const offsets=geometry.match(/axle_offsets = \[([^\]]+)\]/)[1].split(',').map(Number);
const axles=[-halfBogie,halfBogie].flatMap(center=>offsets.map(x=>center+x));
const welded=process.argv.includes('--welded');
const referenceMix=process.argv.includes('--reference-mix');
const rollingMixGain=referenceMix?10**(-12/20):1;
const speedKmh=+(process.argv.find(x=>x.startsWith('--speed='))?.split('=')[1]??100);
const spacing=+(process.argv.find(x=>x.startsWith('--spacing='))?.split('=')[1]??26);
assert(speedKmh>0 && speedKmh<=200 && spacing>=13 && spacing<=1000);
const joints=welded?[0,1000]:Array.from({length:Math.ceil(1000/spacing)},(_,i)=>i*spacing);
const speed=speedKmh/3.6, leadIn=.5;
const events=joints.flatMap((position,joint)=>axles.map((x,axle)=>({
  joint:joint+1,trackMetres:position,axle:axle+1,sound:axle%2?'clang':'cling',
  impactSeconds:leadIn+(position+x-axles[0])/speed,
}))).sort((a,b)=>a.impactSeconds-b.impactSeconds);
const duration=Math.ceil(Math.max(events.at(-1).impactSeconds+1,leadIn+(1000+axles.at(-1)-axles[0])/speed+.4));
const output=[new Float32Array(duration*rate),new Float32Array(duration*rate)];
const reference=constant('REFERENCE_SPEED');
const impactScale=(.3+Math.sqrt(speedKmh/90))/(.3+Math.sqrt(reference/90));
const rollingScale=(speedKmh/reference)**.8;
// Fixed coach-centre listener, three metres to the side, travelling with the coach.
const distances=axles.map(x=>Math.hypot(x,3));
const rollLevel=Math.sqrt(distances.reduce((sum,d)=>sum+1/(1+(d/constant('NOISE_NEAR'))**2),0)/constant('NOISE_REF'));
const commonGain=.5;
for(let i=0;i<output[0].length;i++) {
  const time=i/rate;
  const fade=Math.max(0,Math.min(1,time/.25,(duration-time)/.4));
  for(let ch=0;ch<2;ch++) output[ch][i]=rolling[ch][i%rolling[ch].length]*constant('ROLLING_GAIN')*rollingScale*rollLevel*commonGain*fade*rollingMixGain;
}
for(const event of events) {
  const axle=event.axle-1, wheel=axle%2;
  const start=Math.round((event.impactSeconds-constant('KERNEL_LEAD'))*rate);
  const balance=wheel?10**(constant('DEFAULT_CLANG_BALANCE_DB')/20):1;
  const distanceGain=constant('NEAR_DISTANCE')/Math.max(constant('NEAR_DISTANCE'),distances[axle]);
  // Comparison mix: retain the preferred dry preview's exact per-axle voicing.
  const gain=constant('KERNEL_GAIN')*gains[wheel]*balance*(referenceMix?1:impactScale*distanceGain)*commonGain;
  assert(start>=0 && start+kernels[wheel][0].length<output[0].length);
  for(let ch=0;ch<2;ch++) for(let i=0;i<kernels[wheel][ch].length;i++) output[ch][start+i]+=kernels[wheel][ch][i]*gain;
}
let peak=0;
for(const channel of output) for(const sample of channel) peak=Math.max(peak,Math.abs(sample));
assert(peak<1,'Preview must not clip');
assert.equal(events.length,joints.length*4);
assert.equal(joints[1]-joints[0],welded?1000:spacing);
const directory=new URL('.local/audio-preview/',root);
mkdirSync(directory,{recursive:true});
const filename=`lhb-one-coach-1km-${welded?'welded':`jointed-${spacing}m`}-${speedKmh}kmh${referenceMix?'-reference-mix':''}`;
writeFileSync(new URL(filename+'.wav',directory),Buffer.concat([wavHeader(output[0].length,rate,2),pcm16(...output)]));
const report={coachCount:1,trackLengthMetres:1000,speedKmh,jointsMetres:joints,axleHits:events.length,
  mix:referenceMix?'preferred dry impact level, rolling -12 dB':'coach-centre distance attenuation with rolling',
  bogieCentresMetres:halfBogie*2,wheelbaseMetres:offsets[1]-offsets[0],durationSeconds:duration,peak,events,
  note:welded?'Representative welded panel with two end joints, not a surveyed route. Existing fitted joint timbre is illustrative; this is not a recorded SEJ sound.':`Representative ${spacing} m jointed track. One coach, four axles, both bogies scheduled individually; no locomotive or other coaches.`};
writeFileSync(new URL(filename+'.json',directory),JSON.stringify(report,null,2));
console.log(JSON.stringify({...report,events:events.slice(0,8),jointsMetres:[joints[0],joints.at(-1)],jointCount:joints.length,jointIntervalSeconds:(joints[1]-joints[0])/speed,filename},null,2));
