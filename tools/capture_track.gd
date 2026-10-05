extends SceneTree
## Actual corridor views, kept at identical cameras for track art comparisons.
var output := "res://.local/track-after"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	call_deferred("capture")

func capture() -> void:
	set_meta("imported_fleet", "wap7")
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game._set_paused(true)
	game.hud.hide()
	game.dispatcher.hide()
	game.cam.set_process(false)
	game.cam.fov = 58
	game.cam.near = .04
	DirAccess.make_dir_recursive_absolute(output)
	var g: TrackGraph = game.world.graph
	var p := g.position("W_E0", 450)
	var f := g.tangent("W_E0", 450, 1)
	var r := f.cross(Vector3.UP)
	game.world.place_train(game.train,"W_E0",460,1)
	game.tv.update()
	var views := [
		["rail_detail", p-r*1.9+Vector3.UP*1.2, p+f*3+Vector3.UP*.25],
		["plain_line", p-r*4.7+Vector3.UP*2.5-f*7, p+f*32],
		["turnout", Vector3(1082,5,-7), Vector3(994,.25,-7)],
		["station", Vector3(830,3.1,-6.2), Vector3(940,.5,-6)],
		["yard", Vector3(1120,25,-46), Vector3(995,.2,-2)]
	]
	var axle: Vector3 = game.tv.cars[0].global_position
	views.append(["wheel_contact",axle+Vector3(5.5,1.1,-3.2),axle+Vector3(2.5,.55,0)])
	views.append(["locomotive",axle+Vector3(22,5,-22),axle+Vector3.UP*1.7])
	var joint_s := 6.5+13*34
	var jp := g.position("W_E0",joint_s)
	var jf := g.tangent("W_E0",joint_s,1)
	var jr := jf.cross(Vector3.UP)
	views.append(["joint_detail",jp-jr*1.9-jf*.9+Vector3.UP*.90,jp-jr*.874+Vector3.UP*.40])
	var j: Dictionary = game.wv.track_view.junctions["CPM_P1"][0]
	for feature in ["toe","frog"]:
		var sample: Dictionary = game.wv.track_view._from_node("CPM_P1",j.node,j[feature])
		views.append(["point_"+feature,sample.pos+sample.right*3.8-sample.fwd*4+Vector3.UP*2.7,sample.pos+sample.fwd*1.2+Vector3.UP*.3])
	for v in views:
		game.cam.global_position = v[1]
		game.cam.look_at(v[2])
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/" + v[0] + ".png")
		print("CAPTURE ", v[0])
		if v[0]=="point_toe":
			var previous: bool = g.switches[j.node].reversed
			g.switches[j.node].reversed = not previous
			game.wv.track_view.update_points(true)
			for i in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/point_toe_opposite.png")
			g.switches[j.node].reversed = previous
			game.wv.track_view.update_points(true)
	quit()
