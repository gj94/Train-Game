extends RefCounted
## Builds the static 3D world from a RailWorld: terrain, track, overhead
## electrification, scenery, stations, signals and switch markers.
## Semi-realistic look: CC0 Poly Haven PBR textures + procedural geometry
## (sources in docs/assets.md).

const RAIL_TOP := 0.5
const TrackView := preload("res://game/track_view.gd")
const GAUGE_HALF := TrackView.RAIL_CENTRE # 1676 mm between gauge faces
const SIGNAL_SIDE := 2.8          # signals stand left of the track (India runs on the left)
const OHE_SPACING := 55.0
const OHE_OFFSET := 3.3           # mast distance from track centre
const CONTACT_HEIGHT := 5.6       # contact wire height above rail
const PH := "res://assets/polyhaven/%s/%s_%s_2k.jpg"
const PALM := "res://assets/models/palm_quaternius.glb"
const AxleJoint := preload("res://game/axle_joint.gd")
const HDRI := "res://assets/polyhaven/hdri/kloofendal_43d_clear_puresky_2k.hdr"
const Details := preload("res://game/station_details.gd")

var world: RailWorld
var root: Node3D
var signal_lamps := {}            # signal id -> [green, yellow, red] MeshInstance3D
var route_indicators := {}
var switch_markers := {}          # node id -> {label: Label3D, lamp: MeshInstance3D}
var labels: Array = []            # Label3D nodes to hide in cab view
var joint_markers := {}           # "edge|k" -> MeshInstance3D (rail-joint markers, J toggles)
var _joint_root: Node3D
var _flash := {}                  # "edge|k" -> seconds of red flash left
var _track_samples := PackedVector3Array()
var _mats := {}
var _box_meshes := {}
var _noise_tex: NoiseTexture2D
var _terrain_noise := FastNoiseLite.new()
var _fields: Array[Rect2] = []
var track_view
var scenery_plan
var scenery_library
var railway_clearance


func build(w: RailWorld, parent: Node3D) -> void:
	world = w
	root = Node3D.new()
	root.name = "World"
	parent.add_child(root)
	_noise_tex = NoiseTexture2D.new()
	_noise_tex.width = 512
	_noise_tex.height = 512
	_noise_tex.seamless = true
	var fnl := FastNoiseLite.new()
	fnl.frequency = 0.012
	fnl.fractal_octaves = 4
	_noise_tex.noise = fnl
	_terrain_noise.seed = 7
	_terrain_noise.frequency = 0.0018
	_terrain_noise.fractal_octaves = 5

	_build_environment()
	track_view = TrackView.new()
	track_view.build(self)
	railway_clearance=preload("res://game/scenery_clearance.gd").new(world.graph)
	if world.scenery.get("corridor",false):
		scenery_plan=preload("res://game/scenery_plan.gd").new()
		scenery_plan.build(world)
		scenery_library=preload("res://game/scenery_library.gd").new(self)
	else:
		for eid in world.graph.edges:
			for p in _samples(eid,2.0): _track_samples.append(p.pos)
	_build_terrain()
	_build_ohe()
	_build_stations()
	if world.scenery.get("corridor", false):
		preload("res://game/corridor_scenery.gd").new().build(self)
	_build_scenery()
	Details.new().build(self)
	for sid in world.signals:
		_build_signal(sid)
	for nid in world.graph.switches:
		_build_switch(nid)
	var speed_boards:=preload("res://game/track_speed_board_view.gd").new(world)
	for job in speed_boards.jobs:
		var chunk:=speed_boards.build(job)
		chunk.node.position=chunk.origin;root.add_child(chunk.node)


# --- materials ---------------------------------------------------------------

func mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(), emissive]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 4.0
	_mats[key] = m
	return m


func ph_tex(asset: String, map: String) -> Texture2D:
	return load(PH % [asset, asset, map])


## Triplanar world-space PBR material from a Poly Haven texture set.
## `metres` is the size of one texture repeat.
func pbr(asset: String, metres: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := "pbr|%s|%s|%s" % [asset, metres, tint.to_html()]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = ph_tex(asset, "diff")
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = ph_tex(asset, "nor_gl")
	m.roughness_texture = ph_tex(asset, "rough")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.uv1_triplanar_sharpness = 4.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


func steel() -> StandardMaterial3D:
	if not _mats.has("steel"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.42, 0.38, 0.34)
		m.metallic = 0.85
		m.roughness = 0.42
		_mats["steel"] = m
	return _mats["steel"]


func box(size: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	return box_m(size, pos, mat(color), parent)


func box_m(size: Vector3, pos: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if not _box_meshes.has(size):
		var bm := BoxMesh.new()
		bm.size = size
		_box_meshes[size]=bm
	mi.mesh = _box_meshes[size]
	mi.material_override = material
	mi.position = pos
	(parent if parent else root).add_child(mi)
	return mi


# --- environment -------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load(HDRI)
	sky_mat.energy_multiplier = 1.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.1
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = preload("res://game/railway_render_budget.gd").FOG_BEGIN
	env.fog_depth_end = preload("res://game/railway_render_budget.gd").FOG_END
	env.fog_depth_curve = 1.25
	env.fog_light_color = Color(0.78, 0.84, 0.85)
	# Depth fog uses maximum opacity, unlike exponential fog's density.
	env.fog_density = 1.0
	env.fog_sky_affect = 0.15
	env.fog_aerial_perspective = 0.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.94
	env.adjustment_contrast = 1.02
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.96, 0.89)
	sun.light_energy = 1.55
	sun.light_angular_distance = 0.6          # soft shadow edges
	sun.shadow_enabled = true
	sun.shadow_blur = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 300.0
	sun.directional_shadow_blend_splits = true
	sun.rotation_degrees = Vector3(-32, -42, 0)
	root.add_child(sun)


# --- track -------------------------------------------------------------------

## Samples an edge every `step` metres: [{pos, right, fwd, s}].
func _samples(eid: String, step: float) -> Array:
	var g := world.graph
	var e: Dictionary = g.edges[eid]
	var n := maxi(1, ceili(e.length / step))
	var out := []
	for i in n + 1:
		var s: float = e.length * i / n
		var fwd := g.tangent(eid, s, 1)
		out.append({pos = g.position(eid, s), right = fwd.cross(Vector3.UP).normalized(), fwd = fwd, s = s})
	return out


## Sweeps a 2D profile (x = right offset, y = height) along sample points.
## With `uvs`, UV.x runs 0..1 across the profile and UV.y is distance in metres.
func _extrude(pts: Array, profile: Array, uvs: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last := float(profile.size() - 1)
	for i in pts.size() - 1:
		var a: Dictionary = pts[i]
		var b: Dictionary = pts[i + 1]
		for j in profile.size() - 1:
			var p0: Vector2 = profile[j]
			var p1: Vector2 = profile[j + 1]
			var quad := [
				[a.pos + a.right * p0.x + Vector3.UP * p0.y, Vector2(j / last, a.s)],
				[b.pos + b.right * p0.x + Vector3.UP * p0.y, Vector2(j / last, b.s)],
				[a.pos + a.right * p1.x + Vector3.UP * p1.y, Vector2((j + 1) / last, a.s)],
				[b.pos + b.right * p1.x + Vector3.UP * p1.y, Vector2((j + 1) / last, b.s)],
			]
			for k in [0, 1, 2, 2, 1, 3]:
				if uvs:
					st.set_uv(quad[k][1])
				st.add_vertex(quad[k][0])
	st.generate_normals()
	if not uvs:
		return st.commit()
	st.generate_tangents()
	return st.commit()


func _add_mesh(mesh: Mesh, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	root.add_child(mi)
	return mi


# --- overhead electrification (25 kV AC OHE) ---------------------------------

func _build_ohe() -> void:
	var masts := []
	var arms := []
	var mast_mat := pbr("brushed_concrete", 2.0, Color(0.75, 0.74, 0.72))
	for eid in world.graph.edges:
		var e: Dictionary = world.graph.edges[eid]
		var pts := _samples(eid, 4.0)
		# Contact wire and catenary (messenger) wire along the whole edge.
		var h := RAIL_TOP + CONTACT_HEIGHT
		_add_mesh(_extrude(pts, [Vector2(-0.012, h), Vector2(0.012, h), Vector2(0.012, h + 0.025), Vector2(-0.012, h + 0.025), Vector2(-0.012, h)]), mat(Color(0.35, 0.28, 0.2)))
		_add_mesh(_extrude(pts, [Vector2(-0.01, h + 1.2), Vector2(0.01, h + 1.2), Vector2(0.01, h + 1.22), Vector2(-0.01, h + 1.22), Vector2(-0.01, h + 1.2)]), mat(Color(0.3, 0.3, 0.3)))
		var n := int(e.length / OHE_SPACING)
		for i in n + 1:
			var s := minf(e.length - 6.0, 6.0 + i * OHE_SPACING)
			if s < 0.0:
				continue
			var mast_direction: int = -world.graph.edges[eid].allowed_dir if world.graph.edges[eid].allowed_dir != 0 else 1
			var fwd := world.graph.tangent(eid, s, mast_direction)
			var right := fwd.cross(Vector3.UP).normalized()
			var base := world.graph.position(eid, s) + right * OHE_OFFSET
			if not _mast_site_ok(base):
				continue
			var basis := Basis.looking_at(fwd, Vector3.UP)
			masts.append(Transform3D(basis, base + Vector3(0, 4.3, 0)))
			# Cantilever arm reaching back over the track.
			arms.append(Transform3D(basis, base - right * (OHE_OFFSET * 0.5) + Vector3(0, h + 0.6, 0)))
	var mast := BoxMesh.new()
	mast.size = Vector3(0.35, 8.6, 0.35)
	_multimesh(mast, masts, mast_mat)
	var arm := BoxMesh.new()
	arm.size = Vector3(OHE_OFFSET + 0.4, 0.09, 0.09)
	_multimesh(arm, arms, steel())
	# Station portals support both roads without planting masts on platforms.
	for station in world.stations:
		var z0 := 1000.0
		var z1 := -1000.0
		for platform: Rect2 in station.platforms:
			z0 = minf(z0, platform.position.y - 2.0)
			z1 = maxf(z1, platform.end.y + 2.0)
		z0 = minf(z0, -4.0)
		z1 = maxf(z1, 4.0)
		for track_z in station.get("track_z", []):
			z0 = minf(z0, track_z - 3.4)
			z1 = maxf(z1, track_z + 3.4)
		var origin: Vector3 = station.origin
		for offset in range(-270, 300, 54):
			if absf(offset + 64.0) < 10.0:
				continue
			var x: float = origin.x + offset
			for z in [z0, z1]:
				box_m(Vector3(.5, .5, .5), Vector3(x, .25, z), mast_mat)
				box_m(Vector3(.22, 8.8, .22), Vector3(x, 4.4, z), steel())
			box_m(Vector3(.2, .3, z1-z0), Vector3(x, 8.4, (z0+z1)*.5), steel())
			var tracks := [0.0]
			if station.code == "CPM":
				tracks.append(-12.0)
			elif station.code == "MRT":
				tracks.append(12.0)
			tracks = station.get("track_z", tracks)
			for z in tracks:
				box(Vector3(.11, .65, .11), Vector3(x, 7.92, z), Color("7d6047"))
				box_m(Vector3(.04, 1.25, .04), Vector3(x, 6.9, z), steel())


## Keep masts off platforms and clear of other tracks.
func _mast_site_ok(p: Vector3) -> bool:
	for st in world.stations:
		for r: Rect2 in st.platforms:
			if r.grow(2.0).has_point(Vector2(p.x, p.z)):
				return false
	return railway_clearance.clear_point(p,2.9)


# --- terrain -----------------------------------------------------------------

## Flat Cauvery-delta setting around these Southern Railway station references.
func terrain_height(x: float, z: float) -> float:
	var hill := smoothstep(850.0, 1700.0, absf(z))
	var n := _terrain_noise.get_noise_2d(x, z) * 0.5 + 0.5
	var height := hill * (2.0 + n * 14.0) - 0.03
	for canal in world.scenery.get("canals", []):
		if absf(z) < 400:
			height -= (1.0-smoothstep(10.0,35.0,absf(x-canal)))*2.0
	return height


func _build_terrain() -> void:
	preload("res://game/terrain_scenery.gd").new().build(self)


func _far_from_track(p: Vector3, clearance: float) -> bool:
	if scenery_plan==null: return _legacy_far_from_track(p,clearance)
	if not railway_clearance.clear_point(p,clearance): return false
	if not scenery_plan.clear_land_point(p,3.5 if clearance>10 else .8): return false
	for x in world.scenery.overbridges+world.scenery.canals:
		if absf(p.x-x)<36 and absf(p.z)<450: return false
	for station in world.stations:
		for platform: Rect2 in station.platforms:
			if platform.grow(3).has_point(Vector2(p.x,p.z)): return false
		if absf(p.x-station.building.x)<72 and absf(p.z-station.building.z)<65: return false
	return true

func _legacy_far_from_track(p: Vector3, clearance: float) -> bool:
	if world.scenery.get("corridor", false):
		for x in world.scenery.overbridges + world.scenery.canals:
			if absf(p.x-x) < 36 and absf(p.z) < 450:
				return false
		for x in world.scenery.villages:
			if absf(p.x-x) < 225 and absf(p.z) < 350:
				return false
		for station in world.stations:
			var outward: float = signf(station.building.z)*p.z
			if absf(p.x-station.origin.x) < 420 and outward > 72 and outward < 230:
				return false
	for field in _fields:
		if field.has_point(Vector2(p.x, p.z)):
			return false
	var c2 := clearance * clearance
	for i in range(0, _track_samples.size(), 4):
		if Vector2(p.x - _track_samples[i].x, p.z - _track_samples[i].z).length_squared() < c2:
			return false
	for st in world.stations:
		for platform: Rect2 in st.platforms:
			if platform.grow(3.0).has_point(Vector2(p.x, p.z)):
				return false
		if absf(p.x - st.building.x) < 72.0 and absf(p.z - st.building.z) < 65.0:
			return false
		# Keep random trees out of the station street and house footprints.
		var side := -1.0 if st.building.z < 0 else 1.0
		var village_z: float = (p.z - st.building.z) * side
		if absf(p.x - st.building.x) < 113 and village_z > 25 and village_z < 85:
			return false
	return true


func _build_scenery() -> void:
	if scenery_plan==null:
		_build_legacy_scenery()
		return
	preload("res://game/settlement_scenery.gd").new().build(self,scenery_plan,scenery_library)
	preload("res://game/vegetation_scenery.gd").new().build(self,scenery_plan,scenery_library)
	preload("res://game/crop_scenery.gd").new().build(self,scenery_plan)
	scenery_library.flush()
	preload("res://game/road_traffic.gd").new().build(self,scenery_plan,scenery_library)

func _build_legacy_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260927
	var xmax: float = world.scenery.get("x_max", 5300.0)
	var density: float = (xmax+400.0)/5700.0

	# Paddy fields: flooded / green rice plots with low earth bunds.
	var paddy_green := pbr("leafy_grass", 3.0, Color(0.63, 0.80, 0.39))
	var paddy_water := ShaderMaterial.new()
	paddy_water.shader = load("res://game/shaders/paddy_water.gdshader")
	var bund := pbr("red_laterite_soil_stones", 3.0)
	for i in (0 if world.scenery.get("corridor",false) else int(150*density)):
		var p := Vector3(rng.randf_range(-400, xmax), 0, rng.randf_range(-420, 420))
		if not _far_from_track(p, 65.0):
			continue
		var in_village := false
		for station in world.stations:
			if absf(p.x - station.building.x) < 210 and absf(p.z - station.building.z) < 125:
				in_village = true
		if in_village:
			continue
		var size := Vector3(rng.randf_range(40, 90), 0.06, rng.randf_range(30, 70))
		_fields.append(Rect2(Vector2(p.x - size.x * 0.6, p.z - size.z * 0.6), Vector2(size.x, size.z) * 1.2))
		var field := Node3D.new()
		field.position = p
		field.rotation.y = rng.randf_range(-0.2, 0.2)
		root.add_child(field)
		var field_material: Material = paddy_green
		if rng.randf() >= 0.65:
			field_material = paddy_water
		box_m(size, Vector3.ZERO, field_material, field)
		for side in [-1, 1]:
			box_m(Vector3(size.x, 0.35, 0.8), Vector3(0, 0.1, side * size.z * 0.5), bund, field)
			box_m(Vector3(0.8, 0.35, size.z), Vector3(side * size.x * 0.5, 0.1, 0), bund, field)

	# Coconut palms (CC0 Quaternius model) in clumps, plenty near villages.
	var palm_scene: PackedScene = load(PALM)
	var palm_mesh: Mesh = null
	var palm_scale := 1.0
	var inst := palm_scene.instantiate()
	for n in inst.find_children("*", "MeshInstance3D", true, false):
		palm_mesh = n.mesh
		palm_scale = (n as Node3D).transform.basis.get_scale().x
		break
	inst.free()
	var palms := []
	var placed := 0
	while placed < int(1400*density):
		var centre := Vector3(rng.randf_range(-400, xmax), 0, rng.randf_range(-650, 650))
		var clump := rng.randi_range(3, 12)
		for k in clump:
			var p := centre + Vector3(rng.randf_range(-35, 35), 0, rng.randf_range(-35, 35))
			if not _far_from_track(p, 12.0):
				continue
			p.y = terrain_height(p.x, p.z)
			var s := palm_scale * rng.randf_range(2.9, 4.4)
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_euler(Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08)))
			palms.append(Transform3D(b.scaled(Vector3(s, s, s)), p))
			placed += 1
	# Planted forecourt trees, outside the train/footbridge and vehicle envelopes.
	for station in world.stations:
		var side := signf(station.building.z)
		for x in [-49, 49]:
			for dz in [15, 30]:
				var p: Vector3 = station.building + Vector3(x, .7, side * dz)
				palms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * palm_scale * 3.2), p))
	if palm_mesh:
		_multimesh(palm_mesh, palms, null)

	# Broadleaf trees (mango / banyan-ish): textured crowns.
	var crowns := []
	var trunks := []
	placed = 0
	while placed < int(320*density):
		var p := Vector3(rng.randf_range(-400, xmax), 0, rng.randf_range(-700, 700))
		if not _far_from_track(p, 16.0):
			continue
		placed += 1
		p.y = terrain_height(p.x, p.z)
		var r := rng.randf_range(3.0, 6.0)
		trunks.append(Transform3D(Basis().scaled(Vector3(1.6, r / 5.0, 1.6)), p + Vector3(0, r * 0.5, 0)))
		for k in 9:
			var off := Vector3(rng.randf_range(-r, r) * 0.6, rng.randf_range(-r * 0.2, r * 0.45), rng.randf_range(-r, r) * 0.6)
			crowns.append(Transform3D(Basis().scaled(Vector3(r, r * 0.85, r) * rng.randf_range(0.35, 0.66)), p + Vector3(0, r * 1.5, 0) + off))
	var crown_mesh := SphereMesh.new()
	crown_mesh.radial_segments = 16
	crown_mesh.rings = 10
	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	_multimesh(crown_mesh, crowns, mat(Color("365a35")))
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 5.0
	trunk_mesh.radial_segments = 7
	_multimesh(trunk_mesh, trunks, mat(Color(0.32, 0.25, 0.19)))


func _multimesh(mesh: Mesh, xforms: Array, material: Material) -> void:
	for group in preload("res://game/spatial_batches.gd").split(xforms).values():
		_instance_batch(mesh,group.transforms,material,group.origin)

func _instance_batch(mesh: Mesh, xforms: Array, material: Material, origin: Vector3) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "SceneryBatch"
	mmi.position = origin
	mmi.multimesh = mm
	if material:
		mmi.material_override = material
	root.add_child(mmi)


# --- stations ----------------------------------------------------------------

func _build_stations() -> void:
	var surface_shader := load("res://game/shaders/station_surface.gdshader") as Shader
	var finishes := {}
	for station in world.stations:
		var kit := load("res://assets/models/stations/%s%s.glb" % [station.kit, station.get("asset_variant", "")]) as PackedScene
		var model := kit.instantiate() as Node3D
		model.name = "Station_" + station.code
		model.position = station.origin
		root.add_child(model)
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for s in mesh.mesh.get_surface_count():
				var original := mesh.mesh.surface_get_material(s) as StandardMaterial3D
				if original == null or not original.resource_name.begins_with("SR_"):
					continue
				var key: String = original.resource_name
				if not finishes.has(key):
					var finish := ShaderMaterial.new()
					finish.shader = surface_shader
					finish.set_shader_parameter("base_color", original.albedo_color)
					finish.set_shader_parameter("surface_roughness", original.roughness)
					finish.set_shader_parameter("surface_metallic", original.metallic)
					var role: String = key.get_slice(".",0).trim_prefix("SR_")
					var asset := "plastered_wall"
					var kind := 0
					var metres := 2.0
					if role in ["Paver","PaverPale","TileBlue","TileWhite"]:
						asset="brushed_concrete"; kind=1; metres=1.5
					elif role.begins_with("Roof"):
						asset="brushed_concrete"; kind=2; metres=1.2
					elif role in ["Concrete","Coping","Sandstone"]:
						asset="brushed_concrete"; kind=3; metres=2.0
					elif role=="Asphalt":
						asset="aerial_asphalt_01"; kind=4; metres=8.0
					elif role=="Glass": kind=5
					elif role in ["Steel","DarkSteel","Blue","White"]:
						asset="brushed_concrete"; kind=6
					finish.set_shader_parameter("surface_kind",kind)
					finish.set_shader_parameter("metres",metres)
					for pair in [["surface_albedo","diff"],["surface_normal","nor_gl"],["surface_rough","rough"]]:
						finish.set_shader_parameter(pair[0],ph_tex(asset,pair[1]))
					finishes[key] = finish
				mesh.set_surface_override_material(s, finishes[key])

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

	box_m(Vector3(0.6, 0.4, 0.6), Vector3(0, 0.2, 0), pbr("brushed_concrete", 1.0), node)
	box_m(Vector3(0.16, 5.4, 0.16), Vector3(0, 2.9, 0), steel(), node)
	box(Vector3(0.6, 1.65, 0.3), Vector3(0, 5.6, 0), Color(0.05, 0.05, 0.05), node)
	box(Vector3(0.9, 1.95, 0.04), Vector3(0, 5.6, 0.12), Color(0.03, 0.03, 0.03), node)    # backplate
	# Signal post marking: white plate with black band.
	box(Vector3(0.5, 0.3, 0.05), Vector3(0, 3.8, -0.12), Color(0.95, 0.95, 0.95), node)
	box(Vector3(0.5, 0.08, 0.06), Vector3(0, 3.8, -0.12), Color(0.05, 0.05, 0.05), node)
	var lamps := []
	for k in 3:  # top to bottom: green, yellow, red
		box(Vector3(0.4, 0.06, 0.25), Vector3(0, 6.24 - k * 0.5, -0.25), Color(0.05, 0.05, 0.05), node)   # hood
		var lamp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.15
		sm.height = 0.3
		sm.radial_segments = 12
		sm.rings = 6
		lamp.mesh = sm
		lamp.position = Vector3(0, 6.1 - k * 0.5, -0.12)
		node.add_child(lamp)
		lamps.append(lamp)
	signal_lamps[sid] = lamps
	if sid in world.automatic_signals:
		box(Vector3(.44,.5,.06),Vector3(0,4.25,-.13),Color("e7e4d6"),node)
		var plate := Label3D.new()
		plate.text = "A"
		plate.font_size = 64
		plate.pixel_size = .005
		plate.modulate = Color("171f24")
		plate.outline_size = 0
		plate.rotation.y = PI
		plate.position = Vector3(0,4.25,-.18)
		node.add_child(plate)
	elif sid in ["CPM-H","MRT-HE","MRT-HW","KDP-H"] and world.scenery.get("corridor",false):
		box(Vector3(.72,.75,.28),Vector3(0,6.95,0),Color("182125"),node)
		var indicator := Label3D.new()
		indicator.font_size = 64
		indicator.pixel_size = .009
		indicator.outline_size = 0
		indicator.rotation.y = PI
		indicator.position = Vector3(0,6.95,-.16)
		node.add_child(indicator)
		route_indicators[sid] = indicator

	var label := Label3D.new()
	label.text = sid
	label.position = Vector3(0, 7.6, 0)
	_style_marker_label(label)
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
	for offset in [4.5,-4.5,8.5,-8.5,12.5]:
		pos = g.position(sw.trunk,s)+fwd.cross(Vector3.UP).normalized()*offset
		if _mast_site_ok(pos): break
	# Fouling marker between the diverging roads at the clearance location.
	var ends := []
	for eid in [sw.normal,sw.reverse]:
		var direction := 1 if g.edges[eid].a == nid else -1
		ends.append(g.position(eid,g.entry_s(eid,direction)+direction*sw.clearance))
	box(Vector3(1.0,.15,.25),(ends[0]+ends[1])*.5+Vector3.UP*.24,Color("e4dba9"))
	var node := Node3D.new()
	node.position = pos
	root.add_child(node)
	box_m(Vector3(1.0, 0.6, 0.6), Vector3(0, 0.3, 0), steel(), node)   # point machine
	var lamp := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.13
	cm.bottom_radius = 0.13
	cm.height = 0.22
	cm.radial_segments = 4
	lamp.mesh = cm
	lamp.position = Vector3(0, 0.66, 0)
	node.add_child(lamp)
	var label := Label3D.new()
	label.position = Vector3(0, 3.0, 0)
	_style_marker_label(label)
	node.add_child(label)
	labels.append(label)
	switch_markers[nid] = {label = label, lamp = lamp}
	_clickable(node, Vector3(3, 3, 3), Vector3(0, 1.0, 0), {kind = "switch", id = nid})


## Constant on-screen size so ids stay readable from far away.
func _style_marker_label(label: Label3D) -> void:
	label.font_size = 36
	label.pixel_size = 0.025
	label.fixed_size = false
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.outline_size = 5
	label.visibility_range_end = 260.0


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
	track_view.update_points()
	var dark := Color(0.1, 0.1, 0.1)
	var colors := [Color(0.1, 1.0, 0.35), Color(1.0, 0.72, 0.05), Color(1.0, 0.08, 0.05)]
	for sid in signal_lamps:
		var a := world.aspect(sid)
		var lit := 0 if a == RailWorld.Aspect.GREEN else (1 if a == RailWorld.Aspect.YELLOW else 2)
		for k in 3:
			signal_lamps[sid][k].material_override = mat(colors[k], true) if k == lit else mat(dark)
		if route_indicators.has(sid):
			route_indicators[sid].text = world.signals[sid].destination.right(1) if a != RailWorld.Aspect.RED else ""
	for nid in switch_markers:
		var m: Dictionary = switch_markers[nid]
		var rev: bool = world.graph.switches[nid].reversed
		var locked := world.switch_lock_reason(nid) != ""
		m.label.text = "%s  %s%s" % [nid, "R" if rev else "N", "  (locked)" if locked else ""]
		m.lamp.material_override = mat(Color("b8a779") if rev else Color("b5b4ab"))
		m.lamp.rotation.y = PI * .5 if rev else 0.0


# --- rail-joint markers (where the track sound comes from) --------------------

## A yellow bar across the rails at every rail joint the sound model uses.
func build_joints(spacing: float, offset: float) -> void:
	_joint_root = Node3D.new()
	_joint_root.name = "RailJoints"
	root.add_child(_joint_root)
	var bar := BoxMesh.new()
	bar.size = Vector3(2.6, 0.06, 0.18)
	for eid in world.graph.edges:
		var e: Dictionary = world.graph.edges[eid]
		var ss := AxleJoint.joints_on_edge(e.length, spacing, offset)
		for k in ss.size():
			var s: float = ss[k]
			var mi := MeshInstance3D.new()
			mi.mesh = bar
			mi.material_override = mat(Color(1.0, 0.8, 0.05), true)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.basis = Basis.looking_at(world.graph.tangent(eid, s, 1), Vector3.UP)
			mi.position = world.graph.position(eid, s) + Vector3(0, RAIL_TOP + 0.04, 0)
			_joint_root.add_child(mi)
			# Joint k counts from the edge start: keep the index even if a joint is skipped.
			joint_markers["%s|%d" % [eid, roundi((s - offset) / spacing)]] = mi


## Flash a joint red when an axle hits it.
func flash_joint(edge: String, k: int) -> void:
	var key := "%s|%d" % [edge, k]
	if joint_markers.has(key):
		_flash[key] = 0.35
		joint_markers[key].material_override = mat(Color(1.0, 0.1, 0.05), true)
		joint_markers[key].scale = Vector3(1.3, 3.0, 2.0)


func update_joints(delta: float) -> void:
	for key in _flash.keys():
		_flash[key] -= delta
		if _flash[key] <= 0.0:
			_flash.erase(key)
			joint_markers[key].material_override = mat(Color(1.0, 0.8, 0.05), true)
			joint_markers[key].scale = Vector3.ONE


func set_joints_visible(v: bool) -> void:
	if _joint_root:
		_joint_root.visible = v


func joints_visible() -> bool:
	return _joint_root != null and _joint_root.visible


func set_labels_visible(v: bool) -> void:
	for l in labels:
		l.visible = v
