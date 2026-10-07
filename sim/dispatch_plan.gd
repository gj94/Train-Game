extends RefCounted
## Compatibility entry point for headless scenarios. Planning lives in the world.
static func update(w: RailWorld, hold_maruthur: bool = false, manual_service: String = "") -> void:
	var engine = w.dispatcher()
	engine.hold_maruthur=hold_maruthur
	engine.manual_service=manual_service
	engine.run_cycle(true)
