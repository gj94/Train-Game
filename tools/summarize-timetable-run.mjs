import {readFile,writeFile} from 'node:fs/promises';
import {TrafficEncounters,locationAt} from './lib/traffic-encounters.mjs';
const folder=process.argv[2];
if(!folder)throw Error('Pass an isolated rehearsal folder');
// Read a point-in-time copy. A concurrent writer may have an unfinished last line.
const bytes=await readFile(folder+'/traffic.jsonl','utf8');
const complete=bytes.slice(0,bytes.lastIndexOf('\n'));
const detector=new TrafficEncounters();let latest,first,samples=0;
for(const line of complete.split('\n')){
  if(!line)continue;
  latest=JSON.parse(line);first??=latest[0];detector.sample(latest);samples++;
}
// Geometry station centres are unchanged; final audits supply current yard bounds.
let source,finished=false;
try{source=JSON.parse(await readFile(folder+'/audit.json','utf8'));finished=true;}
catch(error){if(error.code!=='ENOENT')throw error;source=JSON.parse(await readFile('data/timetables/intensive/audit.json','utf8'));}
const events=detector.events.filter(e=>e.kind==='overtake'&&[e.a,e.b].includes('K1')&&e.overtaker!=='K1')
 .sort((a,b)=>a.time-b.time).map(e=>({...e,...locationAt(e.chainage_m,source.stations)}));
const by_station={};
for(const e of events)(by_station[e.station||e.location]??=[]).push({train:e.overtaker,time:e.time});
const counts=Object.values(by_station).map(rows=>rows.length);
const distribution={stations:counts.length,passes:events.length,maximum_at_one_station:Math.max(0,...counts),
 concentration:events.length?counts.reduce((sum,n)=>sum+(n/events.length)**2,0):0};
const punctuality={};
if(finished)for(const service of Object.values(source.services)){
  if(service.arrival_delay<0)continue;
  (punctuality[service.priority]??=[]).push(service.arrival_delay);
}
for(const [priority,values]of Object.entries(punctuality)){
  values.sort((a,b)=>a-b);
  punctuality[priority]={services:values.length,mean_delay_seconds:values.reduce((a,b)=>a+b,0)/values.length,
    p90_delay_seconds:values[Math.max(0,Math.ceil(values.length*.9)-1)],maximum_delay_seconds:values.at(-1)};
}
const report={finished,first,clock:detector.clock,samples,active:latest?.[1].length??0,
 distinct_k1_overtakers:[...new Set(events.map(e=>e.overtaker))],by_station,distribution,events,
 ...(finished?{audit:source.audit,punctuality}:{warning:'Partial replay. Station-centre mapping uses previous yard bounds until final audit; distribution is not a final result.'})};
const output=process.argv.find(a=>a.startsWith('--output='))?.slice(9);
if(output)await writeFile(output,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
