// Conventional BG 60 kg, 1:12, curved overriding switch / CMS crossing.
// Dimensions and assumptions are documented in TURNOUT-MODEL.md.
export const TURNOUT = Object.freeze({gauge:1.676,centres:5.1,radius:441.36,ratio:12,
  srj:-37.1,toe:1.144,stock:13,tongue:13.5,crossingToe:35.6,
  theoreticalNose:37.1,nose:37.298,crossingHeel:39.95,end:39.975});
const angle=Math.atan(1/TURNOUT.ratio),entry=20/60*Math.PI/180;
const arc=TURNOUT.radius*(angle-entry);
const arcX=TURNOUT.radius*(Math.sin(angle)-Math.sin(entry));
const arcZ=TURNOUT.radius*(Math.cos(entry)-Math.cos(angle));
const link=(TURNOUT.centres-2*arcZ)/Math.sin(angle);
const length=2*arc+link,span=2*arcX+link*Math.cos(angle);
const start=TURNOUT.srj+TURNOUT.toe;
export const CROSSOVER=Object.freeze({start,end:start+span,startS:start,endS:start+length,length,span,angle,arc,link,secondSRJ:start+span+TURNOUT.toe});
export const hasPoints=s=>s.points==='straight'||s.points==='diverge';
// Signed horizontal centreline curvature, in inverse metres. Positive bends
// toward +Z; the inner rail is on that same side of the canonical tangent.
export function routeCurvature(s,settings){
 if(settings.points!=='diverge')return 0;
 const u=s-start;
 if(u>0&&u<arc)return -1/TURNOUT.radius;
 if(u>arc+link&&u<length)return 1/TURNOUT.radius;
 return 0;
}

// s is distance along the selected centreline, not its projection onto world X.
// Reverse running traverses the same fixed crossover in the opposite direction.
export function routePose(s,settings){
 if(settings.points!=='diverge')return {x:s,z:0,tx:1,tz:0,s};
 const u=s-start;let x,z,a;
 if(u<=0)return {x:s,z:0,tx:1,tz:0,s};
 if(u>=length)return {x:start+span+u-length,z:-TURNOUT.centres,tx:1,tz:0,s};
 if(u<arc){a=entry+u/TURNOUT.radius;x=TURNOUT.radius*(Math.sin(a)-Math.sin(entry));z=TURNOUT.radius*(Math.cos(entry)-Math.cos(a));}
 else if(u<arc+link){a=angle;x=arcX+(u-arc)*Math.cos(a);z=arcZ+(u-arc)*Math.sin(a);}
 else{const remaining=length-u;a=entry+remaining/TURNOUT.radius;x=span-TURNOUT.radius*(Math.sin(a)-Math.sin(entry));z=TURNOUT.centres-TURNOUT.radius*(Math.cos(entry)-Math.cos(a));}
 return {x:start+x,z:-z,tx:Math.cos(a),tz:-Math.sin(a),s};
}
export function routeStation(x,settings){
 if(settings.points!=='diverge'||x<=start)return x;
 if(x>=CROSSOVER.end)return CROSSOVER.endS+x-CROSSOVER.end;
 let lo=start,hi=CROSSOVER.endS;
 for(let i=0;i<42;i++){const m=(lo+hi)/2;if(routePose(m,settings).x<x)lo=m;else hi=m;}
 return (lo+hi)/2;
}
export function railPoint(s,side,settings){const p=routePose(s,settings),d=side*TURNOUT.gauge/2;return {...p,x:p.x-p.tz*d,z:p.z+p.tx*d};}

// Assembly interfaces are per running rail. Two wheels at the SRJ are two
// contacts, whereas a frog is a transfer on ONE rail, not a whole-axle joint.
// Intermediate lead weld locations and response gains are explicit assumptions.
export function turnoutContacts(settings){
 if(!hasPoints(settings))return [];
 const diverge=settings.points==='diverge',points=diverge?2:1,result=[];
 for(let p=0;p<points;p++){
  const sign=p===0?1:-1,srj=p===0?TURNOUT.srj:CROSSOVER.secondSRJ;
  const inner=(diverge?1:-1)*sign,outer=-inner;
  const rows=[
   ['SRJ-L','Stock rail entry',0,-sign,'joint',.5],['SRJ-R','Stock rail entry',0,sign,'joint',.5],
   ['SW','Switch load transfer',TURNOUT.toe+5.8,inner,'switch',.12],
   ['ST','Stock rail heel',TURNOUT.stock,outer,'joint',.58],
   ['SH','Tongue rail heel',TURNOUT.tongue,inner,'joint',.62],
   ['LW-O','Outer lead weld',26,outer,'weld',.045],['LW-I','Inner lead weld',26.5,inner,'weld',.045],
   ['CT','CMS crossing entry',TURNOUT.crossingToe,inner,'joint',.68],
   ['F','Crossing nose',TURNOUT.nose,inner,'frog',1.05],
   ['CH','CMS crossing exit',TURNOUT.crossingHeel,inner,'joint',.68],
   ['EX','Outer rail exit',TURNOUT.end,outer,'joint',.58]
  ];
  rows.forEach(([code,name,u,side,kind,strength],i)=>{
   const s=routeStation(srj+sign*u,settings),r=railPoint(s,side,settings);
   result.push({id:1000+p*100+i,s,x:r.x,z:r.z,tx:r.tx,tz:r.tz,side,strength,kind,point:p+1,
    label:`P${p+1} ${code}`,name,chainage:u});
  });
 }
 return result.sort((a,b)=>a.s-b.s||a.id-b.id);
}
export function inPointAssembly(x,settings){
 if(!hasPoints(settings))return false;
 return x>=TURNOUT.srj&&x<=TURNOUT.srj+TURNOUT.end || settings.points==='diverge'&&x>=CROSSOVER.secondSRJ-TURNOUT.end&&x<=CROSSOVER.secondSRJ;
}
