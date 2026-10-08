extends RefCounted
## Platform traversal and stopped-train boarding; the railway continues normally.
const Surface := preload("res://game/platform_navigation.gd")
static var _doors := {}
var walk
var game
var outside := false
var surface
var position := Vector2.ZERO
var _surfaces := {}
var _entry_points := {}
var _target := {}
var _refresh := 0.0

func _init(owner) -> void:
	walk=owner;game=walk.game
	if _doors.is_empty():_doors=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/exterior_doors.json"))

func origin() -> Vector3:
	return game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO

func camera_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY,surface.point(position,origin())+Vector3.UP*walk.eye_height)

func doors(car: int) -> Array:
	return _doors.get(game.tv.formation[car].model,{}).get("doors",[])

func dock(car: int,door: Dictionary) -> Dictionary:
	if not game.geographic_drive or game.train.speed>.05: return {}
	var local:=Vector2(door.point[0],door.point[1])
	var back: float=game.tv._center(car)+game.tv._direction(car)*local.y
	var loc: Dictionary=game.tv.motion.locate(back)
	if not _surfaces.has(loc.edge): _surfaces[loc.edge]=Surface.new(game.world,loc.edge)
	var nav=_surfaces[loc.edge]
	if nav.edge.is_empty(): return {}
	var outward: Vector3=game.tv.cars[car].global_basis.x*signf(local.x)
	var right: Vector3=game.world.graph.tangent(loc.edge,loc.s,1).cross(Vector3.UP)*nav.side
	if outward.dot(right)<.65: return {}
	var landing: Dictionary=nav.landing(loc.s)
	if landing.is_empty(): return {}
	return {surface=nav,point=landing.point,car=car,door=door}

func entry_point(car: int,door: Dictionary) -> Dictionary:
	var key: String=game.tv.formation[car].model+str(door.point)
	if not _entry_points.has(key):
		var nav=walk.navigation(car)
		var p:=Vector2(door.point[0]*.6,door.point[1])
		_entry_points[key]=nav.nearest(p,false,1.7,40)
	return _entry_points[key]

func inside_target() -> Dictionary:
	var forward:=Basis(Vector3.UP,game.cam._look.x)*Vector3.FORWARD
	for door in doors(walk.car):
		var local:=Vector2(door.point[0],door.point[1])
		var delta: Vector2=local-walk.position
		if delta.length()>1.9 or Vector2(forward.x,forward.z).dot(delta.normalized())<.35: continue
		if game.train.speed>.05: return {kind="platform_blocked",label="Wait for the train to stop before leaving"}
		var berth:=dock(walk.car,door)
		if berth.is_empty(): return {kind="platform_blocked",label="No platform beside this doorway"}
		berth.kind="alight";berth.label="Step onto platform"
		return berth
	return {}

func boarding_target() -> Dictionary:
	var here: Vector3=surface.point(position,origin())
	var forward:=Basis(Vector3.UP,game.cam._look.x)*Vector3.FORWARD
	if game.train.speed>.05: return {}
	for car in game.tv.cars.size():
		if game.tv.cars[car].global_position.distance_squared_to(here)>400: continue
		for door in doors(car):
			var berth:=dock(car,door)
			if berth.is_empty() or berth.surface.edge!=surface.edge: continue
			var local:=Vector3(door.point[0],1.3,door.point[1])
			var delta: Vector3=game.tv.cars[car].to_global(local)-here
			delta.y=0
			if delta.length()>2.1 or forward.dot(delta.normalized())<.3: continue
			var entry:=entry_point(car,door)
			if entry.is_empty(): continue
			return {kind="board",car=car,door=door,entry=entry.point,label="Board coach %d · %s" % [car+1,str(game.tv.formation[car].model).to_upper().replace("_"," ")]}
	return {}

func alight(berth: Dictionary) -> bool:
	# Revalidate at the moment of use, including speed and platform extent.
	var fresh:=dock(walk.car,berth.door)
	if fresh.is_empty(): return false
	var forward: Vector3=-game.cam._target().basis.z
	surface=fresh.surface;position=fresh.point
	outside=true
	game.cam.set_meta("on_platform",true)
	game.cam._look=Vector2(atan2(-forward.x,-forward.z),0)
	game.tv.walk_car=-1
	game.tv.cab_on=false
	game.tv.passenger_on=false
	game.tv._apply_glass()
	game.tv._interior_light.visible=false
	game.audio.set_interior(false)
	game.audio.reset_positions()
	game.cam._blend=1
	walk._fade_time=.22
	walk.neutralize()
	_refresh=0
	return true

func board(berth: Dictionary) -> bool:
	if game.train.speed>.05: return false
	var fresh:=dock(berth.car,berth.door)
	if fresh.is_empty() or fresh.surface.edge!=surface.edge or position.distance_to(fresh.point)>2.4: return false
	var found:=entry_point(berth.car,berth.door)
	if found.is_empty(): return false
	var forward: Vector3=-game.cam._target().basis.z
	outside=false;game.cam.set_meta("on_platform",false)
	walk.car=berth.car;walk.nav=walk.navigation(walk.car);walk.position=found.point
	walk.crouched=false
	game.tv.passenger_coach=walk.car
	game.tv.walk_car=walk.car
	game.tv._apply_glass()
	forward=game.tv.cars[walk.car].global_basis.inverse()*forward
	game.cam._look=Vector2(atan2(-forward.x,-forward.z),0)
	game.tv._interior_light.visible=true
	game.audio.set_interior(true)
	game.audio.reset_positions()
	walk._refresh_exits()
	walk._fade_time=.22
	walk.neutralize()
	return true

func update(delta: float) -> void:
	var pad: Vector2=game.controller.walk_input() if game.controller!=null else Vector2.ZERO
	var keys: Vector2=walk._keyboard_move()
	if not walk.armed:
		if pad==Vector2.ZERO and keys==Vector2.ZERO:walk.armed=true
	else:
		var input: Vector2=(keys+pad).limit_length()
		var direction:=Basis(Vector3.UP,game.cam._look.x)*Vector3(input.x,0,input.y)
		var tangent: Vector3=game.world.graph.tangent(surface.edge,position.x,1)
		var right: Vector3=tangent.cross(Vector3.UP)*surface.side
		var speed:=.65 if walk.crouched else (2.8 if Input.is_physical_key_pressed(KEY_SHIFT) or (game.controller!=null and game.controller.walk_running()) else 1.4)
		position=surface.move(position,Vector2(direction.dot(tangent),direction.dot(right))*speed*minf(delta,.1))
	walk.eye_height=move_toward(walk.eye_height,.94 if walk.crouched else 1.58,delta*3.6)
	walk._fade_time=maxf(0,walk._fade_time-delta)
	walk._fade.color.a=clampf(walk._fade_time/.22,0,1)
	_refresh-=delta
	if _refresh<=0:_target=boarding_target();_refresh=.1
	walk.target=_target
	var control: String="A" if game.hud.controller_active else "Left click"
	var pilot: String="Hold RS + D-pad up" if game.hud.controller_active else "4"
	walk._prompt.text=control+" · "+_target.label if not _target.is_empty() else "Walk along the platform to another doorway · "+pilot+" returns to the pilot"
