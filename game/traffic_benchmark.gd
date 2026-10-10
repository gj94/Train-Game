extends RefCounted
## Synthetic crowded ERS fixture, only in a disposable benchmark process.
const Policy:=preload("res://game/train_visibility.gd")
const Pax:=preload("res://sim/passenger_service.gd")
var game
var ids: Array=[]
var description: Dictionary={}

func setup(owner) -> Dictionary:
	game=owner
	game._set_paused(true)
	game.traffic_presentation._check_in=1e9
	var station: Dictionary=game.world.stations.filter(func(s):return s.code=="ERS")[0]
	var roads: Array=station.platform_tracks
	assert(roads.size()>=5)
	ids=[game.train.id]
	for id in game.world.trains:
		if id not in ids and ids.size()<5:ids.append(id)
	for id in game.train_views.keys():
		if id not in ids:game.traffic_presentation.release(id)
	var passengers:=0;var vehicles:=0;var details:=[]
	for i in ids.size():
		var t: Train=game.world.trains[ids[i]]
		var edge: String=roads[i]
		assert(game.world.graph.edges[edge].length>t.length+50)
		game.world.place_train(t,edge,game.world.graph.edges[edge].length-35,1)
		t.speed=0;t.controller=0;t.automatic=false
		game.train_motions[t.id].reset()
		Pax.setup(t)
		var count:=0
		for car in t.passengers.cars:
			for seat in car.seats.size():
				car.seats[seat]=1 if seat%5!=0 else -1
				count+=int(car.seats[seat]>=0)
		t.passengers.onboard=count;t.passengers.initial=count
		t.passengers.phase="riding";t.passengers.events=[];t.passengers.door_open=0
		passengers+=count
		game.traffic_presentation.request_view(t.id)
		vehicles+=preload("res://sim/stock/ported_stock.gd").formation(t.stock_kind.trim_prefix("ported:"),t.rake_profile).size()
		details.append({id=t.id,stock=t.stock_kind,rake=t.rake_profile,length=t.length,passengers=count,road=edge})
	game._render_trains(1)
	game._pilot_camera();game.cam._blend=1
	description={trains=ids.size(),vehicles=vehicles,passengers=passengers,services=details,
		note="Five occupied full formations on separate ERS platform roads; dispatcher paused for reproducible rendering comparison. Live simulation is measured separately."}
	return description

func set_view(mode: String) -> void:
	match mode:
		"pilot":game._pilot_camera()
		"passenger":game._passenger_preset(0)
		"overview":
			var pose: Transform3D=game.tv.cars[mini(6,game.tv.cars.size()-1)].global_transform
			var target: Vector3=pose.origin-pose.basis.x*20
			var eye: Vector3=target+pose.basis.x*110+pose.basis.z*200+Vector3.UP*55
			game.cam.enter_free(eye,(target-eye).normalized())
			game._set_cab_visuals(false);game.dispatcher.set_open(false)
		"platform":
			var view=game.tv
			var car: int=mini(2,view.cars.size()-1)
			var pose: Transform3D=view.cars[car].global_transform
			var target: Vector3=pose.origin+Vector3.UP*2
			game.cam.enter_free(target+pose.basis.x*12+pose.basis.z*12,(-pose.basis.x-pose.basis.z*.55).normalized())
			game._set_cab_visuals(false);game.dispatcher.set_open(false)
	game.cam._blend=1

func begin_coasting() -> Dictionary:
	var before:={}
	for id in ids:
		var t: Train=game.world.trains[id]
		before[id]=t.odometer
		t.speed=2.0;t.controller=0;t.automatic=false;t.emergency=false
		t.depot={}
		game.train_motions[id].reset()
	game.time_scale=1.0
	game._set_paused(false)
	return before

func counters() -> Dictionary:
	var visible_interiors:=0;var resident:=0;var passengers:=0;var shadows:=0;var proxies:=0
	for id in ids:
		if not game.train_views.has(id):continue
		resident+=1
		passengers+=int(game.world.trains[id].passengers.onboard)
		for car in game.train_views[id].interior_meshes:
			for mesh in car:visible_interiors+=int(mesh.visible)
		for car in game.train_views[id].shadow_parts:
			for part in car:shadows+=int(part.node.visible and part.node.cast_shadow!=0)
		for proxy in game.train_views[id].shadow_proxies:proxies+=int(proxy.visible)
	return {resident_trains=resident,simulated_passengers=passengers,
		visible_interior_groups=visible_interiors,rendered_passengers=game.passenger_crowd.visible_count,
		rendered_seated=game.passenger_crowd.seated_count,rendered_platform=game.passenger_crowd.moving_count,
		detailed_shadow_parts=shadows,shadow_hulls=proxies,
		maximum_coach_build_ms=game.traffic_presentation.builds.maximum_step_ms}
