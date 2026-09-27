extends RefCounted
## Builds the static 3D world from a RailWorld: track, ground, scenery,
## stations, signals and switch markers. Everything is procedural low-poly.

const RAIL_TOP := 0.5
const GAUGE_HALF := 0.84          # broad gauge (1676 mm)
const SIGNAL_SIDE := 2.8          # signals stand left of the track (India runs on the left)

var world: RailWorld
var root: Node3D
var signal_lamps := {}            # signal id -> [green, yellow, red] MeshInstance3D
var switch_markers := {}          # node id -> {label: Label3D, lamp: MeshInstance3D}
var labels: Array = []            # Label3D nodes to hide in cab view
var _track_samples := PackedVector3Array()
var _mats := {}


func build(w: RailWorld, parent: Node3D) -> void:
	world = w
	root = Node3D.new()
	root.name = "World"
	parent.add_child(root)
	_build_environment()
	for eid in world.graph.edges:
		_build_track(eid)
	_build_ground()
	_build_stations()
	_build_scenery()
	for sid in world.signals:
		_build_signal(sid)
	for nid in world.graph.switches:
		_build_switch(nid)


# --- materials ---------------------------------------------------------------

func mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(), emissive]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 3.0
	_mats[key] = m
	return m


func box(size: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	mi.position = pos
	(parent if parent else root).add_child(mi)
	return mi


# --- environment -------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.78, 0.84, 0.88)
	sky_mat.ground_horizon_color = Color(0.6, 0.62, 0.55)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.84, 0.86)
	env.fog_density = 0.0006
	env.fog_aerial_perspective = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)


# --- track -------------------------------------------------------------------

## Samples an edge every `step` metres: [{pos, right}] where right is the unit
## vector to the right of travel a->b.
func _samples(eid: String, step: float) -> Array:
	var g := world.graph
	var e: Dictionary = g.edges[eid]
	var n := maxi(1, ceili(e.length / step))
	var out := []
	for i in n + 1:
		var s: float = e.length * i / n
		var fwd := g.tangent(eid, s, 1)
		out.append({pos = g.position(eid, s), right = fwd.cross(Vector3.UP).normalized(), fwd = fwd})
	return out


func _build_track(eid: String) -> void:
	var pts := _samples(eid, 2.0)
	for p in pts:
		_track_samples.append(p.pos)
	var lift := 0.002 * world.graph.edges.keys().find(eid)   # avoid z-fighting where tracks overlap

	# Ballast: trapezoid cross-section.
	var ballast := _extrude(pts, [Vector2(-2.3, 0.0), Vector2(-1.5, 0.3 + lift), Vector2(1.5, 0.3 + lift), Vector2(2.3, 0.0)])
	_add_mesh(ballast, Color(0.52, 0.47, 0.42))
	# Rails.
	for side in [-GAUGE_HALF, GAUGE_HALF]:
		var r := _extrude(pts, [Vector2(side - 0.04, 0.36), Vector2(side - 0.04, RAIL_TOP), Vector2(side + 0.04, RAIL_TOP), Vector2(side + 0.04, 0.36)])
		_add_mesh(r, Color(0.45, 0.42, 0.4))

	# Sleepers (concrete).
	var sleeper := BoxMesh.new()
	sleeper.size = Vector3(2.75, 0.14, 0.26)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sleeper
	var e: Dictionary = world.graph.edges[eid]
	var count := int(e.length / 0.8)
	mm.instance_count = count
	for i in count:
		var s := (i + 0.5) * 0.8
		var p := world.graph.position(eid, s)
		var fwd := world.graph.tangent(eid, s, 1)
		var basis := Basis.looking_at(fwd, Vector3.UP)   # local X runs across the track
		mm.set_instance_transform(i, Transform3D(basis, p + Vector3(0, 0.32, 0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat(Color(0.68, 0.66, 0.62))
	root.add_child(mmi)


## Sweeps a 2D profile (x = right offset, y = height) along sample points.
## Returns a flat-shaded ArrayMesh.
func _extrude(pts: Array, profile: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a: Dictionary = pts[i]
		var b: Dictionary = pts[i + 1]
		for j in profile.size() - 1:
			var p0: Vector2 = profile[j]
			var p1: Vector2 = profile[j + 1]
			var a0: Vector3 = a.pos + a.right * p0.x + Vector3.UP * p0.y
			var a1: Vector3 = a.pos + a.right * p1.x + Vector3.UP * p1.y
			var b0: Vector3 = b.pos + b.right * p0.x + Vector3.UP * p0.y
			var b1: Vector3 = b.pos + b.right * p1.x + Vector3.UP * p1.y
			for v in [a0, b0, a1, a1, b0, b1]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


func _add_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color)
	root.add_child(mi)
	return mi


# --- ground and scenery ------------------------------------------------------

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7000, 2400)
	ground.mesh = pm
	ground.material_override = mat(Color(0.36, 0.52, 0.24))
	ground.position = Vector3(1860, -0.02, 0)
	root.add_child(ground)


func _far_from_track(p: Vector3, clearance: float) -> bool:
	var c2 := clearance * clearance
	for i in range(0, _track_samples.size(), 4):
		if Vector2(p.x - _track_samples[i].x, p.z - _track_samples[i].z).length_squared() < c2:
			return false
	for st in world.stations:
		if p.distance_to(st.building) < 30.0:
			return false
	return true


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260927

	# Paddy fields: flat bright-green and water-tinted patches.
	for i in 140:
		var p := Vector3(rng.randf_range(-400, 4100), 0, rng.randf_range(-600, 600))
		if not _far_from_track(p, 40.0):
			continue
		var c := Color(0.55, 0.72, 0.3) if rng.randf() < 0.7 else Color(0.42, 0.55, 0.45)
		var f := box(Vector3(rng.randf_range(40, 90), 0.05, rng.randf_range(30, 70)), p, c)
		f.rotation.y = rng.randf_range(-0.2, 0.2)

	# Coconut palms (trunks + fronds in two MultiMeshes).
	var trunks: Array = []
	var fronds: Array = []
	var placed := 0
	while placed < 700:
		var p := Vector3(rng.randf_range(-400, 4100), 0, rng.randf_range(-700, 700))
		if not _far_from_track(p, 14.0):
			continue
		placed += 1
		var h := rng.randf_range(7.0, 12.0)
		var tb := Basis.from_euler(Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12)))
		var up := tb.y
		trunks.append(Transform3D(tb * Basis.from_scale(Vector3(1, h / 8.0, 1)), p + up * h * 0.5))
		var top := p + up * h
		var spin := rng.randf() * TAU
		for k in 7:
			var yaw := spin + k * TAU / 7.0
			# Frond points outward along local -Z and droops downward.
			var fb := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -deg_to_rad(rng.randf_range(20, 40)))
			fronds.append(Transform3D(fb, top + fb * Vector3(0, 0, -2.0)))
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.15
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 8.0
	trunk_mesh.radial_segments = 6
	trunk_mesh.rings = 1
	_multimesh(trunk_mesh, trunks, Color(0.45, 0.36, 0.26))
	var frond_mesh := BoxMesh.new()
	frond_mesh.size = Vector3(0.9, 0.08, 4.2)
	_multimesh(frond_mesh, fronds, Color(0.22, 0.45, 0.16))

	# Round-crowned trees (mango / banyan-ish).
	var crowns: Array = []
	var tr2: Array = []
	placed = 0
	while placed < 260:
		var p := Vector3(rng.randf_range(-400, 4100), 0, rng.randf_range(-700, 700))
		if not _far_from_track(p, 16.0):
			continue
		placed += 1
		var r := rng.randf_range(2.5, 5.0)
		tr2.append(Transform3D(Basis().scaled(Vector3(1.4, r / 6.0, 1.4)), p + Vector3(0, r * 0.5, 0)))
		crowns.append(Transform3D(Basis().scaled(Vector3(r, r * 0.8, r)), p + Vector3(0, r * 1.5, 0)))
	var crown_mesh := SphereMesh.new()
	crown_mesh.radial_segments = 7
	crown_mesh.rings = 4
	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	_multimesh(crown_mesh, crowns, Color(0.2, 0.38, 0.15))
	_multimesh(trunk_mesh, tr2, Color(0.35, 0.27, 0.2))

	# Distant hills (Western Ghats vibe).
	for i in 18:
		var x := -600.0 + i * 280.0 + rng.randf_range(-80, 80)
		for side in [-1, 1]:
			var hill := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = rng.randf_range(20, 60)
			cm.bottom_radius = rng.randf_range(250, 400)
			cm.height = rng.randf_range(80, 180)
			cm.radial_segments = 7
			cm.rings = 1
			hill.mesh = cm
			hill.material_override = mat(Color(0.3, 0.42, 0.28) if side < 0 else Color(0.34, 0.44, 0.3))
			hill.position = Vector3(x, cm.height * 0.5 - 5, side * rng.randf_range(1000, 1300))
			root.add_child(hill)


func _multimesh(mesh: Mesh, xforms: Array, color: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat(color)
	root.add_child(mmi)


# --- stations ----------------------------------------------------------------

func _build_stations() -> void:
	for st in world.stations:
		for r: Rect2 in st.platforms:
			var c := Vector3(r.position.x + r.size.x * 0.5, 0.45, r.position.y + r.size.y * 0.5)
			box(Vector3(r.size.x, 0.9, r.size.y), c, Color(0.72, 0.7, 0.66))
			# Yellow safety line along both edges.
			for dz in [-r.size.y * 0.5 + 0.35, r.size.y * 0.5 - 0.35]:
				box(Vector3(r.size.x, 0.02, 0.15), c + Vector3(0, 0.46, dz), Color(0.95, 0.8, 0.1))
			# Shelter: posts + roof over the middle third.
			var roof_len := r.size.x * 0.4
			box(Vector3(roof_len, 0.25, r.size.y - 1.2), c + Vector3(0, 4.1, 0), Color(0.6, 0.25, 0.18))
			for k in 6:
				var x := -roof_len * 0.5 + 2.0 + k * (roof_len - 4.0) / 5.0
				box(Vector3(0.2, 3.3, 0.2), c + Vector3(x, 2.1, 0), Color(0.35, 0.4, 0.5))
			# Name boards at both ends: yellow with black lettering.
			for dx in [-r.size.x * 0.5 + 12.0, r.size.x * 0.5 - 12.0]:
				_name_board(st.name, c + Vector3(dx, 0.45, 0))
		# Station building: cream walls, terracotta roof.
		var b: Vector3 = st.building
		box(Vector3(24, 5, 9), b + Vector3(0, 2.5, 0), Color(0.93, 0.88, 0.74))
		box(Vector3(26, 0.5, 11), b + Vector3(0, 5.25, 0), Color(0.7, 0.3, 0.2))
		box(Vector3(3, 3.2, 0.2), b + Vector3(0, 1.6, 4.55 * signf(-b.z)), Color(0.45, 0.3, 0.2))
		_name_board(st.name, b + Vector3(0, 6.5, 0))


func _name_board(text: String, base: Vector3) -> void:
	box(Vector3(0.12, 2.2, 0.12), base + Vector3(-2.2, 1.1, 0), Color(0.2, 0.2, 0.2))
	box(Vector3(0.12, 2.2, 0.12), base + Vector3(2.2, 1.1, 0), Color(0.2, 0.2, 0.2))
	box(Vector3(5.6, 1.2, 0.1), base + Vector3(0, 2.6, 0), Color(0.98, 0.82, 0.1))
	for side in [1, -1]:
		var l := Label3D.new()
		l.text = text.to_upper()
		l.font_size = 72
		l.pixel_size = 0.012
		l.modulate = Color.BLACK
		l.outline_size = 0
		l.position = base + Vector3(0, 2.6, 0.06 * side)
		l.rotation.y = 0.0 if side > 0 else PI
		root.add_child(l)


# --- signals and switches ----------------------------------------------------

func _build_signal(sid: String) -> void:
	var sig: Dictionary = world.signals[sid]
	var g := world.graph
	var fwd := g.tangent(sig.edge, sig.s, sig.dir)
	var left := Vector3.UP.cross(fwd).normalized()
	var base := g.position(sig.edge, sig.s) + left * SIGNAL_SIDE
	var node := Node3D.new()
	node.position = base
	# Face the approaching train: local -Z points back towards it.
	node.basis = Basis.looking_at(-fwd, Vector3.UP)
	root.add_child(node)

	box(Vector3(0.18, 5.2, 0.18), Vector3(0, 2.6, 0), Color(0.55, 0.55, 0.55), node)
	box(Vector3(0.55, 1.55, 0.35), Vector3(0, 5.5, 0), Color(0.08, 0.08, 0.08), node)
	# Aspect plate: black and white bands (Indian signal post marking).
	box(Vector3(0.5, 0.3, 0.05), Vector3(0, 3.8, -0.12), Color(0.95, 0.95, 0.95), node)
	var lamps := []
	for k in 3:  # top to bottom: green, yellow, red
		var lamp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.15
		sm.height = 0.3
		sm.radial_segments = 8
		sm.rings = 4
		lamp.mesh = sm
		lamp.position = Vector3(0, 6.0 - k * 0.48, -0.2)
		node.add_child(lamp)
		lamps.append(lamp)
	signal_lamps[sid] = lamps

	var label := Label3D.new()
	label.text = sid
	_style_marker_label(label)
	label.position = Vector3(0, 7.4, 0)
	node.add_child(label)
	labels.append(label)

	_clickable(node, Vector3(1.6, 8.0, 1.6), Vector3(0, 4.0, 0), {kind = "signal", id = sid})


func _build_switch(nid: String) -> void:
	var g := world.graph
	var sw: Dictionary = g.switches[nid]
	var trunk: Dictionary = g.edges[sw.trunk]
	# Put the marker a few metres along the trunk, off to the side.
	var dir_into := 1 if trunk.a == nid else -1
	var s := g.entry_s(sw.trunk, dir_into) + dir_into * 6.0
	var fwd := g.tangent(sw.trunk, s, dir_into)
	var pos := g.position(sw.trunk, s) + fwd.cross(Vector3.UP).normalized() * 4.5
	var node := Node3D.new()
	node.position = pos
	root.add_child(node)
	box(Vector3(1.0, 0.6, 0.6), Vector3(0, 0.3, 0), Color(0.3, 0.3, 0.32), node)
	var lamp := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.45
	cm.height = 0.12
	cm.radial_segments = 10
	lamp.mesh = cm
	lamp.position = Vector3(0, 0.66, 0)
	node.add_child(lamp)
	var label := Label3D.new()
	_style_marker_label(label)
	label.position = Vector3(0, 3.0, 0)
	node.add_child(label)
	labels.append(label)
	switch_markers[nid] = {label = label, lamp = lamp}
	_clickable(node, Vector3(3, 3, 3), Vector3(0, 1.0, 0), {kind = "switch", id = nid})


## Constant on-screen size so ids stay readable from far away.
func _style_marker_label(label: Label3D) -> void:
	label.font_size = 28
	label.pixel_size = 0.0012
	label.fixed_size = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 8


func _clickable(node: Node3D, size: Vector3, offset: Vector3, info: Dictionary) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	shape.position = offset
	body.add_child(shape)
	body.set_meta("pick", info)
	node.add_child(body)


# --- per-frame updates -------------------------------------------------------

func update() -> void:
	var dark := Color(0.12, 0.12, 0.12)
	var colors := [Color(0.1, 1.0, 0.3), Color(1.0, 0.75, 0.05), Color(1.0, 0.08, 0.05)]
	for sid in signal_lamps:
		var a := world.aspect(sid)
		var lit := 0 if a == RailWorld.Aspect.GREEN else (1 if a == RailWorld.Aspect.YELLOW else 2)
		for k in 3:
			signal_lamps[sid][k].material_override = mat(colors[k], true) if k == lit else mat(dark)
	for nid in switch_markers:
		var m: Dictionary = switch_markers[nid]
		var rev: bool = world.graph.switches[nid].reversed
		var locked := world.switch_lock_reason(nid) != ""
		m.label.text = "%s  %s%s" % [nid, "R" if rev else "N", "  (locked)" if locked else ""]
		m.lamp.material_override = mat(Color(1.0, 0.6, 0.1) if rev else Color(0.3, 0.8, 1.0), true)


func set_labels_visible(v: bool) -> void:
	for l in labels:
		l.visible = v
