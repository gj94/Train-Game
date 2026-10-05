"""Inspect the user-selected 55–60 s excerpt without changing the source MP3."""
from pathlib import Path
import sys,os,json,wave,hashlib
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.local/analysis-python'))
os.environ['MPLCONFIGDIR']=str(ROOT/'.local/matplotlib-config')
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
OUT=ROOT/'.local/audio-preview'
def read(name):
    with wave.open(str(OUT/name),'rb') as w:
        assert w.getframerate()==44100 and w.getnchannels()==2 and w.getsampwidth()==2
        return np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2).astype(float)/32768
RATE=44100
def stft(x,n=2048,hop=128):
    window=np.hanning(n)
    frames=np.lib.stride_tricks.sliding_window_view(x,n,axis=0)[::hop]
    power=(abs(np.fft.rfft(frames*window,axis=-1))**2/(RATE*np.sum(window**2))).mean(axis=1)
    power[:,1:-1]*=2
    return (np.arange(len(frames))*hop+n/2)/RATE,np.fft.rfftfreq(n,1/RATE),power
def db(x): return 20*np.log10(np.maximum(x,1e-12))
reference=read('TrainAudio-55-60.wav')
preferred=read('lhb-one-coach-one-joint-60kmh.wav')
new=read('lhb-one-coach-1km-jointed-26m-100kmh.wav')[:5*RATE]
fixed=read('lhb-one-coach-1km-jointed-26m-100kmh-reference-mix.wav')[:5*RATE]
t,f,p=stft(reference,n=1024)
audible=(f>=100)&(f<=6000)
normalized=np.log1p(p[:,audible]/np.maximum(np.median(p[:,audible],axis=0),1e-15))
flux=np.r_[0,np.maximum(0,np.diff(normalized,axis=0)).mean(axis=1)]
candidates=[i for i in range(1,len(t)-1) if flux[i]>=np.percentile(flux,88) and flux[i]>flux[i-1] and flux[i]>=flux[i+1]]
selected=[]
for i in sorted(candidates,key=lambda j:flux[j],reverse=True):
    if all(abs(t[i]-t[j])>.055 for j in selected): selected.append(i)
selected.sort()
band_envelopes={}
for name,low,high in [('Bass 80–350 Hz',80,350),('Impact body 350–1500 Hz',350,1500),('Metallic detail 1.5–6 kHz',1500,6000)]:
    mask=(f>=low)&(f<high)
    band_envelopes[name]=np.sqrt(p[:,mask].sum(axis=1)*(f[1]-f[0]))

# Repeating group interval, without assigning a group to a particular axle/joint.
envelope=band_envelopes['Impact body 350–1500 Hz']
centred=envelope-np.mean(envelope)
autocorr=np.correlate(centred,centred,mode='full')[len(centred)-1:]
autocorr/=autocorr[0]
lags=np.arange(len(autocorr))*(t[1]-t[0])
period_candidates=[i for i in range(1,len(lags)-1) if .35<lags[i]<1.5 and autocorr[i]>autocorr[i-1] and autocorr[i]>=autocorr[i+1]]
period_index=max(period_candidates,key=lambda i:autocorr[i])

analyses={}
spectra={}
for name,x in [('Recording 00:55–01:00',reference),('Preferred dry preview',preferred),('Rejected long preview',new),('Corrected long preview',fixed)]:
    ts,fs,power=stft(x)
    # Compare tonal balance after removing overall level, only in active/steady spans.
    if name=='Preferred dry preview': power=power[(ts>=.48)&(ts<=2.2)]
    elif name!='Recording 00:55–01:00': power=power[(ts>=.48)&(ts<=4.8)]
    spectrum=power.mean(axis=0)
    total=np.sum(spectrum[(fs>=80)&(fs<=8000)])
    spectra[name]=(fs,spectrum/total)
    band_energy={}
    for title,lo,hi in [('80–350 Hz',80,350),('350–1500 Hz',350,1500),('1500–6000 Hz',1500,6000)]:
        band_energy[title]=float(100*np.sum(spectrum[(fs>=lo)&(fs<hi)])/total)
    analyses[name]={'peak_dbfs':float(db(np.max(abs(x)))),'rms_dbfs':float(db(np.sqrt(np.mean(x*x)))),
      'band_energy_percent_of_80_to_8000_hz':band_energy}
    band=(fs>=350)&(fs<1500)
    band_level=10*np.log10(np.maximum(power[:,band].sum(axis=1),1e-15))
    analyses[name]['midband_95th_minus_median_db']=float(np.percentile(band_level,95)-np.percentile(band_level,50))
    if name=='Recording 00:55–01:00':
        smoothed=np.convolve(spectrum,np.ones(5)/5,'same')
        peaks=[i for i in range(1,len(fs)-1) if 80<=fs[i]<=6000 and smoothed[i]>smoothed[i-1] and smoothed[i]>=smoothed[i+1]]
        prominent=[]
        for i in sorted(peaks,key=lambda j:smoothed[j],reverse=True):
            if all(abs(fs[i]-fs[j])>100 for j in prominent): prominent.append(i)
            if len(prominent)==8: break
        analyses[name]['dominant_spectral_regions_hz']=[round(float(fs[i])) for i in prominent]

result={'source':'TrainAudio.mp3','excerpt_start_seconds':55,'excerpt_end_seconds':60,
  'source_speed_kmh':60,'source_speed_basis':'User identified the recording as 60 km/h; not inferred from sound.',
  'dominant_impact_group_period_seconds':float(lags[period_index]),'period_autocorrelation':float(autocorr[period_index]),
  'excerpt_sha256':hashlib.sha256((OUT/'TrainAudio-55-60.wav').read_bytes()).hexdigest(),
  'analyses':analyses,'transient_candidates_original_timestamps':[round(55+float(t[i]),4) for i in selected],
  'notes':['Transient candidates indicate changing energy, not verified individual wheel contacts.',
           'The user identifies the recording speed as 60 km/h; the repeating groups do not by themselves establish joint spacing.',
           'Spectral shapes are normalized by total 80–8000 Hz power; recording/mastering levels are not assumed equal.',
           'Band values include background and impacts; microphone/cabin response also affects the spectrum.']}
(OUT/'recording-55-60-analysis.json').write_text(json.dumps(result,indent=2),encoding='utf-8')

plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False})
fig,axs=plt.subplots(3,1,figsize=(13,9),layout='constrained',gridspec_kw={'height_ratios':[1,1.5,1.3]})
fig.suptitle('Actual onboard recording • TrainAudio.mp3 • 00:55–01:00',fontsize=16,fontweight='bold')
for name,envelope in band_envelopes.items(): axs[0].plot(55+t,db(envelope),label=name,lw=1.2)
axs[0].set(xlim=(55,60),ylabel='Band RMS (dBFS)',title='Energy rises and decays in separate frequency bands')
axs[0].grid(alpha=.2);axs[0].legend(loc='lower right',ncol=3,fontsize=8)
mask=(f>=80)&(f<=10000)
image=axs[1].pcolormesh(55+t,f[mask],10*np.log10(np.maximum(p[:,mask].T,1e-15)),shading='auto',cmap='magma',vmin=-105,vmax=-40)
axs[1].set(xlim=(55,60),yscale='log',ylim=(80,10000),ylabel='Frequency (Hz)',xlabel='Original recording time (seconds)',title='Spectrogram of the exact five-second excerpt')
fig.colorbar(image,ax=axs[1],label='dBFS/Hz',pad=.01)
colors=['#111111','#2463ac','#d75936','#239070']
for (name,(freq,power)),color in zip(spectra.items(),colors):
    axs[2].semilogx(freq[1:],10*np.log10(np.maximum(power[1:],1e-15)),label=name,color=color,lw=1.6 if color=='#111111' else 1.2)
axs[2].set(xlim=(80,8000),ylim=(-65,-8),ylabel='Relative spectral power (dB)',xlabel='Frequency (Hz)',title='Tonal balance comparison • total 80–8000 Hz power matched')
axs[2].grid(alpha=.2);axs[2].legend(fontsize=8,ncol=2)
fig.savefig(OUT/'recording-55-60-analysis.png',dpi=160)
plt.close(fig)
print(json.dumps(result,indent=2))
