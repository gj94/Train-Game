"""Compare manually reviewed wheel crossings with timestamp-preserved video audio.

Inputs are generated from TrainVideo.mp4 under .local/video-reference. Audio must
be decoded with aresample=async=1000:min_hard_comp=0.001:first_pts=0 to retain the
33.333 ms timestamp gap following its first AAC frame. No game data is edited.
"""
from pathlib import Path
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

OUT = ROOT / '.local/video-reference'
# One-based decoded frame numbers, visually inspected in nine contact sheets.
# Mark the closest visible tread-centre crossing; uncertainty is at least one frame.
# These label near-side wheel passages, not every sound transient in the clip.
FRAMES = [4, 8, 16, 20, 40, 43, 51, 55, 75, 79, 87, 91,
          110, 114, 122, 126, 145, 149, 157, 161, 181, 185,
          192, 197, 216, 220, 228, 232]
times = [float(x.strip().strip(',')) for x in (OUT / 'frame-times.csv').read_text(encoding='utf-8-sig').splitlines() if x.strip().strip(',')]
visual = np.array([times[i - 1] for i in FRAMES])
with wave.open(str(OUT / 'TrainVideo-audio-clocked.wav'), 'rb') as w:
    rate = w.getframerate()
    assert rate == 44100 and w.getnchannels() == 2 and w.getsampwidth() == 2
    audio = np.frombuffer(w.readframes(w.getnframes()), '<i2').reshape(-1, 2).astype(float) / 32768
assert abs(len(audio) / rate - 8.160317) < 1 / rate
n, hop = 1024, 64
window = np.hanning(n)
blocks = np.lib.stride_tricks.sliding_window_view(audio, n, axis=0)[::hop]
power = np.mean(abs(np.fft.rfft(blocks * window, axis=-1)) ** 2, axis=1)
freq = np.fft.rfftfreq(n, 1 / rate)
t = (np.arange(len(blocks)) * hop + n / 2) / rate
attack = np.sqrt(power[:, (freq >= 1500) & (freq < 6000)].sum(axis=1))
# Find the shared alignment against all 28 reviewed contacts, rather than assuming
# that the strongest peak at the same video timestamp is the corresponding hit.
offsets = np.arange(-.35, .351, .001)
scores = [np.mean(np.interp(visual + offset, t, attack, left=0, right=0)) for offset in offsets]
best = float(offsets[np.argmax(scores)])
peak_times = []
for contact in visual:
    indices = np.flatnonzero(abs(t - contact - best) <= .045)
    at = indices[np.argmax(attack[indices])]
    peak_times.append(float(t[at]))
peaks = np.array(peak_times)
assert len(np.unique(peaks)) == len(visual), 'Two wheel labels matched the same audio peak'
lags = peaks - visual
within_pair = peaks[1::2] - peaks[::2]
pair_starts = peaks[::2]
start_intervals = np.diff(pair_starts)
events = [{'wheel': i + 1, 'bogie_group': i // 2 + 1, 'wheel_in_group': i % 2 + 1,
           'reviewed_frame': frame, 'visual_time_s': float(v),
           'matched_attack_peak_s': float(p), 'attack_peak_minus_visual_s': float(p - v)}
          for i, (frame, v, p) in enumerate(zip(FRAMES, visual, peaks))]
result = {
    'source': 'TrainVideo.mp4', 'source_sha256': hashlib.sha256((ROOT / 'TrainVideo.mp4').read_bytes()).hexdigest(),
    'video_frames': len(times), 'frame_rate': 30, 'visual_uncertainty_seconds': 1 / 30,
    'near_side_wheel_crossings': len(visual), 'two_axle_groups': len(visual) // 2,
    'observed_joint_locations': 'One fixed track joint location, with gaps visible in both rails.',
    'source_speed_kmh': None, 'source_coach_type': None,
    'audio_timestamp_gap_preserved_s': 1470 / 44100,
    'audio_attack_peak_minus_visual_median_s': float(np.median(lags)),
    'alignment_residual_rms_s': float(np.sqrt(np.mean((lags - np.median(lags)) ** 2))),
    'within_bogie_attack_peak_interval_median_s': float(np.median(within_pair)),
    'within_bogie_attack_peak_interval_range_s': [float(within_pair.min()), float(within_pair.max())],
    'alternating_pair_start_intervals_median_s': [float(np.median(start_intervals[::2])), float(np.median(start_intervals[1::2]))],
    'four_wheel_pattern_repeat_median_s': float(np.median(pair_starts[2:] - pair_starts[:-2])),
    'events': events,
    'notes': [
        'Visual labels are manually reviewed frame estimates. Audio times are energy peaks, not exact mechanical contact or attack-onset times.',
        'The apparent audio/video lag may include encoding/editing, propagation and attack rise time; its cause is not established.',
        'This is a trackside passing-train view. It cannot establish spacing between successive joints or inherit the other MP3 speed.',
        'No new joint spacing, axle geometry, recorded train type, or invariant second-axle pitch/level is inferred.',
    ],
}
aligned_path = OUT / 'joint-video-v3-aligned-check.wav'
if aligned_path.exists():
    with wave.open(str(aligned_path), 'rb') as w:
        assert w.getframerate() == rate and w.getnchannels() == 2
        aligned = np.frombuffer(w.readframes(w.getnframes()), '<i2').reshape(-1, 2).astype(float) / 32768
    frames = np.lib.stride_tricks.sliding_window_view(aligned, n, axis=0)[::hop]
    aligned_power = np.mean(abs(np.fft.rfft(frames * window, axis=-1)) ** 2, axis=1)
    aligned_attack = np.sqrt(aligned_power[:, (freq >= 1500) & (freq < 6000)].sum(axis=1))
    aligned_t = (np.arange(len(frames)) * hop + n / 2) / rate
    expected = peaks - float(np.median(lags))
    observed = []
    for target in expected:
        candidates = np.flatnonzero(abs(aligned_t - target) <= .025)
        observed.append(float(aligned_t[candidates[np.argmax(aligned_attack[candidates])]]))
    error = np.array(observed) - expected
    visual_error = np.array(observed) - visual
    assert np.max(abs(error)) < .01, 'Muxed audio does not preserve the intended alignment'
    assert np.max(abs(visual_error)) < 1 / 30, 'Aligned peaks exceed visual frame uncertainty'
    result['aligned_preview_verification'] = {
        'audio_advanced_seconds': float(np.median(lags)),
        'matched_peaks': len(observed),
        'max_error_vs_shifted_reference_peaks_seconds': float(np.max(abs(error))),
        'max_error_vs_manual_visual_frames_seconds': float(np.max(abs(visual_error))),
        'note': 'Checked after decoding the remuxed preview AAC, including encoder delay handling.',
    }
(OUT / 'joint-contact-analysis.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False})
fig, axs = plt.subplots(2, 1, figsize=(13, 7), layout='constrained')
fig.suptitle('One fixed joint • 28 visible wheel passages • TrainVideo.mp4', fontsize=15, fontweight='bold')
level = 20 * np.log10(np.maximum(attack / attack.max(), 1e-8))
for ax, limits in zip(axs, [(0, 8.16), (0, 2.3)]):
    ax.plot(t, level, color='#2c3949', lw=1.1, label='Recorded 1.5–6 kHz energy')
    for i, (v, p) in enumerate(zip(visual, peaks)):
        ax.axvline(v, color='#278ac2', lw=1, alpha=.8, label='Visual crossing (±1 frame)' if i == 0 else None)
        ax.axvline(p, color='#d36b2d', lw=1, ls='--', alpha=.8, label='Associated audio peak' if i == 0 else None)
        if limits[0] <= v <= limits[1]:
            ax.text(v, 1, str(i + 1), color='#278ac2', fontsize=8, ha='center')
    ax.set(xlim=limits, ylim=(-35, 4), xlabel='Container timeline (seconds)', ylabel='Relative band level (dB)')
    ax.grid(alpha=.15)
axs[0].legend(loc='lower right', fontsize=8)
axs[1].set_title(f'First eight wheels • audio peaks follow frame estimates by a median {np.median(lags) * 1000:.0f} ms')
fig.savefig(OUT / 'joint-contact-analysis.png', dpi=145)
plt.close(fig)
print(json.dumps({k: v for k, v in result.items() if k != 'events'}, indent=2))
