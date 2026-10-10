extends Node3D
## Observer-local GPU-instanced people; their journeys live in RailWorld.
const MAX_SEATED:=140
const MAX_MOVING:=80
const RANGE:=100.0
const KINDS:=["passenger_man","passenger_phone","passenger_sari","passenger_sari_blue","passenger_seated_man","passenger_seated_phone","passenger_seated_sari","passenger_seated_blue"]
var game
var batches:=[]
var _paths:={}
var _events:={}
var _seat_poses:={}
var render_budget:=1.0
var visible_count:=0
var seated_count:=0
var moving_count:=0

var _clock:=0.0
var platforms:=preload("res://game/passenger_platform.gd").new()

func setup(owner) -> void:
	game=owner
	_paths=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/passenger_paths.json"))

	for i in KINDS.size():
		var source: Node3D=(load("res://assets/models/scenery/"+KINDS[i]+".glb") as PackedScene).instantiate()
		var part: Dictionary=_asset(source,Transform3D.IDENTITY)
		source.free()
		var instance:=MultiMeshInstance3D.new()
		var mesh: Mesh=part.mesh.duplicate()
		var material:=ShaderMaterial.new();material.shader=load("res://game/shaders/passenger.gdshader")
		material.set_shader_parameter("seated",i>=4)
		material.set_shader_parameter("skirt",i in [2,3,6,7])
		for surface in mesh.get_surface_count():mesh.surface_set_material(surface,material)
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true
		mm.mesh=mesh;mm.instance_count=MAX_SEATED+MAX_MOVING;mm.visible_instance_count=0
		instance.multimesh=mm;instance.name=KINDS[i];instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		batches.append({node=instance,mm=mm,material=material,asset_pose=part.transform,count=0})

func _asset(node: Node, parent: Transform3D) -> Dictionary:
	var pose: Transform3D=parent*node.transform if node is Node3D else parent
	if node is MeshInstance3D:return {mesh=node.mesh,transform=pose}
	for child in node.get_children():
		var found:=_asset(child,pose)
		if not found.is_empty():return found
	return {}

func update() -> void:
	if game==null or game.cam==null:return
	_clock=game.world.time
	for id in _events.keys():
		if not game.world.trains.has(id):_events.erase(id)
	var seated:=[];var moving:=[]
	for id in game.train_views:
		if not game.world.trains.has(id):continue
		var t: Train=game.world.trains[id];var view=game.train_views[id]
		var p:=t.passengers
		if p.is_empty():continue
		for car in view.cars.size():
			var transform: Transform3D=view.cars[car].global_transform
			var near: bool=transform.origin.distance_squared_to(game.cam.global_position)<(RANGE+15)*(RANGE+15)
			var side:=roundi(p.side*t.path[0].dir*view._direction(car))
			if car<view.passenger_portals.size():view.passenger_portals[car].update(side,p.door_open if near else 0.0)
			if not near or p.cars[car].seats.is_empty():continue
			var policy:=preload("res://game/train_visibility.gd")
			var occupied: int=policy.occupied_car(game) if id==game.train.id else -100
			var detail_factor: float=game.graphics_options.values.train_detail if game.get("graphics_options")!=null else 1.0
			if not policy.seated_allowed(game.cam.mode,id==game.train.id,car,occupied,transform.origin.distance_to(game.cam.global_position)/detail_factor,game.cam._blend<1.0):continue
			var c: Dictionary=p.cars[car]
			var poses: Array=_seats(c.model,view.specs[car].passengers)
			for seat in c.seats.size():
				if c.seats[seat]<0:continue
				if id==game.train.id and view.passenger_on and view.passenger_seat and view.passenger_coach==car and seat==(maxi(0,view.passenger_seat_index) if view.passenger_seat_index>=0 else mini(view.passenger_bay*maxi(1,c.seats.size()/9),c.seats.size()-1)):continue
				var pose: Transform3D=transform*poses[seat]
				var d:=pose.origin.distance_squared_to(game.cam.global_position)
				if d>RANGE*RANGE or d<.36:continue
				seated.append({pose=pose,id=c.ids[seat],distance=d,walk=0.0,seated=true})
		if p.phase not in ["opening","exchange","closing"]:
			_events.erase(id)
			continue
		if not _events.has(id) or _events[id].visit!=p.visit or _events[id].road!=p.road:
			_events[id]={visit=p.visit,road=p.road,routes={}}
		for event in p.events:
			var car: int=event.car
			if view.cars[car].global_position.distance_squared_to(game.cam.global_position)>RANGE*RANGE:continue
			if event.state==2:
				if event.kind=="alight" and p.elapsed-event.end<35:_event_pose(t,view,event)
				continue
			# Waiting boarders stand off the edge until their individual slot.
			if event.kind=="alight" and event.state==0:continue
			var actor:=_event_pose(t,view,event)
			if actor.is_empty():continue
			actor.distance=actor.pose.origin.distance_squared_to(game.cam.global_position)
			if actor.distance<RANGE*RANGE and actor.distance>.36:moving.append(actor)
	var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
	moving.append_array(platforms.actors(_clock,origin,game.cam.global_position))
	seated.sort_custom(func(a,b):return a.distance<b.distance)
	moving.sort_custom(func(a,b):return a.distance<b.distance)
	for b in batches:b.count=0;b.material.set_shader_parameter("simulation_time",_clock)
	seated_count=mini(floori(MAX_SEATED*render_budget),seated.size())
	moving_count=mini(floori(MAX_MOVING*render_budget),moving.size())
	for i in seated_count:_draw(seated[i])
	for i in moving_count:_draw(moving[i])
	visible_count=0
	for b in batches:b.mm.visible_instance_count=b.count;visible_count+=b.count

func _seats(model: String, seats: Array) -> Array:
	if not _seat_poses.has(model):
		var poses:=[]
		for s in seats:
			poses.append(Transform3D(Basis.looking_at(Vector3(s.forward[0],0,s.forward[2]).normalized()),Vector3(s.position[0],s.position[1],s.position[2])))
		_seat_poses[model]=poses
	return _seat_poses[model]

func _draw(actor: Dictionary) -> void:
	var style: int=posmod(actor.id,4)
	var kind: int=4+style if actor.seated else style
	var b: Dictionary=batches[kind]
	if b.count>=b.mm.instance_count:return
	b.mm.set_instance_transform(b.count,actor.pose*b.asset_pose)
	b.mm.set_instance_custom_data(b.count,Color(fposmod(actor.id*.618,1),actor.walk,fposmod(actor.id*.317,1),actor.get("fade",1.0)))
	b.count+=1

func _event_pose(t: Train, view, e: Dictionary) -> Dictionary:
	var p:=t.passengers;var car: int=e.car
	var key: String=str(e.id)+":"+e.kind
	var cached: Dictionary=_events[t.id].routes
	if cached.has(key):return _sample_event(t,e,cached[key])
	var model: String=view.formation[car].model
	var data: Dictionary=_paths.get(model,{})
	if data.is_empty():return {}
	var side:=roundi(p.side*t.path[0].dir*view._direction(car))
	var ds:=_door_indices(data,model,side)
	if ds.is_empty():return {}
	var door_index: int=ds[mini(e.door,ds.size()-1)]
	var route: Array=data.paths[door_index][e.seat]
	if route.is_empty():return {}
	var transform: Transform3D=view.cars[car].global_transform
	var door: Dictionary=data.doors[door_index]
	var seat: Array=view.specs[car].passengers[e.seat].position
	var points: Array[Vector3]=[transform*Vector3(seat[0],seat[1],seat[2])]
	for point in route:points.append(transform*Vector3(point[0],point[1],point[2]))
	var inside_count:=points.size()
	var lip:=transform*Vector3(door.point[0],route[-1][1],door.point[1])
	points.append(lip)
	var back: float=view._center(car)+view._direction(car)*door.point[1]
	var loc: Dictionary=view.motion.locate(back)
	var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
	var berth: Dictionary=platforms.landing(game.world,loc.edge,loc.s,p.side,e.id)
	if berth.is_empty():return {}
	points.append(berth.nav.point(berth.entry,origin))
	points.append(berth.nav.point(berth.queue,origin))
	cached[key]={points=points,inside_count=inside_count,berth=berth,origin=origin,forward=-transform.basis.z}
	return _sample_event(t,e,cached[key])

func _sample_event(t: Train, e: Dictionary, route: Dictionary) -> Dictionary:
	var p:=t.passengers
	if e.kind=="alight" and e.state==2:
		platforms.remember(t.id+":"+str(p.visit)+":"+str(e.id),e.id,route.berth,_clock-p.elapsed+e.end,_clock)
	var ratio:=clampf((p.elapsed-e.begin)/(e.end-e.begin),0,1)
	var sample:=_walk_path(route.points,route.inside_count,ratio,e.kind=="board")
	var direction: Vector3=sample.direction
	var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
	var pose:=Transform3D(Basis.looking_at(direction if direction.length_squared()>.001 else route.forward),sample.point+route.origin-origin)
	return {pose=pose,id=e.id,walk=1.0 if e.state==1 else 0.0,seated=false}

func _door_indices(data: Dictionary, model: String, side: int) -> Array:
	var result:=[]
	for i in data.doors.size():
		var d: Array=data.doors[i].point
		if signi(d[0])!=side or (model=="vb_dtc" and absf(d[0])>1.61):continue
		result.append(i)
	result.sort_custom(func(a,b):return data.doors[a].point[1]<data.doors[b].point[1])
	return [result[0],result[-1]] if result.size()>1 else result

static func _walk_path(points: Array[Vector3], inside_count: int, ratio: float, boarding: bool) -> Dictionary:
	var segments:=[points.slice(0,inside_count),points.slice(inside_count-1,inside_count+2),points.slice(inside_count+1)]
	var weights:=[.25,.1,.65] if boarding else [.65,.1,.25]
	if boarding:
		segments.reverse()
		for segment in segments:segment.reverse()
	for i in 3:
		if ratio<=weights[i] or i==2:return _along(segments[i],clampf(ratio/weights[i],0,1))
		ratio-=weights[i]
	return {}

static func _along(points: Array[Vector3], ratio: float) -> Dictionary:
	var length:=0.0
	for i in range(1,points.size()):length+=points[i-1].distance_to(points[i])
	var remaining:=length*ratio
	for i in range(1,points.size()):
		var segment:=points[i-1].distance_to(points[i])
		if remaining<=segment or i==points.size()-1:
			var direction:=points[i]-points[i-1];direction.y=0
			return {point=points[i-1].lerp(points[i],clampf(remaining/maxf(.001,segment),0,1)),direction=direction.normalized()}
		remaining-=segment
	return {point=points[-1],direction=Vector3.FORWARD}
