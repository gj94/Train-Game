import {PROFILES,trainPosition,speedMS,axlePose,listenerPosition,isOnboard,spatialFalloff,SPEED_OF_SOUND,seededRandom} from './model.js';
import {routeCurvature,TURNOUT} from './turnouts.js';
import {SQUEAL_PROFILE} from './squeal-profile.js';

export const SQUEAL={bankCount:4,loopSeconds:4,maxVoices:12,sourceHeight:.35,attack:.075,release:.055};
const TAU=2*Math.PI;
const clamp=x=>Math.max(0,Math.min(1,x));
const smooth=(a,b,x)=>{const u=clamp((x-a)/(b-a));return u*u*(3-2*u);};

// A controllable perceptual approximation, not a contact-mechanics solver.
// A game can supply its actual creepage/friction state instead of this proxy.
export function squealDemand(speed,curvature,wheelbase,friction=1){
 const v=Math.abs(speed),creep=Math.abs(curvature)*wheelbase/2;
 return smooth(.0004,.006,creep)*smooth(.35,2.5,v)*(.55+.45*(1-Math.exp(-v/5)))*clamp(friction);
}
// The video identifies sound frequencies, not a surveyed curve radius. Use the
// existing 441.36 m LHB curve as a neutral mix anchor; milder curves lose some
// upper-mode energy and tight curves gain at most 3 dB. Never transpose pitch.
export function squealCurveColor(curvature,wheelbase){
 const relative=Math.abs(curvature)*wheelbase/(2.56/441.36);
 return Math.max(-9,Math.min(3,6*Math.log2(Math.max(.001,relative))));
}
export function bogieSquealState(time,bogie,settings){
 const wb=bogie.vehicle===0?3.7:PROFILES[settings.profile].wheelbase;
 const n=bogie.vehicle===0?3:2,head=trainPosition(time,settings),phase=((bogie.vehicle*37+bogie.index*17)%97)/97*TAU;
 let weightedCurvature=0,dominant=null;
 for(let i=0;i<n;i++){
  const offset=bogie.offset-wb/2+i*wb/(n-1),s=head-settings.direction*offset,k=routeCurvature(s,settings),weight=i===0?.7:.3/(n-1);
  weightedCurvature+=k*weight;
  if(!dominant||Math.abs(k)*weight>dominant.score)dominant={offset,k,index:i,score:Math.abs(k)*weight};
 }
 const p=axlePose(time,dominant,settings),side=Math.sign(dominant.k),distance=side*TURNOUT.gauge/2;
 // The benchmark's 120 ms envelope varies by about 13.5% RMS. Keep a sustained
 // friction texture instead of the earlier deep periodic wah-wah modulation.
 const instability=.7+.3*smooth(-.45,.6,.65*Math.sin(time*TAU*.73+phase)+.35*Math.sin(time*TAU*1.19-phase*.7));
 const level=squealDemand(speedMS(settings),weightedCurvature,wb)*instability;
 return {bogie,axleId:`${bogie.id}-A${dominant.index+1}`,side,curvature:weightedCurvature,level,edgeDb:squealCurveColor(weightedCurvature,wb),
  x:p.x-p.tz*distance,y:SQUEAL.sourceHeight,z:p.z+p.tx*distance,tx:p.tx,tz:p.tz,emission:time};
}
export function heardSquealState(time,bogie,settings,receiver=listenerPosition(time,settings)){
 let emission=time,state;
 // Retarded position of a moving continuous source at this receiver time.
 for(let i=0;i<8;i++){state=bogieSquealState(emission,bogie,settings);emission=time-Math.hypot(state.x-receiver.x,state.y-receiver.y,state.z-receiver.z)/SPEED_OF_SOUND;}
 state=bogieSquealState(emission,bogie,settings);
 const distance=Math.hypot(state.x-receiver.x,state.y-receiver.y,state.z-receiver.z);
 return {...state,distance,received:state.level*spatialFalloff(distance)};
}

// Inverse radix-2 FFT, real output. The conjugate-symmetric spectrum contains
// measured power statistics and newly seeded phases, never video audio/phase.
function inverseSpectrum(re,im){
 const n=re.length;
 for(let i=1,j=0;i<n;i++){let bit=n>>1;for(;j&bit;bit>>=1)j^=bit;j^=bit;if(i<j){[re[i],re[j]]=[re[j],re[i]];[im[i],im[j]]=[im[j],im[i]];}}
 for(let width=2;width<=n;width*=2){
  const angle=TAU/width,wr=Math.cos(angle),wi=Math.sin(angle),half=width/2;
  for(let base=0;base<n;base+=width){let cr=1,ci=0;
   for(let j=0;j<half;j++){
    const a=base+j,b=a+half,tr=cr*re[b]-ci*im[b],ti=cr*im[b]+ci*re[b];
    re[b]=re[a]-tr;im[b]=im[a]-ti;re[a]+=tr;im[a]+=ti;
    const next=cr*wr-ci*wi;ci=cr*wi+ci*wr;cr=next;
   }
  }
 }
 for(let i=0;i<n;i++)re[i]/=n;
}
// A periodic random-phase spectrum preserves the broad, rough wheel-mode bands
// measured in SquealingTrain. Minimum 4 s, rounded to a power-of-two sample count.
// Variants change phases only: no arbitrary ±9% detuning of benchmark frequencies.
export function synthesizeSqueal(variant,sampleRate=48000){
 const n=2**Math.ceil(Math.log2(SQUEAL.loopSeconds*sampleRate)),re=new Float64Array(n),im=new Float64Array(n),random=seededRandom(8209+variant*104729),profile=SQUEAL_PROFILE;
 for(let k=1;k<n/2;k++){
  const x=k*sampleRate/n/profile.stepHz,i=Math.floor(x),u=x-i;
  const power=(profile.density[i]||0)*(1-u)+(profile.density[i+1]||0)*u;
  const amplitude=Math.sqrt(power*sampleRate*n/2)*profile.rms,phase=random()*TAU;
  re[k]=re[n-k]=amplitude*Math.cos(phase);im[k]=amplitude*Math.sin(phase);im[n-k]=-im[k];
 }
 inverseSpectrum(re,im);return Float32Array.from(re);
}

export class CurveSquealAudio {
 constructor(context,output){this.context=context;this.output=output;this.voices=new Map();this.tails=new Set();this.banks=[];this.active=[];this.bogies=[];}
 configure(consist,settings){this.pause();this.bogies=consist.bogies;if(settings?.points==='diverge')for(let i=0;i<SQUEAL.bankCount;i++)this.bank(i);}
 bank(variant){
  if(!this.banks[variant]){const data=synthesizeSqueal(variant,this.context.sampleRate||48000),b=this.context.createBuffer(1,data.length,this.context.sampleRate||48000);b.getChannelData(0).set(data);this.banks[variant]=b;}
  return this.banks[variant];
 }
 create(state){
  const c=this.context,source=c.createBufferSource(),gain=c.createGain(),texture=c.createBiquadFilter(),air=c.createBiquadFilter(),pan=c.createPanner();
  const variant=(state.bogie.vehicle*3+state.bogie.index)%SQUEAL.bankCount;
  source.buffer=this.bank(variant);source.loop=true;gain.gain.value=0;air.type='lowpass';air.Q.value=.5;texture.type='highshelf';texture.frequency.value=4800;texture.gain.value=state.edgeDb;
  pan.panningModel='equalpower';pan.distanceModel='inverse';pan.refDistance=4;pan.rolloffFactor=1.2;pan.maxDistance=1600;
  pan.positionX.value=state.x;pan.positionY.value=state.y;pan.positionZ.value=state.z;
  source.connect(gain).connect(texture).connect(air).connect(pan).connect(this.output);
  const voice={source,gain,texture,air,pan,id:state.bogie.id};
  source.onended=()=>{this.disconnect(voice);if(this.voices.get(voice.id)===voice)this.voices.delete(voice.id);this.tails.delete(voice);};
  const duration=source.buffer.duration;
  source.start(c.currentTime,((state.emission+variant*.731)%duration+duration)%duration);
  this.voices.set(voice.id,voice);return voice;
 }
 disconnect(voice){for(const node of [voice.source,voice.gain,voice.texture,voice.air,voice.pan])node.disconnect();}
 release(voice){this.voices.delete(voice.id);this.tails.add(voice);voice.gain.gain.setTargetAtTime(0,this.context.currentTime,SQUEAL.release);voice.source.stop(this.context.currentTime+.3);}
 pause(){for(const voice of [...this.voices.values(),...this.tails]){try{voice.source.stop();}catch{}this.disconnect(voice);}this.voices.clear();this.tails.clear();this.active=[];}
 update(time,settings,receiver=listenerPosition(time,settings)){
  const amount=clamp(settings.squeal??.6);
  if(settings.points!=='diverge'||amount<=0||speedMS(settings)<=0){for(const voice of this.voices.values())this.release(voice);this.active=[];return;}
  const states=this.bogies.map(b=>heardSquealState(time,b,settings,receiver)).filter(s=>s.received>.0015).sort((a,b)=>b.received-a.received);
  const chosen=states.slice(0,SQUEAL.maxVoices),ids=new Set(chosen.map(s=>s.bogie.id));
  for(const [id,voice] of this.voices)if(!ids.has(id))this.release(voice);
  const normalizer=1/Math.max(1,Math.hypot(...states.map(s=>s.received))),now=this.context.currentTime;
  this.active=chosen;
  for(const state of chosen){
   const voice=this.voices.get(state.bogie.id)||this.create(state),cab=settings.position==='pilot';
   const radial=isOnboard(settings)?0:settings.direction*speedMS(settings)*((state.x-receiver.x)*state.tx+(state.z-receiver.z)*state.tz)/Math.max(.1,state.distance);
   voice.source.playbackRate.setTargetAtTime(SPEED_OF_SOUND/(SPEED_OF_SOUND+radial),now,.06);
   voice.gain.gain.setTargetAtTime(amount*state.level*normalizer*(cab?.85:1),now,SQUEAL.attack);
   voice.texture.gain.setTargetAtTime(state.edgeDb,now,.08);
   voice.air.frequency.setTargetAtTime((cab?3200:12000)/(1+Math.max(0,state.distance-4)/30),now,.06);
   for(const [key,value] of [['positionX',state.x],['positionY',state.y],['positionZ',state.z]])voice.pan[key].setTargetAtTime(value,now,.012);
  }
 }
}
