# Current-source Standard 100: both modes certified

These are fresh complete v7 replays using the passenger-realism and boundary
source, including the completed-crossing fix `9ec3530`. Each mode completed
all 100 services, all 1,530 arrivals and 1,530 departures, and every depot
completion with zero safety events. No authored Standard departure changed.

Both variants have 100 genuine departure states, 233 exact five-minute states
and 4,835 matching source hashes. Finalization checked the complete traffic
sample grid, raw snapshots and current inputs before installation. Independent
installed-data verifiers then checked starts, timeline and reciprocal traffic.
Classic has 468 crossings and 44 completed overtakes. Each mode has three
distinct K1 overtakers; the ten-overtaker requirement belongs to Intensive.

| Cumulative extra waits below | Classic all | V2 all | Classic station | V2 station |
| --- | ---: | ---: | ---: | ---: |
| 10 minutes | 78.03% | 84.36% | 74.36% | 81.82% |
| 20 minutes | 96.53% | 97.21% | 96.58% | 97.52% |
| 30 minutes | 100% | 100% | 100% | 100% |
| 45 minutes | 100% | 100% | 100% | 100% |

All 70/90/98/100% targets pass. Maximum continuous waits are 1,696 and
1,774 seconds; grouped station-wait maxima are 1,694 and 1,772 seconds.
The comparison preserves regressions: V2 adds 891.05 seconds to B020's
endpoint lateness, 691.15 seconds to B012 and 78 seconds to K1. Priority
30 and 100 mean endpoint lateness also increases. Other services improve;
there is no claim that V2 is uniformly better or globally optimal.

Actual native menus pass 36 checks across Classic and V2 Standard, including
real departure restoration, mode labels, reciprocal passes and noon timeline
worker restoration. Four 1280×720 screenshots were reviewed. Dummy audio and
Compatibility rendering were used; the renderer emits its screen-space AA
availability warning. These are menu/data checks, not audio or FPS evidence.
The exact executed checker is archived; its additional Network branches remain
unvalidated and the working tool is intentionally not included in this commit.

Old prepared Standard files were preserved locally before replacement and all
674 backup files hash-checked. Raw current audits, traffic, catalogues, logs,
comparison and native results have provenance here. Original v7 outputs remain.
The unchanged runtime's full suite passes 1,003 tests; the current Network
authoring packs separately pass four tests. No source was edited during replay.

This certifies only the two Standard choices. Intensive preparation and the
208-service Network's failed/incomplete validation are separate. It does not
complete the user's 200-service timetable request or publish an executable.
R47 remains available. Source playtest: select each Standard mode, open K1's
traffic list, load its departure and restore noon through Explore by time.
