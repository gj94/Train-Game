extends SceneTree
## Real main scene and player handover on simulated boundary exits. These small
## test workings are explicit fixtures, never prepared timetable catalogues.
const OUT:="res://.local/realism-2026-10-26/boundary-native-v2"
var failures:=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func frames(n: int=3) -> void:
	for i in n:await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1280,720)
	var fixture=load("res://tests/test_boundary_services.gd").new()
	for north in [true,false]:
		print("BOUNDARY_CASE ","north" if north else "south")
		var w=load("res://sim/layouts/kerala_coast.gd").build(true)
		var data: Dictionary=fixture.definition(w,north,false)
		data.world_start="11:55";data.services[0].departure="11:55"
		data.services[0].journey.origin="Thiruvananthapuram"
		data.services[0].journey.destination="Mangaluru" if north else "Madurai"
		data.services[0].name="Thiruvananthapuram–"+data.services[0].journey.destination+" Mail / Express"
		var built: Dictionary=load("res://sim/service_pack.gd").build(data)
		if not built.ok:printerr(built.reason);quit(1);return
		w=built.world;w.dispatcher().enabled=true
		var t: Train=w.trains.THROUGH;var marker: Dictionary=t.timetable.stops[-1]
		for i in 550:
			if t.path[0].edge==marker.block and absf(t.head_s-marker.s)<140:break
			w.step(2)
		check(t.lifecycle=="active" and t.path[0].edge==marker.block,"actual train reached outward boundary track")
		set_meta("prepared_start",{world=w,service=t.id,mode="ride",timetable_id="network",passenger_start=true})
		change_scene_to_file("res://game/main.tscn");await frames()
		var game=current_scene
		game.set_physics_process(false)
		var began:=Time.get_ticks_msec()
		while game.wv.loading and Time.get_ticks_msec()-began<120000:await process_frame
		check(not game.wv.loading,"boundary scenery loaded")
		game.hud.show_modal("");game._set_paused(false)
		await frames(8)
		check(not game.hud._dispatch_notice.text.contains("No forward signal"),"outward road has no false missing-signal warning")
		check(game.hud._info.text.contains("Railway continues beyond the map"),"outward road displays continuation")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+("/north" if north else "/south")+"-approach.png")
		for frame in 1400:
			game._physics_process(.05)
			if game.paused:break
			if frame%20==0:await process_frame
		check(t.lifecycle=="exited","actual boundary exit completed")
		check(game.paused and game.hud.modal=="time_skip","player receives paused completion page")
		check(game.hud.save_menu.title=="JOURNEY CONTINUES BEYOND THE MAP","boundary completion is distinguished from depot")
		check(game.cam.mode==0 and not game.cam.follow and not game.walker.active,"camera leaves departed train")
		check(w.events.is_empty() and w.occupancy().is_empty(),"whole train clear without safety event")
		check(t.depot.is_empty() and not t.journey.is_empty(),"through identity retained without fake depot")
		await frames(10)
		began=Time.get_ticks_msec()
		while game.wv.loading and Time.get_ticks_msec()-began<120000:await process_frame
		check(not game.wv.loading,"observer station finished loading after exit")
		await frames(6);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+("/north" if north else "/south")+"-complete.png")
		# Use the real menu transition, which drains scenery GPU work while the
		# rendering loop remains alive; direct queue_free is not a gameplay path.
		game._return_to_landing()
		began=Time.get_ticks_msec()
		while is_instance_valid(game) and Time.get_ticks_msec()-began<130000:await process_frame
		check(not is_instance_valid(game),"normal return to journey menu completes")
		if is_instance_valid(game):printerr("Could not return from boundary case");quit(1);return
		await frames(5)
	var report:={ok=failures.is_empty(),checks=checks,failures=failures}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BOUNDARY_NATIVE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
