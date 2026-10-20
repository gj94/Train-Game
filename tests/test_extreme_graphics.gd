extends RefCounted
## Extreme is a local rendering choice, not a new simulation or asset budget.
const Options := preload("res://game/graphics_options.gd")
const Extreme := preload("res://game/extreme_visuals.gd")
const Hud := preload("res://game/hud.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const Visibility := preload("res://game/train_visibility.gd")
const GeographicWorld := preload("res://game/geographic_world.gd")
const LEGACY_HIGH := {
	scale=1.0,msaa=3,fxaa=true,vsync=true,fps=0,shadows=8192,
	shadow_distance=300.0,shadow_filter=3,ssao=true,ssil=true,glow=true,
	view_distance=2200.0,vegetation_density=1.0,vegetation_distance=1.0,
	building_distance=1.0,mesh_detail=1.0,train_detail=1.0,passengers=1.0,
	surface_detail=false,reflections=false
}
const LEGACY_OVERRIDES := {
	High={},
	Balanced={msaa=2,shadows=4096,shadow_filter=1,mesh_detail=2.0},
	Performance={scale=0.85,msaa=1,shadows=2048,shadow_distance=100.0,
		shadow_filter=1,ssil=false,view_distance=1800.0,vegetation_density=0.75,
		vegetation_distance=0.5,building_distance=0.5,mesh_detail=4.0,
		train_detail=0.5,passengers=0.5}
}
const SURFACES := [
	"res://game/shaders/geographic_ground.gdshader",
	"res://game/shaders/scenery_road.gdshader",
	"res://game/shaders/station_surface.gdshader",
	"res://game/shaders/geographic_water.gdshader"
]
const REFLECTION_FIELDS := [
	"ssr_enabled","ssr_max_steps","ssr_fade_in","ssr_fade_out","ssr_depth_tolerance"
]

class Camera extends Camera3D:
	var mode := 0
	var _blend := 1.0

class Host extends Node3D:
	var cam: Camera
	var wv: Dictionary
	var world: RailWorld
	var train: Train
	var train_views := {}
	var passenger_crowd := {render_budget=1.0}
	var graphics_options
	var hud
	var paused := false
	var labels_enabled := false
	func _set_paused(value: bool) -> void:
		paused=value

func legacy_values(label: String) -> Dictionary:
	var result := LEGACY_HIGH.duplicate(true)
	result.merge(LEGACY_OVERRIDES[label],true)
	return result

func fixture() -> Dictionary:
	# Keep viewport changes local to the fixture, not the headless test runner.
	var viewport := SubViewport.new()
	viewport.size=Vector2i(1280,720)
	Engine.get_main_loop().root.add_child(viewport)
	var host := Host.new()
	viewport.add_child(host)
	host.cam=Camera.new()
	host.add_child(host.cam)
	var world := Node3D.new()
	host.add_child(world)
	host.wv={root=world}
	var settings := Options.new()
	settings.game=host
	host.graphics_options=settings
	return {viewport=viewport,host=host,root=world,settings=settings}

func vegetation(label: String,begin: float,finish: float,count: int=24) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.name=label
	node.set_meta("scenery_kind","tf3_KL_LS_Coconut_Tall_A")
	node.multimesh=MultiMesh.new()
	node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	node.multimesh.mesh=BoxMesh.new()
	node.multimesh.instance_count=count
	for i in count:
		node.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(i*3,0,i*2)))
	node.visibility_range_begin=begin
	node.visibility_range_end=finish
	node.visibility_range_begin_margin=8
	node.visibility_range_end_margin=10
	return node

func surface_node(material: ShaderMaterial,mode: int) -> GeometryInstance3D:
	var mesh := BoxMesh.new()
	if mode==3:
		mesh.material=material
		var multi := MultiMeshInstance3D.new()
		multi.multimesh=MultiMesh.new()
		multi.multimesh.mesh=mesh
		multi.multimesh.instance_count=4
		return multi
	var node := MeshInstance3D.new()
	node.mesh=mesh
	if mode==0:node.material_override=material
	elif mode==1:mesh.material=material
	else:node.set_surface_override_material(0,material)
	return node

func reflection_values(environment: Environment) -> Dictionary:
	var result := {}
	for key in REFLECTION_FIELDS:result[key]=environment.get(key)
	result.sky=environment.sky
	if environment.sky!=null:
		result.radiance_size=environment.sky.radiance_size
		result.process_mode=environment.sky.process_mode
	return result

func test_legacy_presets_remain_exact_and_new_install_stays_high():
	var settings := Options.new()
	if settings.values!=LEGACY_HIGH or settings.preset_name()!="High":
		return "New installations no longer use the exact legacy High settings"
	for label in LEGACY_OVERRIDES:
		settings.preset("Extreme")
		settings.preset(label)
		if settings.values!=legacy_values(label):
			return "Legacy preset changed: "+label
		if settings.preset_name()!=label:return "Legacy preset mislabeled: "+label
	return true

func test_extreme_changes_only_the_explicit_render_quality_options():
	var settings := Options.new()
	settings.preset("Extreme")
	var expected := LEGACY_HIGH.duplicate(true)
	expected.merge({surface_detail=true,reflections=true,fxaa=false,
		vegetation_distance=1.5,building_distance=1.5,train_detail=1.5,mesh_detail=0.5},true)
	if settings.values!=expected or settings.preset_name()!="Extreme":
		return "Extreme changed an unapproved setting or omitted a quality improvement"
	for key in expected:
		if not settings.set_option(key,expected[key]):return "Invalid Extreme choice: "+key
	for key in ["vegetation_distance","building_distance","train_detail","mesh_detail"]:
		if settings.set_option(key,int(expected[key])):return "Integer coercion accepted for "+key
	settings.set_option("surface_detail",false)
	return settings.preset_name()=="Custom"

func test_old_preferences_migrate_without_enabling_extreme():
	var settings := Options.new()
	settings.settings_path="user://extreme-legacy-migration-test.cfg"
	var failure := ""
	for label in LEGACY_OVERRIDES:
		var expected := legacy_values(label)
		var config := ConfigFile.new()
		for key in expected:
			if key not in ["surface_detail","reflections"]:config.set_value("graphics",key,expected[key])
		if config.save(settings.settings_path)!=OK:
			failure="Could not write isolated old-format preference fixture"
			break
		settings.preset("Extreme")
		settings.restore()
		if settings.values!=expected or settings.preset_name()!=label:
			failure="Old "+label+" preferences silently enabled Extreme or changed legacy values"
			break
	DirAccess.remove_absolute(settings.settings_path)
	return true if failure.is_empty() else failure

func test_extreme_preferences_round_trip_and_reject_non_boolean_flags():
	var settings := Options.new()
	settings.settings_path="user://extreme-preferences-round-trip-test.cfg"
	settings.preset("Extreme")
	if settings.save()!=OK:return "Could not save isolated Extreme preference fixture"
	var restored := Options.new()
	restored.settings_path=settings.settings_path
	restored.restore()
	var ok := restored.values==settings.values and restored.preset_name()=="Extreme"
	var config := ConfigFile.new()
	config.load(settings.settings_path)
	config.set_value("graphics","surface_detail",1)
	config.set_value("graphics","reflections","true")
	config.set_value("graphics","vegetation_distance",INF)
	config.set_value("graphics","mesh_detail",0)
	config.save(settings.settings_path)
	restored.restore()
	ok=ok and not restored.values.surface_detail and not restored.values.reflections
	ok=ok and restored.values.vegetation_distance==1.0 and restored.values.mesh_detail==1.0
	DirAccess.remove_absolute(settings.settings_path)
	return ok

func test_extreme_lods_match_late_streams_without_adding_or_moving_instances():
	var settings := Options.new()
	settings.preset("Extreme")
	var root := Node3D.new()
	var near := vegetation("Tree",0,45)
	var middle := vegetation("TreeLOD",45,95)
	var far := vegetation("Image",95,2700)
	far.set_meta("impostor",true)
	var legacy := vegetation("Canopy_rain_tree",95,2700)
	legacy.remove_meta("scenery_kind")
	var nodes := [near,middle,far,legacy]
	var buffers := []
	for node in nodes:
		root.add_child(node)
		buffers.append(node.multimesh.buffer.duplicate())
	for repeat in 3:settings.apply_tree(root)
	var ok := near.visibility_range_end==67.5 and middle.visibility_range_begin==67.5
	ok=ok and middle.visibility_range_end==142.5 and far.visibility_range_begin==142.5
	ok=ok and legacy.visibility_range_begin==142.5 and far.visibility_range_end==2700
	ok=ok and legacy.visibility_range_end==2700 and far.visibility_range_end_margin==10
	# This is how a newly activated geographic chunk receives the current settings.
	var late := vegetation("LateTreeLOD",45,95)
	root.add_child(late)
	settings.apply_tree(late)
	ok=ok and late.visibility_range_begin==middle.visibility_range_begin
	ok=ok and late.visibility_range_end==middle.visibility_range_end
	settings.preset("Performance")
	settings.apply_tree(root)
	settings.preset("Extreme")
	settings.apply_tree(root)
	for i in nodes.size():
		ok=ok and nodes[i].multimesh.instance_count==24
		ok=ok and nodes[i].multimesh.visible_instance_count==-1
		ok=ok and nodes[i].multimesh.buffer==buffers[i]
	settings.preset("High")
	settings.apply_tree(root)
	ok=ok and near.visibility_range_end==45 and middle.visibility_range_begin==45
	ok=ok and middle.visibility_range_end==95 and far.visibility_range_begin==95
	ok=ok and legacy.visibility_range_begin==95 and late.visibility_range_end==95
	for node in root.get_children():
		ok=ok and node.multimesh.visible_instance_count==-1
		ok=ok and node.visibility_range_begin_margin==8 and node.visibility_range_end_margin==10
	ok=ok and root.get_child_count()==5
	root.free()
	return ok

func test_extreme_building_lods_restore_and_never_extend_rail_geometry():
	var settings := Options.new()
	var root := Node3D.new()
	var house := MeshInstance3D.new()
	house.set_meta("house_lod_role",0)
	house.set_meta("scenery_kind","balcony_villa")
	house.visibility_range_end=180
	house.visibility_range_end_margin=20
	var image := MeshInstance3D.new()
	image.set_meta("house_lod_role",1)
	image.set_meta("scenery_kind","balcony_villa")
	image.set_meta("impostor",true)
	image.visibility_range_begin=180
	image.visibility_range_begin_margin=20
	image.visibility_range_end=1800
	var rail := MeshInstance3D.new()
	rail.mesh=BoxMesh.new()
	rail.visibility_range_end=650
	var vertices := rail.mesh.get_faces()
	for node in [house,image,rail]:root.add_child(node)
	settings.preset("Extreme")
	settings.apply_tree(root)
	settings.apply_tree(root)
	var ok := house.visibility_range_end==270 and image.visibility_range_begin==270
	ok=ok and house.visibility_range_end_margin==30 and image.visibility_range_begin_margin==30
	ok=ok and image.visibility_range_end==1800 and rail.visibility_range_end==650
	ok=ok and rail.mesh.get_faces()==vertices and root.get_child_count()==3
	settings.preset("High")
	settings.apply_tree(root)
	ok=ok and house.visibility_range_end==180 and image.visibility_range_begin==180
	ok=ok and house.visibility_range_end_margin==20 and image.visibility_range_begin_margin==20
	root.free()
	return ok

func test_surface_shader_contract_is_per_instance_zero_by_default():
	var declaration := RegEx.new()
	declaration.compile("instance\\s+uniform\\s+float\\s+extreme_detail\\s*:\\s*instance_index\\(\\s*15\\s*\\)\\s*=\\s*0(\\.0+)?\\s*;")
	for path in SURFACES:
		var source := FileAccess.get_file_as_string(path)
		if declaration.search(source)==null:
			return "Missing isolated, legacy-zero Extreme uniform in "+path
	return true

func test_surface_detail_is_per_geometry_and_never_mutates_shared_materials():
	var settings := Options.new()
	var root := Node3D.new()
	var failure := ""
	for path in SURFACES:
		var material := ShaderMaterial.new()
		material.shader=load(path)
		var shader_code := material.shader.code
		var material_value: Variant=material.get_shader_parameter("extreme_detail")
		var nodes := []
		for mode in 4:
			var node := surface_node(material,mode)
			root.add_child(node)
			nodes.append(node)
			if not Extreme.supports_surface(node):failure="Unsupported material path %d: %s" % [mode,path]
		settings.preset("Extreme")
		for node in nodes:settings.apply_tree(node)
		for node in nodes:
			if node.get_instance_shader_parameter("extreme_detail")!=1.0:
				failure="Extreme flag was not applied per geometry: "+path
		settings.preset("High")
		settings.apply_tree(nodes[0])
		if nodes[0].get_instance_shader_parameter("extreme_detail")!=0.0:
			failure="High did not clear its geometry flag: "+path
		for i in range(1,nodes.size()):
			if nodes[i].get_instance_shader_parameter("extreme_detail")!=1.0:
				failure="Changing one geometry changed a shared material peer: "+path
		if material.get_shader_parameter("extreme_detail")!=material_value or material.shader.code!=shader_code:
			failure="Shared shader resource was mutated: "+path
		for node in nodes:settings.apply_tree(node)
		for node in nodes:
			if node.get_instance_shader_parameter("extreme_detail")!=0.0:
				failure="Surface detail did not restore to High: "+path
		if not failure.is_empty():break
	root.free()
	return true if failure.is_empty() else failure

func test_surface_detection_ignores_unrelated_and_overridden_materials():
	var material := ShaderMaterial.new()
	material.shader=load(SURFACES[0])
	var supported := surface_node(material,1)
	var blocked := surface_node(material,1)
	blocked.material_override=StandardMaterial3D.new()
	var unrelated := MeshInstance3D.new()
	unrelated.mesh=BoxMesh.new()
	var unrelated_material := ShaderMaterial.new()
	unrelated_material.shader=load("res://game/shaders/track_rail.gdshader")
	unrelated.material_override=unrelated_material
	var empty := MeshInstance3D.new()
	var settings := Options.new()
	settings.preset("Extreme")
	var ok := Extreme.supports_surface(supported)
	for node in [blocked,unrelated,empty]:
		ok=ok and not Extreme.supports_surface(node)
		var before: Variant=node.get_instance_shader_parameter("extreme_detail")
		settings.apply_tree(node)
		ok=ok and node.get_instance_shader_parameter("extreme_detail")==before
		ok=ok and not node.has_meta(Extreme.SURFACE_STATE)
	for node in [supported,blocked,unrelated,empty]:node.free()
	return ok

func test_replacing_supported_surface_material_clears_stale_instance_detail():
	var settings := Options.new()
	var root := Node3D.new()
	var ok := true
	for path in SURFACES:
		var material := origin_material(path)
		var peer := surface_node(material,0)
		root.add_child(peer)
		settings.preset("Extreme")
		settings.apply_tree(peer)
		for mode in 4:
			var node := surface_node(material,mode)
			root.add_child(node)
			settings.apply_tree(node)
			ok=ok and node.get_instance_shader_parameter("extreme_detail")==1.0
			ok=ok and node.has_meta(Extreme.SURFACE_STATE)
			node.material_override=StandardMaterial3D.new()
			settings.apply_tree(node)
			ok=ok and not Extreme.supports_surface(node)
			ok=ok and node.get_instance_shader_parameter("extreme_detail")==null
			ok=ok and not node.has_meta(Extreme.SURFACE_STATE)
			ok=ok and peer.get_instance_shader_parameter("extreme_detail")==1.0
			# Reusing the same geometry for a supported finish remains reversible.
			node.material_override=material
			settings.apply_tree(node)
			ok=ok and node.get_instance_shader_parameter("extreme_detail")==1.0
			settings.preset("High")
			settings.apply_tree(node)
			ok=ok and node.get_instance_shader_parameter("extreme_detail")==0.0
			settings.preset("Extreme")
	root.free()
	return ok

func test_reflections_restore_exact_original_values_after_repeated_toggles():
	var settings := Options.new()
	var node := WorldEnvironment.new()
	node.environment=Environment.new()
	var environment := node.environment
	environment.ssr_enabled=true
	environment.ssr_max_steps=47
	environment.ssr_fade_in=0.37
	environment.ssr_fade_out=3.2
	environment.ssr_depth_tolerance=0.61
	environment.sky=Sky.new()
	environment.sky.radiance_size=Sky.RADIANCE_SIZE_128
	environment.sky.process_mode=Sky.PROCESS_MODE_INCREMENTAL
	var original := reflection_values(environment)
	var ok := true
	for repeat in 3:
		settings.preset("Extreme")
		settings.apply_tree(node)
		settings.apply_tree(node)
		ok=ok and environment.ssr_enabled and environment.ssr_max_steps==96
		ok=ok and is_equal_approx(environment.ssr_fade_in,0.15)
		ok=ok and is_equal_approx(environment.ssr_fade_out,2.0)
		ok=ok and is_equal_approx(environment.ssr_depth_tolerance,0.25)
		ok=ok and environment.sky.radiance_size==Sky.RADIANCE_SIZE_512
		ok=ok and environment.sky.process_mode==Sky.PROCESS_MODE_INCREMENTAL
		settings.preset("High")
		settings.apply_tree(node)
		ok=ok and reflection_values(environment)==original
	node.free()
	return ok

func test_reflections_are_safe_without_sky_and_do_not_cross_environment_instances():
	var settings := Options.new()
	var a := WorldEnvironment.new()
	var b := WorldEnvironment.new()
	a.environment=Environment.new()
	b.environment=Environment.new()
	b.environment.ssr_max_steps=23
	b.environment.sky=Sky.new()
	b.environment.sky.radiance_size=Sky.RADIANCE_SIZE_256
	var original_a := reflection_values(a.environment)
	var original_b := reflection_values(b.environment)
	settings.preset("Extreme")
	settings.apply_tree(a)
	var ok := a.environment.ssr_enabled and a.environment.sky==null
	ok=ok and reflection_values(b.environment)==original_b
	settings.apply_tree(b)
	ok=ok and b.environment.sky.radiance_size==Sky.RADIANCE_SIZE_512
	settings.preset("High")
	settings.apply_tree(a)
	ok=ok and reflection_values(a.environment)==original_a and b.environment.ssr_enabled
	settings.apply_tree(b)
	ok=ok and reflection_values(b.environment)==original_b
	a.free()
	b.free()
	return ok

func test_extreme_ui_action_is_reachable_applies_and_saves_without_touching_simulation():
	var s := fixture()
	var host: Host=s.host
	var settings=s.settings
	var fps := Engine.max_fps
	host.world=Traffic.build()
	host.train=host.world.trains.T1
	var before := Snapshot.capture(host.world)
	settings.settings_path="user://extreme-menu-action-test.cfg"
	host.hud=Hud.new()
	host.hud.graphics_options=settings
	host.add_child(host.hud)
	host.hud.show_modal("graphics")
	var actions := []
	for button in host.hud._buttons.get_children():actions.append(button.get_meta("action"))
	var ok := actions.count("graphics:preset:Extreme")==1
	settings.action("graphics:preset:Extreme")
	ok=ok and host.paused and host.hud.modal=="graphics" and settings.preset_name()=="Extreme"
	var restored := Options.new()
	restored.settings_path=settings.settings_path
	restored.restore()
	ok=ok and restored.values==settings.values and host.hud._body.text.contains("Extreme")
	ok=ok and s.viewport.mesh_lod_threshold==0.5 and s.viewport.msaa_3d==3
	ok=ok and s.viewport.screen_space_aa==Viewport.SCREEN_SPACE_AA_DISABLED
	ok=ok and s.viewport.scaling_3d_scale==1.0 and host.cam.far==2200
	ok=ok and host.passenger_crowd.render_budget==1.0
	for key in ["surface_detail","reflections"]:
		host.hud.show_modal("graphics:"+Options.OPTIONS[key].group)
		actions.clear()
		for button in host.hud._buttons.get_children():actions.append(button.get_meta("action"))
		ok=ok and actions.has("graphics:option:"+key)
	settings.action("graphics:preset:High")
	ok=ok and settings.values==LEGACY_HIGH and s.viewport.mesh_lod_threshold==1.0
	ok=ok and s.viewport.screen_space_aa==Viewport.SCREEN_SPACE_AA_FXAA
	ok=ok and Snapshot.capture(host.world)==before
	Engine.max_fps=fps
	DirAccess.remove_absolute(settings.settings_path)
	s.viewport.free()
	return ok

func test_all_render_presets_leave_real_railway_checkpoint_byte_identical():
	var s := fixture()
	var host: Host=s.host
	var settings=s.settings
	var fps := Engine.max_fps
	host.world=Traffic.build()
	host.train=host.world.trains.T1
	host.world.step(0.25)
	var before := var_to_bytes(Snapshot.capture(host.world))
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	s.root.add_child(env)
	var sun := DirectionalLight3D.new()
	s.root.add_child(sun)
	var tree := vegetation("Tree",0,45)
	s.root.add_child(tree)
	var ok := true
	for label in ["Extreme","Performance","Balanced","High","Extreme","High"]:
		settings.preset(label)
		settings.apply()
		ok=ok and var_to_bytes(Snapshot.capture(host.world))==before
	ok=ok and not host.paused and host.train==host.world.trains.T1
	Engine.max_fps=fps
	s.viewport.free()
	return ok

func test_extreme_train_distance_expands_only_presentation_then_restores():
	var s := fixture()
	var host: Host=s.host
	host.train=Train.new("Player",100)
	var car := Node3D.new()
	host.add_child(car)
	car.position=Vector3(80,0,0)
	var interior := MeshInstance3D.new()
	car.add_child(interior)
	var shadow := MeshInstance3D.new()
	car.add_child(shadow)
	var proxy := MeshInstance3D.new()
	car.add_child(proxy)
	var view := {
		cars=[car],interior_meshes=[[interior]],interior_visible=[true],
		shadow_parts=[[{node=shadow,mode=GeometryInstance3D.SHADOW_CASTING_SETTING_ON}]],
		shadow_proxies=[proxy],shadow_detail=[true]
	}
	var before := Snapshot.fields(host.train,Snapshot.TRAIN)
	s.settings.preset("High")
	Visibility.apply(host,view,"Other")
	var ok: bool=not view.shadow_detail[0] and proxy.visible and not view.interior_visible[0]
	s.settings.preset("Extreme")
	Visibility.apply(host,view,"Other")
	ok=ok and view.shadow_detail[0] and not proxy.visible and not view.interior_visible[0]
	car.position=Vector3(40,0,0)
	Visibility.apply(host,view,"Other")
	ok=ok and view.interior_visible[0]
	s.settings.preset("High")
	Visibility.apply(host,view,"Other")
	ok=ok and not view.interior_visible[0]
	ok=ok and Snapshot.fields(host.train,Snapshot.TRAIN)==before
	ok=ok and car.get_child_count()==3 and view.cars.size()==1
	s.viewport.free()
	return ok

func origin_material(path: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader=load(path)
	return material

func test_route_origin_only_updates_owned_eligible_materials_and_preserves_resources():
	var road := origin_material(SURFACES[1])
	var station := origin_material(SURFACES[2])
	var authored_cache := origin_material(SURFACES[1])
	var water := origin_material(SURFACES[3])
	var ground := origin_material(SURFACES[0])
	var unrelated := origin_material("res://game/shaders/track_rail.gdshader")
	var texture := GradientTexture2D.new()
	var shader: Shader=road.shader
	road.set_shader_parameter("surface_albedo",texture)
	road.set_shader_parameter("tint",Vector3(0.23,0.41,0.57))
	road.set_shader_parameter("metres",5.0)
	station.set_shader_parameter("surface_normal",texture)
	station.set_shader_parameter("surface_roughness",0.63)
	var original_water := Vector3(17,0,29)
	water.set_shader_parameter("route_origin",original_water)
	var standard := StandardMaterial3D.new()
	var blank := ShaderMaterial.new()
	var materials := {
		road=road,road_alias=road,station=station,water=water,
		ground=ground,rail=unrelated,standard=standard,blank=blank,missing=null
	}
	var identities := materials.duplicate()
	var ignored_values := []
	for material in [authored_cache,water,ground,unrelated,blank]:
		ignored_values.append(material.get_shader_parameter("extreme_route_origin"))
	var ok := true
	for origin in [Vector3(1024,0,-2048),Vector3(-6144,0,8192),Vector3.ZERO]:
		Extreme.apply_route_origin(materials,origin)
		ok=ok and road.get_shader_parameter("extreme_route_origin")==origin
		ok=ok and station.get_shader_parameter("extreme_route_origin")==origin
		ok=ok and materials==identities and materials.road==materials.road_alias
		var ignored := [authored_cache,water,ground,unrelated,blank]
		for i in ignored.size():
			ok=ok and ignored[i].get_shader_parameter("extreme_route_origin")==ignored_values[i]
		ok=ok and water.get_shader_parameter("route_origin")==original_water
		ok=ok and road.shader==shader and road.get_shader_parameter("surface_albedo")==texture
		ok=ok and road.get_shader_parameter("tint")==Vector3(0.23,0.41,0.57)
		ok=ok and road.get_shader_parameter("metres")==5.0
		ok=ok and station.get_shader_parameter("surface_normal")==texture
		ok=ok and station.get_shader_parameter("surface_roughness")==0.63
	return ok

func test_geographic_rebase_keeps_loaded_and_activating_detail_absolute():
	var view := GeographicWorld.new()
	view.root=Node3D.new()
	view.world=Traffic.build()
	view.materials={
		road=origin_material(SURFACES[1]),
		platform=origin_material(SURFACES[2]),
		water=origin_material(SURFACES[3])
	}
	# Exercise the real rebase path without asset loading, workers, or daylight.
	var loaded := MeshInstance3D.new()
	loaded.mesh=BoxMesh.new()
	loaded.material_override=view.materials.road
	view.root.add_child(loaded)
	var pending := Node3D.new()
	view.root.add_child(pending)
	var source := MeshInstance3D.new()
	source.mesh=BoxMesh.new()
	source.material_override=view.materials.platform
	source.position=Vector3(3.25,1.1,-7.75)
	pending.add_child(source)
	var loaded_origin := Vector3(3072,0,-1024)
	var pending_origin := Vector3(-4096,0,7168)
	view.loaded={road={node=loaded,origin=loaded_origin}}
	view._activating={station={holder=pending,result={origin=pending_origin}}}
	var before := var_to_bytes(Snapshot.capture(view.world))
	var vertices := loaded.mesh.get_faces()
	var local_vertex := Vector3(5.25,0.1,-2.75)
	var expected_road := loaded_origin+local_vertex
	var expected_station := pending_origin+source.position+local_vertex
	var ok := true
	for origin in [Vector3.ZERO,Vector3(1024,0,-2048),Vector3(-5120,0,6144),Vector3.ZERO]:
		view.rebase(origin)
		var road_origin: Vector3=view.materials.road.get_shader_parameter("extreme_route_origin")
		var station_origin: Vector3=view.materials.platform.get_shader_parameter("extreme_route_origin")
		ok=ok and view.coordinate_origin==origin
		ok=ok and road_origin==origin and station_origin==origin
		ok=ok and view.materials.water.get_shader_parameter("route_origin")==origin
		ok=ok and loaded.position+local_vertex+road_origin==expected_road
		ok=ok and pending.position+source.position+local_vertex+station_origin==expected_station
		ok=ok and loaded.mesh.get_faces()==vertices and view.root.get_child_count()==2
		ok=ok and pending.get_child_count()==1 and source.position==Vector3(3.25,1.1,-7.75)
		ok=ok and var_to_bytes(Snapshot.capture(view.world))==before
	view.root.free()
	return ok

func compact_shader(path: String) -> String:
	var comments := RegEx.new()
	comments.compile("//[^\\n]*")
	var whitespace := RegEx.new()
	whitespace.compile("\\s+")
	return whitespace.sub(comments.sub(FileAccess.get_file_as_string(path),"",true),"",true)

func test_absolute_surface_projection_is_opt_in_and_all_station_layers_stay_aligned():
	var road := compact_shader(SURFACES[1])
	var station := compact_shader(SURFACES[2])
	for source in [road,station]:
		if not source.contains("uniformvec3extreme_route_origin=vec3(0.0);"):
			return "Missing zero-default route origin"
	if not road.contains("vec2p=world_pos.xz;if(extreme_detail>0.0)p+=extreme_route_origin.xz;"):
		return "Road projection no longer preserves local legacy coordinates at zero"
	if not road.contains("vec3base=texture(surface_albedo,p/metres).rgb;"):
		return "Road base color no longer follows the opt-in absolute projection"
	for frequency in ["12.0","31.0"]:
		if not road.contains("extreme_periodic_position(world_pos.xz,extreme_route_origin.xz,vec2("+frequency+"))"):
			return "Road microdetail lost bounded local phase at "+frequency
	if not station.contains("vec3surface_position=world_position;if(extreme_detail>0.0)surface_position+=extreme_route_origin;"):
		return "Station projection is not an opt-in absolute alias of legacy position"
	var fragment := station.get_slice("voidfragment(){",1)
	for projection in ["vec2p=surface_position.xy;","p=surface_position.xz;","p=surface_position.zy;"]:
		if not fragment.contains(projection):return "Station projection missing: "+projection
	for axes in ["xy","xz","zy"]:
		if not fragment.contains("local_p=world_position."+axes+";"):
			return "Station microdetail lost its high-precision local "+axes+" projection"
		if not fragment.contains("origin_p=extreme_route_origin."+axes+";"):
			return "Station origin and local projection axes no longer match"
	if fragment.contains("local_p=p-"):
		return "Station reconstructs local precision after quantizing the absolute position"
	for frequency in ["9.0","32.0","20.0,2.5"]:
		if not fragment.contains("extreme_periodic_position(local_p,origin_p,vec2("+frequency+"))"):
			return "Station detail lost bounded phase at "+frequency
	if not fragment.contains("vec2sheet=vec2(surface_position.x/.96,surface_position.z/3.2);"):
		return "Roof seams are not aligned to the common surface projection"
	if not fragment.contains("vec2paver_cells=p/.30;if(extreme_detail>0.0)paver_cells=extreme_paver_position(local_p,origin_p);"):
		return "Paver coordinates no longer preserve legacy zero or stable Extreme cells"
	for expression in ["fract(paver_cells)","extreme_hash(floor(paver_cells))","vec2cell=fract(paver_cells);"]:
		if not fragment.contains(expression):return "Paver color/joint/bevel grid disconnected: "+expression
	if fragment.contains("fwidth(paver_cells)") or fragment.contains("extreme_detail_filter(paver_cells"):
		return "Wrapped paver phase is being differentiated across its seam"
	if not fragment.contains("extreme_detail_filter(local_p*55.0)"):
		return "Paver bevel footprint must use the continuous local projection"
	var helper := compact_shader("res://game/shaders/extreme_surface_detail.gdshaderinc")
	if not helper.contains("returnlocal_p*frequency+mod(origin*frequency,vec2(4096.0));"):
		return "Periodic microdetail equation changed; revisit float32 precision evidence"
	if not helper.contains("vec2local_blocks=floor(local_p/3.0);") or not helper.contains("returnwhole_cells+remainder*(10.0/3.0);"):
		return "Paver rational-coordinate equation changed; revisit float32 precision evidence"
	var geographic := FileAccess.get_file_as_string("res://game/geographic_world.gd")
	var initialization := geographic.get_slice("func _make_materials()",1).get_slice("func _station_finish(",0)
	if not initialization.contains("apply_route_origin(materials,coordinate_origin)"):
		return "Initial geographic materials miss the nonzero starting route origin"
	return true

func periodic_detail_position(local_p: Vector2,origin: Vector2,frequency: Vector2) -> Vector2:
	# Vector2 arithmetic uses float32, matching shader precision on standard builds.
	return local_p*frequency+(origin*frequency).posmod(4096.0)

func paver_detail_position(local_p: Vector2,origin: Vector2) -> Vector2:
	var blocks := (origin/3.0).floor()
	var local_blocks := (local_p/3.0).floor()
	var whole_cells := ((blocks+local_blocks).posmod(4096.0)*10.0).posmod(4096.0)
	var remainder := (origin-blocks*3.0)+(local_p-local_blocks*3.0)
	return whole_cells+remainder*(10.0/3.0)

func periodic_phase_distance(a: Vector2,b: Vector2) -> Vector2:
	return Vector2(absf(fposmod(float(a.x)-float(b.x)+2048.0,4096.0)-2048.0),
		absf(fposmod(float(a.y)-float(b.y)+2048.0,4096.0)-2048.0))

func test_bounded_float32_detail_retains_millimetres_and_rebase_phase():
	var frequencies := [Vector2(12,12),Vector2(31,31),Vector2(9,9),
		Vector2(32,32),Vector2(20,2.5)]
	var locals := [Vector2(-2047.25,2047.61),Vector2(-1.003,0.001),
		Vector2.ZERO,Vector2(33.999,512.125)]
	var origins := [Vector2(-512000,300032),Vector2(300032,-300032),
		Vector2(512000,-512000),Vector2.ZERO]
	for origin in origins:
		for local_p in locals:
			for shift in [Vector2(1024,-1024),Vector2(-1024,1024)]:
				for frequency in frequencies:
					var before := periodic_detail_position(local_p,origin,frequency)
					var after := periodic_detail_position(local_p-shift,origin+shift,frequency)
					var error_metres: Vector2=periodic_phase_distance(before,after)/frequency
					if maxf(error_metres.x,error_metres.y)>0.001:
						return "Microdetail shifted by over 1 mm across a route-origin rebase"
				var before_paver := paver_detail_position(local_p,origin)
				var after_paver := paver_detail_position(local_p-shift,origin+shift)
				var paver_error := periodic_phase_distance(before_paver,after_paver)*0.30
				if maxf(paver_error.x,paver_error.y)>0.001:
					return "Paver joints shifted by over 1 mm across a route-origin rebase"
	var origin := Vector2(300032,0)
	var local_p := Vector2(1,0)
	var millimetre := Vector2(0.001,0)
	var frequency := Vector2(32,32)
	var before := periodic_detail_position(local_p,origin,frequency)
	var after := periodic_detail_position(local_p+millimetre,origin,frequency)
	var movement := after.x-before.x
	var old_before := (local_p+origin)*frequency
	var old_after := (local_p+millimetre+origin)*frequency
	return movement>0.03 and movement<0.034 and old_before==old_after
