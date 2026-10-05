"""Measure an offline reference/reconstruction pair; no sound assets are changed."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.local/analysis-python'))
os.environ['MPLCONFIGDIR'] = str(ROOT / '.local/matplotlib-config')
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument('prefix', type=Path)
parser.add_argument('--title', default='Offline match • recorded passage 00:55–01:00')
args = parser.parse_args()
prefix = args.prefix.resolve()
RATE = 44100


def read(suffix):
    path = Path(str(prefix) + suffix)
    with wave.open(str(path), 'rb') as w:
        assert w.getframerate() == RATE and w.getnchannels() == 2 and w.getsampwidth() == 2
        samples = np.frombuffer(w.readframes(w.getnframes()), '<i2').reshape(-1, 2).astype(float) / 32768
    return samples, hashlib.sha256(path.read_bytes()).hexdigest()


def stft(x, n=1024, hop=128):
    window = np.sin(np.pi * (np.arange(n) + .5) / n)
    frames = np.lib.stride_tricks.sliding_window_view(x, n, axis=0)[::hop]
    spectrum = np.fft.rfft(frames * window, axis=-1)
    power = np.mean(abs(spectrum) ** 2, axis=1) / (RATE * np.sum(window ** 2))
    power[:, 1:-1] *= 2
    return (np.arange(len(frames)) * hop + n / 2) / RATE, np.fft.rfftfreq(n, 1 / RATE), power


def db(x):
    return 20 * np.log10(np.maximum(x, 1e-12))


def rms(x):
    return float(np.sqrt(np.mean(x * x)))


def envelope(x):
    count = len(x) // 441
    return np.sqrt(np.mean(x[:count * 441].reshape(count, 441, 2) ** 2, axis=(1, 2)))


reference, ref_hash = read('-reference.wav')
synthetic, synth_hash = read('-synthetic.wav')
assert reference.shape == synthetic.shape
ab, ab_hash = read('-AB.wav')
gap = round(.75 * RATE)
assert len(ab) == len(reference) * 2 + gap
assert np.array_equal(ab[:len(reference)], reference)
assert np.count_nonzero(ab[len(reference):len(reference) + gap]) == 0
assert np.array_equal(ab[len(reference) + gap:], synthetic)

t, f, pa = stft(reference)
_, _, pb = stft(synthetic)
bands = [('80–350 Hz', 80, 350), ('350–1500 Hz', 350, 1500), ('1500–6000 Hz', 1500, 6000)]
band_results = {}
for label, low, high in bands:
    mask = (f >= low) & (f < high)
    ea = np.sqrt(pa[:, mask].sum(axis=1))
    eb = np.sqrt(pb[:, mask].sum(axis=1))
    la, lb = db(ea), db(eb)
    band_results[label] = {
        'envelope_correlation': float(np.corrcoef(ea, eb)[0, 1]),
        'energy_difference_db': float(10 * np.log10(pb[:, mask].sum() / pa[:, mask].sum())),
        'reference_transient_contrast_db': float(np.percentile(la, 95) - np.percentile(la, 50)),
        'synthetic_transient_contrast_db': float(np.percentile(lb, 95) - np.percentile(lb, 50)),
    }

# Validate spectral shape at a second, longer analysis resolution too.
_, f2, p2a = stft(reference, n=4096, hop=512)
_, _, p2b = stft(synthetic, n=4096, hop=512)
third_octaves = []
for centre in 100 * 2 ** (np.arange(20) / 3):
    mask = (f2 >= centre / 2 ** (1 / 6)) & (f2 < centre * 2 ** (1 / 6))
    if mask.any():
        third_octaves.append({'centre_hz': float(centre), 'error_db': float(10 * np.log10(p2b[:, mask].sum() / p2a[:, mask].sum()))})

result = {
    'seconds': len(synthetic) / RATE,
    'level_difference_db': float(db(rms(synthetic) / rms(reference))),
    'stereo_energy_envelope_correlation_10ms': float(np.corrcoef(envelope(reference), envelope(synthetic))[0, 1]),
    'reference_peak_dbfs': float(db(np.max(abs(reference)))),
    'synthetic_peak_dbfs': float(db(np.max(abs(synthetic)))),
    'sample_correlation': float(np.corrcoef(reference.ravel(), synthetic.ravel())[0, 1]),
    'bands': band_results,
    'third_octave_rms_error_db': float(np.sqrt(np.mean([b['error_db'] ** 2 for b in third_octaves]))),
    'third_octave_errors': third_octaves,
    'hashes': {'reference': ref_hash, 'synthetic': synth_hash, 'ab': ab_hash},
    'ab_verified': True,
    'note': 'Objective checks on this fitted excerpt, not a perceived-similarity score or proof of physical axle timing. The synthesized phases differ from the recording.',
}
Path(str(prefix) + '-verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')

plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False})
fig, axs = plt.subplots(3, 1, figsize=(12, 9), layout='constrained')
fig.suptitle(args.title, fontsize=16, fontweight='bold')
for i, (label, low, high) in enumerate(bands[1:]):
    mask = (f >= low) & (f < high)
    axs[i].plot(t, db(np.sqrt(pa[:, mask].sum(axis=1) * (f[1] - f[0]))), color='#24364b', lw=1.5, label='Reference')
    axs[i].plot(t, db(np.sqrt(pb[:, mask].sum(axis=1) * (f[1] - f[0]))), color='#d05e28', lw=1, alpha=.85, label='Reconstruction')
    axs[i].set(xlim=(0, len(reference) / RATE), xlabel='Seconds within the selected passage', ylabel='Band RMS (dBFS)', title=f'{label} • measured impact envelope')
    axs[i].grid(alpha=.2)
    axs[i].legend(loc='lower right')
for power, label, color in [(p2a, 'Reference', '#24364b'), (p2b, 'Reconstruction', '#d05e28')]:
    spectrum = np.convolve(power.mean(axis=0), np.ones(7) / 7, mode='same')
    axs[2].semilogx(f2[1:], 10 * np.log10(np.maximum(spectrum[1:], 1e-15)), label=label, color=color, lw=1.3)
axs[2].set(xlim=(80, 8000), ylim=(-105, -35), xlabel='Frequency (Hz)', ylabel='Power (dBFS/Hz)', title='Average spectrum • same presentation gain for both takes')
axs[2].grid(alpha=.2)
axs[2].legend()
fig.savefig(str(prefix) + '-comparison.png', dpi=140)
plt.close(fig)
print(json.dumps(result, indent=2))

assert np.max(abs(synthetic)) < .99, 'Clipping/headroom check failed'
assert abs(result['level_difference_db']) < .1, 'RMS levels differ'
assert result['stereo_energy_envelope_correlation_10ms'] > .97, 'Envelope fit needs further work'
assert result['third_octave_rms_error_db'] < 1.0, 'Spectrum fit needs further work'
