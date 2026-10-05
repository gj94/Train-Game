import {trainPosition,propagationDelay} from './model.js';

// v2 uses stochastic, spectrum-fitted excitations. These WAV assets were generated
// from energy statistics and new random phases; no source waveform is replayed.
export function requestPlaybackSession(nav=globalThis.navigator){
 try{if(nav?.audioSession){nav.audioSession.type='playback';return true;}}catch{}
 return false;
}
async function resumedWithin(promise){let timer;try{return await Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('Audio is waiting for permission. Tap Start passing again, or use Test sound.')),3500);})]);}finally{clearTimeout(timer);}}
function panner(context){const p=context.createPanner();p.panningModel='equalpower';p.distanceModel='inverse';p.refDistance=4;p.maxDistance=600;p.rolloffFactor=1.2;p.coneInnerAngle=360;return p;}
const falloff=distance=>4/(4+1.2*(Math.max(4,distance)-4));

export class TrainAudio {
 constructor(){this.context=null;this.running=false;this.bogies=[];this.pending=new Set();this.settings=null;this.muted=false;this.mediaUnlock=null;this.levelData=new Float32Array(512);this.testingUntil=0;this.ready=false;this.bankPromise=null;}
 unlockMedia(){
  if(requestPlaybackSession())return;
  const isiOS=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
  if(!isiOS)return;
  if(!this.mediaUnlock){this.mediaUnlock=new window.Audio('/audio-unlock.wav');this.mediaUnlock.loop=true;this.mediaUnlock.setAttribute('playsinline','');this.mediaUnlock.preload='auto';}
  this.mediaUnlock.play()?.catch(()=>{});
 }
 async init(){
  // All activation calls precede the first await, preserving the iPhone tap gesture.
  this.unlockMedia();
  const Audio=window.AudioContext||window.webkitAudioContext;
  if(!Audio)throw new Error('This browser does not support Web Audio. Try a recent Chrome, Edge, Firefox or Safari browser.');
  if(!this.context){
   this.context=new Audio({latencyHint:'interactive'});const c=this.context;
   const unlock=c.createBufferSource();unlock.buffer=c.createBuffer(1,1,c.sampleRate);unlock.connect(c.destination);unlock.start();unlock.onended=()=>unlock.disconnect();
   this.master=c.createGain();this.master.gain.value=.65;
   this.compressor=c.createDynamicsCompressor();this.compressor.threshold.value=-4;this.compressor.knee.value=3;this.compressor.ratio.value=4;this.compressor.attack.value=.002;this.compressor.release.value=.15;
   this.analyser=c.createAnalyser();this.analyser.fftSize=512;this.master.connect(this.compressor).connect(this.analyser).connect(c.destination);
   this.strikeBus=c.createGain();this.bodyFilter=c.createBiquadFilter();this.bodyFilter.type='lowshelf';this.bodyFilter.frequency.value=280;
   this.brightnessFilter=c.createBiquadFilter();this.brightnessFilter.type='highshelf';this.brightnessFilter.frequency.value=1300;
   this.fixedJoint=panner(c);this.fixedJoint.positionX.value=0;this.fixedJoint.positionY.value=.3;this.fixedJoint.positionZ.value=0;
   this.strikeBus.connect(this.bodyFilter).connect(this.brightnessFilter).connect(this.fixedJoint).connect(this.master);
  }
  const resumePromise=resumedWithin(this.context.resume());
  if(!this.bankPromise){
   const decode=async name=>{const response=await fetch(`/synthesis/${name}.wav`);if(!response.ok)throw new Error('The fitted sound files could not load. Refresh the page and try again.');return this.context.decodeAudioData(await response.arrayBuffer());};
   this.bankPromise=Promise.all([...Array.from({length:8},(_,i)=>decode(`impact-${i}`)),decode('rolling-bed')]).then(buffers=>{this.banks=buffers.slice(0,8);this.noise=buffers[8];this.ready=true;}).catch(error=>{this.bankPromise=null;throw error;});
  }
  await Promise.all([resumePromise,this.bankPromise]);
 }
 configure(consist,settings){
  this.settings=settings;if(!this.ready)return;
  const c=this.context;this.cancelImpacts();
  for(const voice of this.bogies){voice.source.stop();voice.source.disconnect();voice.gain.disconnect();voice.panner.disconnect();}this.bogies=[];
  for(let i=0;i<consist.bogies.length;i++){
   const bogie=consist.bogies[i],source=c.createBufferSource(),gain=c.createGain(),pan=panner(c);
   source.buffer=this.noise;source.loop=true;gain.gain.value=0;source.connect(gain).connect(pan).connect(this.master);
   source.start(0,(i*.731)%this.noise.duration);this.bogies.push({bogie,source,gain,panner:pan});
  }
  this.setLevels(settings);
 }
 setLevels(settings){
  this.settings=settings;if(!this.context)return;const now=this.context.currentTime;
  this.master.gain.setTargetAtTime(this.muted?0:settings.volume,now,.025);
  this.strikeBus.gain.setTargetAtTime(settings.jointStrength/.7,now,.025);
  this.bodyFilter.gain.setTargetAtTime(((settings.body??.5)-.5)*18,now,.025);
  this.brightnessFilter.gain.setTargetAtTime((settings.ring-.5)*18,now,.025);
 }
 async resume(){if(!this.context)return;if(this.context.state!=='running')await resumedWithin(this.context.resume());if(this.context.state!=='running')throw new Error('Audio is interrupted. Tap Start passing again.');this.running=true;this.setLevels(this.settings);}
 async pause(){this.running=false;this.cancelImpacts();this.mediaUnlock?.pause();if(this.context)for(const v of this.bogies)v.gain.gain.setTargetAtTime(0,this.context.currentTime,.012);}
 async testTone(){
  await this.init();const c=this.context,osc=c.createOscillator(),gain=c.createGain();osc.frequency.value=660;gain.gain.setValueAtTime(0,c.currentTime);gain.gain.linearRampToValueAtTime(.15,c.currentTime+.03);gain.gain.setValueAtTime(.15,c.currentTime+.55);gain.gain.linearRampToValueAtTime(0,c.currentTime+.75);osc.connect(gain).connect(this.analyser);osc.start();osc.stop(c.currentTime+.8);this.testingUntil=performance.now()+1100;osc.onended=()=>{osc.disconnect();gain.disconnect();if(!this.running)this.mediaUnlock?.pause();};
 }
 outputLevel(){if(!this.analyser)return 0;this.analyser.getFloatTimeDomainData(this.levelData);let sum=0;for(const sample of this.levelData)sum+=sample*sample;return Math.sqrt(sum/this.levelData.length);}
 cancelImpacts(){for(const source of this.pending){try{source.stop();}catch{}source.disconnect();}this.pending.clear();}
 impact(event,when){
  if(!this.running||!this.ready)return;const c=this.context,variant=(event.axle.vehicle*3+event.axle.bogie*2+event.axle.index)%8;
  const source=c.createBufferSource(),gain=c.createGain();source.buffer=this.banks[variant];source.playbackRate.value=1;
  // Preserve measured timbre at all speeds; speed changes the event schedule only.
  gain.gain.value=event.axle.load;source.connect(gain).connect(this.strikeBus);
  // The fitted kernel includes 21.3 ms of pre-contact attack. The audible contact
  // and axle highlight keep their original timing; no interval is changed.
  source.start(Math.max(c.currentTime,when-.0213333));this.pending.add(source);
  source.onended=()=>{this.pending.delete(source);source.disconnect();gain.disconnect();};
 }
 update(time,settings,camera){
  if(!this.context||!this.running)return;
  const c=this.context,now=c.currentTime,listener=c.listener,pos=camera?.position||{x:3.8,y:2.73,z:settings.distance};
  let forward={x:-.97,y:-.015,z:-.23};if(camera){const m=camera.matrixWorld.elements;forward={x:-m[8],y:-m[9],z:-m[10]};}
  if(listener.positionX){for(const [key,val] of [['positionX',pos.x],['positionY',pos.y],['positionZ',pos.z],['forwardX',forward.x],['forwardY',forward.y],['forwardZ',forward.z],['upX',0],['upY',1],['upZ',0]])listener[key].setTargetAtTime(val,now,.035);}else{listener.setPosition(pos.x,pos.y,pos.z);listener.setOrientation(forward.x,forward.y,forward.z,0,1,0);}
  const head=trainPosition(time,settings),v=settings.speed/3.6;
  const distances=this.bogies.map(voice=>Math.hypot(head-settings.direction*voice.bogie.offset-pos.x,pos.z,pos.y-.7));
  const weights=distances.map(falloff),normalizer=Math.max(...weights,0)/Math.max(.001,Math.hypot(...weights));
  for(let i=0;i<this.bogies.length;i++){
   const voice=this.bogies[i],x=head-settings.direction*voice.bogie.offset,radial=settings.direction*v*(x-pos.x)/distances[i];
   voice.panner.positionX.setTargetAtTime(x,now,.04);voice.panner.positionY.value=.7;
   // Very modest rolling Doppler; impact sample pitch is never altered.
   voice.source.playbackRate.setTargetAtTime(343/(343+radial*.3),now,.04);
   voice.gain.gain.setTargetAtTime(settings.rumble/.55*normalizer,now,.035);
  }
 }
 arrivalTime(event,settings){return event.time+propagationDelay(event.joint.x-3.8,settings.distance);}
 setMuted(value){this.muted=value;if(this.settings)this.setLevels(this.settings);}
}
