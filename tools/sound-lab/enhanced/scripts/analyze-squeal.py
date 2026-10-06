"""Inspect the SquealingTrain curve benchmark. Requires ffmpeg, NumPy, SciPy, Matplotlib.

Outputs are measurements/plots under analysis; the video is never a runtime asset.
"""
import os, sys, json, subprocess, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.analysis-deps'))
os.environ.setdefault('MPLCONFIGDIR',str(ROOT/'analysis'/'mpl'))
import numpy as np
from scipy import signal, ndimage
from scipy.io import wavfile
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

VIDEO=ROOT.parent/'SquealingTrain.mp4'
WAV=ROOT/'analysis'/'squeal-reference-48k.wav'
WAV.parent.mkdir(parents=True,exist_ok=True)
stamp=WAV.with_suffix('.source-sha256')
source_hash=hashlib.sha256(VIDEO.read_bytes()).hexdigest()
if not WAV.exists() or not stamp.exists() or stamp.read_text(encoding='utf-8').strip()!=source_hash:
 subprocess.run(['ffmpeg','-v','error','-i',str(VIDEO),'-vn','-ac','1','-ar','48000','-y',str(WAV)],check=True)
 stamp.write_text(source_hash+'\n',encoding='utf-8')
sr,raw=wavfile.read(WAV)
x=signal.resample_poly(raw.astype(np.float32)/32768,1,2); sr=sr//2
f,t,Z=signal.stft(x,sr,nperseg=4096,noverlap=3584,boundary=None)
p=(np.abs(Z)**2).astype(np.float32)
db=10*np.log10(np.maximum(p,1e-14))
fig,axes=plt.subplots(2,1,figsize=(18,10),sharex=True,gridspec_kw={'height_ratios':[4,1]},constrained_layout=True)
axes[0].pcolormesh(t,f,db,cmap='magma',vmin=-80,vmax=-25,shading='auto',rasterized=True)
axes[0].set(ylim=(300,7000),ylabel='Frequency (Hz)',title='SquealingTrain: recorded spectrum (includes wheel noise, rushing, voices and other sources)')
axes[0].set_yscale('log');axes[0].set_yticks([400,600,800,1000,1500,2000,3000,4000,6000],labels=['400','600','800','1k','1.5k','2k','3k','4k','6k'])
for lo,hi in [(400,1000),(1000,2000),(2000,4000),(4000,7000)]:axes[1].plot(t,10*np.log10(p[(f>=lo)&(f<hi)].sum(axis=0)+1e-14),label=f'{lo}–{hi} Hz',lw=.8)
axes[1].set(xlabel='Video time (seconds)',ylabel='Band power (dB)');axes[1].legend(ncol=4);axes[1].grid(alpha=.2)
fig.savefig(ROOT/'analysis'/'squeal-overview.png',dpi=130);plt.close(fig)
rows=[]
for start in range(0,int(len(x)/sr),10):
 end=min(start+10,len(x)/sr);freq,psd=signal.welch(x[int(start*sr):int(end*sr)],sr,nperseg=32768)
 floor=ndimage.median_filter(psd,size=201);contrast=10*np.log10((psd+1e-16)/(floor+1e-16))
 peaks,_=signal.find_peaks(10*np.log10(psd+1e-16),distance=60,prominence=5)
 peaks=[int(i) for i in peaks if 400<freq[i]<7000 and contrast[i]>5]
 peaks=sorted(peaks,key=lambda i:psd[i],reverse=True)[:12]
 rows.append({'start':start,'end':round(end,3),'peaks':[{'hz':round(float(freq[i]),2),'db':round(float(10*np.log10(psd[i])),1),'contrastDb':round(float(contrast[i]),1)} for i in peaks]})
(ROOT/'analysis'/'squeal-overview.json').write_text(json.dumps({'source':VIDEO.name,'duration':len(x)/sr,'windows':rows},indent=2),encoding='utf-8')
print(json.dumps([{'start':r['start'],'peaksHz':[p['hz'] for p in r['peaks'][:5]]} for r in rows],indent=2))
