extends SceneTree
## Actual ported houses, authored-window masks and pooled porch fixtures.
var output:="res://.local/overnight-2026-10-14/houses"
var context
var library
var lights
var camera: Camera3D
var chunks:={}
var report:={checks=0,failures=0,cases=[]}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	report.checks+=1
	if not ok:report.failures+=1;printerr("FAIL: "+message)

func capture(label: String,hour: float,eye: Vector3,target: Vector3,fov: float=60.0) -> void:
	context.day_night.update(hour*3600,true)
	camera.position=eye;camera.fov=fov;camera.look_at(target)
	lights.update(chunks,eye,Vector3.ZERO,context.day_night.state.night,hour,true)
	for i in 40:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	check(lights.active_lights<=8,"bounded residential lights")
	check(lights.active_lights==0 if hour==12 else lights.active_lights>0 or eye.length()>100,"clock-driven light pool")
	report.cases.append({name=label,hour=hour,lights=lights.active_lights,fixtures=lights.visible_fixtures,
		draws=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})

func run() -> void:
	root.size=Vector2i(1600,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene:=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment()
	var floor_node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(600,.15,600)
	floor_node.mesh=mesh;floor_node.position.y=-.1
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.22,.25,.18);mat.roughness=.95
	floor_node.material_override=mat;scene.add_child(floor_node)
	library=preload("res://game/scenery_library.gd").new(context)
	preload("res://game/trackside_assets.gd").prepare(library)
	preload("res://game/building_impostors.gd").prepare(library)
	var kinds:=["tf3_BLD_Home_Verandah_01","tf3_BLD_Cottage_Hipped_01","tf3_BLD_Home_Concrete_01","tf3_BLD_TeaShop_Open_01","kerala_bungalow","tiled_house","shop_house"]
	for i in kinds.size():
		library.place(kinds[i],Vector3((i%4)*16.0-24+(4 if i==0 else 0),0,(i/4)*22.0),PI,Vector3.ONE)
	var sites:=preload("res://game/night_windows.gd").porch_sites(library)
	library.flush();context.day_night.bind_scenery(library)
	check(context.day_night.windows.materials.size()>10,"near/far material clock bindings")
	for kind in kinds:
		check(library.impostors[kind].material.get_shader_parameter("has_window_mask"),"mask imported: "+kind)
	lights=preload("res://game/residential_lighting.gd").new(scene)
	chunks["test"]={node=scene,origin=Vector3.ZERO,night_sites=sites}
	camera=Camera3D.new();scene.add_child(camera);camera.current=true;camera.far=1200
	await capture("street_day",12,Vector3(18,5,60),Vector3(0,2,5))
	await capture("street_night",22,Vector3(18,5,60),Vector3(0,2,5))
	await capture("street_dawn",5.8,Vector3(18,5,60),Vector3(0,2,5))
	await capture("verandah_day",12,Vector3(-14,2.0,13),Vector3(-20,1.8,0))
	await capture("verandah_night",22,Vector3(-14,2.0,13),Vector3(-20,1.8,0))
	await capture("concrete_night",22,Vector3(14,2.2,12),Vector3(8,1.8,0))
	await capture("legacy_night",22,Vector3(-13,2.3,40),Vector3(-22,2.0,22))
	for distance in [165.0,180.0,195.0,240.0]:
		await capture("lod_night_%d"%distance,22,Vector3(0,3,distance),Vector3(0,2,0),16)
	report.complete=true;report.adapter=RenderingServer.get_video_adapter_name()
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("HOUSE_CHECK ",JSON.stringify(report));quit(1 if report.failures else 0)
