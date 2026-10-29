extends RefCounted
## Keep the midnight state and all five-minute states around actual workings.
## Empty pre-service hours need no repeated restoration during construction.
## Final playable-day preparation continues to use the full original recorder.

static func needed(clock: float, first_departure: float, retained: int) -> bool:
	return retained == 0 or clock >= first_departure - 120.0
