import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,readFile,writeFile,rm} from 'node:fs/promises';
import {join,resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {waitQuality} from './lib/wait-quality.mjs';
const hash=b=>createHash('sha256').update(b).digest('hex');
async function fixture(t,mode='predictive',network=false){
  const root=await mkdtemp(resolve('.local/finalizer-test-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  const input=join(root,'input'),output=join(root,'output');
  for(const sub of ['starts','times'])await mkdir(join(input,sub),{recursive:true});
  const state=Buffer.from('Synthetic integrity-test bytes; Godot owns snapshot round-trip validation.');
  const count=network?208:100;
  const services=Object.fromEntries(Array.from({length:count},(_,i)=>['S'+i,{stabled:true,actual_arrivals:[0,300],actual_departures:[0,300],booked_stops:[{},network&&i===0?{boundary:'exit'}:{}],...(network?{terminal_kind:i===0?'boundary_exit':'depot'}:{})}]));
  const audit={ok:true,finished:count,operating_day:network?'network':'standard',dispatcher:mode,events:[],maximum_wait:0,delay:0,wait_quality:waitQuality([]),station_wait_quality:waitQuality([])};
  const stations=network?[{code:'A',name:'Alpha',s:0,half:1000},{code:'B',name:'Beta',s:10000,half:1000}]:[];
  await writeFile(join(input,'audit.json'),JSON.stringify({audit,services,stations,station_waits:[],signal_waits:[]}));
  const position=(id,s)=>[id,s,s+50,s-50,1];
  const frames=Array.from({length:151},(_,i)=>[i*2,[position('S0',0),position('S1',[-200,-20,20,200][Math.min(i,3)]),position('S2',10000),position('S3',10000+[-200,-20,20,200][Math.min(i,3)])]]);
  await writeFile(join(input,'traffic.jsonl'),network?frames.map(f=>JSON.stringify(f)+'\n').join(''):'[28800,[]]\n');
  const starts={complete:true,dispatcher:mode,audit,services:Object.keys(services).map(id=>({id,file:id+'.bin',sha256:hash(state)})),sources:{},layout_signature:'synthetic'};
  const startBytes=JSON.stringify(starts);
  await writeFile(join(input,'starts/catalogue.json'),startBytes);
  const clocks=network?[0,300]:[28800];
  const times={complete:true,dispatcher:mode,audit:{ok:true,round_trips:clocks.length},sources:{},layout_signature:'synthetic',departure_catalogue_sha256:hash(startBytes),states:clocks.map(clock=>({id:'T'+String(clock).padStart(6,'0'),file:'T'+String(clock).padStart(6,'0')+'.bin',clock,sha256:hash(state)}))};
  await writeFile(join(input,'times/catalogue.json'),JSON.stringify(times));
  for(const row of starts.services)await writeFile(join(input,'starts',row.file),state);
  for(const row of times.states)await writeFile(join(input,'times',row.file),state);
  return {input,output,network};
}
function run(f,...flags){return spawnSync(process.execPath,['tools/finalize_timetable_variant.mjs',f.input,f.output,f.network?'--network':'--standard',...flags],{encoding:'utf8'});}
test('V2 standard publishes separate starts/times and declares its dispatcher',async t=>{
  const f=await fixture(t),r=run(f,'--predictive');assert.equal(r.status,0,r.stderr);
  const traffic=JSON.parse(await readFile(join(f.output,'starts/traffic.json')));
  assert.equal(traffic.dispatcher,'predictive');assert.equal(traffic.services.length,100);
  assert.equal(JSON.parse(await readFile(join(f.output,'times/catalogue.json'))).dispatcher,'predictive');
  await assert.rejects(readFile(join(f.output,'service_starts/catalogue.json')));
});
test('Classic standard retains existing directory layout',async t=>{
  const f=await fixture(t,'classic'),r=run(f);assert.equal(r.status,0,r.stderr);
  assert.equal(JSON.parse(await readFile(join(f.output,'service_starts/traffic.json'))).dispatcher,'classic');
  await readFile(join(f.output,'railway_times/catalogue.json'));
});
test('Wrong mode cannot publish even a complete rehearsal',async t=>{
  const f=await fixture(t,'classic'),r=run(f,'--predictive');assert.notEqual(r.status,0);assert.match(r.stderr,/Wrong dispatcher/);
  await assert.rejects(readFile(join(f.output,'starts/catalogue.json')));
});
test('Corrupt snapshot prevents any copy to the active day',async t=>{
  const f=await fixture(t);await writeFile(join(f.input,'starts/S99.bin'),'corrupt');
  assert.notEqual(run(f,'--predictive').status,0);
  await assert.rejects(readFile(join(f.output,'starts/catalogue.json')));
});
test('A timeline from another dispatcher cannot accompany valid departures',async t=>{
  const f=await fixture(t),path=join(f.input,'times/catalogue.json');
  const data=JSON.parse(await readFile(path));data.dispatcher='classic';await writeFile(path,JSON.stringify(data));
  assert.notEqual(run(f,'--predictive').status,0);
  await assert.rejects(readFile(join(f.output,'starts/catalogue.json')));
});
test('Network publication preserves midnight states and measured distributed passes',async t=>{
  const f=await fixture(t,'predictive',true),r=run(f,'--predictive');assert.equal(r.status,0,r.stderr);
  const traffic=JSON.parse(await readFile(join(f.output,'starts/traffic.json')));
  assert.equal(traffic.services.length,208);assert.equal(traffic.audit.overtake_count,2);
  assert.equal(new Set(traffic.events.map(e=>e.station)).size,2);
  assert.equal(JSON.parse(await readFile(join(f.output,'times/catalogue.json'))).states[0].clock,0);
});
test('Network publication rejects disappearance masquerading as overtakes',async t=>{
  const f=await fixture(t,'predictive',true);
  const path=join(f.input,'traffic.jsonl'),frames=(await readFile(path,'utf8')).trim().split('\n').map(JSON.parse);
  frames[1][1]=[];await writeFile(path,frames.map(f=>JSON.stringify(f)+'\n').join(''));
  const r=run(f,'--predictive');assert.notEqual(r.status,0);assert.match(r.stderr,/actual overtakes/);
  await assert.rejects(readFile(join(f.output,'starts/catalogue.json')));
});
test('Network publication rejects a boundary working mislabeled as depot completion',async t=>{
  const f=await fixture(t,'predictive',true),path=join(f.input,'audit.json');
  const report=JSON.parse(await readFile(path));report.services.S0.terminal_kind='depot';await writeFile(path,JSON.stringify(report));
  assert.notEqual(run(f,'--predictive').status,0);
  await assert.rejects(readFile(join(f.output,'starts/catalogue.json')));
});
