"""Compare native and Web Audio captures; does not claim waveform identity."""
import sys,json,wave
from pathlib import Path
project=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(project/'.local/analysis-python'))
import numpy as np
root=Path(sys.argv[1]) if len(sys.argv)>1 else project/'.local/onboard-ab'
def read(path):
 with wave.open(str(path)) as w:
  return w.getframerate(),np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,w.getnchannels()).astype(float)/32768
def spectrum(a,sr):
 n=8192;win=np.hanning(n+1)[:-1]
 chunks=np.stack([a[i:i+n] for i in range(0,len(a)-n+1,n//2)])
 return np.fft.rfftfreq(n,1/sr),np.mean(abs(np.fft.rfft(chunks*win[None,:,None],axis=1))**2,axis=(0,2))
out=[]
for speed,stem in [(s,t) for s in ['30','71.6','120'] for t in ['-pilot', '-passenger']]:
 gamefile=root/f'game-{float(speed)}{stem}kmh.wav'
 if not gamefile.exists():continue
 sr,a=read(root/f'website-{speed}{stem}kmh.wav');sg,b=read(gamefile)
 if sr!=sg:
  b=np.stack([np.interp(np.arange(round(len(b)*sr/sg))/sr,np.arange(len(b))/sg,b[:,c]) for c in range(2)],axis=1)
 n=min(len(a),len(b));a=a[:n];b=b[:n]
 # Ignore the first half second of mixer warm-up and last capture-buffer edge.
 a=a[int(.5*sr):-int(.15*sr)];b=b[int(.5*sr):-int(.15*sr)]
 f,pa=spectrum(a,sr);_,pb=spectrum(b,sr)
 errs=[]
 for hz in 1000*2.**(np.arange(-11,10)/3):
  mask=(f>=hz/2**(1/6))&(f<hz*2**(1/6))
  errs.append(10*np.log10(pb[mask].sum()/pa[mask].sum()))
 block=round(sr*.01);m=min(len(a),len(b))//block
 ea=np.sqrt(np.mean(a[:m*block].reshape(m,block,2)**2,axis=(1,2)))
 eb=np.sqrt(np.mean(b[:m*block].reshape(m,block,2)**2,axis=(1,2)))
 corr=[]
 for lag in range(-10,11):
  aa=ea[max(0,lag):len(ea)+min(0,lag)];bb=eb[max(0,-lag):len(eb)+min(0,-lag)]
  corr.append((float(np.corrcoef(aa,bb)[0,1]),lag*.01))
 out.append(dict(speed=speed,stem=stem or 'full',game_seconds=n/sr,rms_delta_db=float(10*np.log10(np.mean(b*b)/np.mean(a*a))),mean_band_error_db=float(np.mean(np.abs(errs))),envelope=max(corr),game_peak=float(abs(b).max()),reference_peak=float(abs(a).max()),channel_rms_ratio=[float(np.sqrt(np.mean(b[:,i]**2)/np.mean(a[:,i]**2))) for i in range(2)]))
print(json.dumps(out,indent=2));(root/'comparison.json').write_text(json.dumps(out,indent=2))
