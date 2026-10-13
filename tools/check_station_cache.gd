extends SceneTree
## Exercise real imported station resources, eviction and a visible revisit.
const Stations:=preload("res://game/authored_station.gd")
const Materials:=preload("res://game/authored_vehicle_materials.gd")
var output:="res://.local/overnight-2026-10-14/station-cache"
var report:={checks=0,failures=0,samples=[]}
var scene: Node3D
var camera: Camera3D
var model: Node3D
var context
var retain_all:=false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg=="--retain-all":retain_all=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));call_deferred("run")

func check(ok: bool,message: String) -> void:
	report.checks+=1
	if not ok:report.failures+=1;printerr("FAIL: "+message)

func prepare(code: String) -> WeakRef:
	var prepared: Dictionary=Stations.prepare(code)
	return weakref(prepared.scene)

func alive(reference: WeakRef) -> bool:
	return reference.get_ref()!=null

func add_visible() -> void:
	model=Stations.add_building(scene,"KUMM",Vector3.ZERO,Vector3.RIGHT,Vector3.BACK).model

func sample(code: String) -> void:
	for i in 8:await process_frame
	var item:={code=code,station_cache=Stations._cache.counts(),material_cache=Materials._cache.counts(),
		heap=OS.get_static_memory_usage(),video=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	report.samples.append(item);print("CACHE ",JSON.stringify(item))
	check(item.station_cache.bounded<=(64 if retain_all else 8) and item.material_cache.bounded<=(64 if retain_all else 8),"station cache budget "+code)

func capture(label: String) -> void:
	for i in 40:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")

func run() -> void:
	if retain_all:Stations._cache._capacity=64;Materials._cache._capacity=64
	report.retain_all=retain_all
	root.size=Vector2i(1280,720);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment();context.day_night.update(14*3600,true)
	camera=Camera3D.new();scene.add_child(camera);camera.current=true;camera.far=2000
	camera.position=Vector3(35,12,40);camera.look_at(Vector3(0,2,0));camera.fov=65
	var first:=prepare("KUMM")
	add_visible();await capture("before")
	var original_nodes:=model.find_children("*","MeshInstance3D",true,false).size()
	for code in ["AROR","EZP","TUVR","VAY","SRTL","TRVZ","MAKM","KAVR","TMPY","ALLP","AMPA","HAD","CHPD","KYJ","KPY","QLN"]:
		prepare(code);await sample(code)
	check(Stations.is_prepared("KUMM")==retain_all,"first station residency matches cache policy")
	check(alive(first)==retain_all,"PackedScene lifetime matches cache policy while visible meshes stay alive")
	check(model.find_children("*","MeshInstance3D",true,false).size()==original_nodes,"live station hierarchy survives cache eviction")
	await capture("evicted_but_visible")
	model.queue_free();model=null
	for i in 8:await process_frame
	var began:=Time.get_ticks_usec();add_visible();report.revisit_ms=(Time.get_ticks_usec()-began)*.001
	check(Stations.is_prepared("KUMM"),"evicted station prepared again on revisit")
	check(model.find_children("*","MeshInstance3D",true,false).size()==original_nodes,"revisited source hierarchy restored")
	await capture("revisited");await sample("KUMM_revisit")
	report.complete=true;report.adapter=RenderingServer.get_video_adapter_name()
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("STATION_CACHE ",JSON.stringify(report));quit(1 if report.failures else 0)
