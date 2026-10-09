extends SceneTree
const Placement := preload("res://game/coastal_station_placement.gd")
const Authored := preload("res://game/authored_station.gd")
var failures:=0
var checks:=0
func expect(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("COASTAL FAIL ",message)
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	root.size=Vector2i(1440,900)
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var scene:=Node3D.new();root.add_child(scene)
	var environment:=WorldEnvironment.new();scene.add_child(environment)
	var env:=Environment.new();environment.environment=env
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.49,.61,.71)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.76,.82,.88);env.ambient_light_energy=.8
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	var sun:=DirectionalLight3D.new();scene.add_child(sun);sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.8;sun.shadow_enabled=true;sun.directional_shadow_max_distance=350
	var camera:=Camera3D.new();scene.add_child(camera);camera.current=true;camera.fov=55;camera.far=2000
	var ground:=MeshInstance3D.new();scene.add_child(ground)
	var plane:=PlaneMesh.new();plane.size=Vector2(700,700);ground.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.32,.34,.29);ground.material_override=mat
	var total_triangles:=0
	for code in Placement.CODES:
		var stations: Array=world.stations.filter(func(s):return s.code==code)
		expect(stations.size()==1,"Active route entry "+code)
		if stations.is_empty():continue
		var station: Dictionary=stations[0]
		var site:=Placement.site(world,station,station.origin)
		var assembly:=Authored.add_building(scene,code,site.position,site.forward,site.right)
		var count:=0
		var shaders:=true
		for mesh in assembly.model.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).begins_with("Shadow_"):continue
			for i in mesh.mesh.get_surface_count():
				shaders=shaders and mesh.get_surface_override_material(i) is ShaderMaterial
				count+=mesh.mesh.surface_get_array_index_len(i)/3
		var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/station_"+Placement.asset_code(code).to_lower()+"_detail/provenance.json"))
		expect(count==int(provenance.triangles),"Unchanged full-detail triangles "+code)
		expect(shaders,"Source shader on every surface "+code)
		expect(absf(assembly.model.basis.determinant()-1.0)<.0001,"Metre scale without mirroring "+code)
		var b: Array=provenance.source_bounds
		var footprint: AABB=AABB(Vector3(b[0][0],b[0][2],-b[1][1]),Vector3(b[1][0]-b[0][0],b[1][2]-b[0][2],b[1][1]-b[0][1]))
		var inverse: Transform3D=assembly.model.transform.affine_inverse()
		var clear:=true
		if code!="VRLR":
			for edge: String in station.platform_tracks:
				var length: float=world.graph.edges[edge].length
				for offset in range(-180,181,10):
					var point:=inverse*world.graph.position_relative(edge,length*.5+offset,station.origin)
					if point.x>=footprint.position.x-2.8 and point.x<=footprint.end.x+2.8 and point.z>=footprint.position.z-2.8 and point.z<=footprint.end.z+2.8:clear=false
		expect(clear,"Building clear of all running roads "+code)
		total_triangles+=count
		print("COASTAL ",code," triangles=",count," footprint=",assembly.footprint)
		# Inspect every model in native renderer; capture representative regional
		# families including corrected signage and the shelter-only station.
		if DisplayServer.get_name()!="headless":
			ground.position=assembly.position-Vector3.UP*.03
			var distance: float=maxf(35,assembly.footprint.x*.7)
			camera.position=assembly.position-site.right*distance+site.forward*distance*.55+Vector3.UP*distance*.37
			camera.look_at(assembly.position+Vector3.UP*3)
			for frame in 4:await process_frame
			await RenderingServer.frame_post_draw
			if code in ["KUMM","TUVR","ALLP","KPY","QLN","VAK","TVCN","NYY","VRLR","NJT"]:
				root.get_texture().get_image().save_png("res://.local/coastal-"+code.to_lower()+".png")
		assembly.model.free()
	expect(not Authored.available("TNU"),"Historical Tirunettur not an active station")
	expect(Placement.CODES.size()==52,"All 52 new active station assets")
	print("COASTAL_STATIONS checks=",checks," failures=",failures," triangles=",total_triangles)
	quit(failures)
