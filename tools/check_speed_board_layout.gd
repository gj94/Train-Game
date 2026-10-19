extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720);Engine.max_fps=30
	var w:=preload("res://sim/layouts/kerala_coast.gd").build()
	var view:=preload("res://game/track_speed_board_view.gd").new(w,preload("res://game/vegetation_clearance.gd").build(w))
	var shared: Dictionary=view.jobs[0];var stacked: Dictionary=view.jobs[0];var release: Dictionary={}
	for job: Dictionary in view.jobs:
		if job.members.size()>shared.members.size():shared=job
		if job.plates.size()>stacked.plates.size():stacked=job
		if job.plates[0].kind=="termination" and job.members.size()>release.get("members",[]).size():release=job
	var scene:=Node3D.new();root.add_child(scene)
	var env=preload("res://game/world_view.gd").new();env.root=scene;env._build_environment();env.day_night.update(10*3600,true)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(100,100);ground.mesh=plane;scene.add_child(ground)
	for i in 3:
		var job: Dictionary=[shared,stacked,release][i].duplicate(true)
		job.point=Vector3.ZERO;job.rail_y=0;job.forward=Vector3.FORWARD
		var built: Dictionary=view.build(job);scene.add_child(built.node);built.node.position=Vector3((i-1)*4.5,0,0)
	var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,4.3,16);camera.look_at(Vector3(0,2.3,0));camera.make_current()
	for i in 70:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r35-fixes/speed-board-layout.png")
	print("BOARD_LAYOUT posts=",view.jobs.size()," samples=",shared.id," ",stacked.id," ",release.id)
	scene.queue_free();await process_frame;quit()
