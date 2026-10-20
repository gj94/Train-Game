extends SceneTree
## Source-only close inspection: shifted rows, non-grid edge joins and roof shadows.
var output:="res://.local/ohe-render"
var legacy:=false
var shadow_width:=0.0
var normal_bias:=-1.0
var hour:=15.0
var shadow_resolution:=8192
var shadow_distance:=300.0
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg=="--legacy":legacy=true
		if arg.begins_with("--shadow-width="):shadow_width=arg.trim_prefix("--shadow-width=").to_float()
		if arg.begins_with("--normal-bias="):normal_bias=arg.trim_prefix("--normal-bias=").to_float()
		if arg.begins_with("--hour="):hour=arg.trim_prefix("--hour=").to_float()
		if arg.begins_with("--shadow-resolution="):shadow_resolution=arg.trim_prefix("--shadow-resolution=").to_int()
		if arg.begins_with("--shadow-distance="):shadow_distance=arg.trim_prefix("--shadow-distance=").to_float()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900);Engine.max_fps=60
	var scene:=Node3D.new();root.add_child(scene)
	var context=preload("res://game/world_view.gd").new()
	context.root=scene;context._build_environment();context.day_night.update(hour*3600,true)
	RenderingServer.directional_shadow_atlas_set_size(shadow_resolution,true)
	context.day_night.sun.directional_shadow_max_distance=shadow_distance
	if normal_bias>=0:context.day_night.sun.shadow_normal_bias=normal_bias
	var world:=RailWorld.new()
	for road in 3:
		var id:="R"+str(road)
		world.graph.add_node(id+"a",Vector3(0,0,road*5.3))
		world.graph.add_node(id+"b",Vector3(103,0,road*5.3))
		world.graph.add_node(id+"c",Vector3(250,0,road*5.3+3))
		world.graph.add_edge(id+"first",id+"a",id+"b")
		world.graph.add_edge(id+"next",id+"b",id+"c")
		world.graph.edges[id+"first"].merge({chainage_start=13.0,chainage_end=116.0})
		world.graph.edges[id+"next"].merge({chainage_start=116.0,chainage_end=263.0})
	world.stations=[{s=50.0,through_halt=false,platform_tracks=[]}]
	var materials:={}
	for kind in ["wire","metal","concrete","insulator"]:
		materials[kind]=context.mat(Color(.12,.13,.13) if kind=="wire" else Color(.45,.47,.43))
	var layout=load("res://.local/ohe-baseline-layout.gd" if legacy else "res://game/geographic_ohe_layout.gd").new(world)
	var builder=load("res://.local/ohe-baseline-chunk.gd" if legacy else "res://game/geographic_railway_chunk.gd")
	for eid in world.graph.edges:
		var length: float=world.graph.edges[eid].length
		for limits in [[0.0,83.4],[83.4,length]]:
			if limits[0]>=length:continue
			var built: Dictionary=builder.new(world,{bridges=[]},materials,null).build_ohe(eid,limits[0],minf(limits[1],length),layout)
			built.node.position=built.origin;scene.add_child(built.node)
			if shadow_width>0:
				var batch=preload("res://game/geographic_mesh.gd").new()
				for span in preload("res://game/geographic_ohe_layout.gd").new(world).wire_spans(eid,limits[0],minf(limits[1],length),built.origin):
					for key in ["contacts","messengers"]:
						for i in range(1,span[key].size()):batch.beam("wire",span[key][i-1],span[key][i],shadow_width)
				var proxy:=Node3D.new();proxy.position=built.origin;batch.finish(proxy,materials,"Proxy");scene.add_child(proxy)
				for mesh in proxy.get_children():mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				for mesh in built.node.get_children():
					if mesh.name.ends_with("_wire"):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					elif mesh.name.ends_with("_wire_shadow"):mesh.visible=false
	var ground:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(400,.2,200);ground.mesh=mesh
	ground.position=Vector3(100,-.15,0);ground.material_override=context.mat(Color(.68,.67,.60));scene.add_child(ground)
	# A plain roof gives a clean receiver for shadow continuity measurements.
	var roof:=MeshInstance3D.new();var body:=BoxMesh.new();body.size=Vector3(150,3.7,3.3)
	roof.mesh=body;roof.position=Vector3(85,2.0,5.3);roof.material_override=context.mat(Color(.7,.7,.7));scene.add_child(roof)
	var camera:=Camera3D.new();scene.add_child(camera);camera.make_current();camera.fov=55
	var report:=[]
	for view in [
		{name="registration",eye=Vector3(97,9.5,23),target=Vector3(107,6.8,5.3)},
		{name="roof",eye=Vector3(73,7.6,13),target=Vector3(96,3.8,5.3)},
		{name="join",eye=Vector3(93,8.2,16),target=Vector3(103,6.8,5.3)}]:
		camera.position=view.eye;camera.look_at(view.target)
		for i in 30:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/"+view.name+".png")
		report.append({view=view.name,hour=hour,shadow_resolution=shadow_resolution,shadow_distance=shadow_distance,
			draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("OHE_RENDER_COMPLETE ",output);quit()
