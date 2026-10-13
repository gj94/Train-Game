extends RefCounted
const Windows:=preload("res://game/night_windows.gd")

func test_residential_occupancy_is_bounded_smooth_and_repeats_at_midnight():
	var previous:=Windows.occupied_fraction(0)
	for minute in range(1,1441):
		var hour:=minute/60.0
		var value:=Windows.occupied_fraction(hour)
		if value<.25 or value>.75 or absf(value-previous)>.01:return "Abrupt household lighting"
		if not is_equal_approx(value,Windows.occupied_fraction(hour+24)):return "Clock rollover changed households"
		previous=value
	return Windows.occupied_fraction(19)>Windows.occupied_fraction(3)

func test_window_materials_keep_source_daytime_properties_and_share_clock_updates():
	var source:=StandardMaterial3D.new();source.resource_name="TF3_BLD_MAT_glass"
	source.albedo_color=Color(.1,.2,.3,.4);source.roughness=.3;source.metallic=.2
	source.normal_enabled=true;source.normal_texture=GradientTexture2D.new();source.normal_scale=.6
	source.roughness_texture=GradientTexture2D.new();source.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	var material:=Windows.window_material(source)
	var windows:=Windows.new()
	windows.bind({finishes={glass=material,duplicate=material},meshes={},impostors={}})
	windows.update(1,22)
	var ok: bool=windows.materials.size()==1 and material.get_shader_parameter("window_night")==1
	ok=ok and material.get_shader_parameter("glass_colour")==source.albedo_color and material.get_shader_parameter("glass_roughness")==source.roughness
	ok=ok and material.get_shader_parameter("glass_normal")==source.normal_texture and material.get_shader_parameter("normal_depth")==source.normal_scale
	ok=ok and material.get_shader_parameter("roughness_channel")==Vector4(0,1,0,0)
	windows.update(0,12)
	return ok and material.get_shader_parameter("window_night")==0 and source.emission_enabled==false

func test_shutters_remain_opaque_and_only_supported_house_panels_are_lit():
	var source:=StandardMaterial3D.new();source.resource_name="TF3_BLD_MAT_wood_teal"
	var material:=Windows.window_material(source,true)
	return not material.shader.code.contains("ALPHA=") and material.get_meta("shuttered_window") and Windows.is_shutter("tf3_BLD_Home_Verandah_01",source.resource_name) and not Windows.is_shutter("tf3_BLD_TeaShop_Open_01",source.resource_name)

func test_porch_pool_stays_bounded_rebases_and_excludes_hidden_chunks():
	var root:=Node3D.new();var pool:=preload("res://game/residential_lighting.gd").new(root)
	var chunk:=Node3D.new();root.add_child(chunk)
	var sites:=[]
	for i in 120:sites.append({position=Vector3((i%15)*4,2.6,floori(i/15.0)*4),seed=.2})
	var chunks:={tile={node=chunk,origin=Vector3.ZERO,night_sites=sites}}
	pool.update(chunks,Vector3.ZERO,Vector3.ZERO,1,22,true)
	var position: Vector3=pool.slots[0].light.position
	var identity: String=pool.slots[0].id
	var ok: bool=pool.active_lights==8 and pool.visible_fixtures==96
	pool.update(chunks,Vector3(2,0,2),Vector3(1024,0,2048),1,22,true)
	ok=ok and pool.slots[0].id==identity and pool.slots[0].light.position==position-Vector3(1024,0,2048)
	ok=ok and pool.slots.all(func(slot):return not slot.light.shadow_enabled)
	pool.update(chunks,Vector3.ZERO,Vector3.ZERO,0,12,true)
	ok=ok and pool.active_lights==0
	chunk.visible=false;pool.update(chunks,Vector3.ZERO,Vector3.ZERO,1,22,true)
	ok=ok and pool.active_lights==0 and pool.visible_fixtures==0
	root.free();return ok
