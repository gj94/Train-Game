extends RefCounted
## Simulation-time departure cues survive save/load and rendering-free skips.
const GAP := 3.5
static func update(t: Train, now: float, departing: bool) -> void:
	if departing:
		t.horn_sequence += 1
		t.horn_emitted_at = now
		t.horn_pending_at = now + GAP
	elif t.horn_pending_at >= 0 and now >= t.horn_pending_at:
		t.horn_sequence += 1
		t.horn_emitted_at = t.horn_pending_at
		t.horn_pending_at = -1.0
