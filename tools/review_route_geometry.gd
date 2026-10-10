extends Node
## Reproducible source-scene review of corrected yards, formations and curves.
## Open with the companion temporary review scene, not the exported game.
var game
var shots := []
@export var codes: Array[String]=["QLN","TVC","NEM","BRAM","KUMM"]
func _ready() -> void:
	get_tree().set_meta("route","kerala_coast")
	get_tree().set_meta("traffic_seed",0)
	call_deferred("run")
func settle() -> bool:
	var began:=Time.get_ticks_msec()
	for i in 8:await get_tree().process_frame
	while game.wv.loading or game.wv.has_pending_work():
		if Time.get_ticks_msec()-began>180000:printerr("MAP_REVIEW loading timeout");return false
		await get_tree().process_frame
	for i in 30:await get_tree().process_frame
	return true
func run() -> void:
	Engine.max_fps=20
	get_tree().root.size=Vector2i(1440,900)
	game=load("res://game/main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	game._set_paused(true)
	if not await settle():get_tree().quit(1);return
	game.hud.show_modal("");game.hud.hide()
	var builder=preload("res://sim/layouts/kerala_coast.gd").new()
	builder.data=game.world.scenery.route
	builder.distance=PackedFloat64Array(builder.data.chainage)
	for code in codes:
		var station: Dictionary=game.world.stations.filter(func(s):return s.code==code)[0]
		game._visit_station(game.world.stations.find(station))
		if not await settle():get_tree().quit(1);return
		var samples: Array=[{label=code.to_lower()+"-yard",s=station.s,height=35.0,back=115.0,side=50.0}]
		if code=="QLN":samples.append({label="qln-curve",s=142098.0,height=5.0,back=55.0,side=8.0})
		if code=="TVC":samples.append({label="tvc-throat",s=station.s-station.yard_half-160,height=12.0,back=75.0,side=13.0})
		if code=="NEM":samples=[{label="nem-curve",s=214608.0,height=4.0,back=55.0,side=6.0}]
		if code=="BRAM":samples=[{label="bram-curve",s=219097.0,height=4.0,back=55.0,side=6.0}]
		if code=="KUMM":samples=[{label="kumbalam-bridge",s=6600.0,height=30.0,back=60.0,side=-35.0}]
		for sample in samples:
			var a: Array=builder.point(sample.s);var b: Array=builder.point(sample.s+10)
			var p: Vector3=Vector3(a[0],a[1],a[2])-game.wv.coordinate_origin
			var f:=Vector3(b[0]-a[0],0,b[2]-a[2]).normalized()
			var right:=f.cross(Vector3.UP)
			var eye: Vector3=p-f*sample.back+right*sample.side+Vector3.UP*sample.height
			game.cam.enter_free(eye,(p+Vector3.UP*.5-eye).normalized())
			game._set_cab_visuals(false);game.hud.hide()
			if not await settle():get_tree().quit(1);return
			await RenderingServer.frame_post_draw
			var path: String="res://.local/map-visual-"+sample.label+".png"
			get_viewport().get_texture().get_image().save_png(path)
			shots.append({label=sample.label,path=path,pending=game.wv.queue.size(),draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),triangles=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
			print("MAP_REVIEW ",JSON.stringify(shots[-1]))
	FileAccess.open("res://.local/map-visual.json",FileAccess.WRITE).store_string(JSON.stringify(shots,"\t"))
	print("MAP_REVIEW_COMPLETE")
	get_tree().quit()
