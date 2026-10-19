extends RefCounted
class Platform extends RefCounted:
	var outside:=false
	var kind:="platform_blocked"
	func inside_target():return {kind=kind,label="Exterior door"}
func walker():
	var walk:=preload("res://game/train_walk.gd").new()
	walk.game={cam={_look=Vector2(PI,0)}}
	walk.platform=Platform.new();walk.position=Vector2.ZERO
	walk.exits=[{point=Vector2.ZERO,bridge={point=Vector2(0,1)},direction=1}]
	return walk
func test_blocked_exterior_door_does_not_mask_aligned_interior_passage():
	var walk=walker();var target: Dictionary=walk._interaction()
	walk.free();return target.get("kind")=="door" and target.get("point")==Vector2(0,1)
func test_unavailable_platform_still_explained_when_not_facing_a_passage():
	var walk=walker();walk.game.cam._look=Vector2.ZERO
	var target: Dictionary=walk._interaction();walk.free()
	return target.get("kind")=="platform_blocked"
func test_usable_platform_door_remains_interactive():
	var walk=walker();walk.platform.kind="alight"
	var target: Dictionary=walk._interaction();walk.free()
	return target.get("kind")=="alight"
