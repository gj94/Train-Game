// Canonical sound-lab source; mirrored in train-game/tools/audio-source.
// Short loose-panel / latch resonances, not a rail-joint or a squealing wheel.
export const RATE = 48000;
export const COUNT = 8;
export function random(seed) {
  let state = seed >>> 0;
  return () => { state = (Math.imul(state, 1664525) + 1013904223) >>> 0; return state / 4294967296; };
}
export function synthesizeRattle(variant, rate = RATE) {
  if (!Number.isInteger(variant) || variant < 0 || variant >= COUNT) throw Error('Invalid rattle variant');
  const rng = random(89173 + variant * 977);
  const samples = new Float32Array(Math.round(rate * .38));
  const modes = [235, 417, 693, 1063, 1727, 2591].map((hz, i) => ({
    hz: hz * (.87 + .26 * rng()), decay: (.018 + .055 * rng()) / (1 + i * .12),
    gain: (.17 + .08 * rng()) / (1 + i * .48), phase: rng() * Math.PI * 2,
  }));
  const taps = [[0, 1], [.027 + rng() * .030, .35 + rng() * .24], [.08 + rng() * .06, .17 + rng() * .18]];
  let previousNoise = 0;
  for (let i = 0; i < samples.length; i++) {
    const time = i / rate;
    let sample = 0;
    for (const [onset, strength] of taps) {
      const t = time - onset;
      if (t < 0) continue;
      const attack = 1 - Math.exp(-t / .0018);
      for (const mode of modes) sample += strength * mode.gain * attack * Math.exp(-t / mode.decay) * Math.sin(2 * Math.PI * mode.hz * t + mode.phase);
    }
    const noise = rng() * 2 - 1;
    sample += (noise - previousNoise) * .020 * (1 - Math.exp(-time / .001)) * Math.exp(-time / .045);
    previousNoise = noise;
    samples[i] = sample * Math.min(1, (samples.length - i - 1) / (rate * .015));
  }
  return samples;
}

export function wav(samples) {
  const b = Buffer.alloc(44 + samples.length * 2);
  b.write('RIFF'); b.writeUInt32LE(b.length - 8, 4); b.write('WAVEfmt ', 8);
  b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(RATE, 24); b.writeUInt32LE(RATE * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(samples.length * 2, 40);
  samples.forEach((s, i) => { if (!Number.isFinite(s) || Math.abs(s) >= 1) throw Error('Invalid/clipped PCM'); b.writeInt16LE(Math.round(s * 32767), 44 + i * 2); });
  return b;
}
