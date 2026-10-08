extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var world:=preload("res://tests/test_receiving_capacity.gd").new().fixture()
	var desk=preload("res://game/dispatch_desk.gd").new()
	root.add_child(desk);desk.selected_train="K1";desk.setup(world);desk.set_open(true)
	desk.inspect_train("K2");desk._prompt_delete()
	for i in 8:await process_frame
	var frame: Rect2=desk._root.get_global_rect()
	var dialog: Rect2=desk._confirm.get_global_rect()
	var okay:=frame.encloses(dialog) and (frame.get_center()-dialog.get_center()).length()<2
	print("DIALOG_LAYOUT ",JSON.stringify({frame=str(frame),dialog=str(dialog),ok=okay}))
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/delete-dialog-final.png")
	quit(0 if okay else 1)
