extends RefCounted
## Species clusters, field-edge planting and close railway verges.
var view
var plan
var library
var rng:=RandomNumberGenerator.new()
var service_clearance
func build(world_view,layout,assets) -> void:
	view=world_view
	plan=layout
	library=assets
	rng.seed=2026100702
	# Match CorridorScenery's world-Z offsets for paths, troughs and open drains.
	var service_edges:={}
	for edge in view.world.graph.edges.values():
		if edge.allowed_dir!=1: continue
		for offset in [14.0,-7.0,-10.0]:
			var points:=PackedVector3Array()
			for p in edge.points: points.append(p+Vector3(0,0,offset))
			service_edges[str(edge.id)+":"+str(offset)]={points=points}
	service_clearance=preload("res://game/scenery_clearance.gd").new({edges=service_edges})
	for item in plan.tree_sites:
		var p: Vector3=item.position
		p.y=view.terrain_height(p.x,p.z)
		library.place(item.kind,p,item.angle,Vector3.ONE*item.scale)
	for station in view.world.stations:
		var side: float=signf(station.building.z)
		for x in [-49,49]:
			for dz in [15,30]:
				var p: Vector3=station.building+Vector3(x,.0,side*dz)
				library.place("young_palm",p,rng.randf()*TAU,Vector3.ONE*.9)
	_groves()
	_verges()
	_watercourses()
func _groves() -> void:
	var xmin: float=view.world.scenery.get("x_min",-500)
	var xmax: float=view.world.scenery.get("x_max",22200)
	for i in 1200:
		var c:=Vector3(rng.randf_range(xmin,xmax),0,rng.randf_range(-780,780))
		var species: String=["coconut_palm","coconut_palm","mango_tree","rain_tree","young_palm","tree_small_02"][rng.randi_range(0,5)]
		for k in rng.randi_range(3,8):
			var p:=c+Vector3(rng.randf_range(-30,30),0,rng.randf_range(-25,25))
			if not view._far_from_track(p,18): continue
			p.y=view.terrain_height(p.x,p.z)
			var size:=rng.randf_range(.72,1.23)
			library.place(species,p,rng.randf()*TAU,Vector3.ONE*size)
		if i%2==0:
			var p:=c+Vector3(rng.randf_range(-12,12),0,rng.randf_range(-12,12))
			if view._far_from_track(p,16):
				p.y=view.terrain_height(p.x,p.z)
				library.place("shrub",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.7,1.4))
	# Narrow planted lines follow irrigation boundaries instead of random trees in crops.
	for field in plan.fields:
		var rect: Rect2=field.rect
		if rng.randf()>.17: continue
		for x in range(int(rect.position.x)+8,int(rect.end.x)-8,17):
			var p:=Vector3(x,0,rect.end.y+5)
			if not _open_site(p,6): continue
			p.y=view.terrain_height(p.x,p.z)
			library.place("young_palm" if rng.randf()>.5 else "coconut_palm",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.75,1.0))
func _open_site(p: Vector3,margin: float) -> bool:
	if not plan.clearance.clear_point(p,25): return false
	var site:=Vector2(p.x,p.z)
	for district in plan.districts:
		if district.rect.grow(margin).has_point(site): return false
	for road in plan.roads:
		if road.rect.grow(margin).has_point(site): return false
	for building in plan.buildings:
		if building.rect.grow(margin).has_point(site): return false
	for canal in view.world.scenery.canals:
		if absf(canal-p.x)<38: return false
	for bridge in view.world.scenery.overbridges:
		if absf(bridge-p.x)<24 and absf(p.z)<420: return false
	return true
func _verges() -> void:
	for edge in view.world.graph.edges.values():
		if edge.allowed_dir!=1: continue
		for s in range(0,int(edge.length),8):
			var centre: Vector3=view.world.graph.position(edge.id,s)
			var right: Vector3=view.world.graph.tangent(edge.id,s,1).cross(Vector3.UP)
			for side in [-1,1]:
				for k in 5:
					var p: Vector3=centre+right*side*rng.randf_range(4.0,16.0)+Vector3(rng.randf_range(-4,4),0,0)
					if not view._far_from_track(p,3.6) or not service_clearance.clear_point(p,1.7): continue
					p.y=view.terrain_height(p.x,p.z)+.015
					library.place("grass_tuft",p,rng.randf()*TAU,Vector3(rng.randf_range(1.0,2.2),rng.randf_range(.55,1.0),rng.randf_range(1.0,2.2)))
				for band in [7.5,13.0,19.0,26.0]:
					var patch: Vector3=centre+right*side*(band+rng.randf_range(-1.5,1.5))+Vector3(rng.randf_range(-3.5,3.5),0,0)
					if not view._far_from_track(patch,6.0) or not plan.clear_land_point(patch,2.8) or not service_clearance.clear_point(patch,3.8): continue
					patch.y=view.terrain_height(patch.x,patch.z)+.012
					library.place("verge_patch",patch,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.8,1.2))
				if s%40==0:
					var p: Vector3=centre+right*side*rng.randf_range(17.5,24.0)
					if view._far_from_track(p,16):
						p.y=view.terrain_height(p.x,p.z)
						library.place("shrub",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.48,.85))
	for field in plan.fields:
		if rng.randf()>.35: continue
		var rect: Rect2=field.rect
		for x in range(int(rect.position.x),int(rect.end.x),4):
			var p:=Vector3(x+rng.randf_range(-.7,.7),.025,rect.position.y-1.1+rng.randf_range(-.30,.30))
			library.place("grass_tuft",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.7,1.2))
func _watercourses() -> void:
	for x in view.world.scenery.canals:
		var centre: Vector3=plan.track_at(x)
		for side in [-1,1]:
			for z in range(-305,306,3):
				if absf(z)<24: continue
				var p:=centre+Vector3(side*rng.randf_range(15.5,23.5),0,z+rng.randf_range(-1.3,1.3))
				p.y=view.terrain_height(p.x,p.z)
				library.place("reeds",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.8,1.3))
			for z in range(-290,295,24):
				if absf(z)<40: continue
				var p:=centre+Vector3(side*rng.randf_range(34,43),0,z+rng.randf_range(-4,4))
				if not plan.clearance.clear_point(p,24): continue
				p.y=view.terrain_height(p.x,p.z)
				library.place("young_palm",p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.75,1.1))
