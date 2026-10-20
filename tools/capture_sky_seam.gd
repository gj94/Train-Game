extends SceneTree
## Pure-sky reproduction of the panorama wrap artifact found above Kollam.
## No world geometry, railway advancement, or distribution launch.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var output:="res://.local/sky-seam"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,900);Engine.max_fps=30
	var scene:=Node3D.new();root.add_child(scene)
	var environment=preload("res://game/world_view.gd").new()
	environment.root=scene;environment._build_environment()
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var sites:=preload("res://game/coastal_station_sites.gd").build(world)
	var station: Dictionary=world.stations.filter(func(s):return s.code=="QLN")[0]
	var site: Dictionary=preload("res://game/station_precinct_plan.gd").entries(sites,station)[0]
	var camera:=Camera3D.new();scene.add_child(camera);camera.make_current()
	var direction: Vector3=site.basis.z*85-site.basis.x*45-Vector3.UP*25
	for hour in [9,16,20]:
		environment.day_night.update(hour*3600,true)
		for fov in [18,65,85]:
			camera.fov=fov;camera.look_at(direction)
			for i in 30:await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/%02d-%02d.png"%[hour,fov])
	print("SKY_SEAM_CAPTURES_COMPLETE ",output);quit()
