extends RefCounted
## A stationary departure ceremony, owned by the simulation even without audio.
const GAP := 3.5
const CALL_SECONDS := 1.15

static func cancel(t: Train) -> void:
	# Consume the reserved second sequence number. An audio emitter that saw
	# manual takeover must not mistake the next fresh pair for that cancelled call.
	t.cancel_departure_horns()

## Called only after the booked release, doors and starter permit departure.
## True means BOTH calls have finished; traction can then be released.
static func update(t: Train, now: float, ready: bool) -> bool:
	if not t.automatic or not ready:
		cancel(t)
		return false
	if t.horn_ready_at < 0:
		t.horn_sequence += 1
		t.horn_emitted_at = now
		t.horn_pending_at = now + GAP
		t.horn_ready_at = now + GAP + CALL_SECONDS
	elif t.horn_pending_at >= 0 and now >= t.horn_pending_at:
		t.horn_sequence += 1
		t.horn_emitted_at = t.horn_pending_at
		t.horn_pending_at = -1.0
	return now >= t.horn_ready_at
