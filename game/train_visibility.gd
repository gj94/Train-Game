extends RefCounted
## Presentation only. Passenger journeys, physics and sound never depend on this.
const CAB:=1
const PASSENGER:=2
const HEAD_OUT:=3
const WALKING:=4
const EXTERIOR_INTERIOR_RANGE:=32.0
# Only the isolated benchmark toggles this for an in-process A/B comparison.
static var benchmark_full_interiors:=false

static func interior_allowed(mode: int, own: bool, car: int, occupied: int, distance: float, blending: bool=false) -> bool:
	if benchmark_full_interiors:return true
	if own and car==occupied and mode in [CAB,PASSENGER,HEAD_OUT,WALKING]:return true
	if mode==CAB and not blending:return false
	if own and mode in [PASSENGER,WALKING] and absi(car-occupied)<=1:return true
	return distance<EXTERIOR_INTERIOR_RANGE

static func seated_allowed(mode: int, own: bool, car: int, occupied: int, distance: float, blending: bool=false) -> bool:
	if benchmark_full_interiors:return true
	if mode==CAB and not blending:return false
	return interior_allowed(mode,own,car,occupied,distance,blending)

static func detailed_shadows(mode: int,own: bool,car: int,occupied: int,distance: float) -> bool:
	if benchmark_full_interiors:return true
	if own and car==occupied and mode in [CAB,PASSENGER,HEAD_OUT,WALKING]:return true
	if own and mode==CAB:return false
	return distance<65.0

static func occupied_car(game) -> int:
	if game.walker!=null and game.walker.active and not game.walker.platform.outside:return game.walker.car
	if game.cam.mode==PASSENGER or (game.cam.mode==HEAD_OUT and game.tv.get("passenger_head_out")==true):return game.tv.passenger_coach
	return game.tv.cars.size()-1 if game.train.cab_end==2 else 0

static func apply(game,view,id: String) -> void:
	var detail_factor: float=game.graphics_options.values.train_detail if game.get("graphics_options")!=null else 1.0
	var own: bool=id==game.train.id
	var occupied:=occupied_car(game) if own else -100
	var blending: bool=game.cam._blend<1.0
	for car in view.interior_meshes.size():
		var distance: float=view.cars[car].global_position.distance_to(game.cam.global_position)
		var allowed:=interior_allowed(game.cam.mode,own,car,occupied,distance/detail_factor,blending)
		if view.interior_visible[car]!=allowed:
			for mesh in view.interior_meshes[car]:mesh.visible=allowed
			view.interior_visible[car]=allowed
		var detailed:=detailed_shadows(game.cam.mode,own,car,occupied,distance/detail_factor)
		if view.shadow_detail[car]!=detailed:
			for part in view.shadow_parts[car]:
				part.node.cast_shadow=part.mode if detailed else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				# Roughly two-pixel mesh error for distant vehicles; occupied detail stays intact.
				part.node.lod_bias=1.0 if detailed else .5
			view.shadow_proxies[car].visible=not detailed
			view.shadow_detail[car]=detailed
