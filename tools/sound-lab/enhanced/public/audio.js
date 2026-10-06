import {PROFILES,makeJoints,eventArrivalTime,spatialFalloff,isOnboard,listenerPosition,passengerAxlePair,axlePose,observerLocal} from './model.js';
import {CurveSquealAudio} from './squeal.js';

// v2 uses stochastic, spectrum-fitted excitations. These WAV assets were generated
// from energy statistics and new random phases; no source waveform is replayed.
export function requestPlaybackSession(nav=globalThis.navigator){
 try{if(nav?.audioSession){nav.audioSession.type='playback';return true;}}catch{}
 return false;
}
async function resumedWithin(promise){let timer;try{return await Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('Audio is waiting for permission. Tap Start passing again, or use Test sound.')),3500);})]);}finally{clearTimeout(timer);}}
function panner(context){const p=context.createPanner();p.panningModel='equalpower';p.distanceModel='inverse';p.refDistance=4;p.maxDistance=600;p.rolloffFactor=1.2;p.coneInnerAngle=360;return p;}
const falloff=spatialFalloff;
const impactVariant=event=>(event.axle.vehicle*3+event.axle.bogie*2+event.axle.index+Math.abs(event.joint.id)*3)%8;
// The fitted rolling bed also carries the broad rushing/wind-like sound.
// Keep the accepted reference-speed mix at unity, with less hiss when crawling.
export function rollingSpeedMix(speed){
 const ratio=Math.max(0,speed)/PROFILES.lhb.speed;
 return {gain:Math.min(1.4,ratio**1.25),hissDb:Math.max(-24,Math.min(0,15*Math.log10(Math.max(.001,ratio))))};
}
// Compare the body of each strike, including receiver motion during its decay.
// Bins hold the unchanged bank's measured energy; no waveform is rewritten.
function energyEnvelope(buffer){
 const data=buffer.getChannelData(0),bins=32;
 return Array.from({length:bins},(_,i)=>{const start=Math.floor(i*data.length/bins),end=Math.floor((i+1)*data.length/bins);let energy=0;for(let n=start;n<end;n++)energy+=data[n]*data[n];return {time:(start+end)/2/buffer.sampleRate-.0213333,energy:energy/data.length};});
}
function receivedAxleBody(event,axle,settings,envelopes){
  const time=event.time+(axle.offset-event.axle.offset)/(settings.speed/3.6),strike={...event,axle,time};
  const arrival=eventArrivalTime(strike,settings),envelope=envelopes[impactVariant(strike)]||[{time:0,energy:1}];
  let energy=0;for(const bin of envelope){const p=listenerPosition(arrival+bin.time,settings),distance=Math.hypot(p.x-event.joint.x,p.y-.3,p.z-(event.joint.z||0));energy+=bin.energy*falloff(distance)**2;}
  return axle.load*Math.sqrt(energy);
}
export function passengerAxleGain(event,settings,pair,envelopes=[]){
 if(settings.position!=='passenger'||!pair||event.axle.id!==pair.trailing.id)return 1;
 const preceding=receivedAxleBody(event,pair.trailing,settings,envelopes),leading=receivedAxleBody(event,pair.leading,settings,envelopes);
 // Up to +2 dB, with a small margin below the nearby leading axle's body level.
 return preceding>0?Math.min(10**(2/20),.95*leading/preceding):1;
}
export function cabAxleGain(event,settings,leadingAxle,envelopes=[]){
 if(settings.position!=='pilot'||event.axle.vehicle!==0||!leadingAxle||event.axle.id===leadingAxle.id)return 1;
 const own=receivedAxleBody(event,event.axle,settings,envelopes),front=receivedAxleBody(event,leadingAxle,settings,envelopes);
 // Compress the distance-driven level difference inside the locomotive. This
 // cab mix approximation keeps the rear audible without making it equal to the
 // axle under the cab. It leaves the waveform, contact time and source intact.
 return own>0?Math.max(1,Math.min(10**(8/20),(front/own)**.6)):1;
}

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
   this.jointBuses=new Map([[0,{joint:{id:0,x:0,strength:1},input:this.strikeBus,body:this.bodyFilter,brightness:this.brightnessFilter,pan:this.fixedJoint}]]);
  }
  const resumePromise=resumedWithin(this.context.resume());
  if(!this.bankPromise){
   const decode=async name=>{const response=await fetch(`/synthesis/${name}.wav`);if(!response.ok)throw new Error('The fitted sound files could not load. Refresh the page and try again.');return this.context.decodeAudioData(await response.arrayBuffer());};
   this.bankPromise=Promise.all([...Array.from({length:8},(_,i)=>decode(`impact-${i}`)),decode('rolling-bed')]).then(buffers=>{this.banks=buffers.slice(0,8);this.impactEnvelopes=this.banks.map(energyEnvelope);this.noise=buffers[8];this.ready=true;}).catch(error=>{this.bankPromise=null;throw error;});
  }
  await Promise.all([resumePromise,this.bankPromise]);
 }
 configure(consist,settings){
  this.settings=settings;this.passengerPair=passengerAxlePair(consist,settings);this.cabLeadingAxle=consist.axles.find(a=>a.vehicle===0&&a.bogie===0&&a.index===0);if(!this.ready)return;
  const c=this.context;this.cancelImpacts();
  this.curves??=new CurveSquealAudio(c,this.master);this.curves.configure(consist,settings);
  for(const [id,route] of this.jointBuses){if(id===0)continue;for(const node of [route.input,route.body,route.brightness,route.air,route.pan])node.disconnect();this.jointBuses.delete(id);}
  // J0 has the original, unfiltered route on the platform. On board it needs
  // the same moving-distance treatment as every other joint.
  const central=this.jointBuses.get(0);central.brightness.disconnect();central.air?.disconnect();delete central.air;
  central.pan.maxDistance=isOnboard(settings)?1600:600;
  if(isOnboard(settings)){central.air=c.createBiquadFilter();central.air.type='lowpass';central.air.Q.value=.5;central.brightness.connect(central.air).connect(central.pan);}
  else central.brightness.connect(central.pan);
  for(const joint of makeJoints(settings)){
   if(joint.id===0)continue;
   const input=c.createGain(),body=c.createBiquadFilter(),brightness=c.createBiquadFilter(),air=c.createBiquadFilter(),pan=panner(c);
   body.type='lowshelf';body.frequency.value=280;brightness.type='highshelf';brightness.frequency.value=1300;air.type='lowpass';air.Q.value=.5;
   pan.maxDistance=1600;pan.positionX.value=joint.x;pan.positionY.value=.3;pan.positionZ.value=joint.z||0;
   input.connect(body).connect(brightness).connect(air).connect(pan).connect(this.master);
   this.jointBuses.set(joint.id,{joint,input,body,brightness,air,pan});
  }
  for(const voice of this.bogies){voice.source.stop();voice.source.disconnect();voice.hiss.disconnect();voice.gain.disconnect();voice.panner.disconnect();}this.bogies=[];
  for(let i=0;i<consist.bogies.length;i++){
   const bogie=consist.bogies[i],source=c.createBufferSource(),gain=c.createGain(),pan=panner(c),hiss=c.createBiquadFilter();
   hiss.type='highshelf';hiss.frequency.value=900;hiss.gain.value=rollingSpeedMix(settings.speed).hissDb;
   source.buffer=this.noise;source.loop=true;gain.gain.value=0;source.connect(hiss).connect(gain).connect(pan).connect(this.master);
   source.start(0,(i*.731)%this.noise.duration);this.bogies.push({bogie,source,gain,panner:pan,hiss});
  }
  this.setLevels(settings);
 }
 setLevels(settings){
  this.settings=settings;if(!this.context)return;const now=this.context.currentTime;
  this.master.gain.setTargetAtTime(this.muted?0:settings.volume,now,.025);
  for(const route of this.jointBuses.values()){
   const doorwayBoost=settings.position==='passenger'?Math.SQRT2:1;
   route.input.gain.setTargetAtTime(settings.jointStrength/.7*route.joint.strength*doorwayBoost,now,.025);
   route.body.gain.setTargetAtTime(((settings.body??.5)-.5)*18,now,.025);
   route.brightness.gain.setTargetAtTime((settings.ring-.5)*18,now,.025);
  }
  this.updateJointFilters(this.lastSimTime||0,settings);
 }
 updateJointFilters(time,settings){
  if(!this.context)return;const onboard=isOnboard(settings),pos=listenerPosition(time,settings),now=this.context.currentTime;
  const near=onboard?Math.hypot(observerLocal(settings).z,pos.y-.3):Math.hypot(3.8,settings.distance);
  for(const route of this.jointBuses.values())if(route.air){
   const distance=onboard?Math.hypot(route.joint.x-pos.x,pos.z-(route.joint.z||0),pos.y-.3):Math.hypot(route.joint.x-3.8,settings.distance-(route.joint.z||0));
   const ceiling=settings.position==='pilot'?6500:18000;
   route.air.frequency.setTargetAtTime(ceiling/(1+Math.max(0,distance-near)/22),now,.05);
  }
  this.lastFilterUpdate=now;
 }
 async resume(){if(!this.context)return;if(this.context.state!=='running')await resumedWithin(this.context.resume());if(this.context.state!=='running')throw new Error('Audio is interrupted. Tap Start passing again.');this.running=true;this.setLevels(this.settings);}
 async pause(){this.running=false;this.cancelImpacts();this.curves?.pause();this.mediaUnlock?.pause();if(this.context)for(const v of this.bogies)v.gain.gain.setTargetAtTime(0,this.context.currentTime,.012);}
 async testTone(){
  await this.init();const c=this.context,osc=c.createOscillator(),gain=c.createGain();osc.frequency.value=660;gain.gain.setValueAtTime(0,c.currentTime);gain.gain.linearRampToValueAtTime(.15,c.currentTime+.03);gain.gain.setValueAtTime(.15,c.currentTime+.55);gain.gain.linearRampToValueAtTime(0,c.currentTime+.75);osc.connect(gain).connect(this.analyser);osc.start();osc.stop(c.currentTime+.8);this.testingUntil=performance.now()+1100;osc.onended=()=>{osc.disconnect();gain.disconnect();if(!this.running)this.mediaUnlock?.pause();};
 }
 outputLevel(){if(!this.analyser)return 0;this.analyser.getFloatTimeDomainData(this.levelData);let sum=0;for(const sample of this.levelData)sum+=sample*sample;return Math.sqrt(sum/this.levelData.length);}
 cancelImpacts(){for(const source of this.pending){try{source.stop();}catch{}source.disconnect();}this.pending.clear();}
 impact(event,when){
  if(!this.running||!this.ready)return;const route=this.jointBuses.get(event.joint.id);if(!route)return;const c=this.context,variant=impactVariant(event);
  const source=c.createBufferSource(),gain=c.createGain();source.buffer=this.banks[variant];source.playbackRate.value=1;
  // Preserve measured timbre at all speeds; speed changes the event schedule only.
  gain.gain.value=event.axle.load*passengerAxleGain(event,this.settings,this.passengerPair,this.impactEnvelopes)*cabAxleGain(event,this.settings,this.cabLeadingAxle,this.impactEnvelopes);source.connect(gain).connect(route.input);
  // The fitted kernel includes 21.3 ms of pre-contact attack. The audible contact
  // and axle highlight keep their original timing; no interval is changed.
  source.start(Math.max(c.currentTime,when-.0213333));this.pending.add(source);
  source.onended=()=>{this.pending.delete(source);source.disconnect();gain.disconnect();};
 }
 update(time,settings,camera){
  if(!this.context||!this.running)return;
  const c=this.context,now=c.currentTime,listener=c.listener,pos=camera?.position||listenerPosition(time,settings),onboard=isOnboard(settings);
  this.lastSimTime=time;if(onboard&&now-(this.lastFilterUpdate??-1)>.08)this.updateJointFilters(time,settings);
  let forward={x:-.97,y:-.015,z:-.23};if(camera){const m=camera.matrixWorld.elements;forward={x:-m[8],y:-m[9],z:-m[10]};}
  if(listener.positionX){for(const [key,val] of [['positionX',pos.x],['positionY',pos.y],['positionZ',pos.z],['forwardX',forward.x],['forwardY',forward.y],['forwardZ',forward.z],['upX',0],['upY',1],['upZ',0]])listener[key].setTargetAtTime(val,now,onboard?.008:.035);}else{listener.setPosition(pos.x,pos.y,pos.z);listener.setOrientation(forward.x,forward.y,forward.z,0,1,0);}
  const v=settings.speed/3.6,speedMix=rollingSpeedMix(settings.speed);
  const positions=this.bogies.map(voice=>axlePose(time,voice.bogie,settings));
  const distances=positions.map(p=>Math.hypot(p.x-pos.x,p.z-pos.z,pos.y-.7));
  const weights=distances.map(falloff),normalizer=Math.max(...weights,0)/Math.max(.001,Math.hypot(...weights));
  for(let i=0;i<this.bogies.length;i++){
   const voice=this.bogies[i],p=positions[i],x=p.x,radial=onboard?0:settings.direction*v*((x-pos.x)*p.tx+(p.z-pos.z)*p.tz)/distances[i];
   voice.panner.positionX.setTargetAtTime(x,now,onboard?.008:.04);voice.panner.positionY.value=.7;voice.panner.positionZ.setTargetAtTime(p.z,now,onboard?.008:.04);
   // Very modest rolling Doppler; impact sample pitch is never altered.
   voice.source.playbackRate.setTargetAtTime(343/(343+radial*.3),now,.04);
   voice.hiss.gain.setTargetAtTime(speedMix.hissDb,now,.08);
   voice.gain.gain.setTargetAtTime(settings.rumble/.55*normalizer*speedMix.gain,now,.035);
  }
  this.curves?.update(time,settings,pos);
 }
 arrivalTime(event,settings){return eventArrivalTime(event,settings);}
 setMuted(value){this.muted=value;if(this.settings)this.setLevels(this.settings);}
}
