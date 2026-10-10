extends RefCounted
const Options:=preload("res://game/graphics_options.gd")
const Hud:=preload("res://game/hud.gd")

class Host extends Node3D:
	var cam: Camera3D
	var wv: Dictionary
	var train_views:={}
	var passenger_crowd:={render_budget=1.0}
	var hud
	var paused:=true
	var labels_enabled:=false
	func _set_paused(value: bool):paused=value

func test_presets_are_valid_and_custom_is_detected():
	var settings:=Options.new()
	for name in Options.PRESETS:
		settings.preset(name)
		if settings.preset_name()!=name:return "Wrong preset name"
		for key in Options.OPTIONS:
			if not settings.set_option(key,settings.values[key]):return "Invalid preset: "+name+"/"+key
	settings.preset("High");settings.set_option("fps",90)
	return settings.preset_name()=="Custom"

func test_local_preferences_round_trip_and_reject_corrupt_values():
	var settings:=Options.new();settings.settings_path="user://graphics-unit-test.cfg"
	settings.preset("Performance");settings.set_option("fps",90)
	var error:=settings.save()
	var other:=Options.new();other.settings_path=settings.settings_path;other.restore()
	var ok:=error==OK and other.values==settings.values
	var config:=ConfigFile.new();config.load(settings.settings_path)
	config.set_value("graphics","view_distance",INF)
	config.set_value("graphics","vegetation_density",-1.0)
	config.set_value("graphics","ssil",1)
	config.set_value("graphics","msaa","3")
	config.save(settings.settings_path);other.restore()
	ok=ok and other.values.view_distance==2200.0 and other.values.vegetation_density==1.0 and other.values.ssil==true and other.values.msaa==3
	DirAccess.remove_absolute(settings.settings_path)
	return ok

func vegetation(name: String,begin: float,finish: float):
	var node:=MultiMeshInstance3D.new();node.name=name
	node.set_meta("scenery_kind","tf3_KL_LS_Coconut_Tall_A")
	var mm:=MultiMesh.new();mm.mesh=BoxMesh.new();mm.instance_count=16;node.multimesh=mm
	node.visibility_range_begin=begin;node.visibility_range_end=finish
	node.visibility_range_begin_margin=8;node.visibility_range_end_margin=8
	return node

func test_vegetation_lods_keep_matching_instances_and_restore_exactly():
	var settings:=Options.new();settings.preset("Performance")
	var near=vegetation("Tree",0,45);var middle=vegetation("TreeLOD",45,95)
	var far=vegetation("Image",95,2700);far.set_meta("impostor",true)
	for node in [near,middle,far]:settings.apply_tree(node)
	var ok: bool=near.visibility_range_end==middle.visibility_range_begin and middle.visibility_range_end==far.visibility_range_begin and far.visibility_range_end==2700
	for node in [near,middle,far]:
		ok=ok and node.multimesh.visible_instance_count==12
		settings.apply_tree(node)
		ok=ok and node.multimesh.visible_instance_count==12 # Not compounded by repeated apply.
	settings.preset("High")
	for node in [near,middle,far]:settings.apply_tree(node)
	ok=ok and near.visibility_range_end==45 and middle.visibility_range_end==95 and far.visibility_range_begin==95
	for node in [near,middle,far]:
		ok=ok and node.multimesh.visible_instance_count==-1 and node.visibility_range_begin_margin==8
		node.free()
	return ok

func test_legacy_canopy_and_new_streamed_geometry_use_current_preferences():
	var settings:=Options.new();settings.preset("Performance")
	var canopy=vegetation("Canopy_rain_tree",115,2700);canopy.remove_meta("scenery_kind")
	var late=vegetation("NewTree",0,45)
	settings.apply_tree(canopy);settings.apply_tree(late)
	var ok: bool=canopy.visibility_range_begin==57.5 and canopy.visibility_range_end==2700 and canopy.multimesh.visible_instance_count==late.multimesh.visible_instance_count
	canopy.free();late.free();return ok

func test_buildings_transition_together_and_rail_geometry_is_untouched():
	var settings:=Options.new();settings.preset("Performance")
	var house:=MeshInstance3D.new();house.set_meta("house_lod_role",0);house.set_meta("scenery_kind","balcony_villa");house.visibility_range_end=180
	var image:=MeshInstance3D.new();image.set_meta("house_lod_role",1);image.set_meta("scenery_kind","balcony_villa");image.set_meta("impostor",true);image.visibility_range_begin=180;image.visibility_range_end=1800
	var rail:=MeshInstance3D.new();rail.visibility_range_end=650
	for node in [house,image,rail]:settings.apply_tree(node)
	var ok:=house.visibility_range_end==90 and image.visibility_range_begin==90 and image.visibility_range_end==1800 and rail.visibility_range_end==650
	for node in [house,image,rail]:node.free()
	return ok

func test_live_environment_viewport_and_crowd_mapping():
	var host:=Host.new();Engine.get_main_loop().root.add_child(host)
	host.cam=Camera3D.new();host.add_child(host.cam)
	var world:=Node3D.new();host.add_child(world);host.wv={root=world}
	var env:=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env)
	var sun:=DirectionalLight3D.new();world.add_child(sun)
	var settings:=Options.new();settings.game=host;settings.preset("Performance");settings.apply()
	var vp:=host.get_viewport()
	var ok:=vp.msaa_3d==1 and is_equal_approx(vp.scaling_3d_scale,.85) and vp.mesh_lod_threshold==4
	ok=ok and host.cam.far==1800 and env.environment.fog_depth_end<1800 and not env.environment.ssil_enabled
	ok=ok and sun.directional_shadow_max_distance==100 and host.passenger_crowd.render_budget==.5
	settings.set_option("shadows",0);settings.apply();ok=ok and not sun.shadow_enabled
	settings.preset("High");settings.apply()
	ok=ok and sun.shadow_enabled and vp.msaa_3d==3 and vp.scaling_3d_scale==1 and host.cam.far==2200 and host.passenger_crowd.render_budget==1
	host.free();return ok

func test_every_option_is_reachable_and_nested_back_preserves_context():
	var host:=Host.new();Engine.get_main_loop().root.add_child(host)
	var settings:=Options.new();settings.game=host
	host.hud=Hud.new();host.hud.graphics_options=settings;host.add_child(host.hud)
	var ok:=true
	for key in Options.OPTIONS:
		host.hud.show_modal("graphics:option:"+key)
		ok=ok and host.hud._buttons.get_child_count()==Options.OPTIONS[key].values.size()+1
		settings.back();ok=ok and host.hud.modal=="graphics:"+Options.OPTIONS[key].group
		var buttons: Array=host.hud._buttons.get_children()
		ok=ok and buttons.any(func(b):return b.get_meta("action")=="graphics:option:"+key)
	settings.back();ok=ok and host.hud.modal=="graphics"
	settings.back();ok=ok and host.hud.modal=="pause"
	host.free();return ok
