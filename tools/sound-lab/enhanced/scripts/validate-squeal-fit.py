"""Compare actual JS-generated PCM against calibration and held-out video windows.

Generate analysis/squeal-fitted-{0..3}.f32 with synthesizeSqueal() at 48 kHz first.
Optional analysis/squeal-before.f32 supplies the previous implementation comparison.
"""
import os,sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.analysis-deps'))
os.environ.setdefault('MPLCONFIGDIR',str(ROOT/'analysis'/'mpl'))
import numpy as np
from scipy import signal,ndimage
from scipy.io import wavfile
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

target=np.load(ROOT/'analysis'/'squeal-fit-target.npz')
f=target['frequency'];df=f[1]-f[0];ref=target['target']
report=json.loads((ROOT/'public'/'squeal-fit.json').read_text(encoding='utf-8'))
banks=[np.fromfile(ROOT/'analysis'/f'squeal-fitted-{i}.f32',dtype='<f4') for i in range(4)]
spectra=[signal.welch(x,48000,nperseg=65536,noverlap=32768)[1] for x in banks]
freq=signal.welch(banks[0],48000,nperseg=65536)[0]
synth=np.mean([np.interp(f,freq,p) for p in spectra],axis=0)
use=(f>=2250)&(f<=7600)
def normalize(p):return p/np.trapezoid(p[use],f[use])
ref=normalize(ref);synth=normalize(synth)
rows=[];heldErrors=[]
for band in report['peaks']:
 lo,hi=band['bandHz'];indices=np.flatnonzero((f>=lo)&(f<=hi))
 rp=np.trapezoid(ref[indices],f[indices]);sp=np.trapezoid(synth[indices],f[indices])
 observed=ndimage.gaussian_filter1d(synth,8/df)
 peak=float(f[indices[np.argmax(observed[indices])]])
 referenceSmooth=ndimage.gaussian_filter1d(ref,8/df)
 referencePeak=float(f[indices[np.argmax(referenceSmooth[indices])]])
 rows.append({'bandHz':[lo,hi],'referencePeakHz':round(referencePeak,2),'syntheticPeakHz':round(peak,2),'peakErrorHz':round(peak-referencePeak,2),'bandErrorDb':round(float(10*np.log10(sp/rp)),4)})
for window,p in zip(report['holdoutWindowsSeconds'],target['heldout']):
 p=normalize(p);errors=[]
 for band in report['peaks']:
  lo,hi=band['bandHz'];mask=(f>=lo)&(f<=hi)
  errors.append(float(10*np.log10(np.trapezoid(synth[mask],f[mask])/np.trapezoid(p[mask],f[mask]))))
 heldErrors.append({'windowSeconds':window,'bandErrorsDb':[round(v,3) for v in errors],'meanAbsoluteBandErrorDb':round(float(np.mean(np.abs(errors))),3)})
report['validation']={'scope':'RMS-normalized squeal-band spectra before spatialization, curve color and mix. Welch comparison of four independently phased JS banks against fit windows and separately held-out windows from the same video. Peak estimates use identical 8 Hz smoothing; broad bands can have multiple nearby maxima.',
 'bands':rows,'meanAbsoluteBandErrorDb':round(float(np.mean([abs(r['bandErrorDb']) for r in rows])),4),
 'maxAbsoluteBandErrorDb':round(float(max(abs(r['bandErrorDb']) for r in rows)),4),
 'heldOut':heldErrors,'maxPcmPeak':round(float(max(np.max(np.abs(x)) for x in banks)),6)}
(ROOT/'public'/'squeal-fit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
fig,axes=plt.subplots(2,1,figsize=(12,8),gridspec_kw={'height_ratios':[3,1]},constrained_layout=True)
def line(p,label,color,lw):axes[0].plot(f,10*np.log10(np.maximum(ndimage.gaussian_filter1d(p,8/df),1e-12)),label=label,color=color,lw=lw)
line(ref,'Video: fitted curve windows, background subtracted','#254c68',1.8)
line(synth,'New synthetic squeal (four new phases)','#b86b30',1.3)
before=ROOT/'analysis'/'squeal-before.f32'
if before.exists():
 fb,pb=signal.welch(np.fromfile(before,dtype='<f4'),48000,nperseg=65536)
 line(normalize(np.interp(f,fb,pb)),'Previous three-tone model','#aaa',.8)
axes[0].set(xlim=(2300,7600),ylim=(-65,-15),xlabel='Frequency (Hz)',ylabel='Normalized power density (dB/Hz)',title='SquealingTrain — measured broad squeal bands vs synthesis')
axes[0].legend(fontsize=9,loc='lower left');axes[0].grid(alpha=.2)
for r in rows:axes[0].axvline(r['referencePeakHz'],color='#254c68',alpha=.15)
centres=np.arange(len(rows));axes[1].bar(centres,[r['bandErrorDb'] for r in rows],color='#b86b30');axes[1].set_xticks(centres,[f"{r['bandHz'][0]}–{r['bandHz'][1]}" for r in rows]);axes[1].set(ylim=(-1,1),xlabel='Measured mode band (Hz)',ylabel='Fit error (dB)');axes[1].axhline(0,color='#444',lw=.6)
fig.savefig(ROOT/'public'/'squeal-spectrum.png',dpi=150);plt.close(fig)
# Listening aid: synthetic bank only, with a small head/tail fade for file playback.
preview=np.tile(banks[0],2);fade=np.linspace(0,1,2400);preview[:len(fade)]*=fade;preview[-len(fade):]*=fade[::-1]
wavfile.write(ROOT/'analysis'/'squeal-fitted-preview.wav',48000,np.int16(np.clip(preview,-1,1)*32767))
print(json.dumps(report['validation'],indent=2))
