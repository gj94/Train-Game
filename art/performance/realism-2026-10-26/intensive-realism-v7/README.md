# Current-source Intensive 140 certification

Both original v7 replays finished on unchanged runtime `9ec3530`. Every 140
service completes all calls and depot clearance, with zero safety events.
Each has 140 exact departure states, 233 five-minute states, and 4,836 verified
current source fingerprints. Old prepared data was copied and hash-verified
(754 files) before installation. Independent installed-data verifiers pass.

| Measure | Classic | Predictive V2 |
| --- | ---: | ---: |
| All waits under 10/20/30/45 min (%) | 80.0781 / 96.0938 / 98.8281 / 100 | 86.8613 / 98.1752 / 100 / 100 |
| Station waits under 10/20/30/45 min (%) | 73.7805 / 94.5122 / 98.1707 / 100 | 83.6257 / 97.6608 / 100 / 100 |
| Maximum continuous wait (s) | 2402 | 1652 |
| K1 endpoint delay (s) | 2811.65 | 561.70 |
| Distinct K1 overtakers / locations | 12 / 8 | 11 / 7 |
| Largest K1 pass group at one station | 5 at KPY | 3 at STKT |

The actual source menus pass 55 native checks: real service restoration,
reciprocal traffic and noon-worker mode identity. Four 1280x720 screenshots were
reviewed. Compatibility rendering emitted only its screen-space-AA availability
warning. Dummy audio was used; this check makes no audio or FPS claim.

V2 is not uniformly better. Priority-75 and priority-85 mean endpoint delays
increase from 405.62 to 528.07 seconds and 676.68 to 858.83 seconds respectively.
Fifteen authored departure differences also prevent planner-only attribution.
The exact comparison retains every regression.

These results certify the existing Intensive choices, not Network 208. Network
still needs a complete accepted baseline and disturbance in both modes. The
executed UI checker is archived, but its local Network branches remain untested.
