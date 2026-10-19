extends RefCounted
## Context predicate shared by the input router.
static func is_free(camera) -> bool:
	return camera.mode==0 and not camera.follow
