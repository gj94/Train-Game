export const PROFILES = {
  lhb: { name:'LHB express', length:24, bodyLength:23.54, bogieCentres:14.9, wheelbase:2.56, radius:.4575, color:0xad2724, speed:71.6, referenceStart:15, referenceEnd:35 },
  icf: { name:'ICF passenger', length:22.297, bodyLength:21.336, bogieCentres:14.783, wheelbase:2.896, radius:.4575, color:0xd9bc77, speed:65.4, referenceStart:64, referenceEnd:80 }
};
export const DEFAULTS = { profile:'lhb', speed:71.6, coaches:20, distance:5.8, jointStrength:.7, body:.5, ring:.5, rumble:.55, volume:.65, direction:1, loop:true, showAxles:true };
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
// The outside listener hears the one nearby joint. Never schedule other joints.
export function makeJoints() { return [{id:0,x:0,strength:1}]; }
export const speedMS = settings=>settings.speed/3.6;
export const trainPosition = (time,settings)=>settings.direction*(-APPROACH+time*speedMS(settings));
export const axlePosition = (time,axle,settings)=>trainPosition(time,settings)-settings.direction*axle.offset;
export const passDuration = (consist,settings)=>(APPROACH+consist.length+150)/speedMS(settings);
export function buildEvents(consist,settings) {
  const v=speedMS(settings), events=[];
  for(const axle of consist.axles) for(const joint of makeJoints()) {
    const time=(APPROACH+axle.offset+settings.direction*joint.x)/v;
    if(time>=0) events.push({time,axle,joint});
  }
  return events.sort((a,b)=>a.time-b.time||a.axle.offset-b.axle.offset);
}
export const propagationDelay=(x,distance)=>Math.hypot(x,distance)/SPEED_OF_SOUND;
export const attenuation=(x,distance)=>Math.min(1,4.5/Math.hypot(x,distance));
export const seededRandom=seed=>()=>{seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return ((t^t>>>14)>>>0)/4294967296;};
