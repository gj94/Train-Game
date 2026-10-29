extends RefCounted
const Policy = preload("res://tools/lib/construction_snapshots.gd")

func test_keep_initial_and_active_window_snapshots():
	if not Policy.needed(0, 21600, 0):return "Missing midnight state"
	if Policy.needed(21000, 21600, 1):return "Redundant empty pre-service snapshot"
	if not Policy.needed(21480, 21600, 1):return "Missing depot activation window"
	if not Policy.needed(43200, 21600, 1):return "Missing final state"
	return true
