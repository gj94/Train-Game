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
		var outward := signf(st.building.z)
		# A narrow market street behind the approach road, then lanes of houses.
		_box(Vector3(820,.12,7),Vector3(cx,.08,outward*91),asphalt)
		for row in 3:
			for k in range(-12,13):
				var p := Vector3(cx+k*18+rng.randf_range(-1,1),0,outward*(103+row*21+rng.randf_range(-2,2)))
				_house(p,k%3==0,concrete,PI if outward<0 else 0.0)
			_box(Vector3(480,.10,3.5),Vector3(cx,.09,outward*(94+row*21)),soil)
			for x in range(-300,320,60):
				_box(Vector3(4,.10,30),Vector3(cx+x,.08,outward*(116+row*27)),soil)
		for x in range(-360,380,45):
			var p := Vector3(cx+x,0,outward*85)
			_box(Vector3(.18,7,.18),p+Vector3.UP*3.5,concrete)
			_box(Vector3(2.6,.12,.15),p+Vector3.UP*6.5,dark)
			_line(p+Vector3(0,6.7,0),p+Vector3(45,6.7,0),.025,.025,dark)
	# Village clusters and irrigation plots alongside the longer rural stretches.
	var water := ShaderMaterial.new()
	water.shader = load("res://game/shaders/paddy_water.gdshader")
	water.set_shader_parameter("ripple_strength",.18)
	water.set_shader_parameter("water_roughness",.34)
	var planted_water := water.duplicate() as ShaderMaterial
	planted_water.set_shader_parameter("rice_rows",.85)
	planted_water.set_shader_parameter("water_roughness",.68)
	planted_water.set_shader_parameter("ripple_strength",.05)
	for x in view.world.scenery.villages:
		var centre := _track_at(x)
		var side := -1.0 if int(x)%3==0 else 1.0
		_box(Vector3(420,.10,5),centre+Vector3(0,.08,side*80),asphalt)
		for k in range(-7,8):
			_house(centre+Vector3(k*19,0,side*(100+int(k%2)*24)),k%4==0,concrete,PI if side<0 else 0.0)
	for x in range(2500,19700,210):
		if abs(x-11000)<1700: continue
		var excluded := false
		for landmark in view.world.scenery.canals + view.world.scenery.overbridges:
			if absf(x-landmark) < 130: excluded = true
		for village in view.world.scenery.villages:
			if absf(x-village) < 300: excluded = true
		if excluded: continue
		var centre := _track_at(x)
		for side in [-1,1]:
			for row in 2:
				var p := centre+Vector3(0,.055,side*(65+row*90))
				view._fields.append(Rect2(p.x-93,p.z-45,186,90))
				var field_mat: Material = planted_water if (floori(x/210.0)+row)%3==0 else view.pbr("leafy_grass",2.2,Color("9da952") if row==0 else Color("7e9840"))
				_box(Vector3(176,.06,73),p,field_mat)
				for dx in [-89,89]: _box(Vector3(1.5,.4,77),p+Vector3(dx,.13,0),soil)
				for dz in [-38,38]: _box(Vector3(180,.4,1.5),p+Vector3(0,.13,dz),soil)
				_box(Vector3(180,.05,1.3),p+Vector3(0,.02,side*42),water)
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

func _house(p: Vector3, shop: bool, concrete: Material, facing: float = 0) -> void:
	var prior := {}
	for key in batches: prior[key]=batches[key].transforms.size()
	var cream = view.pbr("plastered_wall",2.0,[Color("dfcda7"),Color("c4caba"),Color("b5c8cf"),Color("cfbaa8")][rng.randi_range(0,3)])
	var dark = view.mat(Color("303c40"))
	var roof = view.pbr("roof_tiles",1.3,Color("a37965"))
	var h := 3.6 if shop else (6.6 if rng.randf()>.65 else 3.6)
	_box(Vector3(17.5,.06,18),p+Vector3(0,.04,0),view.pbr("red_laterite_soil_stones",2.8,Color("c4b399")))
	_box(Vector3(15,h,10),p+Vector3(0,h*.5,0),cream)
	_box(Vector3(15.4,.3,10.4),p+Vector3(0,h+.1,0),concrete)
	_box(Vector3(15.4,.3,10.4),p+Vector3(0,.15,0),concrete)
	for x in [-5,0,5]:
		_box(Vector3(2.0,2.5,.06),p+Vector3(x,1.55,-5.035),dark)
		_box(Vector3(2.6,.12,1.15),p+Vector3(x,2.9,-5.45),concrete)
		if h>4: _box(Vector3(1.7,1.4,.06),p+Vector3(x,4.9,-5.035),dark)
		_box(Vector3(1.3,1.2,.06),p+Vector3(x,2.1,5.035),dark)
		_box(Vector3(1.7,.12,.65),p+Vector3(x,2.8,5.3),concrete)
		if h>4: _box(Vector3(1.3,1.2,.06),p+Vector3(x,4.9,5.035),dark)
	for side in [-1,1]:
		for z in [-2,2]:
			_box(Vector3(.06,1.2,1.3),p+Vector3(side*7.53,2.1,z),dark)
			_box(Vector3(.65,.12,1.7),p+Vector3(side*7.8,2.8,z),concrete)
	if shop:
		_box(Vector3(15,1.0,.12),p+Vector3(0,3.0,-5.07),view.mat(Color("446576")))
		_box(Vector3(16,.12,3),p+Vector3(0,2.6,-6.2),roof,Vector3(.08,0,0))
		for x in [-7,7]: _box(Vector3(.09,2.6,.09),p+Vector3(x,1.3,-7.3),dark)
	else:
		_box(Vector3(15.8,.16,5.7),p+Vector3(0,h+.8,-2.6),roof,Vector3(-.22,0,0))
		_box(Vector3(15.8,.16,5.7),p+Vector3(0,h+.8,2.6),roof,Vector3(.22,0,0))
		_box(Vector3(1.5,1.2,1.5),p+Vector3(4,h+1.4,2),dark)
		for side in [-1,1]: _box(Vector3(.16,.9,17),p+Vector3(side*8.3,.45,0),cream)
	# Face the street and vary frontage/plot proportions without moving the roads.
	var basis := Basis(Vector3.UP,facing+rng.randf_range(-.035,.035)).scaled(Vector3(rng.randf_range(.85,1.0),1,rng.randf_range(.85,1.05)))
	for key in batches:
		for i in range(prior.get(key,0),batches[key].transforms.size()):
			var t: Transform3D = batches[key].transforms[i]
			t.origin = p+basis*(t.origin-p)
			t.basis = basis*t.basis
			batches[key].transforms[i]=t
