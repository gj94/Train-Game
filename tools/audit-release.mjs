// Read-only publication audit. Does not launch/extract the game or fetch full ZIPs.
import {readFile,open,stat,writeFile} from 'node:fs/promises';
import {createPublicKey,createHash,verify} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import assert from 'node:assert/strict';
const root=fileURLToPath(new URL('../',import.meta.url));
const build=process.argv[2],base=process.argv[3]||'http://192.168.8.183:8765';
assert.match(build,/^TrainGame-[A-Za-z0-9_-]+$/);
const folder=join(root,'export'),local=join(folder,build);
const policy=JSON.parse(await readFile(join(folder,'download-release.json')));
assert.equal(policy.build,build);assert.equal(policy.incremental,true);
const signed=JSON.parse(await readFile(join(folder,'updates/latest.json')));
const bytes=Buffer.from(signed.payload,'base64'),manifest=JSON.parse(bytes);
const xml=await readFile(join(root,'tools/updater/public-key.xml'),'utf8');
const key=createPublicKey({format:'jwk',key:{kty:'RSA',n:Buffer.from(xml.match(/<Modulus>(.*?)<\/Modulus>/)[1],'base64').toString('base64url'),e:Buffer.from(xml.match(/<Exponent>(.*?)<\/Exponent>/)[1],'base64').toString('base64url')}});
assert.ok(verify('sha256',bytes,key,Buffer.from(signed.signature,'base64')));assert.equal(manifest.version,build);
const identity=await readFile(join(local,'BUILD.txt'),'utf8');
assert.match(identity,/Uncommitted tracked changes included: False/);
const remote=await fetch(base+'/updates/latest.json');assert.equal(remote.status,200);assert.deepEqual(await remote.json(),signed);
const page=await (await fetch(base+'/')).text();assert.ok(page.includes(build+'.zip'));
const zip=join(folder,build+'.zip'),size=(await stat(zip)).size;
const head=await fetch(base+'/'+build+'.zip',{method:'HEAD'});assert.equal(head.status,200);assert.equal(Number(head.headers.get('content-length')),size);
const sha=b=>createHash('sha256').update(b).digest('hex');
async function rangeCheck(path,url,offset,length,expected){
  const file=await open(path,'r');const buffer=Buffer.alloc(length);
  try{assert.equal((await file.read(buffer,0,length,offset)).bytesRead,length);}finally{await file.close();}
  const response=await fetch(url,{headers:{Range:`bytes=${offset}-${offset+length-1}`}});assert.equal(response.status,206);
  const actual=Buffer.from(await response.arrayBuffer());assert.deepEqual(actual,buffer);
  if(expected)assert.equal(sha(actual),expected);
}
for(const offset of [0,Math.floor(size/2),size-65536])await rangeCheck(zip,base+'/'+build+'.zip',offset,65536);
const pack=manifest.files.find(f=>f.path==='TrainGame.pck');assert.ok(pack);
for(const index of [0,Math.floor(pack.chunks.length/2),pack.chunks.length-1])await rangeCheck(join(local,pack.path),base+'/update-files/'+build+'/'+pack.path,index*manifest.blockSize,Math.min(manifest.blockSize,pack.size-index*manifest.blockSize),pack.chunks[index]);
const oldBuild='TrainGame-Kerala-Coast-R29-Windows';
assert.equal((await fetch(base+'/'+oldBuild+'.zip',{method:'HEAD'})).status,404);
let changed=0,changedBytes=0;
const oldSigned=JSON.parse(await readFile(join(folder,'updates',oldBuild+'.json')));
const previous=JSON.parse(Buffer.from(oldSigned.payload,'base64'));
for(const file of manifest.files){
  const old=previous.files.find(f=>f.path===file.path);
  for(let i=0;i<file.chunks.length;i++)if(file.chunks[i]!==old?.chunks[i]){changed++;changedBytes+=Math.min(manifest.blockSize,file.size-i*manifest.blockSize);}
}
const report={version:build,source_export_commit:identity.match(/Source base: (\S+)/)[1],clean_export:true,sequence:manifest.sequence,signature_valid:true,zip_bytes:size,pck_bytes:pack.size,managed_files:manifest.files.length,zip_ranges_checked:3,update_blocks_checked:3,lan_downloads_verified:true,old_downloads_return_404:true,changed_blocks_from_R29:changed,changed_bytes_from_R29:changedBytes,distribution_gameplay_test:false};
await writeFile(join(root,'.local/r30-publication.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
