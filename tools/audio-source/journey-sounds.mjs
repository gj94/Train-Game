// Authored synthesis, not recordings. Canonical source in railway-clang-simulator.
import {random, wav, RATE} from './coach-rattle.mjs';
export {wav};
export const names=['fan-wap','fan-vb','vent','compressor','rush','wake','step-floor','step-platform','door','brake-air','clearance'];
export function synthesize(name){
  if(!names.includes(name))throw Error('Unknown layer');
  const loop=names.indexOf(name)<6;
  const seconds=loop?6:(name==='brake-air'?1.1:name==='door'?.55:name==='clearance'?.45:.25);
  const n=Math.round(seconds*RATE), a=new Float32Array(n), rng=random(991+names.indexOf(name)*719);
  let low=0,mid=0,prev=0;
  for(let i=0;i<n;i++){
    const t=i/RATE, noise=2*rng()-1;
    low+=.018*(noise-low);mid+=.17*(noise-mid);
    const envelope=loop?1:(1-Math.exp(-t/.006))*Math.exp(-t/(seconds*.23))*Math.min(1,(n-i-1)/800);
    let s=0;
    if(name==='fan-wap')s=.32*low+.025*Math.sin(2*Math.PI*100*t)+.009*Math.sin(2*Math.PI*301*t);
    if(name==='fan-vb')s=.20*mid+.012*Math.sin(2*Math.PI*240*t);
    if(name==='vent')s=.20*mid+.12*low;
    if(name==='compressor')s=(.26*low+.024*Math.sin(2*Math.PI*48*t)+.012*Math.sin(2*Math.PI*144*t))*(.85+.15*Math.sin(2*Math.PI*8*t));
    if(name==='rush')s=(.35*mid+.35*low+.04*(noise-prev))*(.85+.15*Math.sin(2*Math.PI*3.5*t));
    if(name==='wake')s=.65*low*(.65+.35*Math.sin(2*Math.PI*5*t));
    if(name.startsWith('step'))s=(.20*low+.09*Math.sin(2*Math.PI*(name==='step-floor'?130:310)*t)*Math.exp(-t/.025)+.06*noise*Math.exp(-t/.016));
    if(name==='door')s=.17*noise*Math.exp(-t/.04)+.12*Math.sin(2*Math.PI*180*t)*Math.exp(-t/.13)+.035*Math.sin(2*Math.PI*890*t)*Math.exp(-t/.05);
    if(name==='brake-air')s=.26*(noise-low);
    if(name==='clearance')s=.13*(Math.sin(2*Math.PI*660*t)+.45*Math.sin(2*Math.PI*990*t));
    a[i]=s*envelope;prev=noise;
  }
  // Circular overlap at the loop seam, preserving the stochastic texture.
  if(loop){const fade=2400;for(let i=0;i<fade;i++){const w=i/fade;a[i]=a[n-fade+i]*(1-w)+a[i]*w;}a[n-1]=a[0];}
  return a;
}
