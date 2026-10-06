import {hasPoints,routePose,routeStation,turnoutContacts,inPointAssembly} from './turnouts.js';
export const PROFILES = {
  lhb: { name:'LHB express', length:24, bodyLength:23.54, bogieCentres:14.9, wheelbase:2.56, radius:.4575, color:0xad2724, speed:71.6, referenceStart:15, referenceEnd:35 },
  icf: { name:'ICF passenger', length:22.297, bodyLength:21.336, bogieCentres:14.783, wheelbase:2.896, radius:.4575, color:0xd9bc77, speed:65.4, referenceStart:64, referenceEnd:80 }
};
export const TRACKS = {
  swr: {name:'Short welded rail',spacing:39},
  jointed: {name:'Jointed rail',spacing:13},
  reference: {name:'Approved single-joint reference',spacing:null}
};
export const TRACK_HALF_LENGTH = 800;
export const DEFAULTS = { profile:'lhb', speed:71.6, coaches:20, distance:5.8, track:'swr', points:'none', position:'platform', passengerCoach:1, passengerEnd:'front', passengerSide:1, jointStrength:.7, body:.5, ring:.5, rumble:.55, squeal:.6, volume:.65, direction:1, loop:true, showAxles:true };
export const APPROACH = 110;
export const SPEED_OF_SOUND = 343;
export function createConsist(profileId='lhb', coachCount=20) {
  const p=PROFILES[profileId];
  if(!p) throw new Error('Unknown coach profile');
  if(!Number.isInteger(coachCount)||coachCount<1||coachCount>30) throw new Error('Coach count must be 1–30');
  const vehicles=[], axles=[], bogies=[];
  // WAP-7-inspired Co-Co locomotive. Three axles in each bogie.
  const loco={id:'locomotive',index:0,kind:'locomotive',length:20.56,bodyLength:20.2,centre:10.28};
  vehicles.push(loco);
  for(let b=0;b<2;b++) {
    const centre=loco.centre+(b===0?-5.5:5.5);
    const bogie={id:`L-B${b+1}`,vehicle:0,index:b,offset:centre};bogies.push(bogie);
    for(let a=0;a<3;a++) axles.push({id:`L-B${b+1}-A${a+1}`,vehicle:0,bogie:b,index:a,offset:centre+(a-1)*1.85,radius:.546,load:1.22});
  }
  for(let c=0;c<coachCount;c++) {
    const centre=loco.length+c*p.length+p.length/2;
    vehicles.push({id:`C${String(c+1).padStart(2,'0')}`,index:c+1,kind:'coach',length:p.length,bodyLength:p.bodyLength,centre});
    for(let b=0;b<2;b++) {
      const offset=centre+(b===0?-1:1)*p.bogieCentres/2;
      bogies.push({id:`C${c+1}-B${b+1}`,vehicle:c+1,index:b,offset});
      for(let a=0;a<2;a++) axles.push({id:`C${c+1}-B${b+1}-A${a+1}`,vehicle:c+1,bogie:b,index:a,offset:offset+(a===0?-1:1)*p.wheelbase/2,radius:p.radius,load:.9+((c*7+b*3+a)%9)*.025});
    }
  }
  return {profile:p,vehicles,axles,bogies,length:loco.length+coachCount*p.length};
}
// Model each open mechanical joint along the full rendered 1.6 km track.
// Smooth internal welds in a 39 m (3 × 13 m) SWR panel are not open gaps.
// CAMTECH Track Maintainer handbook, September 2024, Part VI, printed p. 1.
export function makeJoints(settings=DEFAULTS) {
  const track=TRACKS[settings.track??DEFAULTS.track];
  if(!track)throw new Error('Unknown track arrangement');
  const count=track.spacing===null?0:Math.floor(TRACK_HALF_LENGTH/track.spacing);
  const regular=Array.from({length:2*count+1},(_,i)=>({id:i-count,x:(i-count)*(track.spacing||0),strength:1}));
  if(!hasPoints(settings))return regular;
  return [...regular.filter(j=>!inPointAssembly(j.x,settings)).map(j=>{const s=routeStation(j.x,settings);return {...j,...routePose(s,settings)};}),...turnoutContacts(settings)].sort((a,b)=>a.s-b.s||a.id-b.id);
}
export const jointLabel=joint=>joint.label||`J${joint.id>0?'+':''}${joint.id}`;
export const isOnboard=settings=>settings.position==='pilot'||settings.position==='passenger';
// Interior coordinates are deliberately simple, with a standing eye height at
// the end doorway and a seated cab viewpoint. Front always means toward the loco.
export function observerLocal(settings){
  if(settings.position==='pilot')return {offset:1.8,y:3.15,z:.68,vehicle:0,label:'Loco pilot · leading cab'};
  if(settings.position==='passenger'){
    const profile=PROFILES[settings.profile],vehicle=Math.max(1,Math.min(settings.coaches,Number(settings.passengerCoach)||1));
    const rear=settings.passengerEnd==='rear',centre=20.56+(vehicle-.5)*profile.length;
    return {offset:centre+(rear?1:-1)*(profile.bodyLength/2-1.2),y:3.18,z:(settings.passengerSide===-1?-1:1)*.4,vehicle,label:`Coach ${String(vehicle).padStart(2,'0')} · ${rear?'rear':'front'} doorway`};
  }
  return {offset:null,x:3.8,y:2.73,z:settings.distance,vehicle:null,label:'Platform listener'};
}
export function listenerPosition(time,settings){
  const local=observerLocal(settings);
  if(isOnboard(settings)&&settings.points==='diverge'){
    const vehicle={centre:local.vehicle===0?10.28:20.56+(local.vehicle-.5)*PROFILES[settings.profile].length,index:local.vehicle};
    const p=vehiclePose(time,vehicle,settings),along=settings.direction*(vehicle.centre-local.offset);
    return {x:p.x+along*p.tx-local.z*p.tz,y:local.y,z:p.z+along*p.tz+local.z*p.tx,tx:p.tx,tz:p.tz};
  }
  return {x:isOnboard(settings)?trainPosition(time,settings)-settings.direction*local.offset:local.x,y:local.y,z:local.z};
}
export function passengerAxlePair(consist,settings){
  if(settings.position!=='passenger')return null;
  const rider=observerLocal(settings),ordered=[...consist.bogies].sort((a,b)=>a.offset-b.offset);
  const own=ordered.filter(b=>b.vehicle===rider.vehicle).reduce((a,b)=>Math.abs(a.offset-rider.offset)<Math.abs(b.offset-rider.offset)?a:b);
  const preceding=ordered[ordered.indexOf(own)-1];if(!preceding)return null;
  const axlesOf=bogie=>consist.axles.filter(a=>a.vehicle===bogie.vehicle&&a.bogie===bogie.index).sort((a,b)=>a.offset-b.offset);
  return {trailing:axlesOf(preceding).at(-1),leading:axlesOf(own)[0]};
}
export function eventArrivalTime(event,settings){
  // Preserve the exact approved platform timing, including its fixed station.
  if(!isOnboard(settings))return event.time+propagationDelay(event.joint.x-3.8,settings.distance-(event.joint.z||0));
  if(settings.points==='diverge'){
    // Solve retarded arrival along the curved receiver trajectory. Speed/c < .11.
    let delay=0;for(let i=0;i<12;i++){const p=listenerPosition(event.time+delay,settings);delay=Math.hypot(p.x-event.joint.x,p.y-.3,p.z-(event.joint.z||0))/SPEED_OF_SOUND;}
    return event.time+delay;
  }
  // Solve c*tau = |listener(contact) + velocity*tau - joint|.
  // The joint stays still while the receiver continues moving during flight.
  const p=listenerPosition(event.time,settings),dx=p.x-event.joint.x,dy=p.y-.3;
  const velocity=settings.direction*speedMS(settings),a=SPEED_OF_SOUND**2-velocity**2;
  const r2=dx*dx+dy*dy+(p.z-(event.joint.z||0))**2,dot=dx*velocity,disc=Math.sqrt(dot*dot+a*r2);
  const delay=dot<0?r2/(disc-dot):(dot+disc)/a;
  return event.time+delay;
}
export const spatialFalloff=distance=>4/(4+1.2*(Math.max(4,distance)-4));
export function jointRelativeLevel(joint,settings,time=0){
  if(!isOnboard(settings))return spatialFalloff(Math.hypot(joint.x-3.8,settings.distance-(joint.z||0),2.43))/spatialFalloff(Math.hypot(3.8,settings.distance,2.43));
  const p=listenerPosition(time,settings);
  return spatialFalloff(Math.hypot(joint.x-p.x,p.z-(joint.z||0),p.y-.3))/spatialFalloff(Math.hypot(observerLocal(settings).z,p.y-.3));
}
export const nearestJoint=(joints,time,settings)=>{const p=listenerPosition(time,settings);return joints.reduce((best,joint)=>Math.hypot(joint.x-p.x,(joint.z||0)-p.z)<Math.hypot(best.x-p.x,(best.z||0)-p.z)?joint:best);};
export const speedMS = settings=>settings.speed/3.6;
export const trainPosition = (time,settings)=>settings.direction*(-APPROACH+time*speedMS(settings));
export const axlePosition = (time,axle,settings)=>trainPosition(time,settings)-settings.direction*axle.offset;
export const axlePose=(time,axle,settings)=>routePose(axlePosition(time,axle,settings),settings);
export function vehiclePose(time,vehicle,settings){
 const half=vehicle.index===0?5.5:PROFILES[settings.profile].bogieCentres/2;
 const front=axlePose(time,{offset:vehicle.centre-half},settings),rear=axlePose(time,{offset:vehicle.centre+half},settings);
 const n=Math.hypot(front.x-rear.x,front.z-rear.z),d=settings.direction;
 return {x:(front.x+rear.x)/2,z:(front.z+rear.z)/2,tx:(front.x-rear.x)/n*d,tz:(front.z-rear.z)/n*d};
}
export const passDuration = (consist,settings)=>(APPROACH+consist.length+150)/speedMS(settings);
export function buildEvents(consist,settings) {
  const v=speedMS(settings), events=[];
  const duration=passDuration(consist,settings);
  for(const axle of consist.axles) for(const joint of makeJoints(settings)) {
    const time=(APPROACH+axle.offset+settings.direction*(joint.s??joint.x))/v;
    const event={time,axle,joint};
    const arrival=eventArrivalTime(event,settings);
    // Retarded sound may arrive just after start from a contact just before start.
    if(arrival>=0&&arrival<=duration)events.push({...event,arrival});
  }
  // Crossings at different distances can be heard out of contact-time order.
  return events.sort((a,b)=>a.arrival-b.arrival||a.joint.id-b.joint.id||a.axle.offset-b.axle.offset);
}
export const propagationDelay=(x,distance)=>Math.hypot(x,distance)/SPEED_OF_SOUND;
export const attenuation=(x,distance)=>Math.min(1,4.5/Math.hypot(x,distance));
export const seededRandom=seed=>()=>{seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return ((t^t>>>14)>>>0)/4294967296;};
