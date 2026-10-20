extends SceneTree
## Bounded, synthetic review scene built with the actual station/track/environment code.
## No RailWorld.step, full route load, train, authored station model or preference writes.
## Prepare with tools/prepare_extreme_station_scene.py before importing.
## Forward+ capture: -- --output=/tmp/station-review --size=1280x720
## Headless structural-only check: -- --validate-only (never emits PNGs).
## Original source: --presets=High. Patched comparison: --compare-high=.../manifest.json.
const Graphics := preload("res://game/graphics_options.gd")
const GeographicWorld := preload("res://game/geographic_world.gd")
const RailwayChunk := preload("res://game/geographic_railway_chunk.gd")
const TrackView := preload("res://game/track_view.gd")
const Library := preload("res://game/scenery_library.gd")
const OHELayout := preload("res://game/geographic_ohe_layout.gd")
const MeshBuilder := preload("res://game/geographic_mesh.gd")
const VIEWS := [
	{id="platform-track",eye=Vector3(-5.5,2.1,322),target=Vector3(4.0,2.6,296)},
	{id="platform-canopy",eye=Vector3(4.0,2.95,330),target=Vector3(4.0,2.3,282)}
]
const PERIODS := [{id="daylight",hour=12.0},{id="dusk",hour=18.65}]

class FlatGeo extends RefCounted:
	var station_sites: Dictionary = {}
	var bridges: Array = []
	func ground_at(_x: float,_z: float) -> float:return 0.0

# Gives the production Graphics.apply() its normal game-facing API without a
# gameplay node or a simulation update callback. No copied options implementation.
class ReviewHost extends Node3D:
	var cam: Camera3D
	var wv
	var passenger_crowd = null

var output := "user://extreme-station-review"
var resolution := Vector2i(1280,720)
var settle_frames := 12
var sample_frames := 4
var validate_only := false
var presets := PackedStringArray(["High","Extreme","High-restored"])
var reference_path := ""
var reference_captures: Dictionary = {}
var report: Dictionary = {}
var viewport: SubViewport
var scene: ReviewHost
var camera: Camera3D
var environment: Environment
var world: RailWorld
var view
var options := Graphics.new()
var source_before: Dictionary = {}
var state_before := ""
var geometry_before := ""
var finished := false

func _initialize() -> void:
	Engine.time_scale=0.0
	if RenderingServer.has_method("set_shader_time_scale"):
		RenderingServer.call("set_shader_time_scale",0.0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--size="):
			var size:=arg.trim_prefix("--size=").split("x")
			if size.size()==2:resolution=Vector2i(size[0].to_int(),size[1].to_int())
		elif arg.begins_with("--settle-frames="):settle_frames=clampi(arg.trim_prefix("--settle-frames=").to_int(),4,240)
		elif arg.begins_with("--sample-frames="):sample_frames=clampi(arg.trim_prefix("--sample-frames=").to_int(),4,240)
		elif arg.begins_with("--presets="):presets=arg.trim_prefix("--presets=").split(",")
		elif arg.begins_with("--compare-high="):reference_path=ProjectSettings.globalize_path(arg.trim_prefix("--compare-high="))
		elif arg=="--validate-only":validate_only=true
	call_deferred("_run")

func _run() -> void:
	var run_id:=Time.get_datetime_string_from_system(true).replace(":","-")+"-"+str(Time.get_ticks_usec())
	output=ProjectSettings.globalize_path(output.path_join(run_id))
	if DirAccess.make_dir_recursive_absolute(output)!=OK:
		printerr("EXTREME_STATION_BLOCKED: Cannot create output directory: ",output);quit(2);return
	report={
		capture_status="initializing",capture_scope="bounded_synthetic_station",output_directory=output,
		godot=Engine.get_version_info(),os=OS.get_name(),display_server=DisplayServer.get_name(),
		renderer=RenderingServer.get_current_rendering_method(),
		rendering_driver=RenderingServer.get_current_rendering_driver_name(),
		device=RenderingServer.get_video_adapter_name(),device_vendor=RenderingServer.get_video_adapter_vendor(),
		rendering_device_available=RenderingServer.get_rendering_device()!=null,
		resolution=[resolution.x,resolution.y],presets=presets,settle_frames=settle_frames,frame_samples=sample_frames,
		shader_time_frozen=true,shader_time_method="Engine.time_scale=0.0 before first scene frame",
		fixture_overrides={vsync=false,fps_cap=0,taa=false,sky_process="QUALITY",flat_ground=true},
		builders=["GeographicWorld._make_materials","WorldView._build_environment",
			"GeographicRailwayChunk.build_station","TrackView.build","GeographicRailwayChunk.build_ohe",
			"DayNight.update","StationLighting.update","Graphics.apply"],
		captures=[],comparisons=[],high_baseline_comparisons=[],source_sha256={},invariant_checks=[],
		simulation_step_calls=0,synthetic_station={code="EXTREME_REVIEW",through_halt=true,major=false,edge_metres=600.0},
		limitations=[
			"Synthetic single-track halt using actual source builders, not an authored station or complete game scene.",
			"No train interiors, traffic, vegetation, streaming, route traversal or LOD-distance validation.",
			"Flat ground is a review-only mesh with the actual geographic ground material; it is not a route tile.",
			"Simulation source is copied unchanged and world state is fingerprinted; no simulation step is called.",
			"Frame intervals are wall-clock render-loop samples, not GPU timings or target-PC performance.",
			"Pixel equality/differences do not establish artistic quality. Human review is required.",
			"Sky radiance is QUALITY for deterministic captures; runtime normally uses incremental sky updates."
		]
	}
	if not _load_sources():return
	if not validate_only and (DisplayServer.get_name()=="headless" or report.device.is_empty() or
			report.renderer!="forward_plus" or not report.rendering_device_available):
		_fail("A real Forward+ renderer is required. Headless/dummy rendering cannot produce screenshots.");return
	if resolution.x<320 or resolution.y<180 or resolution.x>7680 or resolution.y>4320:
		_fail("Invalid --size; use 320x180 through 7680x4320.");return
	if presets!=PackedStringArray(["High"]) and presets!=PackedStringArray(["High","Extreme","High-restored"]):
		_fail("Use --presets=High or --presets=High,Extreme,High-restored.");return
	if presets.has("Extreme") and not Graphics.PRESETS.has("Extreme"):
		_fail("Original options have no Extreme preset. Use --presets=High.");return
	if validate_only and not reference_path.is_empty():
		_fail("--compare-high requires rendered captures, not --validate-only.");return
	# The timer uses wall clock while the engine and all shader TIME are frozen.
	create_timer(840.0,true,false,true).timeout.connect(func():_fail("Station review timed out before completion."))
	_build_scene()
	if not _check_scene():return
	geometry_before=_geometry_digest()
	report.geometry_sha256_before=geometry_before
	if not _check_invariants("after_build"):return
	if not reference_path.is_empty() and not _load_reference():return
	if validate_only:
		for period in PERIODS:
			_set_lighting(period.hour)
			for preset in presets:
				_apply_preset(preset)
				for camera_view in VIEWS:
					_set_camera(camera_view)
					if not _check_invariants(period.id+"-"+preset+"-"+camera_view.id):return
		if not _check_sources():return
		report.capture_status="structural_validation_only_not_rendered"
		report.screenshots_captured=0
		finished=true
		if not _write_report():return
		print("EXTREME_STATION_STRUCTURE_OK: ",output,"; no rendering or visual approval claimed.")
		quit(0);return
	report.capture_status="capturing"
	if not _write_report():return
	for period in PERIODS:
		_set_lighting(period.hour)
		var high: Dictionary={};var extreme: Dictionary={}
		for preset in presets:
			_apply_preset(preset)
			for camera_view in VIEWS:
				_set_camera(camera_view)
				var label: String=period.id+"-"+camera_view.id+"-"+preset.to_lower()
				var captured: Image=await _capture(label,period,camera_view,preset)
				if captured==null:return
				if preset=="High":
					high[camera_view.id]=captured
					if not reference_path.is_empty() and not _compare_reference(label,captured):return
				elif preset=="Extreme":extreme[camera_view.id]=captured
				else:
					report.comparisons.append({period=period.id,view=camera_view.id,
						high_vs_extreme=_difference(high[camera_view.id],extreme[camera_view.id]),
						high_vs_restored=_difference(high[camera_view.id],captured)})
				if not _check_invariants(label):return
	if not _check_sources():return
	report.capture_status="captured_requires_visual_review"
	report.all_high_restored_pixels_equal=null if report.comparisons.is_empty() else true
	for comparison in report.comparisons:
		if not comparison.high_vs_restored.exact_equal:report.all_high_restored_pixels_equal=false
	report.all_baseline_high_pixels_equal=null if report.high_baseline_comparisons.is_empty() else true
	for comparison in report.high_baseline_comparisons:
		if not comparison.high_vs_baseline.exact_equal:report.all_baseline_high_pixels_equal=false
	finished=true
	if not _write_report():return
	print("EXTREME_STATION_CAPTURED: ",output,"; visual quality is NOT automatically approved.")
	quit(0)

func _build_scene() -> void:
	world=RailWorld.new()
	world.graph.add_node("START",Vector3.ZERO)
	world.graph.add_node("END",Vector3(0,0,600))
	world.graph.add_edge("REVIEW_ROAD","START","END")
	world.graph.edges.REVIEW_ROAD.merge({chainage_start=0.0,chainage_end=600.0,lateral=0.0})
	var detail:={offset=0.0,platform_width=4.4,platform_side=-1.0}
	world.stations.append({code="EXTREME_REVIEW",name="VISUAL REVIEW",board_name="VISUAL REVIEW",
		origin=Vector3(0,0,300),s=300.0,major=false,through_halt=true,passenger_open=true,
		platform_tracks=["REVIEW_ROAD"],platform_details={REVIEW_ROAD=detail},operating_roads=[detail]})
	world.scenery={geographic=true}
	state_before=_world_digest()
	report.world_sha256_before=state_before
	viewport=SubViewport.new();viewport.size=resolution;viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.use_taa=false
	root.add_child(viewport)
	var preview:=TextureRect.new();preview.texture=viewport.get_texture()
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(preview);preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene=ReviewHost.new();scene.name="SyntheticStationReview";viewport.add_child(scene)
	view=GeographicWorld.new();view.world=world;view.root=scene
	scene.wv=view
	view._noise_tex=NoiseTexture2D.new()
	view._noise_tex.width=256;view._noise_tex.height=256;view._noise_tex.seamless=true
	var noise:=FastNoiseLite.new();noise.frequency=.012
	view._noise_tex.noise=noise
	view.assets=Library.new(view)
	view._make_materials()
	# Same source noise parameters, evaluated synchronously to avoid worker timing.
	view.materials.ground.set_shader_parameter("macro_noise",ImageTexture.create_from_image(noise.get_seamless_image(256,256)))
	view._build_environment()
	environment=view.day_night.environment;environment.sky.process_mode=Sky.PROCESS_MODE_QUALITY
	view.day_night.bind_scenery(view.assets,[view.materials.architecture])
	var geo:=FlatGeo.new()
	var railway:=RailwayChunk.new(world,geo,view.materials,view.assets)
	var station: Dictionary=railway.build_station(0)
	station.node.position=station.origin;scene.add_child(station.node)
	var track:=TrackView.new();track.build(view)
	report.track_stats=track.stats.duplicate(true)
	var overhead: Dictionary=railway.build_ohe("REVIEW_ROAD",0.0,600.0,OHELayout.new(world))
	overhead.node.position=overhead.origin;scene.add_child(overhead.node)
	var ground:=MeshBuilder.new()
	ground.quad("ground",Vector3(-120,-.03,0),Vector3(120,-.03,0),Vector3(120,-.03,600),Vector3(-120,-.03,600),
		Vector3.UP,Color(.72,.80,.60,.12),[Vector2(-120,0)/3.5,Vector2(120,0)/3.5,Vector2(120,600)/3.5,Vector2(-120,600)/3.5])
	ground.finish(scene,view.materials,"ReviewFlat")
	camera=Camera3D.new();camera.fov=58.0;camera.near=.05;scene.add_child(camera);camera.make_current()
	scene.cam=camera;options.game=scene

func _check_scene() -> bool:
	var required:=["Station_EXTREME_REVIEW","PermanentWay","Electrification_REVIEW_ROAD",
		"Railway_platform","Railway_roof","Railway_concrete","Railway_metal","Railway_paint",
		"Railway_sign","Railway_architecture","Railway_station_boundary","StationName_1_0"]
	for label in required:
		if scene.find_child(label,true,false)==null:
			_fail("Actual game builder omitted required node: "+label);return false
	if report.track_stats.chunks!=10 or report.track_stats.sleepers<900:
		_fail("Actual 600 m track geometry was not built completely.");return false
	var geometries:=scene.find_children("*","GeometryInstance3D",true,false)
	report.geometry_instances=geometries.size()
	report.station_nameboards=scene.find_children("*","Label3D",true,false).size()
	report.station_light_sites=view.night_lights.groups[0].sites.size()
	report.station_platform_metres=200.0
	if report.station_nameboards!=4 or report.station_light_sites!=4:
		_fail("Expected four actual nameboard faces and four bounded canopy light sites.");return false
	for path in source_before:
		if str(path).ends_with(".jpg") or str(path).ends_with(".hdr"):
			if not load(path) is Texture2D:
				_fail("Missing imported source texture: "+str(path));return false
	return true

func _set_lighting(hour: float) -> void:
	# Feed the presentation-only controller explicitly. Never change world time.
	view.day_night.update(hour*3600.0,true)

func _set_camera(camera_view: Dictionary) -> void:
	camera.position=camera_view.eye;camera.look_at(camera_view.target)
	view.night_lights.update(camera.position,Vector3.ZERO,view.day_night.state.night,Callable(),true)

func _apply_preset(preset: String) -> void:
	options.preset("High" if preset=="High-restored" else preset)
	options.values.vsync=false;options.values.fps=0
	options.apply()

func _world_digest() -> String:
	return _digest({nodes=world.graph.nodes,edges=world.graph.edges,switches=world.graph.switches,
		time=world.time,clock_start=world.clock_start,trains=world.trains,signals=world.signals,
		stations=world.stations,scenery=world.scenery,depots=world.depots,depot_reservations=world.depot_reservations,
		events=world.events,event_seq=world._event_seq,dispatch_history=world.dispatch_history,
		dispatch_holds=world.dispatch_holds,dispatch_notices=world.dispatch_notices,
		single_line_sections=world.single_line_sections,automatic_signals=world.automatic_signals})

func _geometry_digest() -> String:
	var geometry: Array=[]
	var meshes: Dictionary={}
	# Only static actual scene geometry. Station lamps intentionally update their
	# visible instance pool with the camera/time; they do not modify this geometry.
	for node in scene.find_children("*","GeometryInstance3D",true,false):
		if str(node.name).begins_with("StationLight"):continue
		var record:={path=str(scene.get_path_to(node)),transform=node.global_transform}
		if node is MeshInstance3D:
			record.mesh=_mesh_digest(node.mesh,meshes)
		elif node is MultiMeshInstance3D:
			record.mesh=_mesh_digest(node.multimesh.mesh,meshes)
			record.instances=node.multimesh.instance_count
			record.buffer_sha256=_digest(node.multimesh.buffer)
		elif node is Label3D:record.text=node.text
		geometry.append(record)
	return _digest(geometry)

func _mesh_digest(mesh: Mesh,cache: Dictionary) -> String:
	var identity:=mesh.get_instance_id()
	if cache.has(identity):return cache[identity]
	var surfaces: Array=[]
	for index in mesh.get_surface_count():surfaces.append(mesh.surface_get_arrays(index))
	cache[identity]=_digest(surfaces)
	return cache[identity]

func _digest(value: Variant) -> String:
	var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(value));return context.finish().hex_encode()

func _check_invariants(label: String) -> bool:
	var state:=_world_digest();var geometry:=_geometry_digest()
	var equal:=state==state_before and geometry==geometry_before
	report.invariant_checks.append({id=label,world_unchanged=state==state_before,
		geometry_unchanged=geometry==geometry_before,world_sha256=state,geometry_sha256=geometry})
	report.world_unchanged=state==state_before;report.static_geometry_unchanged=geometry==geometry_before
	if not equal:_fail("World or static geometry mutated during presentation review: "+label);return false
	return true

func _load_sources() -> bool:
	var path:="res://station-source-manifest.json"
	if not FileAccess.file_exists(path):
		_fail("Prepare an isolated station scene first; source manifest is required.");return false
	var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not source is Dictionary or source.get("status")!="bounded_station_source_prepared_not_rendered":
		_fail("Invalid station source manifest.");return false
	report.source_provenance=source
	for entry in source.get("files",[]):
		var relative: String=entry.get("path","")
		if relative.is_empty() or relative.is_absolute_path() or ".." in relative.split("/"):
			_fail("Unsafe source manifest path.");return false
		var resource:="res://"+relative
		# The importer may rewrite cache remaps in the isolated .import files.
		# Original import bytes remain recorded in source_provenance.
		if relative.ends_with(".import"):
			if not report.has("import_metadata_sha256"):report.import_metadata_sha256={}
			report.import_metadata_sha256[resource]=FileAccess.get_sha256(resource)
			continue
		if not FileAccess.file_exists(resource) or FileAccess.get_sha256(resource)!=entry.get("sha256"):
			_fail("Source missing or hash-mismatched: "+resource);return false
		source_before[resource]=entry.sha256
	report.source_sha256=source_before.duplicate()
	return true

func _check_sources() -> bool:
	for path in source_before:
		# Godot regenerates texture import metadata in the isolated copy only.
		if str(path).ends_with(".import"):continue
		if FileAccess.get_sha256(path)!=source_before[path]:
			_fail("Source changed during station review: "+str(path));return false
	report.source_files_unchanged=true
	return true

func _load_reference() -> bool:
	if not FileAccess.file_exists(reference_path):_fail("Missing baseline manifest.");return false
	var reference: Variant=JSON.parse_string(FileAccess.get_file_as_string(reference_path))
	if not reference is Dictionary or reference.get("capture_status")!="captured_requires_visual_review":
		_fail("Baseline must contain completed real station captures.");return false
	var normalized: Dictionary=JSON.parse_string(JSON.stringify(report))
	for key in ["capture_scope","resolution","godot","renderer","rendering_driver","device","fixture_overrides","settle_frames","frame_samples"]:
		if reference.get(key)!=normalized.get(key):_fail("Baseline mismatch: "+key);return false
	for entry in reference.get("captures",[]):
		if entry.get("preset")=="High":reference_captures[entry.id]=entry
	for period in PERIODS:
		for camera_view in VIEWS:
			if not reference_captures.has(period.id+"-"+camera_view.id+"-high"):
				_fail("Baseline missing a required station High capture.");return false
	report.baseline_manifest=reference_path;report.baseline_source_sha256=reference.get("source_sha256",{})
	return true

func _compare_reference(label: String,current: Image) -> bool:
	var entry: Dictionary=reference_captures[label]
	var file: String=entry.get("file","")
	if file.is_empty() or file!=file.get_file():_fail("Invalid baseline image path.");return false
	var path:=reference_path.get_base_dir().path_join(file)
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=entry.get("png_sha256"):
		_fail("Baseline image missing or hash-mismatched: "+path);return false
	var original:=Image.load_from_file(path)
	if original==null or original.is_empty() or original.get_size()!=current.get_size():
		_fail("Invalid baseline image: "+path);return false
	original.convert(Image.FORMAT_RGBA8)
	report.high_baseline_comparisons.append({id=label,baseline_file=file,baseline_png_sha256=entry.png_sha256,
		high_vs_baseline=_difference(original,current)})
	return _write_report()

func _capture(label: String,period: Dictionary,camera_view: Dictionary,preset: String) -> Image:
	for i in settle_frames:await process_frame
	var samples: Array[float]=[]
	await RenderingServer.frame_post_draw
	var previous:=Time.get_ticks_usec()
	for i in sample_frames:
		await process_frame;await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();samples.append(float(now-previous)/1000.0);previous=now
	var captured:=viewport.get_texture().get_image()
	if captured==null or captured.is_empty() or captured.get_size()!=resolution:
		_fail("Missing or wrong-sized real viewport image: "+label);return null
	captured.convert(Image.FORMAT_RGBA8)
	var stats:=_image_stats(captured)
	var draws:=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	if draws<=0 or stats.rgb_range<2 or stats.maximum_rgb<3:
		_fail("Empty, flat or black viewport / no geometry draw calls: "+label);return null
	var path:=output.path_join(label+".png")
	if captured.save_png(path)!=OK:_fail("PNG write failed: "+label);return null
	samples.sort()
	report.captures.append({id=label,file=label+".png",capture_status="captured",period=period.id,hour=period.hour,
		view=camera_view.id,preset=preset,preset_values=options.values.duplicate(true),resolution=[resolution.x,resolution.y],
		camera_eye=_xyz(camera_view.eye),camera_target=_xyz(camera_view.target),camera_fov=camera.fov,
		shader_time_frozen=true,ssr_requested=options.values.get("reflections",false),ssr_enabled=environment.ssr_enabled,
		radiance_size_enum=environment.sky.radiance_size,draw_calls=draws,
		primitives=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		station_active_lights=view.night_lights.active_lights,station_visible_fixtures=view.night_lights.visible_fixtures,
		frame_ms_median=samples[sample_frames/2],frame_ms_p95=samples[ceili(sample_frames*.95)-1],
		frame_timing="wall-clock frame_post_draw intervals; uncapped/vsync disabled; not GPU duration",
		png_sha256=FileAccess.get_sha256(path),image_stats=stats})
	if not _write_report():return null
	print("EXTREME_STATION_FRAME: ",label)
	return captured

func _difference(a: Image,b: Image) -> Dictionary:
	var left:=a.get_data();var right:=b.get_data();var pixels:=a.get_width()*a.get_height()
	if left==right:return {exact_equal=true,changed_rgb_pixels=0,total_pixels=pixels,changed_rgb_fraction=0.0,mean_absolute_rgb_error_255=0.0,max_rgb_error_255=0}
	var changed:=0;var total:=0;var maximum:=0
	for i in range(0,left.size(),4):
		var pixel_changed:=false
		for channel in 3:
			var delta:=absi(int(left[i+channel])-int(right[i+channel]));total+=delta;maximum=maxi(maximum,delta)
			if delta>0:pixel_changed=true
		if pixel_changed:changed+=1
	return {exact_equal=false,changed_rgb_pixels=changed,total_pixels=pixels,changed_rgb_fraction=float(changed)/pixels,
		mean_absolute_rgb_error_255=float(total)/(pixels*3),max_rgb_error_255=maximum}

func _image_stats(captured: Image) -> Dictionary:
	var data:=captured.get_data();var low: Array[int]=[255,255,255];var high: Array[int]=[0,0,0]
	var step:=maxi(1,(captured.get_width()*captured.get_height())/8192)
	for i in range(0,data.size(),4*step):
		for channel in 3:
			var value:=int(data[i+channel]);low[channel]=mini(low[channel],value);high[channel]=maxi(high[channel],value)
	return {minimum_rgb=mini(low[0],mini(low[1],low[2])),maximum_rgb=maxi(high[0],maxi(high[1],high[2])),
		rgb_range=maxi(high[0]-low[0],maxi(high[1]-low[1],high[2]-low[2]))}

func _xyz(value: Vector3) -> Array:return [value.x,value.y,value.z]

func _write_report() -> bool:
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	if file==null:
		finished=true;printerr("EXTREME_STATION_BLOCKED: Cannot write manifest: ",FileAccess.get_open_error());quit(2);return false
	file.store_string(JSON.stringify(report,"\t"));return true

func _fail(reason: String) -> void:
	if finished:return
	finished=true;report.capture_status="blocked";report.failure=reason
	_write_report();printerr("EXTREME_STATION_BLOCKED: ",reason," Manifest: ",output.path_join("manifest.json"));quit(2)
