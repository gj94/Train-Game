// Local-only development harness. Uses the preserved approved website source.
import http from 'node:http';
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url));
const source=join(root,'tools/sound-lab/enhanced/public');
const out=join(root,'.local/onboard-ab');mkdirSync(out,{recursive:true});
const bank=join(root,'assets/sounds/body_v2');
const allowed=new Map([...['audio.js','model.js','squeal.js','squeal-profile.js','turnouts.js'].map(name=>['/'+name,join(source,name)]),...Array.from({length:8},(_,i)=>[`/synthesis/impact-${i}.wav`,join(bank,`impact-${i}.wav`)]),['/synthesis/rolling-bed.wav',join(bank,'rolling-bed.wav')]]);
const server=http.createServer((req,res)=>{
 if(req.method==='POST'&&/^\/capture\/(30|71.6|120)-(pilot|passenger)$/.test(req.url)){
  const chunks=[];let bytes=0;
  req.on('data',b=>{bytes+=b.length;if(bytes>8000000)req.destroy();else chunks.push(b);});
  req.on('end',()=>{writeFileSync(join(out,`website-${req.url.split('/').pop()}kmh.wav`),Buffer.concat(chunks));res.end('saved');});return;
 }
 if(req.url==='/'&&req.method==='GET'){res.setHeader('content-type','text/html');res.end(readFileSync(new URL('./index.html',import.meta.url)));return;}
 if(allowed.has(req.url)&&req.method==='GET'){res.setHeader('content-type',req.url.endsWith('.js')?'text/javascript':'audio/wav');res.end(readFileSync(allowed.get(req.url)));return;}
 res.writeHead(404).end();
});
server.listen(49995,'127.0.0.1',()=>console.log('Onboard reference renderer: http://127.0.0.1:49995/'));
