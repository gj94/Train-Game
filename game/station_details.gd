extends RefCounted
## Original procedural scenery. Reuses registered project PBR textures.
var view
var rng := RandomNumberGenerator.new()

func build(world_view) -> void:
	view = world_view
	rng.seed = 30092026
	for station in view.world.stations:
		_station(station)
	_footbridge()
	_lineside()

func _box(size: Vector3, pos: Vector3, color: Color) -> void:
	view.box(size, pos, color)

func _text(text: String, pos: Vector3, size: float, color: Color, rotation_y: float = 0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = size / 64.0
	label.modulate = color
	label.outline_size = 0
	label.position = pos
	label.rotation.y = rotation_y
	view.root.add_child(label)

func _station(station: Dictionary) -> void:
	var cream := Color("dccdac")
	var teal := Color("1a565b")
	var metal := Color("414b50")
	for r: Rect2 in station.platforms:
		var z := r.get_center().y
		# Individual coping / painted platform fascia.
		for x in range(int(r.position.x), int(r.end.x), 3):
			for edge_z in [r.position.y, r.end.y]:
				_box(Vector3(2.8, 0.34, 0.06), Vector3(x + 1.4, 0.62, edge_z), Color("f0e8d2") if (x / 3) % 2 == 0 else Color("884e3f"))
		# Real benches, kiosk, bins, posters, station clock and lamp standards.
		for x in range(int(r.position.x + 24), int(r.end.x - 15), 28):
			_box(Vector3(2.4, 0.12, 0.6), Vector3(x, 1.45, z), teal)
			_box(Vector3(2.4, 0.60, 0.09), Vector3(x, 1.8, z + 0.25), teal)
			for dx in [-0.9, 0.9]:
				_box(Vector3(0.08, 0.54, 0.45), Vector3(x + dx, 1.17, z), metal)
			_box(Vector3(0.48, 0.85, 0.48), Vector3(x + 3.5, 1.32, z), Color("3b655b"))
			_box(Vector3(0.10, 5.0, 0.10), Vector3(x + 8, 3.4, z), metal)
			_box(Vector3(2.2, 0.10, 0.10), Vector3(x + 8, 5.9, z), metal)
			for dx in [-0.85, 0.85]:
				view.box_m(Vector3(0.4, 0.08, 0.3), Vector3(x + 8 + dx, 5.83, z), view.mat(Color("fff1cd"), true))
		for i in 18:
			_person(Vector3(rng.randf_range(r.position.x + 8, r.end.x - 8), 0.94, rng.randf_range(r.position.y + 1.2, r.end.y - 1.2)))
		var kiosk := Vector3(r.get_center().x - 33, 0.95, z)
		_box(Vector3(4.4, 2.8, 1.5), kiosk + Vector3(0, 1.4, 0), cream)
		_box(Vector3(4.6, 0.45, 1.7), kiosk + Vector3(0, 2.85, 0), teal)
		for side in [-1, 1]:
			_box(Vector3(3.4, 1.0, 0.08), kiosk + Vector3(0, 1.5, 0.78 * side), Color("29363b"))
			_text("TEA  •  COFFEE", kiosk + Vector3(0, 2.86, 0.87 * side), 0.24, Color("f5e5b8"), 0 if side > 0 else PI)
		for x in [r.position.x + 35, r.end.x - 35]:
			_box(Vector3(2.6, 0.65, 0.12), Vector3(x, 3.4, z), teal)
			_text("PLATFORM 1 / 2" if station.code != "KDP" else "PLATFORM 1", Vector3(x, 3.4, z + 0.075), 0.25, Color("f5e5b8"))
	var b: Vector3 = station.building
	var side := -1.0 if b.z < 0 else 1.0
	# Station approach: paved apron, access road, low boundary wall, planters.
	view.box_m(Vector3(68, 0.14, 22), b + Vector3(0, 0.02, side * 15), view.pbr("brushed_concrete", 4.0, Color("a6aaa1")))
	_box(Vector3(360, 0.10, 7), b + Vector3(0, 0.03, side * 32), Color("4b504d"))
	for x in range(-175, 180, 9):
		_box(Vector3(4, 0.01, 0.12), b + Vector3(x, 0.09, side * 32), Color("ded7b8"))
	for x in [-28, -20, 20, 28]:
		_box(Vector3(2.3, 0.6, 1.4), b + Vector3(x, 0.35, side * 10), Color("af795a"))
		_box(Vector3(2.1, 0.6, 1.2), b + Vector3(x, 0.86, side * 10), Color("53613b"))
	for i in 7:
		var p := b + Vector3(-90 + i * 29, 0, side * rng.randf_range(51, 68))
		_house(p, i)
	# Fences stop at the station entrance.
	for x in range(-145, 146, 3):
		if abs(x) < 14:
			continue
		var p := b + Vector3(x, 0, side * 24)
		_box(Vector3(0.15, 1.25, 0.15), p + Vector3(0, 0.65, 0), cream)
		for height in [0.4, 0.85]:
			_box(Vector3(3, 0.12, 0.10), p + Vector3(1.5, height, 0), cream)

func _person(pos: Vector3) -> void:
	var palette := [Color("d89260"), Color("3c7b88"), Color("be5861"), Color("e7cf8d"), Color("627459")]
	var body := CapsuleMesh.new()
	body.radius = 0.19
	body.height = 0.76
	var torso: MeshInstance3D = view._add_mesh(body, view.mat(palette[rng.randi_range(0, palette.size() - 1)]))
	torso.position = pos + Vector3(0, 1.1, 0)
	var head := SphereMesh.new()
	head.radius = 0.14
	head.height = 0.28
	var mi: MeshInstance3D = view._add_mesh(head, view.mat(Color("8b6049")))
	mi.position = pos + Vector3(0, 1.61, 0)
	for dx in [-0.10, 0.10]:
		_box(Vector3(0.14, 0.75, 0.18), pos + Vector3(dx, 0.38, 0), Color("343c44"))

func _house(p: Vector3, index: int) -> void:
	var colors := [Color("cbb790"), Color("c3d3c8"), Color("d4a08a"), Color("d6d3b7")]
	view.box_m(Vector3(13, 4.2, 10), p + Vector3(0, 2.1, 0), view.pbr("plastered_wall", 2.5, colors[index % 4]))
	view._gable(Vector3(15, 1.9, 12), p + Vector3(0, 4.2, 0), view.pbr("roof_tiles", 1.5, Color("b69a87")))
	for side in [-1, 1]:
		for x in [-4, 0, 4]:
			_box(Vector3(1.8, 1.7, 0.15), p + Vector3(x, 2.35, side * 5.05), Color("e4dac3"))
			_box(Vector3(1.45, 1.35, 0.17), p + Vector3(x, 2.35, side * 5.08), Color("345252"))

func _footbridge() -> void:
	var color := Color("708b8b")
	var x := 2017.0
	_box(Vector3(3.8, 0.35, 39), Vector3(x, 8.0, 4.5), color)
	for z in [-15, 24]:
		for dx in [-1.55, 1.55]:
			_box(Vector3(0.28, 8, 0.28), Vector3(x + dx, 4.0, z), color)
		# Stairs outside both running lines.
		for i in 40:
			_box(Vector3(0.48, 0.18, 3.0), Vector3(x - 1.7 - i * 0.43, 7.9 - i * 0.195, z), color)
		for dz in [-1.5, 1.5]:
			for i in range(0, 40, 3):
				_box(Vector3(0.08, 1.1, 0.08), Vector3(x - 1.7 - i * 0.43, 8.5 - i * 0.195, z + dz), color)
	for z in range(-15, 25, 2):
		for dx in [-1.8, 1.8]:
			_box(Vector3(0.08, 1.3, 0.08), Vector3(x + dx, 8.8, z), color)
	for z in range(-15, 25, 8):
		for dx in [-1.8, 1.8]:
			_box(Vector3(0.10, 2.1, 0.10), Vector3(x + dx, 9.15, z), color)
	for dx in [-1.8, 1.8]:
		_box(Vector3(0.10, 0.10, 39), Vector3(x + dx, 9.4, 4.5), color)
	view._gable(Vector3(4.8, 0.8, 40), Vector3(x, 10.1, 4.5), view.mat(Color("566e71")))

func _lineside() -> void:
	# Small equipment cabinets, chainage posts, drain channels and grass tufts.
	var grass_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 11:
		var angle := rng.randf() * TAU
		var right := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(0.009, 0.023)
		var base := Vector3(rng.randf_range(-0.14, 0.14), 0, rng.randf_range(-0.14, 0.14))
		var height := rng.randf_range(0.22, 0.52)
		var bend := Vector3(sin(angle), 0, -cos(angle)) * height * 0.28
		var mid := base + Vector3.UP * height * 0.65 + bend * 0.3
		var tip := base + Vector3.UP * height + bend
		for v in [base - right, base + right, mid - right * 0.6, mid - right * 0.6, base + right, mid + right * 0.6, mid - right * 0.6, mid + right * 0.6, tip]:
			st.add_vertex(v)
	st.generate_normals()
	grass_mesh = st.commit()
	var grasses := []
	for eid in view.world.graph.edges:
		var e: Dictionary = view.world.graph.edges[eid]
		for s in range(35, int(e.length - 30), 125):
			var p: Vector3 = view.world.graph.position(eid, s)
			var right: Vector3 = view.world.graph.tangent(eid, s, 1).cross(Vector3.UP)
			var base := p + right * 4.8
			if not view._far_from_track(base, 3.5):
				continue
			_box(Vector3(0.5, 1.0, 0.5), base + Vector3(0, 0.5, 0), Color("e1dbc4"))
			_text("%d" % int(p.x / 100), base + Vector3(0, 0.65, 0.26), 0.3, Color("283735"))
		for i in int(e.length * 2):
			var s := rng.randf_range(0, e.length)
			var p: Vector3 = view.world.graph.position(eid, s)
			var right: Vector3 = view.world.graph.tangent(eid, s, 1).cross(Vector3.UP)
			p += right * rng.randf_range(4.3, 14) * (-1 if rng.randf() < 0.5 else 1)
			if not view._far_from_track(p, 3.9):
				continue
			var on_platform := false
			for station in view.world.stations:
				for r: Rect2 in station.platforms:
					if r.grow(1).has_point(Vector2(p.x, p.z)):
						on_platform = true
			if on_platform:
				continue
			p.y = 0.03
			var scale := rng.randf_range(0.6, 1.5)
			grasses.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), p))
	var grass: StandardMaterial3D = view.mat(Color("40522b")).duplicate()
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.roughness = 1.0
	view._multimesh(grass_mesh, grasses, grass)
