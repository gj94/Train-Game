# LHB integration and visible-interior follow-up

`tools/check_passenger_walk_visuals.gd -- --fleet=lhb` completes **215 checks,
zero failures**, in the actual game with Forward+ rendering and Dummy audio.
Stderr is empty. The inherited checks cover real available seats, standing,
camera/audio attachment under carriage transforms, continuous gangway handoff
and return, and controller ownership. The derived capture additionally checks
occupied interior visibility, completed camera blend and the actual walked eye
position. Four 1280x720 screens were reviewed.

The aisle screen shows the furnished LHB interior and passengers. After the
straight gangway crossing, the forward view faces the protected berth partition;
the player must turn into the side aisle. The additional look-back screen shows
the vestibule behind that position. The separate five-model native test in the
parent directory verifies the complete saloon/side-aisle route through the end.
This fixture does not erase the partition or teleport through it.

The earlier controller-only run passed 203 checks but disabled automatic game
presentation updates. Its captures consequently retained an old visibility
selection. A 209-check intermediate probe updated visibility but had not waited
for the seat-to-walk camera blend. Both remain local as harness diagnostics;
their screenshots are not the accepted visual evidence here. The final harness
advances the normal presentation and blend instead of forcing mesh visibility.

`guide-full-tests.log` records **990 passed, zero failures**, empty stderr after
the gangway help wording change. After that full suite finished, six garbled
middle-dot strings in the walking reticle/prompts were corrected. The subsequent
eleven focused walking tests and this native run pass. Walking mechanics and all
frozen timetable replay inputs remain unchanged.

No physical audio listening or target-PC FPS claim is made. Reproduce with a
native source Godot launch, Forward+, `--audio-driver Dummy`, and the script
above. Existing ICF/VB acceptance is retained; it was not repeated.
