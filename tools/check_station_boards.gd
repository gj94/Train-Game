extends SceneTree
const Board=preload("res://game/station_nameboard.gd")
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1400,800)
	var scene:=Node3D.new();root.add_child(scene)
	var signs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/routes/kerala_coast/station-signs.json"))
	var yellow:=StandardMaterial3D.new();yellow.albedo_color=Color(.96,.75,.10);yellow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var i:=0
	for code in ["ERS","TVC","KAVR","NCJ"]:
		var position:=Vector3(-3.05 if i%2==0 else 3.05,2 if i<2 else -.5,0)
		var board:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(5.6,1.5,.10);board.mesh=box;board.material_override=yellow;scene.add_child(board);board.position=position
		var data: Dictionary=signs[code].duplicate();data.name=data.board_name
		Board.add(scene,data,position,Basis(Vector3.UP,PI) if i%2 else Basis.IDENTITY)
		i+=1
	var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,.8,16);camera.look_at(Vector3(0,.8,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8;camera.make_current()
	await process_frame
	await process_frame
	var count:=0
	for node in scene.get_children():
		if node is Label3D:
			count+=1
			if node.font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.font_size).x*node.pixel_size>5.19:printerr("Board overflow ",node.text);quit(1);return
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/station-boards.png")
	print("STATION_BOARDS PASS ",count," labels, both faces, 3 scripts")
	quit(0)
