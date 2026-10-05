"""Compare immutable LHB previews; no changes to game/generated sound assets."""
from pathlib import Path
import sys, os, json, re, wave, hashlib
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.local/analysis-python'))
os.environ['MPLCONFIGDIR'] = str(ROOT / '.local/matplotlib-config')
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUT = ROOT / '.local/audio-preview'
TEXT = (ROOT / 'game/physical_model_data.gd').read_text(encoding='utf-8-sig')
def value(name):
    return float(re.search(r'const '+name+r' := ([\d.+-]+)', TEXT)[1])
RATE = int(value('RATE'))
GAINS = json.loads(re.search(r'const WHEEL_GAIN := (\[[^\]]+\])', TEXT)[1])
def read_wav(path):
    with wave.open(str(path), 'rb') as stream:
        assert stream.getframerate() == RATE and stream.getsampwidth() == 2 and stream.getnchannels() == 2
        return np.frombuffer(stream.readframes(stream.getnframes()), dtype='<i2').reshape(-1,2).astype(np.float64)/32768
def db(x):
    return float(20*np.log10(max(float(x), 1e-12)))
def rms(x):
    return float(np.sqrt(np.mean(x*x)))
def psd(x, n=2048, hop=512):
    window = np.hanning(n)
    frames = np.lib.stride_tricks.sliding_window_view(x, n, axis=0)[::hop]
    spectrum = np.fft.rfft(frames*window, axis=-1)
    power = np.abs(spectrum)**2/(RATE*np.sum(window**2))
    power[:,:,1:-1] *= 2
    return np.fft.rfftfreq(n,1/RATE), power.mean(axis=(0,1))
def spectrogram(x):
    n,hop=1024,128
    window=np.hanning(n)
    frames=np.lib.stride_tricks.sliding_window_view(x,n,axis=0)[::hop]
    power=np.abs(np.fft.rfft(frames*window,axis=-1))**2/(RATE*np.sum(window**2))
    power[:,:,1:-1]*=2
    return (np.arange(len(frames))*hop+n/2)/RATE,np.fft.rfftfreq(n,1/RATE),10*np.log10(np.maximum(power.mean(axis=1).T,1e-15))

old_path=OUT/'lhb-one-coach-one-joint-60kmh.wav'
new_path=OUT/'lhb-one-coach-1km-jointed-26m-100kmh.wav'
old,new=read_wav(old_path),read_wav(new_path)
report=json.loads(new_path.with_suffix('.json').read_text())
kernels=[read_wav(ROOT/f'assets/sounds/lab/physical_icf_wheel{k}.wav') for k in [1,2]]
roll=read_wav(ROOT/'assets/sounds/lab/physical_icf_rolling.wav')
axles=np.array([-8.73,-6.17,6.17,8.73])
distances=np.hypot(axles,3)
speed=report['speedKmh']
impact_scale=(.3+np.sqrt(speed/90))/(.3+np.sqrt(value('REFERENCE_SPEED')/90))
rolling_scale=(speed/value('REFERENCE_SPEED'))**.8
roll_level=np.sqrt(np.sum(1/(1+(distances/value('NOISE_NEAR'))**2))/value('NOISE_REF'))
times=np.arange(len(new))/RATE
fade=np.clip(np.minimum(times/.25,(len(new)/RATE-times)/.4),0,1)
background=(roll[np.arange(len(new))%len(roll)]*value('ROLLING_GAIN')*rolling_scale*roll_level*.5*fade[:,None]).astype(np.float32)
impacts=np.zeros(new.shape,np.float32)
for event in report['events']:
    axle=event['axle']-1; wheel=axle%2
    start=round((event['impactSeconds']-value('KERNEL_LEAD'))*RATE)
    gain=value('KERNEL_GAIN')*GAINS[wheel]*(10**(value('DEFAULT_CLANG_BALANCE_DB')/20) if wheel else 1)*impact_scale*(3/distances[axle])*.5
    impacts[start:start+len(kernels[wheel])] += kernels[wheel]*gain
# The JS WAV writer multiplies by 32767; decoded dBFS uses 32768.
background=background.astype(np.float64)*(32767/32768)
impacts=impacts.astype(np.float64)*(32767/32768)
error=new-background-impacts
assert np.max(np.abs(error))<1/32768, 'Stem reconstruction must agree within one PCM step'

# The first 80 ms of the first axle excludes the second axle in BOTH clips.
start=round((.5-value('KERNEL_LEAD'))*RATE)
end=start+round(.080*RATE)
old_hit=old[start:end]
new_hit=(new-background)[start:end]
matched_roll=background[start:end]
fit=float(np.sum(old_hit*new_hit)/np.sum(old_hit*old_hit))
correlation=float(np.corrcoef(old_hit.ravel(),new_hit.ravel())[0,1])
f,old_power=psd(old_hit)
_,new_power=psd(new_hit)
_,roll_power=psd(matched_roll)
_,normalized_power=psd(new_hit/fit)
reliable=(f>=80)&(f<=8000)&(old_power>np.max(old_power)*1e-5)
shape_delta=10*np.log10(np.maximum(normalized_power[reliable],1e-20)/old_power[reliable])

# Isolate the second axle too: remove the still-ringing first axle and background.
old_second=round(.6536*RATE)-round(value('KERNEL_LEAD')*RATE)
new_second=round((report['events'][1]['impactSeconds']-value('KERNEL_LEAD'))*RATE)
samples=end-start
first_basis=kernels[0]*value('KERNEL_GAIN')*GAINS[0]*.5*(32767/32768)
old_clang=old[old_second:old_second+samples]-first_basis[old_second-start:old_second-start+samples]
new_clang=(new-background)[new_second:new_second+samples]-first_basis[new_second-start:new_second-start+samples]*(impact_scale*3/distances[0])
clang_fit=float(np.sum(old_clang*new_clang)/np.sum(old_clang*old_clang))
_,clang_old_power=psd(old_clang)
_,clang_matched_power=psd(new_clang/clang_fit)
clang_reliable=(f>=80)&(f<=8000)&(clang_old_power>np.max(clang_old_power)*1e-5)
clang_difference=10*np.log10(clang_matched_power[clang_reliable]/clang_old_power[clang_reliable])

steady=slice(RATE,36*RATE)
fs,pimpact=psd(impacts[steady],hop=2048)
_,proll=psd(background[steady],hop=2048)
bands={}
for title,lo,hi in [('20–150 Hz',20,150),('150–1500 Hz',150,1500),('1500–8000 Hz',1500,8000)]:
    chosen=(fs>=lo)&(fs<hi)
    bands[title]={'impact_to_rolling_db':float(10*np.log10(np.sum(pimpact[chosen])/np.sum(proll[chosen])))}
result={
  'files':{p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'peak_dbfs':db(np.max(np.abs(x))),'rms_dbfs_whole_file':db(rms(x))} for p,x in [(old_path,old),(new_path,new)]},
  'matched_first_axle_80ms':{'old_rms_dbfs':db(rms(old_hit)),'new_impact_rms_dbfs':db(rms(new_hit)),'new_rolling_rms_dbfs':db(rms(matched_roll)),
      'impact_change_db':db(fit),'level_matched_correlation':correlation,'level_matched_median_abs_spectral_difference_db':float(np.median(np.abs(shape_delta)))},
  'per_axle_gain_change_db_vs_dry_reference':[db(impact_scale*3/d) for d in distances],
  'matched_second_axle_80ms':{'impact_change_db':db(clang_fit),'level_matched_correlation':float(np.corrcoef(old_clang.ravel(),new_clang.ravel())[0,1]),
      'level_matched_median_abs_spectral_difference_db':float(np.median(np.abs(clang_difference)))},
  'new_steady_1_to_36_seconds':{'impact_rms_dbfs':db(rms(impacts[steady])),'rolling_rms_dbfs':db(rms(background[steady])),
      'impact_to_rolling_db':db(rms(impacts[steady])/rms(background[steady])),'bands':bands},
  'within_bogie_impact_interval_ms':{'old':153.6,'new':92.16},
  'stem_reconstruction_max_error_dbfs':db(np.max(np.abs(error))),
  'method':'Stereo power averaged without mono downmix; matched first-axle 80 ms window before second axle; Hann Welch 2048 samples / 512 hop. Rolling stem reconstructed from the exact preview recipe and verified against PCM. No claim of equal subjective loudness from whole-file RMS.'
}
fixed_path=OUT/'lhb-one-coach-1km-jointed-26m-100kmh-reference-mix.wav'
if fixed_path.exists():
    fixed=read_wav(fixed_path)
    fixed_background=background*10**(-12/20)
    fixed_hit=(fixed-fixed_background)[start:end]
    fixed_fit=float(np.sum(old_hit*fixed_hit)/np.sum(old_hit*old_hit))
    assert abs(db(fixed_fit))<.01
    result['corrected_preview']={'first_axle_level_change_vs_preferred_db':db(fixed_fit),
      'rolling_change_db':-12,'steady_impact_to_rolling_db':db(rms((fixed-fixed_background)[steady])/rms(fixed_background[steady])),
      'peak_dbfs':db(np.max(np.abs(fixed)))}
(OUT/'spectrum-comparison.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
np.savetxt(OUT/'matched-axle-spectrum.csv',np.column_stack((f,old_power,new_power,roll_power,normalized_power)),delimiter=',',header='Hz,original_PSD,new_impact_PSD,new_rolling_PSD,new_level_matched_PSD',comments='')

plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.titlesize':12,'axes.spines.top':False,'axes.spines.right':False})
fig,axs=plt.subplots(2,2,figsize=(13,8.7),layout='constrained')
fig.suptitle('Why the longer preview loses its cling–clang prominence',fontsize=17,fontweight='bold')
a=axs[0,0]
for p,label,color in [(old_power,'Preferred: dry first axle','#2463ac'),(new_power,'New: same axle, rolling removed','#d75936'),(roll_power,'New: rolling background','#999999')]:
    a.semilogx(f[1:],10*np.log10(np.maximum(p[1:],1e-15)),label=label,color=color,lw=1.8)
a.set(title='Same first axle • identical 80 ms window',xlabel='Frequency (Hz)',ylabel='Power spectral density (dBFS/Hz)',xlim=(40,10000),ylim=(-125,-45))
a.grid(alpha=.2); a.legend(fontsize=8,loc='lower left')
a.text(.97,.95,f'Impact reduced by {abs(db(fit)):.1f} dB',ha='right',va='top',transform=a.transAxes,color='#ae4023',fontweight='bold')
a=axs[0,1]
a.semilogx(f[1:],10*np.log10(np.maximum(old_power[1:],1e-15)),label='Preferred first axle',color='#2463ac',lw=2.4)
a.semilogx(f[1:],10*np.log10(np.maximum(normalized_power[1:],1e-15)),label='New impact, level matched',color='#d75936',ls='--',lw=1.4)
a.set(title='After matching impact level: spectra coincide',xlabel='Frequency (Hz)',ylabel='Power spectral density (dBFS/Hz)',xlim=(40,10000),ylim=(-125,-45))
a.grid(alpha=.2);a.legend(fontsize=8,loc='lower left')
for a,x,label in [(axs[1,0],old,'Preferred • 60 km/h • four impacts, no rolling'),(axs[1,1],new,'New • 100 km/h • continuous rolling + impacts')]:
    ts,freq,power=spectrogram(x[:2*RATE])
    chosen=(freq>=80)&(freq<=10000)
    mesh=a.pcolormesh(ts,freq[chosen],power[chosen],shading='auto',vmin=-110,vmax=-45,cmap='magma')
    a.set(title=label,xlabel='Time (seconds)',ylabel='Frequency (Hz)',xlim=(0,2),ylim=(80,10000),yscale='log')
fig.colorbar(mesh,ax=axs[1,:],label='Same colour scale: dBFS/Hz',shrink=.9,pad=.02)
fig.savefig(OUT/'spectrum-comparison.png',dpi=170)
plt.close(fig)
print(json.dumps(result,indent=2))
