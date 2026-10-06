// Independent expected results evaluated by the supplied, unmodified JavaScript.
import {readFileSync,writeFileSync} from 'node:fs';
import {DEFAULTS,createConsist,listenerPosition,passengerAxlePair,eventArrivalTime} from './public/model.js';
import {passengerAxleGain,cabAxleGain,rollingSpeedMix} from './public/audio.js';
import {squealDemand,bogieSquealState} from './public/squeal.js';
import {routeCurvature,CROSSOVER} from './public/turnouts.js';
import {axlePose} from './public/model.js';
const game=process.argv[2]||'D:/ClaudeWS/train-game';
const consist=createConsist(),envelopes=[];
for(let i=0;i<8;i++){const b=readFileSync(`${game}/assets/sounds/body_v2/impact-${i}.wav`),n=b.readUInt32LE(40)/2;envelopes.push(Array.from({length:32},(_,i)=>{const start=Math.floor(i*n/32),end=Math.floor((i+1)*n/32);let energy=0;for(let s=start;s<end;s++)energy+=(b.readInt16LE(44+s*2)/32768)**2;return {time:(start+end)/2/48000-.0213333,energy:energy/n};}));}
const cases=[];
for(const speed of [10,30,71.6,130])for(const direction of [-1,1])for(const position of ['pilot','passenger'])for(const coach of [1,10,20])for(const end of ['front','rear']){
 if(position==='pilot'&&(coach!==1||end!=='front'))continue;
 const settings={...DEFAULTS,speed,direction,position,passengerCoach:coach,passengerEnd:end,track:'reference'};
 const pair=passengerAxlePair(consist,settings),axle=pair?.trailing??consist.axles[5],leading=pair?.leading??consist.axles[0],time=(110+axle.offset)/(speed/3.6);
 const event={time,axle,joint:{id:0,x:0,z:0,strength:1}},p=listenerPosition(time,settings);
 cases.push({speed,direction,position,coach,end,axle:consist.axles.indexOf(axle),leading:consist.axles.indexOf(leading),receiver:[p.x,p.y,p.z],arrival:eventArrivalTime(event,settings)-time,gain:position==='pilot'?cabAxleGain(event,settings,leading,envelopes):passengerAxleGain(event,settings,pair,envelopes)});
}
const squeal=[];for(const v of [0,.2,1,8,20,40])for(const k of [0,-1/441.36,1/200,1/50])for(const wb of [2.56,3.7])squeal.push({v,k,wb,expected:squealDemand(v,k,wb)});
const states=[];
const bogie=consist.bogies[2],wheelAxles=consist.axles.filter(a=>a.vehicle===1&&a.bogie===0);
for(const direction of [-1,1])for(const speed of [10,30,130])for(const s of [CROSSOVER.startS-.3,CROSSOVER.startS+5,CROSSOVER.startS+CROSSOVER.arc,CROSSOVER.endS-CROSSOVER.arc/2]){
 const settings={...DEFAULTS,points:'diverge',direction,speed},time=(110+bogie.offset+direction*s)/(speed/3.6),expected=bogieSquealState(time,bogie,settings);
 const poses=wheelAxles.map(a=>axlePose(time,a,settings)),curves=wheelAxles.map(a=>routeCurvature(direction*(-110+time*speed/3.6-a.offset),settings));
 states.push({time,speed,poses,curves,expected});
}
writeFileSync(`${game}/tests/fixtures/platform_enhanced.json`,JSON.stringify({cases,squeal,states,rolling:[0,10,30,71.6,120].map(speed=>({speed,...rollingSpeedMix(speed)}))},null,2)+'\n');
console.log(`Independent website fixture: ${cases.length} onboard cases, ${squeal.length} squeal demand cases.`);
