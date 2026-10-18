extends RefCounted
## Cheap moving acoustic compartments. No render geometry ray casts or sim writes.
static func doppler(source: Vector3, ear: Vector3, velocity: Vector3, receiver_velocity: Vector3) -> float:
	var away := (source-ear).normalized()
	return clampf((343.0+receiver_velocity.dot(away))/maxf(200,343.0+velocity.dot(away)),.65,1.5)

static func compartment(model: String, position: Vector3, pitch: float, doors: float, outside: bool=false) -> Dictionary:
	if outside:return {inside=false,exposure=1.0,room=0.0,model=model,position=position}
	var end := absf(position.z)
	var vestibule := smoothstep(pitch*.5-3.0,pitch*.5-1.0,end)
	var window := smoothstep(.35,1.35,absf(position.x))*smoothstep(1.2,1.8,position.y)*(1-smoothstep(3.1,3.5,position.y))
	var open_stock := model.begins_with("icf_") and model.get_slice("_",1) in ["gs","2s","sl"]
	var exposure := .04 + (.46*window if open_stock else .03*window)
	exposure=maxf(exposure,(0.0 if model=="wap7" else doors)*vestibule*.92)
	var machinery := (1-smoothstep(5,7,end)) if model=="wap7" else 0.0
	return {inside=true,exposure=clampf(exposure,0,1),room=lerpf(.055,.025,vestibule),model=model,position=position,machinery=machinery,vestibule=vestibule}

static func directional_cutoff(source: Vector3, ear: Vector3, forward: Vector3) -> float:
	# Modest front/back coloration for headphones, not a measured HRTF.
	return lerpf(6500,18000,smoothstep(-.7,.3,(source-ear).normalized().dot(forward)))

static func response(space: Dictionary, own: bool, layer: String) -> Vector2:
	if not space.get("inside",false):return Vector2(1,18000)
	var open: float=space.exposure
	var sealed: bool=str(space.model).begins_with("vb_")
	if layer=="traction" and own:
		return Vector2(lerpf(.36,.85,float(space.get("machinery",0))),lerpf(2300,6500,float(space.get("machinery",0))))
	if own and layer=="track":return Vector2(lerpf(.72,1.0,open),lerpf(3300,16500,open))
	return Vector2(lerpf(.12 if sealed else .20,1,open),lerpf(1050 if sealed else 1700,18000,open))

static func sample(game, delta: float=1.0/60) -> Dictionary:
	if game==null or game.cam==null or game.tv==null:return {inside=false,exposure=1.0,room=0.0}
	var outside: bool=game.cam.mode in [0,3] or game.cam.get_meta("on_platform",false)
	var car:=0
	if game.walker!=null and game.walker.active and not game.walker.platform.outside:car=game.walker.car
	elif game.cam.mode==2 or (game.cam.mode==3 and game.tv.passenger_head_out):car=game.tv.passenger_coach
	elif game.train.cab_end==2:car=game.tv.cars.size()-1
	car=clampi(car,0,game.tv.cars.size()-1)
	var local: Vector3=game.tv.cars[car].to_local(game.cam.global_position)
	var doors: float=game.train.passengers.get("door_open",0.0)
	var space:=compartment(game.tv.formation[car].model,local,game.tv.formation[car].pitch,doors,outside)
	space.car=car;space.service=game.train.id
	var loc: Dictionary=game.train_motions[game.train.id].locate(0)
	space.velocity=game.world.graph.tangent(loc.edge,loc.s,loc.dir)*game.train.speed if not outside or game.cam.mode==3 else Vector3.ZERO
	var absolute: Vector3=game.cam.global_position+(game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO)
	if outside and game.cam.mode!=3 and game.audio_previous_eye.is_finite():
		var velocity: Vector3=(absolute-game.audio_previous_eye)/maxf(.001,delta*game.time_scale)
		space.velocity=velocity if velocity.length()<100 else Vector3.ZERO
	game.audio_previous_eye=absolute
	# A short canopy response only where the pedestrian platform geometry exists.
	if outside and game.walker!=null and game.walker.active and game.walker.platform.outside:
		var surface=game.walker.platform.surface
		var midpoint: float=game.world.graph.edges[surface.edge].length*.5
		space.room=.035*(1-smoothstep(150,190,absf(game.walker.platform.position.x-midpoint)))
	return space
