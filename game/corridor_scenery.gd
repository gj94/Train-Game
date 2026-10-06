extends RefCounted
## Original metre-scale lineside setting: engineering, agriculture and town edges.
var view
var batches := {}
var rng := RandomNumberGenerator.new()

func _box(size: Vector3, pos: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	# One unit box per material; dimensions live in the instance transform.
	# Unique drain/wall lengths no longer fragment thousands of draw batches.
	var key := str(material.get_instance_id())
	if not batches.has(key):
		batches[key] = {material=material, transforms=[]}
	batches[key].transforms.append(Transform3D(Basis.from_euler(rotation).scaled_local(size),pos))

func _line(a: Vector3, b: Vector3, width: float, height: float, material: Material) -> void:
	var d := b-a
	_box(Vector3(width,height,d.length()),(a+b)*.5,material,Basis.looking_at(d,Vector3.UP).get_euler())

func _track_at(x: float) -> Vector3:
	for e in view.world.graph.edges.values():
		if e.allowed_dir != 1 or x < e.points[0].x or x > e.points[-1].x:
			continue
		for i in range(1,e.points.size()):
			if e.points[i].x >= x:
				return e.points[i-1].lerp(e.points[i],(x-e.points[i-1].x)/(e.points[i].x-e.points[i-1].x)) + Vector3(0,0,3)
	return Vector3(x,0,0)

func build(world_view) -> void:
	view = world_view
	rng.seed = 20261001
	var concrete = view.pbr("brushed_concrete",1.8,Color("afa996"))
	var soil = view.pbr("red_laterite_soil_stones",2.5,Color("b19d78"))
	var dark = view.mat(Color("343c3d"))
	var white = view.mat(Color("e4dec8"))
	var ochre = view.mat(Color("caa451"))
	var asphalt = view.mat(Color("303636"))
	var steel = view.steel()
	# Continuous maintenance path, cable trough and drainage beside both main lines.
	for e in view.world.graph.edges.values():
		if e.allowed_dir != 1: continue
		for i in range(1,e.points.size()):
			var a: Vector3 = e.points[i-1]+Vector3(0,0,3)
			var b: Vector3 = e.points[i]+Vector3(0,0,3)
			var over_water := false
			for x in view.world.scenery.canals:
				if absf((a.x+b.x)*.5-x)<30: over_water=true
			if over_water: continue
			_line(a+Vector3(0,.055,11),b+Vector3(0,.055,11),2.0,.08,soil)
			_line(a+Vector3(0,.09,-10),b+Vector3(0,.09,-10),.65,.18,concrete)
			_line(a+Vector3(0,.04,-13),b+Vector3(0,.04,-13),1.2,.08,dark)
			for dz in [-13.65,-12.35]: _line(a+Vector3(0,.15,dz),b+Vector3(0,.15,dz),.14,.28,concrete)
		for s in range(60,int(e.length)-30,220):
			var p: Vector3 = view.world.graph.position(e.id,s)
			_box(Vector3(.75,1.3,.48),p+Vector3(0,.65,-6),concrete)
			_box(Vector3(.58,1.05,.04),p+Vector3(0,.67,-5.74),dark)
			_box(Vector3(1.1,.12,.8),p+Vector3(0,1.35,-6),concrete)
	# Station boundary, point equipment and a dense, layered town beyond each forecourt.
	for st in view.world.stations:
		var cx: float = st.origin.x
		for side in [-1,1]:
			for x in range(-720,721,6):
				if abs(x)<72 and signf(st.building.z)==side: continue
				_box(Vector3(5.8,1.4,.22),Vector3(cx+x,.7,side*49),concrete)
				_box(Vector3(.35,1.8,.38),Vector3(cx+x+3,.9,side*49),white)
				_box(Vector3(5.8,.16,.26),Vector3(cx+x,1.46,side*49),ochre)
	var water := ShaderMaterial.new()
	water.shader=load("res://game/shaders/paddy_water.gdshader")
	water.set_shader_parameter("ripple_strength",.18)
	water.set_shader_parameter("water_roughness",.34)
	# Road overbridges: piers stand outside both running lines and the OHE.
	for x in view.world.scenery.overbridges:
		var p := _track_at(x)
		_box(Vector3(11,.65,110),p+Vector3(0,9,0),concrete)
		_box(Vector3(9,.1,110),p+Vector3(0,9.38,0),asphalt)
		for z in [-45,-14,14,45]:
			_box(Vector3(1.3,8.6,1.6),p+Vector3(0,4.3,z),concrete)
			_box(Vector3(12,.6,2),p+Vector3(0,8.45,z),concrete)
		for side in [-1,1]:
			_line(p+Vector3(side*5,10.25,-55),p+Vector3(side*5,10.25,55),.12,.13,steel)
			for z in range(-54,56,3): _box(Vector3(.1,.9,.1),p+Vector3(side*5,9.8,z),steel)
			_line(p+Vector3(0,9.2,side*55),p+Vector3(0,.15,side*230),11,.65,concrete)
			_line(p+Vector3(0,9.55,side*55),p+Vector3(0,.5,side*230),9,.10,asphalt)
			_ramp_bank(p,side,soil)
			for z in range(-52,54,8): _box(Vector3(.15,.02,3.6),p+Vector3(0,9.45,z),white)
	# Watercourses cross beneath track-deck culverts, with wing walls and guardrails.
	for x in view.world.scenery.canals:
		var p := _track_at(x)
		_box(Vector3(17,.05,650),p+Vector3(0,-1.1,0),water)
		_box(Vector3(26,.30,28),p+Vector3(0,-.12,0),concrete)
		for side in [-1,1]:
			_box(Vector3(28,1.45,.5),p+Vector3(0,-.55,side*14),concrete)
			for dx in [-14,14]: _box(Vector3(.7,2.0,9),p+Vector3(dx,-.6,side*17),concrete)
			_line(p+Vector3(-13,1.1,side*14),p+Vector3(13,1.1,side*14),.12,.12,white)
			for dx in range(-12,13,3): _box(Vector3(.13,1.2,.13),p+Vector3(dx,.5,side*14),white)
	# Flush instanced scenery batches; all meshes/materials are original or registered CC0.
	for item in batches.values():
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		view._multimesh(mesh,item.transforms,item.material)

func _ramp_bank(p: Vector3, side: int, material: Material) -> void:
	var vertices := [Vector3(-14,0,55),Vector3(14,0,55),Vector3(14,0,230),Vector3(-14,0,230),Vector3(-5.8,8.7,55),Vector3(5.8,8.7,55),Vector3(5.8,.12,230),Vector3(-5.8,.12,230)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[4,7,6,5],[0,4,5,1],[0,3,7,4],[1,5,6,2],[2,6,7,3]]:
		for i in [0,1,2,2,3,0]:
			var v: Vector3 = vertices[face[i]]
			v.z *= side
			st.add_vertex(p+v)
	st.generate_normals()
	var m := material.duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	view._add_mesh(st.commit(),m)
