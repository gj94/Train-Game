// Isolated native updater comparison. Never touches a published installation.
// node tools/updater/benchmark-transfer.mjs --mib=32 --baseline=885dc17
import {catalogue, envelope, BLOCK} from './publish.mjs';
import {createServer} from 'node:http';
import {createReadStream} from 'node:fs';
import {mkdir, writeFile, readFile, cp, stat} from 'node:fs/promises';
import {generateKeyPairSync, randomBytes} from 'node:crypto';
import {spawn} from 'node:child_process';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {parseArgs} from 'node:util';
import assert from 'node:assert/strict';

const {values} = parseArgs({options:{mib:{type:'string',default:'32'},baseline:{type:'string',default:'885dc17'}}});
const mib=Number(values.mib);
assert(Number.isInteger(mib)&&mib>=8&&mib<=128);
assert(/^[a-f0-9]{7,40}$/.test(values.baseline));
const root=fileURLToPath(new URL('../../',import.meta.url));
const temp=join(root,'.local','updater-transfer-benchmark-'+Date.now());
await mkdir(temp,{recursive:true});
async function run(command,args) {
  return await new Promise((resolve,reject)=>{
    const start=performance.now(),child=spawn(command,args,{windowsHide:true,cwd:root});let out='',err='';
    child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>err+=d);
    child.on('error',reject);child.on('close',code=>resolve({code,out,err,seconds:(performance.now()-start)/1000}));
  });
}
const old=await run('git',['-c','safe.directory=D:/ClaudeWS/train-game','show',values.baseline+':tools/updater/UpdateCore.cs']);
assert.equal(old.code,0,old.err);
await writeFile(join(temp,'V3.cs'),old.out);
for(const [label,source] of [['v3',join(temp,'V3.cs')],['v4',join(root,'tools/updater/UpdateCore.cs')]]) {
  const result=await run('C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\csc.exe',
    ['/nologo','/optimize+','/target:exe','/r:System.Web.Extensions.dll','/r:System.Core.dll','/r:System.IO.Compression.dll',
      '/out:'+join(temp,label+'.exe'),source.replaceAll('/','\\'),join(root,'tools/updater/TestClient.cs').replaceAll('/','\\')]);
  assert.equal(result.code,0,result.out+result.err);
}
const base=join(temp,'base'),target=join(temp,'TrainGame-Benchmark'),payloadDirectory=join(temp,'payloads');
await mkdir(base);await mkdir(target);
const exe=randomBytes(1024),targetPack=randomBytes(mib*1024*1024+31);
// Mixed raw and compressible blocks, always unique and without unchanged holes.
for(let offset=0;offset+BLOCK<=targetPack.length;offset+=BLOCK*3)targetPack.fill(0,offset+BLOCK/2,offset+BLOCK);
await writeFile(join(base,'TrainGame.exe'),exe);await writeFile(join(target,'TrainGame.exe'),exe);
await writeFile(join(base,'TrainGame.pck'),randomBytes(targetPack.length));
await writeFile(join(target,'TrainGame.pck'),targetPack);
const manifest=await catalogue(target,'TrainGame-Benchmark',1,{payloadDirectory});
const keys=generateKeyPairSync('rsa',{modulusLength:2048}),jwk=keys.publicKey.export({format:'jwk'});
const keyFile=join(temp,'key.xml');
await writeFile(keyFile,`<RSAKeyValue><Modulus>${Buffer.from(jwk.n,'base64url').toString('base64')}</Modulus><Exponent>${Buffer.from(jwk.e,'base64url').toString('base64')}</Exponent></RSAKeyValue>`);
const signed=envelope(manifest,keys.privateKey);
let delay=0,requests=0,bytes=0,active=0,maxActive=0;
const server=createServer(async(req,res)=>{
  try {
    if(req.url==='/updates/latest.json'){res.end(signed);return;}
    if(req.url!=='/update-payloads/TrainGame-Benchmark/TrainGame.pck.blocks'){res.writeHead(404);res.end();return;}
    const path=join(payloadDirectory,'TrainGame.pck.blocks'),size=(await stat(path)).size;
    const range=/^bytes=(\d+)-(\d+)$/.exec(req.headers.range??'');
    if(!range||+range[1]>+range[2]||+range[2]>=size){res.writeHead(416);res.end();return;}
    const start=+range[1],end=+range[2];requests++;bytes+=end-start+1;active++;maxActive=Math.max(active,maxActive);
    res.once('close',()=>active--);
    if(delay)await new Promise(resolve=>setTimeout(resolve,delay));
    res.writeHead(206,{'Content-Range':`bytes ${start}-${end}/${size}`,'Content-Length':end-start+1});
    const stream=createReadStream(path,{start,end});stream.on('error',()=>res.destroy());res.on('close',()=>stream.destroy());stream.pipe(res);
  } catch {res.destroy();}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const address=`http://127.0.0.1:${server.address().port}/`,samples=[];
try {
  for(const addedLatency of [0,5]) {
    for(const label of addedLatency===0?['v3','v4']:['v4','v3']) {
      delay=addedLatency;requests=bytes=active=maxActive=0;
      const directory=join(temp,label+'-'+addedLatency);await cp(base,directory,{recursive:true});
      const result=await run(join(temp,label+'.exe'),[directory,address,keyFile]);
      assert.equal(result.code,0,result.err);
      const info=JSON.parse(result.out);
      assert.deepEqual(await readFile(join(directory,'TrainGame.pck')),targetPack);
      const sample={client:label,added_request_latency_ms:addedLatency,wall_seconds:result.seconds,
        http_requests:requests,max_concurrent_requests:maxActive,network_bytes:bytes,
        end_to_end_mib_s:bytes/1048576/result.seconds,...info};
      samples.push(sample);console.log(JSON.stringify(sample));
    }
  }
  const comparisons=[0,5].map(latency=>{
    const before=samples.find(s=>s.client==='v3'&&s.added_request_latency_ms===latency);
    const after=samples.find(s=>s.client==='v4'&&s.added_request_latency_ms===latency);
    return {added_request_latency_ms:latency,wall_speedup:before.wall_seconds/after.wall_seconds,
      request_reduction_percent:100*(1-after.http_requests/before.http_requests)};
  });
  const report={baseline:values.baseline,fixture_mib:mib,fixtureDirectory:temp,
    environment:'Development PC, same-host loopback; real disk, native .NET clients; 0 and injected 5 ms per HTTP request. Not target-PC LAN throughput.',
    integrity:'All final game bytes match; no production installation or download server changed.',samples,comparisons};
  await writeFile(join(temp,'results.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({report:join(temp,'results.json'),comparisons}));
} finally {server.closeAllConnections();await new Promise(resolve=>server.close(resolve));}
