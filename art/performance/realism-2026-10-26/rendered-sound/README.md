# Actual rendered passenger sound — 26 October 2026

Two completed native probes run the real `game/main.tscn`, normal simulation,
traffic presentation, scenery streaming and sound scheduler. K1 is viewed from
a passenger seat while its look direction continuously turns through both
sides. Its own rail layer is muted for measurement so it cannot conceal loss
of an external train's rolling sound. No runtime change is made by the probe.

| Case | Renderer | Capture bins | Nearby bins | Lowest external rolling RMS |
| --- | --- | ---: | ---: | ---: |
| B002 overtakes stationary K1 at Sasthamkotta | Compatibility | 903 shared | 113 | 0.000525 |
| B014 passes stationary K1 in the opposite direction | Compatibility | same capture | 114 | 0.000520 |
| B012 passes moving K1, both about 98.56 km/h | Forward+ | 720 | 35 | 0.000909 |

Nearby means a moving train has a bogie within 100 m of the receiver. Every
nearby rolling bin contains at least 100 PCM samples and remains above the
1e-7 dropout threshold. No nearby source is paused and the audio receiver
matches the actual geographic camera exactly. Independent inspection of all
bins with a head or tail within 100 m finds no lost audio residency either.
All probes finish with no safety event. Each nearby interval spans almost the
entire -pi to +pi head-yaw range.

Global external-impact maximum RMS during those intervals is
0.01831 / 0.01346 / 0.00990, compared with passing-air maxima
0.00440 / 0.00188 / 0.00075. These maxima occur in different bins and the global
buses may contain other traffic; they are not a matched loudness ratio or a
per-target impact attribution. Discrete clacks naturally have quiet intervals.

The two fixture snapshots have their exact SHA-256 checked against their
historical five-minute catalogue before restoring. They are diagnostic starting
conditions from the old Intensive V2 day, never installed as current-source
prepared data or claimed as full-day acceptance. The entire railway then moves
under current runtime source. `summary.json` contains the snapshot hashes,
compressed raw-report hashes and detailed measurements. Each raw JSON can be
recovered byte-for-byte from `report.json.gz`.

The STKT accepted run preceded addition of an explicit residency assertion to
the harness; the independent raw-bin check above applies that condition to it.
The moving run includes the assertion. Earlier local STKT harness attempts
failed to read a compressed snapshot and then to handle a not-yet-initialized
streamed audio object. Neither produced acceptance evidence. Those errors were
fixed in the diagnostic, without changing game behavior.

Dummy audio captures native mixer output without hardware playback. Compatibility
reports unsupported AA/SSIL feature warnings; Forward+ stderr is empty. The
reviewed 1280x720 screens show the actual passenger viewpoint at capture time,
which may face away from the passing train. Eight headless day replays were also
running, so these are not performance benchmarks. This closes these reproduced
scene cases, not every possible intermittent dropout or a subjective listening
verdict on the player's device.

Reproduce with `tools/check_rendered_passenger_sound.gd`, normal native Godot,
`--audio-driver Dummy`, and the specified renderer. STKT uses
`--snapshot=res://data/timetables/intensive_v2/times/T042600.bin`,
`--targets=B002,B014 --seconds=240`. Moving Forward+ uses
`--snapshot=res://data/timetables/intensive_v2/times/T041400.bin`,
`--targets=B012 --seconds=210`. Set a fresh `--output=res://.local/...` directory.
Archive the historical fixtures before new data replaces their catalogue; the
same filename in a later preparation is not necessarily the same snapshot.
