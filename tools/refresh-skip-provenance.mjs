// R41-only provenance refresh. Skip presentation/observers are not called by a
// timetable replay. Verify the ORIGINAL movement method and worker loop verbatim,
// and reject every other changed railway input. No checkpoint/audit is regenerated.
import {readFile,writeFile,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=new URL('../',import.meta.url);
const base='ce0a7d9';
const additions=['sim/skip_options.gd','sim/skip_history.gd','sim/skip_map_state.gd','sim/skip_encounters.gd','sim/skip_to_event.gd'];
const changed=['sim/time_skip.gd','sim/time_skip_worker.gd'];
const sha=b=>createHash('sha256').update(b).digest('hex');
const normalized=b=>b.toString('utf8').replaceAll('\r\n','\n');
const prior=p=>execFileSync('git',['-c','safe.directory=D:/ClaudeWS/train-game','show',`${base}:${p}`],{encoding:'utf8'}).replaceAll('\r\n','\n');
const pretty=value=>JSON.stringify(value,null,'\t').replaceAll('\n','\n\t');
function replaceObject(raw,key,value){
  const pattern=new RegExp(`(\t"${key}": )\\{[\\s\\S]*?\\n\t\\}`);
  assert.ok(pattern.test(raw));return raw.replace(pattern,(_match,prefix)=>prefix+pretty(value));
}
function replaceString(raw,key,value){
  const pattern=new RegExp(`("${key}": )"[^"]*"`);assert.ok(pattern.test(raw));return raw.replace(pattern,(_match,prefix)=>prefix+JSON.stringify(value));
}
function withProvenance(raw,value){return raw.replace(/\n}\s*$/,',\n\t"skip_observer_refresh": '+pretty(value)+'\n}\n');}
for(const [path,start] of [['sim/time_skip.gd','func _init('],['sim/time_skip_worker.gd','func _run(']]){
  const old=prior(path),now=normalized(await readFile(new URL(path,root)));
  assert.equal(now.slice(now.indexOf(start)),old.slice(old.indexOf(start)),`Simulation algorithm changed: ${path}`);
}
const sources={};
async function walk(folder){
  for(const e of await readdir(new URL(folder+'/',root),{withFileTypes:true})){
    const path=folder+'/'+e.name;
    if(e.isDirectory())await walk(path);
    else if(/\.(gd|json|bin|csv)$/.test(path)){
      const bytes=await readFile(new URL(path,root));sources[path]=sha(path.endsWith('.bin')?bytes:normalized(bytes));
    }
  }
}
await walk('sim');await walk('data/routes/kerala_coast');
const report={base,reason:'Skip observers/UI only; original Advance.step and worker simulation loop identical. All other railway inputs and all prepared checkpoint bytes unchanged.',days:[]};
for(const [startDir,timeDir]of [['data/service_starts','data/railway_times'],['data/timetables/intensive/starts','data/timetables/intensive/times']]){
  const startRaw=prior(startDir+'/catalogue.json'),timeRaw=prior(timeDir+'/catalogue.json'),trafficRaw=prior(startDir+'/traffic.json');
  const starts=JSON.parse(startRaw),times=JSON.parse(timeRaw),traffic=JSON.parse(trafficRaw);
  // Preserve exact schedule/preview number formatting. Refuse an unrelated
  // working-copy edit; allow only this tool's previously generated provenance.
  for(const [path,original]of [[startDir+'/catalogue.json',starts],[timeDir+'/catalogue.json',times],[startDir+'/traffic.json',traffic]]){
    const current=JSON.parse(await readFile(new URL(path,root)));
    for(const key of ['sources','skip_observer_refresh','departure_catalogue_sha256','start_sha256','timeline_sha256']){
      delete current[key];delete original[key];
    }
    assert.deepEqual(current,original,`Unrelated prepared-data change: ${path}`);
  }
  Object.assign(starts,JSON.parse(startRaw));Object.assign(times,JSON.parse(timeRaw));Object.assign(traffic,JSON.parse(trafficRaw));
  assert.deepEqual(times.sources,starts.sources);
  const revised={...sources};
  if(startDir.includes('intensive'))revised['art/timetables/kerala-coast-intensive.json']=sha(normalized(await readFile(new URL('art/timetables/kerala-coast-intensive.json',root))));
  const differences=[];
  for(const path of new Set([...Object.keys(starts.sources),...Object.keys(revised)])){
    if(starts.sources[path]===revised[path])continue;
    assert.ok([...changed,...additions].includes(path),`Unaudited changed railway input: ${path}`);
    if(changed.includes(path))assert.equal(starts.sources[path],sha(prior(path)),`Unexpected source baseline: ${path}`);
    else assert.equal(starts.sources[path],undefined,`Previously existing helper: ${path}`);
    differences.push({path,before:starts.sources[path]??null,after:revised[path]});
  }
  assert.equal(differences.length,7,'This is a one-time refresh, not a generic stale-audit bypass');
  const provenance={base,reason:report.reason,differences};
  starts.sources=revised;starts.skip_observer_refresh=provenance;
  const ordered=Object.fromEntries(Object.entries(revised).sort(([a],[b])=>a<b?-1:a>b?1:0));
  const startBytes=withProvenance(replaceObject(startRaw,'sources',ordered),provenance);
  times.sources=revised;times.departure_catalogue_sha256=sha(startBytes);times.skip_observer_refresh=provenance;
  const timeBytes=withProvenance(replaceString(replaceObject(timeRaw,'sources',ordered),'departure_catalogue_sha256',sha(startBytes)),provenance);
  traffic.start_sha256=sha(startBytes);traffic.timeline_sha256=sha(timeBytes);traffic.skip_observer_refresh=provenance;
  await writeFile(new URL(startDir+'/catalogue.json',root),startBytes);
  await writeFile(new URL(timeDir+'/catalogue.json',root),timeBytes);
  const trafficBytes=withProvenance(replaceString(replaceString(trafficRaw,'start_sha256',sha(startBytes)),'timeline_sha256',sha(timeBytes)),provenance);
  await writeFile(new URL(startDir+'/traffic.json',root),trafficBytes);
  report.days.push({startDir,timeDir,differences});
}
console.log(JSON.stringify(report,null,2));
