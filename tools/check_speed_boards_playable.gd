extends SceneTree
var game
var failures := []
var captures := DisplayServer.get_name()!="headless"
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	call_deferred("run")
func settle() -> void:
	for i in 10:await process_frame
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
	for i in 25:await process_frame
func run() -> void:
	Engine.max_fps=30;root.size=Vector2i(1440,900)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;game.set_physics_process(false)
	await settle()
	game._set_paused(true);game.hud.show_modal("");game.hud.hide()
	var view=game.wv.speed_boards
	var checks:=0
	var clearance:=preload("res://game/scenery_clearance.gd").new(game.world.graph)
	for job in view.jobs:
		if not clearance.clear_point(job.point,3.04):failures.append("Board intrudes into track: "+job.id)
		checks+=1
	for kind in ["speed","caution","termination","kumbalam"]:
		var wanted_kind: String="speed" if kind=="kumbalam" else kind
		var place: String="KUMM" if kind=="kumbalam" else "ERS"
		var nearby: Array=view.jobs.filter(func(j):return str(j.id).contains(place) and j.plates.any(func(p):return p.kind==wanted_kind))
		if nearby.is_empty():failures.append("No "+kind+" board near ERS");continue
		var job: Dictionary=nearby[0]
		var target: Vector3=job.point-game.wv.coordinate_origin+Vector3.UP*2.7
		var eye: Vector3=target-job.forward*15+job.forward.cross(Vector3.UP)*2+Vector3.UP*.6
		game.cam.enter_free(eye,(target-eye).normalized());game._set_cab_visuals(false)
		await settle()
		if not game.wv.loaded.has(job.id):failures.append("Board did not stream: "+job.id);continue
		var chunk: Dictionary=game.wv.loaded[job.id]
		if chunk.node.get_child_count()==0:failures.append("Empty indicator: "+job.id)
		checks+=1
		if captures:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/r21-"+kind+".png")
		print("SPEED_BOARD ",kind," ",job.id," plates=",job.plates," position=",job.point)
	if not is_equal_approx(game.train.max_speed*3.6,110):failures.append("Default player cap not upgraded")
	print("SPEED_BOARDS ",checks," checks; ",view.jobs.size()," streamed indicator assemblies; ",failures.size()," failures")
	for message in failures:printerr(message)
	quit(0 if failures.is_empty() else 1)
