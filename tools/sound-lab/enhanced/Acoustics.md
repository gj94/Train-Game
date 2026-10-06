# Railway acoustics — train-game porting guide

Implementation baseline: 6 October 2026. This document describes the working **BODY V2** impact engine, rolling/rushing bed, onboard balance, conventional turnouts and curve squeal. It is intended for an audio/game programmer porting the behavior into an engine with a physics clock, an audio clock and spatial sound sources.

The first red LHB train in `../MultipleTrainsTrackside.mp4`, especially 00:15–00:35, supplied the impact/rolling spectral calibration. The owner approved the impact sound at **71.6 km/h**. Preserve that baseline before changing the mix. Curve squeal now uses measured spectral statistics from the separate `../SquealingTrain.mp4` benchmark. Its curvature-to-strength mapping, turnout strengths and cab/doorway response remain perceptual models, not field-calibrated transfer functions.

## 1. What to take into the game

| File | Responsibility |
| --- | --- |
| `public/model.js` | Consist geometry, stable axle identities, joints, listener positions, contact/arrival times |
| `public/turnouts.js` | Selected route, signed curvature, per-rail turnout contacts |
| `public/audio.js` | Impact routing, reference bank decoding, receiver balance, rolling bed, master output |
| `public/squeal.js` | Curvature demand/color, moving squeal sources, four synthesized spectral loops, voice lifecycle |
| `public/squeal-profile.js` | Required compact power-density table fitted to SquealingTrain; contains no recorded samples |
| `public/squeal-fit.json`, `public/squeal-spectrum.png` | Fit windows, validation measurements and spectrum comparison |
| `scripts/analyze-squeal.py`, `scripts/fit-squeal-spectrum.py`, `scripts/validate-squeal-fit.py` | Inspect video, fit power statistics and independently check actual JS-generated PCM |
| `public/app.js` | Audio-clock scheduling, pause/seek/reset, controls and heard-event visualization |
| `public/synthesis/impact-0.wav` … `impact-7.wav` | Eight required, synthesized impact kernels |
| `public/synthesis/rolling-bed.wav` | Required continuous rolling/rushing bed |
| `public/synthesis/spectral-fit.json` | Calibration measurements and kernel time origin |
| `scripts/fit-impact-spectrum.py` | Offline fit/regeneration; unnecessary for runtime |
| `tests/*.test.mjs` | Executable timing, routing, geometry, mix, squeal and server contracts |
| [TURNOUT-MODEL.md](TURNOUT-MODEL.md) | Engineering basis and limits of the point layout |

The Node server and Three.js renderer are demonstration infrastructure. A game needs the models, audio assets and scheduling behavior, not Node, the video or a browser. Source-only backups deliberately omit generated assets: **a source-only archive alone cannot reproduce BODY V2**. Supply the nine WAV files separately, or regenerate them from the reference analysis.

Import the WAVs as mono, with normalization, random pitch, automatic loudness matching and lossy compression disabled for the initial comparison. Allow quality sample-rate conversion if the engine runs at 44.1 kHz. Preserve the full kernel, including its pre-contact attack. The `bankGain` in the JSON report was already applied when writing the WAVs; do not multiply by it again.

## 2. Coordinates, geometry and identity

Distances are metres; times are seconds; frequencies are hertz. UI speed is km/h, converted once to `v = speed / 3.6` in m/s. The right-handed scene uses +Y up, +X along the canonical track direction and +Z toward the platform. A centreline tangent is `(tx, 0, tz)` and its lateral normal is `(-tz, 0, tx)`. Convert positions, tangents, normals and listener orientation together when adapting to another engine's axes or centimetre units.

| Quantity | Baseline |
| --- | ---: |
| LHB length over couplers / modeled body length | 24 / 23.54 m |
| LHB bogie-centre spacing / axle wheelbase | 14.9 / 2.56 m |
| LHB wheel radius | 0.4575 m |
| Locomotive length / body length | 20.56 / 20.2 m |
| Locomotive bogie centres behind nose | 4.78 and 15.78 m |
| Locomotive axles within each bogie | centre −1.85, centre, centre +1.85 m |
| Gauge / adjoining-track centres | 1.676 / 5.1 m |
| Default consist | Co-Co loco + 20 coaches: 42 bogies, 86 axles |
| Speed of sound | 343 m/s |

LHB dimensions are based on the [South Central Railway carriage and wagon knowledge bank](https://scr.indianrailways.gov.in/uploads/files/1623859353046-Knowledge%20Bank.pdf). Locomotive dimensions, loads and consist length are modeling choices. There is an ICF profile in the source, but the exposed and calibrated experience is LHB.

Each axle has an immutable ID such as `L-B2-A3` or `C12-B1-A2`, plus its vehicle, bogie and axle indices, offset behind the nose, wheel radius and load multiplier. Code indices are zero-based except coach vehicle indices, which start at 1; visible bogie/axle numbers start at 1. Coach centre `c`, with `c=0` for coach 1, is `20.56 + (c + 0.5)*24`. Its axle offsets are centre ±7.45 ±1.28 m.

Load multipliers are 1.22 for locomotive axles and `0.9 + ((c*7 + b*3 + a) % 9)*0.025` for coach axles. They are variation gains, not forces in newtons. Retain stable identities through pooling, network updates and reversals; use them for sound variation and visual attribution.

## 3. Contact time is different from heard time

For this constant-speed demonstration, direction `D` is ±1 and the nose's route station is:

```text
headStation(t) = D * (-110 + v*t)
axleStation(t) = headStation(t) - D*axleOffset
contactTime   = (110 + axleOffset + D*jointStation) / v
```

Use distance **along the selected route**, `joint.s`, when available; `joint.x` is only the straight-track fallback. Projected world X is not distance around a curve. The within-bogie LHB interval at 71.6 km/h is 0.1287150838 s. Successive coach patterns recur every 1.20670391 s.

The event carries `axle`, `joint`, `time` (physical contact) and `arrival` (heard contact). Sort by arrival, then stable IDs. A distant earlier contact can arrive after a nearby later contact. The original platform calibration intentionally uses:

```text
arrival = contactTime + hypot(joint.x - 3.8, distanceSetting - joint.z) / 343
```

This two-dimensional platform propagation formula is retained for compatibility, even though spatial gain uses height. For onboard listeners, the source is the **stationary joint at Y=0.3**, while the receiver moves during flight:

```text
343 * delay = length(listener(contactTime + delay) - jointPosition)
arrival     = contactTime + delay
```

Straight onboard motion uses a stable quadratic solution. Let `r` be receiver-minus-source at contact, `u=(D*v,0,0)`, `a=343²-dot(u,u)`, `b=dot(r,u)` and `h=sqrt(b²+a*dot(r,r))`. Delay is `dot(r,r)/(h-b)` for `b<0`, otherwise `(b+h)/a`. Curved onboard motion uses 12 fixed-point iterations of the distance equation.

The audio listener follows the cab/doorway camera. Platform camera presets can shift the actual panning position slightly; the approved impact propagation timing continues to use the fixed platform station. A game may use one fully physical receiver position for both, but that changes baseline timing.

### Scheduling and changing speed

The browser uses `AudioContext.currentTime` as the playback clock, a 25 ms scheduler interval and 160 ms look-ahead. It skips events already more than 40 ms late. An impact's buffer begins **0.0213333 s before its heard contact**, clamped to the current audio time if necessary. UI flashes/logs use the heard contact itself, on that same clock. Output-device latency is additional.

Do not port the constant-speed event formula unchanged to an accelerating game. Query all contacts swept by each axle during a physics step, solve the crossing fraction or root on the selected track segment, then map that simulation time to the DSP clock. Detect multiple crossings within one frame. For predicted contacts, invalidate unsounded events when speed, route or consist changes. The short pre-contact portion needs reliable look-ahead; if a newly discovered contact is already too late, start immediately rather than delaying every subsequent axle to compensate.

The demo's direction selector mirrors a nose-leading consist. Actual game shunting can make the last axle physically leading: retain IDs but determine leading/trailing weights and doorway adjacency from actual travel direction.

## 4. BODY V2 impact synthesis and graph

BODY V2 is eight **new stochastic waveforms fitted to energy statistics**, not eight cuts of the video. The offline process holds the accepted rhythm fixed, uses a 2,048-sample STFT with 256-sample hop at 48 kHz, separates repeated impact power from a slowly changing bed, and resynthesizes with random initial phase and 36 spectrogram-consistency iterations. Local onset refinement helps the fit; it does not change the application's axle spacing. Broad spectral corrections and shared headroom are baked into the files.

```text
impact kernel, playback rate 1
  → axle load × passenger/cab correction
  → stationary joint bus: impact amount × contact strength × doorway gain
  → low shelf, 280 Hz
  → high shelf, 1,300 Hz
  → distance low-pass (except approved platform J0)
  → stationary spatial panner at the rail contact
  → master → compressor → output
```

Bank selection is `(vehicle*3 + bogie*2 + axleIndex + abs(jointId)*3) % 8`. Use the same choice for playback and energy-envelope calculations. Each kernel lasts 0.3413333333 s, so successive axle decays overlap naturally. Never truncate the preceding axle's body when the next axle arrives. **Impact pitch stays at 1 at every speed**: speed changes crossing times, not the kernel's spectral body.

For normalized slider values from 0 to 1:

| Parameter | Formula / value |
| --- | --- |
| Joint bus gain | `(jointStrength / 0.7) * contact.strength * doorwayGain` |
| Doorway gain | `sqrt(2)` for passenger, otherwise 1 |
| Body shelf | `(body - 0.5)*18 dB` at 280 Hz |
| Brightness shelf | `(ring - 0.5)*18 dB` at 1,300 Hz |
| Distance low-pass | `ceiling / (1 + max(0, distance - nearDistance)/22)` |
| Ceiling | 6,500 Hz in cab; 18,000 Hz elsewhere |
| Low-pass Q | 0.5 |
| Master | 0.65 by default; mute targets zero |
| Compressor | threshold −4 dB, knee 3 dB, ratio 4:1, attack 2 ms, release 150 ms |

For onboard filtering, distance is full 3D and `nearDistance=hypot(listenerLocalZ, listenerY-0.3)`. Platform filtering uses the legacy horizontal distance and `nearDistance=hypot(3.8, distanceSetting)`. Only platform J0 bypasses this low-pass. Body and brightness at 50% mean zero shelf gain.

Spatialization uses equal-power panning, inverse distance, reference distance 4 m and rolloff 1.2. The matching amplitude helper is:

```text
A(d) = 4 / (4 + 1.2*(max(4,d) - 4))
```

Apply this falloff once. In the website the panner applies it; manual calculations use it only for balance/selection. The panner's maximum distance is 600 m for platform J0, 1,600 m for other impact and squeal routes, and 600 m for rolling. Beyond maximum distance the engine behavior can differ; configure that explicitly in a port. Do not add automatic engine Doppler to stationary impact sources. Start with the same panning law before evaluating HRTF, occlusion or reverberation; each changes the approved spectrum.

## 5. Listener attachment and axle balance

Platform receiver: `(3.8, 2.73, distanceSetting)`, with 5.8 m default distance. Pilot: 1.8 m behind the nose, Y=3.15 m, lateral offset +0.68 m. Passenger: inside the chosen coach, 1.2 m inward from the front or rear body end, Y=3.18 m, lateral offset ±0.4 m. Front means toward the locomotive. On curves, mount the listener on the rigid body spanning its two bogie centres, rather than directly on the centreline at the doorway chainage.

The passenger mix raises impact buses by 3 dB. It also brings forward the **preceding bogie's last axle**, limited below the nearest bogie's leading axle. At a front doorway, that preceding bogie belongs to the previous vehicle; at a rear doorway, it is the same coach's front bogie. For coach 1's front doorway it is locomotive bogie 2, axle 3.

To calculate balance, split each decoded kernel into 32 equal-time bins. Store each bin's energy sum divided by the full buffer length and its time centre relative to contact (subtract 0.0213333 s). Estimate each axle's received body proxy:

```text
B(axle) = load * sqrt(sum(binEnergy * A(distanceAtArrivalPlusBinTime)^2))
passengerGain = min(10^(2/20), 0.95*B(nearLeading)/B(precedingLast))
cabGain      = clamp((B(locoLeading)/B(currentLocoAxle))^0.6, 1, 10^(8/20))
```

Only the selected preceding last axle receives `passengerGain`; it may be below 1 if already too prominent. Only locomotive axles other than the leading axle receive `cabGain`. The cab cap is +8 dB and preserves a quieter rear body in the modeled positions. Compare equivalent contacts at the same joint; their physical contact times differ by `(otherOffset-currentOffset)/v`.

This body proxy measures the complete bank envelope with distance, not a separately low-passed body signal. It omits low-pass energy loss and structural transmission. The corrections are listening-mix choices, not measured interior vibration-transfer functions. In a game with a proper carbody/acoustic transfer path, replace them deliberately and recheck the adjacent-bogie balance.

## 6. Continuous rolling and wind-like noise

One eight-second rolling-bed loop follows each bogie centre, at Y=0.7 m. Start the `i`th bogie's loop at `(i*0.731) % 8` seconds to avoid phase alignment. Let `w_i=A(distance_i)`:

```text
normalizer  = max(w_i) / max(0.001, sqrt(sum(w_i^2)))
speedRatio  = max(0, speedKmh) / 71.6
speedGain   = min(1.4, speedRatio^1.25)
hissShelfDb = clamp(15*log10(max(0.001,speedRatio)), -24, 0)
voiceGain   = (rumble/0.55) * normalizer * speedGain
```

The hiss control is a 900 Hz high shelf before each voice's gain and panner. It reduces low-speed rushing without thinning the impact kernels. At 30 km/h the bed is about 9.4 dB below reference and its upper band about 15.1 dB below; at 10 km/h those figures are about 21.4 and 34.2 dB. At rest the bed is silent. At 71.6 km/h both corrections are neutral.

This file includes broad wind-like/rushing texture; there is no independent aerodynamic wind solver or weather system. If the game already generates wind, avoid doubling that texture. The normalizer approximates uncorrelated sources but all bogies share offset copies of one bed, so it is not an exact measured power model.

For platform rolling noise, `pitch = 343/(343 + 0.3*radialSourceVelocity)`. The factor 0.3 is an intentionally modest artistic Doppler. Onboard rolling pitch is 1. Smooth gain changes with a 35 ms exponential time constant and source positions with 8 ms onboard / 40 ms platform constants. Do not pitch the rolling layer directly in proportion to train speed.

## 7. Ordinary joints and points

The demonstration renders ±800 m of track. Jointed track has 13 m panels (123 open joints); SWR has 39 m panels (41 open joints). Internal 13 m welds in an SWR panel do not get gap impacts. Single-joint reference mode keeps only J0. These presets follow the representative arrangements described in [CAMTECH's September 2024 Track Maintainer Handbook, Part VI](https://nfr.indianrailways.gov.in/railwayboard/uploads/directorate/eff_res/camtech/Civil%20Engineering/YearWise/Handbook%20on%20Induction%20Course%20%28Track%20Maintainer%29%20Part%20%E2%80%93%20VI%20Long%20and%20Short%20Welded%20Rails%E2%80%9D%281%29.pdf); they are not a claim that all Indian routes use these gaps.

At the default platform position the next 39 m joint is about 14 dB quieter than J0 before filtering, but it is still modeled. Onboard listeners repeatedly approach different joints. A port must use the game track's actual joint/weld metadata rather than attach a repeating click to the listener or play only one joint globally.

The current turnout preset is conventional 1:12, 60 kg rail, CMS crossing, with nominal 441.36 m curve radius. Straight routing traverses one point; the crossover traverses two opposing points and a diagonal. Full geometry, engineering sources and assumptions are in [TURNOUT-MODEL.md](TURNOUT-MODEL.md). The following strengths are audio tuning values, not measured forces:

| Contact, facing-direction chainage | Gain relative to one reference axle/joint |
| --- | ---: |
| Stock rail entry, 0 m, left/right separately | 0.5 each |
| Switch transfer, 6.944 m | 0.12 |
| Stock / tongue heel, 13 / 13.5 m | 0.58 / 0.62 |
| Lead welds, 26 / 26.5 m | 0.045 each |
| CMS entry, 35.6 m | 0.68 |
| Actual crossing nose, 37.298 m | 1.05 |
| CMS exit / outer exit, 39.95 / 39.975 m | 0.68 / 0.58 |

Each point has 11 contacts per axle: seven rail-interface contacts, one nose transfer, one switch transfer and two quiet welds. A crossover has 22, or 1,892 for the default train. Every turnout event identifies the affected rail/wheel and gets its own stationary source offset ±0.838 m from the centreline. Ordinary periodic joints inside an assembly are removed to prevent double strikes. The second point mirrors the first; reverse traversal reverses event order. Check rails are not assigned invented vertical gap impacts.

All these contacts currently reuse BODY V2 with different gains. A welded turnout or movable crossing may need a different contact list and different kernels. Neither the nose response spectrum nor the assumed lead-weld and switch-transfer locations have been independently measured here.

## 8. Curve squeal

Unstable tangential wheel/rail forces associated with creepage can excite wheel vibration modes. This is the basis for the separate tonal layer; see [Hsu et al., 2007, *Experimental and theoretical investigation of railway wheel squeal*](https://journals.sagepub.com/doi/10.1243/0954409JRRT85). That research includes friction, vehicle and wheel/track dynamics. The lightweight implementation here approximates audible behavior and does not solve those dynamics.

### Curvature and demand

`routeCurvature(station, settings)` returns signed horizontal curvature in 1/m: −1/441.36 on the crossover's first arc, +1/441.36 on the return arc, zero on the diagonal and outside the arcs. Straight-through running stays silent in this layer. The switch-entry tangent has a small geometric angle step; it does not get a false infinite-curvature squeal impulse.

Evaluate curvature under **each axle**, not just the vehicle centre. The current model produces one voice per bogie, using a weighted mean: 0.7 for its leading axle, with 0.3 shared by the remaining axle(s). Coach rigid wheelbase is 2.56 m; locomotive outer-axle span is 3.7 m. For `S(a,b,x) = u²*(3−2u)` with `u=clamp((x−a)/(b−a),0,1)`:

```text
creepProxy = abs(weightedCurvature) * wheelbase / 2
demand = S(0.0004, 0.006, creepProxy)
       * S(0.35, 2.5, abs(speedMS))
       * (0.55 + 0.45*(1-exp(-abs(speedMS)/5)))
       * clamp(frictionMultiplier, 0, 1)
```

`frictionMultiplier` defaults to 1 in the pure helper and is not exposed in this website. It is an artistic suppression factor, not a physical friction coefficient. Curvature is a proxy for contact instability; thresholds, weights and mode levels are tuning choices. A stronger game physics system should feed angle of attack, lateral creepage, wheel load, contact condition and measured mode excitation instead. Do not assume every real curve necessarily squeals, or apply a generic “wet rails” multiplier without calibration.

Bogies have deterministic, different intermittent envelopes. For phase `phi=((vehicle*37 + bogieIndex*17)%97)/97 * 2π` and emission time `t`:

```text
instability = 0.7 + 0.3*S(-0.45, 0.6,
              0.65*sin(2π*0.73*t + phi) + 0.35*sin(2π*1.19*t - 0.7*phi))
level = demand * instability
```

Source position follows the inner wheel of the axle with the largest `abs(curvature)*weight`, at Y=0.35 m. Thus the rear axle can sustain squeal briefly after the leading axle straightens. Inner rail is the signed-curvature side of the canonical tangent, irrespective of traversal direction. This source choice is a localization approximation, not proof that all real squeal radiates from that wheel. For very short opposing curves, averaging signed curvature can cancel demand; evaluate wheel contacts independently if the game needs that case.

### Timbre and voice management

The earlier three-tone implementation has been replaced by **SquealingTrain-fitted spectral synthesis**. Frame inspection shows successive curved and straighter sections from an onboard viewpoint. Persistent broad upper-frequency ridges coincide with the curved passages. Brief lower harmonic bursts near 50, 69 and 113–117 seconds were treated as likely horns and excluded; intro/outro and possible voices were also avoided. This is a reasoned source selection, not perfectly isolated wheel audio. The frames do not establish surveyed radius or speed, and this is a different train from the original LHB impact reference.

Training windows in seconds are 6–14, 18–26, 57–61, 64–67, 98–102, 106–109, 135–139 and 142–144. Held-out checks use 14–18, 61–64, 102–106 and 139–142. Background estimates use 32–38, 73–78 and 151–169. The 44.1 kHz stereo source is decoded to mono and analyzed at 24 kHz. A 32,768-sample Welch spectrum gives 0.7324 Hz bin spacing. The fitter subtracts the median background power, clamps to zero, smooths by 4 Hz and tapers to zero outside 2,250–7,600 Hz. The lower band therefore stays with BODY V2/rolling rather than importing horn-like tones into squeal.

| Persistent mode region | Calibration band | Peak of 4 Hz-smoothed fit | Fraction of fitted squeal power |
| --- | --- | ---: | ---: |
| 2.67 kHz | 2,450–2,850 Hz | 2,668.95 Hz | 3.07% |
| 3.62 kHz | 3,400–3,950 Hz | 3,621.09 Hz | 17.16% |
| 4.56–4.61 kHz, multiple nearby peaks | 4,350–5,000 Hz | 4,562.99 Hz | 23.55% |
| 5.56 kHz | 5,250–5,900 Hz | 5,557.62 Hz | 17.57% |
| 6.55–6.67 kHz, broad ridge | 6,200–7,050 Hz | 6,604.98 Hz | 26.08% |

The remaining power lies between or outside these five reporting bands, within the tapered profile. Retain that texture: replacing these regions with isolated sine oscillators loses the recorded roughness. Peak labels depend on smoothing when adjacent maxima are close; they are not five exact stationary sinusoidal frequencies.

The compact profile in `public/squeal-profile.js` stores normalized power density every 6 Hz. `synthesizeSqueal()` generates four new random-phase, conjugate-symmetric spectra and performs an inverse FFT. No video samples or phase are copied. For sample rate `Fs`, choose `N=2^ceil(log2(4*Fs))`; bin `k` has magnitude `sqrt(PSD(k*Fs/N)*Fs*N/2)*0.11`. Phase comes from `seededRandom(8209 + variant*104729)`. The output RMS is 0.11 before source gains, an explicit mix choice rather than absolute SPL calibration. The measured fitted recording RMS was approximately 0.08715.

Each bank is periodic and lasts at least four seconds: 262,144 samples, or 5.4613 s at 48 kHz / 5.9443 s at 44.1 kHz. Four float banks use about 4 MiB. They are cached before crossover playback. Variants change phase only; the old ±9% pitch variation is removed. Bank index is `(vehicle*3 + bogieIndex)%4`; initial offset is positive-modulo `(emissionTime + bankIndex*0.731, actualBufferDuration)`. Preserve periodicity when exporting. The deterministic slow envelope above now has a 0.7 floor, replacing the old 0.22 floor; this approximates the reference's sustained texture and roughly 13.5% variability of its 120 ms envelope.

Curve sharpness changes gain through `squealDemand()` and spectral emphasis through a 4,800 Hz high shelf:

```text
relativeCreep = abs(weightedCurvature) * wheelbase / (2.56 / 441.36)
edgeDb = clamp(6*log2(max(0.001, relativeCreep)), -9, 3)
```

The existing 441.36 m LHB crossover is the neutral color anchor, **not an estimate of the benchmark video's radius**. Example model outputs at 30 km/h, before the intermittent envelope, user amount, distance and normalization:

| Curve radius | LHB demand | Upper-band shelf |
| ---: | ---: | ---: |
| Straight | 0 | Silent |
| 1,500 m, gentle | 0.0170 | −9 dB |
| 900 m | 0.0803 | −6.17 dB |
| 600 m | 0.2087 | −2.66 dB |
| 441.36 m, existing crossover | 0.3843 | 0 dB |
| 300 m, tighter | 0.7063 | +3 dB |
| 200 m, tight | 0.9150 | +3 dB |

These values are a bounded perceptual scaling law. The website's route geometry still uses its fixed-radius crossover; arbitrary radii are supported by the response functions for a game track provider. Do not change the route's stated radius just to turn up squeal. Smaller radii excite the existing spectrum more strongly; they do not transpose the frequency bands.

For continuous sources, compute **retarded emission time** at the current receiver time `t`:

```text
emission = t - distance(source(emission), listener(t))/343
```

The current implementation iterates eight times, then evaluates source position, level and distance there. Only candidates with `level*A(distance) > 0.0015` are considered; the 12 strongest are voiced. Normalize with `1/max(1, sqrt(sum(receivedCandidateLevel²)))`. This is a voice/mix bound, not an acoustic power prediction; it does not include the user amount or cab filtering when ranking.

```text
fitted spectral loop → gain → 4.8 kHz curve-color shelf → low-pass → moving inner-wheel panner → master
gain   = squealSlider * level * normalizer * (cab ? 0.85 : 1)
cutoff = (cab ? 3200 : 12000) / (1 + max(0,distance-4)/30)
```

Squeal uses the same inverse distance law; the panner supplies attenuation. Default slider is 0.6. Gain follows a 75 ms exponential time constant; release uses 55 ms, with source disposal after 300 ms. Position smoothing is 12 ms; cutoff/pitch smoothing 60 ms; curve-color smoothing 80 ms. Dropped voices can re-enter without an old voice's completion callback deleting the replacement. Pause, seek and consist reconfiguration stop active and releasing voices; banks remain cached. Setting the squeal amount to zero fades this layer independently.

Platform squeal has `pitch=343/(343+radialSourceVelocity)`; onboard pitch remains 1. Wheel-mode pitch is not directly tied to wheel revolutions or train speed. Engine Doppler must be disabled if applying these rates manually. Onboard relative Doppler is simplified to zero even across differently curving bogies, and loop phase after re-entry is deterministic rather than a complete integration of historic Doppler.

In the UI, teal rings mark the heard squeal-source positions, with the strongest bogies named under the slider. Gold flashes continue to identify discrete impact arrivals. The squeal voice state contains both bogie and dominant axle IDs for a game's visualization. Current sound only occurs on the existing curved crossover sections; to support arbitrary game curves, replace the route-specific lookup and `points==='diverge'` gate with actual track curvature/contact state.

## 9. Engine integration contract

Keep physics and audio separate, joined by timestamped data. Suggested engine-neutral records:

```text
Axle: immutable ID, vehicle/bogie indices, wheel contacts, world pose, velocity
TrackContact: ID, route/rail ID, station, world position, kind, strength
ImpactEvent: axle ID, contact ID, physical time, arrival time, bank, gain
ContinuousVoice: bogie ID, source pose, emission time, gain, cutoff, pitch
Listener: position, orientation, velocity, platform/cab/doorway context
```

One possible game loop, shown as pseudocode rather than a specific engine API:

```text
onPhysicsStep(previous, current):
    for each axle:
        for each contact swept on its selected route:
            crossing = solveAxleContactTime(previous, current, contact)
            arrival = solvePropagationToMovingListener(crossing, contact)
            queueUniqueImpact(axle.id, contact.id, traversalNumber, crossing, arrival)

onAudioControlUpdate(simulationTime):
    schedule queued impacts within the DSP look-ahead window
        use bufferStart = arrivalDSP - 0.0213333
        leave each stationary source alive through its decay
    update rolling positions, speed gain and shared normalization
    evaluate squeal from recent/predicted wheel trajectories and current receiver
    rank/virtualize moving voices, then smooth gains, filters and positions
    publish event arrival/voice state for visual feedback

onSeekOrRouteReplacement():
    cancel scheduled impacts and stale heard-event markers
    stop continuous voices and release tails
    rebuild crossing state and simulation-to-DSP clock mapping
    resume with shared banks and stable source IDs
```

Use one DSP/simulation clock mapping for all layers. Frame-rate variation must not quantize impacts to render frames. A game can predict upcoming crossings for sample-accurate scheduling; its prediction window must be invalidated safely on changed motion. Keep historical poses long enough for retarded moving sources, particularly a distant listener. Rebase large world coordinates before submitting positions to a float-based audio engine.

A full train game should pool impact voices and virtualize distant contacts; this demo keeps one bus per joint and lets all in-window events occur. Base priority on predicted received level, preserving near-body decays and adjacent bogie strikes. Do not normalize each impact independently to the same loudness. Culling beyond a game budget should not change physical contact identity or delete the corresponding event from a debug trace.

For multiplayer, transmit or reproduce physics/contact state and stable seeds; each listener needs its own propagation and interior balance. A single pre-mixed pass cannot represent all viewpoints. To add structure-borne sound, route a separate axle-to-carbody transfer path and calibrate it against the airborne path, rather than boost the whole train indiscriminately.

## 10. Reproduce and validate the port

First compare approved single-joint mode at 71.6 km/h, 20 coaches, platform distance 5.8 m, impact 0.7, body/brightness 0.5, rumble 0.55, volume 0.65, with points off. Squeal is then silent regardless of its slider. Match that output before introducing engine reverb, occlusion, randomization or mastering changes.

The recorded offline fit has mean absolute third-octave error **0.03887995 dB** and maximum **0.37641378 dB** over 80–8,000 Hz. The 50–800 Hz share of 50 Hz–10 kHz energy is 87.8658% in the reference and 87.8416% in the reconstruction. These are for the fitted 20-second mono composite on the same passage used for calibration, before browser spatialization, additional joints, variable loads or controls. They establish spectral agreement in that scope, not waveform identity or an independent perceptual result. They say nothing about the new squeal's accuracy.

The new squeal validation compares actual PCM rendered by the JS synthesizer with the RMS-normalized fitted spectrum before curve color, air filters and listener mixing. Across the five reporting bands its mean absolute energy error is 0.0156 dB and maximum is 0.0408 dB. Identically smoothed dominant peak estimates differ by 0–14.65 Hz; broad ridges have nearby competing peaks. The four held-out windows have mean absolute band errors of 1.572, 1.754, 1.179 and 0.887 dB. They are separate windows of the same recording, not an independent train or a measured curve-radius calibration. See `public/squeal-fit.json` and [the comparison plot](public/squeal-spectrum.png).

Run `npm test` in this project; this baseline passes 36 tests. Carry the relevant assertions into the game:

1. Every default axle has a unique ID; each axle/contact pair occurs once per traversal. Verify 128.715 ms LHB axle spacing at reference speed, both directions, and independent overlapping decays.
2. Confirm 13/39 m layouts and continuous route distance. A crossover gives 22 contacts per axle and no duplicate ordinary joints inside point assemblies.
3. Check that moving-listener arrival lies on the emitted wavefront. Visual flashes use arrival time; the wheel crossing itself uses physical time.
4. Check passenger front/rear doorways in coach 1, middle and last coach; include the preceding locomotive bogie. The preceding last axle stays below the modeled leading body cap.
5. In cab view, the rear wheelsets remain audible but quieter than the front. Confirm the effect is absent on coach axles and other views.
6. At 30 and 10 km/h, the rushing layer falls by the specified amounts. Impacts keep their waveform and pitch. At reference speed the rolling correction is neutral.
7. Squeal is silent at rest, on straight routes and outside curves; both curvature signs work. The rear axle may continue after the leading axle exits. Verify 44.1/48 kHz loop seams, bounded PCM and distinct tonal banks.
8. Test mute, squeal-off, pause, seek, route changes, re-entry and rapid repeated toggles. There must be no orphan loops or delayed old impacts. Verify voice budgets with long consists.
9. Compare platform, cab and doorway listening at low/reference speed using headphones and a phone speaker. The automated checks verify math/routing, not subjective timbre or real-world SPL.

For the website, audio activation must occur within the user's tap: resume the audio context and request the playback audio session before awaiting downloads. Older iOS uses the included silent media file as a routing fallback. Hidden tabs pause playback. A native game can replace these browser-specific mechanisms with its own device/focus lifecycle.

## 11. Asset integrity and calibration limits

All nine shipped WAVs are mono, 48,000 Hz, 16-bit PCM. Each impact has 16,384 frames / 32,812 bytes; the rolling bed has 384,000 frames / 768,044 bytes. SHA-256 values for this baseline:

```text
impact-0.wav  c8340d1c58790a63f627975d22db0aed1f2b7afd7027aab3146161c2d7931ca6
impact-1.wav  3cbe3cf73f052978eb282c133c8d861a168fa73f4d20b8d8987399c2d53c49cb
impact-2.wav  c0745f750e25ad89cc4ad3113c0203395debe4c36f825a7bdd9886bcae61c44c
impact-3.wav  35d099be7e8057114d0949cca4c2019632d802b0dcaaaa56ce5d253a2b84e04b
impact-4.wav  6853d653cae2eafb1783ca1db950f3b5f888a60953efd7c78e702de52c84cfd2
impact-5.wav  396745f72b50df7edf0b4203c539c4d76f04f53ae49d5a229a21e225043c2736
impact-6.wav  9ebe68fc1a29bfec24541d28aec33027390195d78ee6b5150a81787daa50e86d
impact-7.wav  b5992a978acef0eb6c8f66e47e8df73fee016ce5f0caa82dbfb7c93098ea290c
rolling-bed.wav  42683b3ad58e5a98537b8f11b8d80b62ad12fd93284b22f5d3d884e1a9c1bef2
```

To regenerate BODY V2, extract the video's 15–35 second passage as 48 kHz mono PCM into `analysis/lhb-reference-48k.wav`, install NumPy/SciPy/Matplotlib, then run `scripts/fit-impact-spectrum.py`. Regeneration overwrites banks and fit outputs, so preserve the approved assets before experimentation. Runtime squeal needs no extra WAV assets: **copy both `squeal.js` and `squeal-profile.js`**, or export the four loops without normalization.

To rebuild the squeal calibration with ffmpeg and the same Python scientific packages:

```text
python scripts/analyze-squeal.py
python scripts/fit-squeal-spectrum.py
```

Render the actual runtime banks for validation, from the project root:

```javascript
// Save as an .mjs script in the project root, or run with node --input-type=module.
import {writeFileSync} from 'node:fs';
import {synthesizeSqueal} from './public/squeal.js';
for (let i=0; i<4; i++) {
  const pcm = synthesizeSqueal(i, 48000);
  writeFileSync(`analysis/squeal-fitted-${i}.f32`, Buffer.from(pcm.buffer));
}
```

Then run `python scripts/validate-squeal-fit.py`. It writes the measured report, comparison plot and an optional synthetic listening preview under `analysis`. `analysis/squeal-before.f32`, if present, adds the previous implementation to the plot. Source-only handoffs must retain `squeal-profile.js` because it is required runtime calibration data, even though the fitting script generates it.

No absolute sound-pressure calibration, measured interior impulse responses, weather/occlusion solution, flange-impact solver or complete wheel/rail mechanics model is included. The guide's exact formulas describe the software baseline. Squeal frequency statistics now come from the supplied onboard benchmark; their transfer to another vehicle, curve-level gain laws and contact approximations remain explicit modeling choices.
