"""Fit a stochastic, body-rich wheel/joint excitation to the first train.

No source waveform is reused. Only time/frequency energy statistics are retained.
The existing 71.6 km/h geometry and event spacing are held fixed.
"""
import os, sys, json, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.analysis-deps'))
os.environ.setdefault('MPLCONFIGDIR',str(ROOT/'analysis'/'mpl'))
import numpy as np
from scipy import signal, ndimage
from scipy.optimize import nnls
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.io import wavfile

OUT=ROOT/'public'/'synthesis'
OUT.mkdir(exist_ok=True)
sr,x=wavfile.read(ROOT/'analysis'/'lhb-reference-48k.wav')
x=x.astype(np.float64)/32768
v=71.6/3.6
period=24/v
offsets=np.array([0,2.56,14.9,17.46])/v
predicted=(np.arange(-1,18)[:,None]*period+offsets[None,:]+.6136+.0232).ravel()
predicted=np.sort(predicted[(predicted>.08)&(predicted<19.7)])

# Estimate actual transient centers locally, never alter the simulation rhythm.
sos=signal.butter(3,[500,5500],btype='bandpass',fs=sr,output='sos')
high=signal.sosfilt(sos,x)
energy=ndimage.gaussian_filter1d(high**2,sr*.0015)
onsets=[]
for t in predicted:
    a=int((t-.025)*sr);b=int((t+.025)*sr)
    onsets.append((a+np.argmax(energy[a:b]))/sr)
onsets=np.array(onsets)

# Power deconvolution: one impulse-response spectrogram shared by all detected
# wheelsets, plus a slowly varying noise floor. Close axle pairs overlap naturally.
nfft=2048;hop=256
freq,tt,Z=signal.stft(x,sr,nperseg=nfft,noverlap=nfft-hop,boundary='zeros')
power=np.abs(Z)**2
dt=hop/sr
kernel_times=np.arange(-.0213333,.325,dt)
X=np.zeros((len(tt),len(kernel_times)))
for onset in onsets:
    for j,lag in enumerate(kernel_times):
        position=(onset+lag)/dt
        i=int(np.floor(position));f=position-i
        if 0<=i<len(tt)-1:X[i,j]+=1-f;X[i+1,j]+=f
# Piecewise-linear background captures passing rumble without ringing modes.
knots=np.arange(0,22,1.)
B=np.maximum(0,1-np.abs(tt[:,None]-knots[None,:]))
A=np.c_[X,B]
# Normalize columns and solve nonnegative least squares in all 1025 FFT bins.
scales=np.maximum(np.linalg.norm(A,axis=0),1e-9)
An=A/scales
gram=An.T@An
rhs=An.T@power.T
# A small temporal smoothness prior regularizes the overlapping wheel contacts.
D=np.diff(np.eye(len(kernel_times)),axis=0)
reg=np.zeros_like(gram)
reg[:len(kernel_times),:len(kernel_times)]=.015*(D.T@D)
L=np.linalg.eigvalsh(gram+reg).max()
H=np.maximum(0,np.linalg.lstsq(gram+reg+np.eye(gram.shape[0])*.0005,rhs,rcond=None)[0])
momentum=H.copy();alpha=1.
for _ in range(1000):
    updated=np.maximum(0,momentum-((gram+reg)@momentum-rhs)/L)
    new_alpha=(1+np.sqrt(1+4*alpha*alpha))/2
    momentum=updated+(alpha-1)/new_alpha*(updated-H)
    H=updated;alpha=new_alpha
H=H/scales[:,None]
kernel=H[:len(kernel_times)].T
background=(B@H[len(kernel_times):]).T
bg=np.maximum(np.median(background,axis=1),1e-12)
# Smooth only one frequency bin: retain the recording's broad body structure.
kernel=ndimage.gaussian_filter(kernel,[.65,.65])
kernel[freq<45]*=(freq[freq<45,None]/45)**2
kernel[freq>11000]*=np.exp(-(freq[freq>11000,None]-11000)/2500)

def synthesize_spectrogram(P,seed):
    rng=np.random.default_rng(seed)
    phase=rng.uniform(-np.pi,np.pi,P.shape)
    target=np.sqrt(np.maximum(P,0))
    complex_spec=target*np.exp(1j*phase)
    # Griffin–Lim makes the overlapping windows consistent. Phases start random;
    # they are never copied from the reference. This is stochastic resynthesis.
    for _ in range(36):
        _,out=signal.istft(complex_spec,sr,nperseg=nfft,noverlap=nfft-hop,boundary=True)
        _,_,rebuilt=signal.stft(out,sr,nperseg=nfft,noverlap=nfft-hop,boundary='zeros')
        rebuilt=rebuilt[:,:P.shape[1]]
        if rebuilt.shape[1]<P.shape[1]:rebuilt=np.pad(rebuilt,((0,0),(0,P.shape[1]-rebuilt.shape[1])))
        complex_spec=target*rebuilt/np.maximum(np.abs(rebuilt),1e-15)
    _,out=signal.istft(complex_spec,sr,nperseg=nfft,noverlap=nfft-hop,boundary=True)
    # The kernel starts just before the fitted contact, including its finite attack.
    fade=int(sr*.002)
    out[:fade]*=np.linspace(0,1,fade);out[-int(sr*.025):]*=np.linspace(1,0,int(sr*.025))
    return out

variants=[synthesize_spectrogram(kernel,2301+i*937) for i in range(8)]
# A long Gaussian noise process colored to the fitted continuous background.
rng=np.random.default_rng(42991);N=sr*8
ff=np.fft.rfftfreq(N,1/sr)
psd=np.interp(ff,freq,bg,left=bg[0],right=0)
bed=np.fft.irfft(np.sqrt(psd)*(rng.normal(size=len(ff))+1j*rng.normal(size=len(ff))),n=N)
bed*=np.sqrt(np.mean(bg)/max(np.mean(np.abs(signal.stft(bed,sr,nperseg=nfft,noverlap=nfft-hop)[2])**2),1e-15))

def assemble(variants,bed):
    output=np.resize(bed,len(x)).copy()
    for i,t in enumerate(onsets):
        start=int((t+kernel_times[0])*sr)
        sample=variants[i%len(variants)]
        n=min(len(sample),len(output)-start)
        if start>=0 and n>0:output[start:start+n]+=sample[:n]
    return output

def third_octave(a):
    f,p=signal.welch(a,sr,nperseg=8192,noverlap=4096)
    centers=1000*2**(np.arange(-13,13)/3)
    energies=[]
    for center in centers:
        mask=(f>=center/2**(1/6))&(f<center*2**(1/6))
        energies.append(np.trapezoid(p[mask],f[mask]))
    return centers,np.array(energies)

# Correct remaining broad coloration in the actual resynthesized signal.
# This does not create or boost isolated metallic sinusoids.
def spectral_correct(a,frequencies,gain):
    n=2**int(np.ceil(np.log2(len(a)+8192)))
    f=np.fft.rfftfreq(n,1/sr)
    correction=np.interp(f,frequencies,gain,left=gain[0],right=gain[-1])
    return np.fft.irfft(np.fft.rfft(a,n)*correction,n)[:len(a)]

before=assemble(variants,bed)
target_freq,target_psd=signal.welch(x,sr,nperseg=8192,noverlap=4096)
for _ in range(3):
    check=assemble(variants,bed)
    _,fit_psd=signal.welch(check,sr,nperseg=8192,noverlap=4096)
    ratio=np.sqrt(ndimage.gaussian_filter1d(target_psd,2.5)/np.maximum(ndimage.gaussian_filter1d(fit_psd,2.5),1e-15))
    ratio=np.clip(ratio,.55,1.8)
    variants=[spectral_correct(a,target_freq,ratio) for a in variants]
    bed=spectral_correct(bed,target_freq,ratio)
result=assemble(variants,bed)

# One shared gain preserves the fitted impact/rumble balance and leaves headroom.
peak=max(max(np.max(np.abs(a)) for a in variants),np.max(np.abs(bed)),np.max(np.abs(result)))
gain=min(1,.82/peak)
for i,a in enumerate(variants):wavfile.write(OUT/f'impact-{i}.wav',sr,(np.clip(a*gain,-1,1)*32767).astype(np.int16))
wavfile.write(OUT/'rolling-bed.wav',sr,(np.clip(bed*gain,-1,1)*32767).astype(np.int16))
wavfile.write(ROOT/'analysis'/'spectrum-matched-pass.wav',sr,(np.clip(result*gain,-1,1)*32767).astype(np.int16))

centers,target_bands=third_octave(x)
_,synth_bands=third_octave(result)
delta=10*np.log10(np.maximum(synth_bands,1e-15)/np.maximum(target_bands,1e-15))
scored=(centers>=80)&(centers<=8000)
def band_share(p,lo,hi):
    mask=(target_freq>=lo)&(target_freq<hi)
    allmask=(target_freq>=50)&(target_freq<10000)
    return float(np.trapezoid(p[mask],target_freq[mask])/np.trapezoid(p[allmask],target_freq[allmask]))
_,result_psd=signal.welch(result,sr,nperseg=8192,noverlap=4096)
metrics={'method':'Nonnegative time/frequency power deconvolution of fixed-spacing axle events + smooth rolling bed; randomized-phase stochastic resynthesis; broad spectral correction. No source waveform or phase is reused.',
 'referenceSeconds':[15,35],'speedKmh':71.6,'spacingChanged':False,'matchedContacts':len(onsets),'sampleRate':sr,'variants':8,
 'spectralMatchScope':'Offline 20-second mono composite, 1/3-octave energy, 80–8000 Hz, before browser spatialization/controls. Matching this statistic does not imply perceptual or waveform identity.',
 'meanAbsoluteBandErrorDb':float(np.mean(np.abs(delta[scored]))),'maxAbsoluteBandErrorDb':float(np.max(np.abs(delta[scored]))),
 'referenceBodyEnergyShare50to800Hz':band_share(target_psd,50,800),'synthesisBodyEnergyShare50to800Hz':band_share(result_psd,50,800),
 'bankGain':gain,'kernelStartSeconds':float(kernel_times[0]),'impactRms':float(np.mean([np.sqrt(np.mean(a*a)) for a in variants])*gain),'bedRms':float(np.sqrt(np.mean(bed*bed))*gain),
 'bands':[{'hz':round(float(c),1),'errorDb':round(float(d),3),'referenceDb':round(float(10*np.log10(max(r,1e-15))),3),'syntheticDb':round(float(10*np.log10(max(s,1e-15))),3)} for c,d,r,s in zip(centers,delta,target_bands,synth_bands)]}
(OUT/'spectral-fit.json').write_text(json.dumps(metrics,indent=2))

plt.rcParams.update({'figure.facecolor':'#111a17','axes.facecolor':'#16231c','savefig.facecolor':'#111a17','text.color':'#e6e7db','axes.labelcolor':'#cbd5c8','xtick.color':'#b7c6b4','ytick.color':'#b7c6b4','axes.edgecolor':'#51624c','font.family':'DejaVu Sans','font.size':10})
fig,axs=plt.subplots(2,2,figsize=(15,9),layout='constrained')
fig.suptitle('First-train impact: body and spectrum reconstruction',fontsize=20,fontweight='bold')
ax=axs[0,0];mask=(target_freq>40)&(target_freq<12000);norm=max(target_psd)
ax.semilogx(target_freq[mask],10*np.log10(ndimage.gaussian_filter1d(target_psd,2)[mask]/norm),color='#e8be77',label='Video, 00:15–00:35',lw=1.5)
ax.semilogx(target_freq[mask],10*np.log10(ndimage.gaussian_filter1d(result_psd,2)[mask]/norm),color='#76cab5',label='Resynthesized composite',lw=1,alpha=.9)
ax.axvspan(50,800,color='#e8be77',alpha=.08);ax.set(xlabel='Frequency (Hz)',ylabel='Power relative to reference peak (dB)',title='Measured spectrum vs. reconstruction',ylim=(-65,5),xlim=(40,12000));ax.grid(alpha=.13);ax.legend(frameon=False)
ax=axs[0,1];ax.bar(np.arange(sum(scored)),delta[scored],color='#76cab5');ax.axhline(0,color='#e8be77');ax.axhspan(-1,1,color='#e8be77',alpha=.07);ax.set_xticks(np.arange(sum(scored))[::2],[f'{f:.0f}' for f in centers[scored][::2]],rotation=40);ax.set(ylabel='Synthesis − reference (dB)',xlabel='1/3-octave band centre (Hz)',title=f'Band balance · mean error {metrics["meanAbsoluteBandErrorDb"]:.2f} dB');ax.grid(axis='y',alpha=.13)
ax=axs[1,0];db=10*np.log10(np.maximum(kernel,1e-13)/max(kernel.max(),1e-12));im=ax.pcolormesh((kernel_times-kernel_times[0])*1000,freq,db,vmin=-50,vmax=0,cmap='magma',shading='auto');ax.set(ylim=(60,8000),yscale='log',xlabel='Time within one impact (ms)',ylabel='Frequency (Hz)',title='Extracted impact energy: low body + short broadband contact');fig.colorbar(im,ax=ax,label='Relative power (dB)')
ax=axs[1,1];reconstructed=variants[0];f,ts,Zs=signal.stft(reconstructed,sr,nperseg=nfft,noverlap=nfft-hop);rec=np.sum(kernel,axis=0);syn=np.sum(abs(Zs)**2,axis=0);ax.plot((kernel_times-kernel_times[0])*1000,rec/max(rec),color='#e8be77',label='Fitted reference envelope');ax.plot(ts*1000,syn/max(syn),color='#76cab5',label='Generated impact');ax.set(xlim=(0,330),xlabel='Time (ms)',ylabel='Normalized spectral energy',title='Attack and decay of one wheelset');ax.legend(frameon=False);ax.grid(alpha=.13)
fig.text(.5,-.018,'Spacing unchanged. Phases and waveforms are newly generated. Spectrum match is measured before browser spatialization; it is not a claim of identical sound.',ha='center',fontsize=10,color='#b7c6b4')
fig.savefig(ROOT/'public'/'spectrum-analysis.png',dpi=140,bbox_inches='tight')
print(json.dumps({k:v for k,v in metrics.items() if k!='bands'},indent=2))
