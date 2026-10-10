// Publish a small, explicit service-file download without replacing the game ZIP.
import { readFile, writeFile, mkdir, rename, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { currentRelease } from './download-catalogue.mjs';

const {values}=parseArgs({options:{verified:{type:'boolean',default:false},baseline:{type:'string'},delayed:{type:'string'}}});
const root=fileURLToPath(new URL('../',import.meta.url));
const exportRoot=join(root,'export');
const release=await currentRelease(exportRoot);
if(!release) throw Error('Publish a game release before its compatible timetable.');
const source=await readFile(join(root,'art/timetables/kerala-coast-100-through-services.json'));
const pack=JSON.parse(source.toString('utf8'));
if(pack.layout!=='kerala_coast' || pack.services?.length!==100) throw Error('Expected the 100-service Kerala timetable.');
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const buildInfo=await readFile(join(exportRoot,release.build,'BUILD.txt'),'utf8');
const releasedCommit=buildInfo.match(/^Source base: ([a-f0-9]{7,40})\r?$/m)?.[1];
if(!releasedCommit) throw Error('Published game has no source identity.');
const git=async args=>(await promisify(execFile)('git',['-c','safe.directory='+root.replaceAll('\\','/').replace(/\/$/,''),...args],{cwd:root})).stdout.trim();
// Timetable data can change independently; dispatcher/physics/layout code cannot
// be certified against a game that does not contain those changes.
const changedRuntime=await git(['diff','--name-only',releasedCommit,'--','sim','data/routes/kerala_coast/route.json','data/routes/kerala_coast/operations.json',':!sim/timetables']);
const untrackedRuntime=(await git(['ls-files','--others','--exclude-standard','--','sim'])).split('\n').filter(path=>path && !path.startsWith('sim/timetables/'));
const requiresUpdate=Boolean(changedRuntime || untrackedRuntime.length || !buildInfo.includes('Uncommitted tracked changes included: False'));
async function sourceDigest(path) {
  const entries=[];
  for(const entry of await readdir(path,{withFileTypes:true})) {
    if(entry.isDirectory()) entries.push(entry.name+':'+await sourceDigest(join(path,entry.name)));
    else if(entry.name.endsWith('.gd') || entry.name.endsWith('.json')) entries.push(entry.name+':'+hash(await readFile(join(path,entry.name))));
  }
  return hash(entries.sort().join('\n'));
}
if(values.verified) {
  if(requiresUpdate) throw Error('Publish the updated game runtime before certifying this timetable for it.');
  if(!values.baseline || !values.delayed) throw Error('Verified publication requires baseline and delayed audit reports.');
  const digest=await sourceDigest(join(root,'sim'));
  for(const [key,path] of [['baseline',values.baseline],['delayed',values.delayed]]) {
    const report=JSON.parse(await readFile(path,'utf8'));
    if(!report.ok || report.finished!==100 || report.events.length || report.resumed_from || report.source_digest!==digest || (key==='delayed' ? report.player_delay<600 : report.player_delay!==0)) throw Error(key+' must be a complete clean audit of the current simulation sources.');
    for(const service of pack.services) {
      const record=report.services[service.id];
      const departure=service.departure.split(':').reduce((seconds,part)=>seconds*60+Number(part),0)+(service.day-1)*86400;
      if(!record?.stabled || record.completed_calls!==service.stops.length-1 || record.actual_departures[0]<0 || record.max_wait_seconds>1800 || record.departure!==departure || record.priority!==service.priority) throw Error('Incomplete/excessively held or mismatched working '+service.id);
      if(record.booked_stops.length!==service.stops.length) throw Error('Stale calling pattern '+service.id);
      for(let i=0;i<service.stops.length;i++) {
        const a=service.stops[i],b=record.booked_stops[i];
        for(const field of ['block','direction','minutes_from_origin','dwell_minutes']) if(a[field]!==b[field]) throw Error('Stale timetable '+service.id+': '+field);
      }
    }
  }
}
const directory=join(exportRoot,'timetables');
await mkdir(directory,{recursive:true});
// Immutable data names keep an in-flight download consistent while the
// catalogue atomically switches to a revised timetable.
const file='Kerala-Coast-100-Through-Services-'+hash(source).slice(0,12)+'.json';
const instructions=`KERALA COAST: 100 THROUGH AND REGIONAL SERVICES\n\n${requiresUpdate ? "Preview download: a game update is required for the terminal/depot dispatcher fix. The current "+release.build+" is not validated for this timetable." : "For "+release.build+". Timetable-only download: no replacement EXE/PCK needed."}\nStatus: ${values.verified ? 'Full-day baseline and ten-minute-late start passed.' : 'Preview; full-day simulation validation is still running.'}\n\n24 ERS-NCJ workings (12 each direction), including exactly two Vande Bharats.\nB001: ERS 08:35 -> NCJ, 8 cars. B012: NCJ 09:10 -> ERS, 16 cars.\nBoth call at ERS, ALLP, KYJ, QLN, TVC, KZT and NCJ in travel order.\n12 ERS-TVC intercity workings and 64 regional workings complete the day.\nThis is an authored busy scenario, not a published Indian Railways timetable.\nNorthbound locals omit TZH, VELI and VRLR because their current game geometry\nhas no reachable northbound passenger face.\n\n1. Download the JSON file to the PC where you play.\n2. Open the Kerala route and press F5 for Service Designer.\n3. Export your existing draft first if you want to retain it.\n4. Import this JSON, select K1, then Play and confirm starting a new run.\n5. The designer may say it has not been rehearsed locally; local rehearsal is optional.\n6. Drive K1, use A for AI, or take over another active train from Dispatch.\n\nExisting saves retain their original traffic. Import starts a new scenario.\nKeep the host PC awake until your download finishes.\n`;
for(const [name,bytes] of [[file,source],[file+'.sha256',hash(source)+'  '+file+'\n'],['README.txt',instructions]]) {
  await writeFile(join(directory,name+'.tmp'),bytes);
  await rename(join(directory,name+'.tmp'),join(directory,name));
}
const catalogue={format:1,build:release.build,file,status:values.verified?'verified':'validating',requires_update:requiresUpdate,sha256:hash(source)};
await writeFile(join(directory,'catalogue.json.tmp'),JSON.stringify(catalogue,null,2)+'\n');
await rename(join(directory,'catalogue.json.tmp'),join(directory,'catalogue.json'));
console.log(JSON.stringify({...catalogue,bytes:source.length}));
