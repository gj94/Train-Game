# Reproducible Network authoring

The departure override record omitted three already-authored candidate changes
and had an older L033 time. The record now reproduces the existing candidate
exactly. Neither operating pack nor simulation changed in this repair.

`author_network_timetable.gd --check` builds the same serialized JSON values
as the normal author and compares them without writing either pack. It compares
a JSON round trip to avoid comparing unrounded intermediate float coordinates
with the precision actually published in JSON. This is an authoring check, not
a source-fingerprint or snapshot compatibility exception.

Both modes pass; a diagnostic using the previous committed override record is
correctly rejected. All four Network authoring/physics/checkpoint guards pass.
The repaired candidate still failed full-day traffic acceptance. Reproducibility
does not certify the timetable; the next departure proposal needs fresh replay.
