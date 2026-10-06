extends RefCounted
## Station identity on the photo-referenced architectural kits.
var view
var rng := RandomNumberGenerator.new()
var _font := SystemFont.new()
var _boxes := {}

func build(world_view) -> void:
	view = world_view
	rng.seed = 30092026
	_font.font_names = PackedStringArray(["Nirmala UI", "Arial"])
	_font.font_weight = 700
	for station in view.world.stations:
		_station(station)
	_lineside()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	for color in _boxes:
		view._multimesh(cube,_boxes[color],view.mat(color))

func _box(size: Vector3, pos: Vector3, color: Color) -> void:
	if not _boxes.has(color): _boxes[color]=[]
	_boxes[color].append(Transform3D(Basis.IDENTITY.scaled(size),pos))

func _text(content: String, pos: Vector3, size: float, color: Color, rotation_y: float = 0) -> void:
	var label := Label3D.new()
	label.text = content
	label.font = _font
	label.font_size = 96
	label.pixel_size = size / 96.0
	label.modulate = color
	label.outline_size = 0
	label.position = pos
	label.rotation.y = rotation_y
	view.root.add_child(label)

func _board(station: Dictionary, base: Vector3) -> void:
	for dx in [-2.6, 2.6]:
		_box(Vector3(.14, 3.15, .14), base + Vector3(dx, 1.575, 0), Color("262c29"))
	_box(Vector3(6.2, 1.8, .14), base + Vector3(0, 2.55, 0), Color("1f2926"))
	for side in [-1, 1]:
		_box(Vector3(6.02, 1.62, .025), base + Vector3(0, 2.55, side * .081), Color("f3bf16"))
		var angle := 0.0 if side > 0 else PI
		_text(station.tamil, base + Vector3(0, 3.04, side * .101), .42, Color("171e1b"), angle)
		_text(station.hindi, base + Vector3(0, 2.54, side * .101), .36, Color("171e1b"), angle)
		_text(station.name.to_upper(), base + Vector3(0, 2.04, side * .101), .40, Color("171e1b"), angle)

func _station(station: Dictionary) -> void:
	for index in station.platforms.size():
		var r: Rect2 = station.platforms[index]
		var z := r.get_center().y
		for x in [r.position.x + 18, r.end.x - 18]:
			_board(station, Vector3(x, 1.3, z))
		for offset in [-180, -108, 84, 180]:
			var p := Vector3(r.get_center().x + offset, 4.65, z)
			_box(Vector3(1.0, 1.0, .10), p, Color("153c68"))
			for side in [-1, 1]:
				var number: int = station.platform_numbers[index][0 if side < 0 else 1] if station.has("platform_numbers") else index+1
				_text(str(number), p + Vector3(0, 0, side * .065), .65, Color("f4f0df"), 0.0 if side > 0 else PI)
		for offset in [62, -104]:
			for side in [-1, 1]:
				var p := Vector3(r.get_center().x + offset, 3.84, z + side * 1.425)
				_text("TEA  •  COFFEE" if offset == 62 else "BOOK STALL", p, .31, Color("f5e7c8"), 0.0 if side > 0 else PI)
		for offset in [-218, -122, 116, 236]:
			_text("DRINKING WATER", Vector3(r.get_center().x + offset, 2.1, z + .51), .14, Color("19466b"))
		for i in 26:
			var x := r.position.x + 22 + i * 21.3
			if absf(x - (r.get_center().x - 58)) < 14 or absf(x - (r.get_center().x + 62)) < 6 or absf(x - (r.get_center().x - 104)) < 6:
				continue
			_person(Vector3(x, 1.3, z + rng.randf_range(-1.7, 1.7)))
	var b: Vector3 = station.building
	var side := -1.0 if b.z < 0 else 1.0
	var face_z := b.z + side * (15.78 if station.kit == "kumbakonam" else 11.68)
	var angle := 0.0 if side > 0 else PI
	var title: String = station.tamil + "  •  " + station.name.to_upper()
	if station.kit == "thanjavur":
		for i in 3:
			_text([station.tamil, station.name.to_upper(), station.hindi][i], Vector3(b.x + (i-1)*23, 9.65, b.z + side*7.23), .90, Color("163c58"), angle)
	elif station.kit == "kumbakonam":
		_text(station.tamil + " ரயில் நிலையம்", Vector3(b.x, 6.55, face_z), .85, Color("163c58"), angle)
		_text(station.hindi + "  •  " + station.name.to_upper(), Vector3(b.x, 5.62, face_z), .58, Color("163c58"), angle)
		for dx in [-16.2, 16.2]:
			_text("SOUTHERN\nRAILWAY", Vector3(b.x+dx, 6.12, face_z), .46, Color("f0e8cc"), angle)
	else:
		_text(title, Vector3(b.x, 6.72, face_z), .70, Color("163c58"), angle)
		_text("SOUTHERN RAILWAY", Vector3(b.x, 6.15, face_z), .28, Color("163c58"), angle)
	var stop_platform: Rect2 = station.platforms[0]
	var marker := Vector3(stop_platform.end.x - 10, 1.3, stop_platform.get_center().y)
	_box(Vector3(.08, 2.3, .08), marker + Vector3.UP * 1.15, Color("505b59"))
	_box(Vector3(1.25, .7, .09), marker + Vector3.UP * 2.1, Color("182e44"))
	_text("20 / 24\nCOACH", marker + Vector3(0, 2.1, .055), .21, Color("f4eee0"))

func _person(pos: Vector3) -> void:
	var palette := [Color("bc8154"), Color("3c677b"), Color("a94355"), Color("e5cc95"), Color("64735b")]
	var clothes: Color = palette[rng.randi_range(0, palette.size() - 1)]
	var body := CapsuleMesh.new()
	body.radius = .20
	body.height = .68
	var torso: MeshInstance3D = view._add_mesh(body, view.mat(clothes))
	torso.position = pos + Vector3(0, 1.12, 0)
	var head := SphereMesh.new()
	head.radius = .13
	head.height = .28
	var mi: MeshInstance3D = view._add_mesh(head, view.mat(Color("825338")))
	mi.position = pos + Vector3(0, 1.59, 0)
	for side in [-1, 1]:
		_box(Vector3(.13, .72, .16), pos + Vector3(side * .1, .4, 0), Color("343e46"))
		_box(Vector3(.1, .57, .13), pos + Vector3(side * .23, 1.04, 0), clothes)
		_box(Vector3(.14, .08, .28), pos + Vector3(side * .1, .04, -.055), Color("232720"))
	_box(Vector3(.34, .48, .23), pos + Vector3(.37, .29, 0), Color("633e2d"))

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
