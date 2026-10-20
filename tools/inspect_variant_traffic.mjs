import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';
import {readFile, writeFile} from 'node:fs/promises';
const folder=process.argv[2]??'.local/intensive-v1';
const detector=new TrafficEncounters();let last;
for await(const line of createInterface({input:createReadStream(folder+'/traffic.jsonl'),crlfDelay:Infinity})){
  if(!line)continue;
  let frame;try{frame=JSON.parse(line);}catch{break;}
  detector.sample(frame);last=frame;
}
const passed=detector.events.filter(e=>e.kind==='overtake'&&[e.a,e.b].includes('K1')&&e.overtaker!=='K1');
console.log(JSON.stringify({clock:detector.clock,events:detector.events.length,k1_passes:passed.length,
  distinct_overtakers:[...new Set(passed.map(e=>e.overtaker))],
  k1:passed,pair:detector.events.filter(e=>[e.a,e.b].includes('B002')&&[e.a,e.b].includes('B042'))},null,2));
if(process.argv.includes('--positions'))console.log(JSON.stringify(last[1].filter(r=>['K1','B002','D100','D101','D102','D103','D104','D105','D108','D109','D110','D111','D114','D115','D116'].includes(r[0])),null,2));
if(process.argv.includes('--write')){
  const audit=JSON.parse(await readFile(folder+'/audit.json'));
  const events=detector.events.map(e=>({...e,...locationAt(e.chainage_m,audit.stations)}));
  await writeFile(folder+'/encounters.json',JSON.stringify(events,null,2)+'\n');
}
