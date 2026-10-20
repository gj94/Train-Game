extends SceneTree
## Actual source-material A/B fixture, not a railway or a performance benchmark.
## Run with a real display/GPU (not --headless):
## godot --path . --rendering-method forward_plus --script res://tools/check_extreme_visuals.gd
## User args: -- --output=user://extreme-visual-review --size=1280x720 --allow-compatibility
## Software-rendered CI may add --settle-frames=12 --sample-frames=8; this is NOT target-GPU performance.
## Baseline fixture: --presets=High. Patched fixture: --compare-high=/path/to/baseline/manifest.json
## Optional --check-rebase adds four Extreme daylight road/station frames at a 300 km route origin.
## Optional --views=road,station --periods=daylight is a labelled subset smoke, not the full review.
## Optional --reflection-diagnostic instead captures six isolated water/SSR/normal diagnostic images.
## Each run gets a fresh directory. A failed/dummy renderer writes only a blocked manifest.
const Graphics := preload("res://game/graphics_options.gd")
const ExtremeVisuals := preload("res://game/extreme_visuals.gd")
# Same source path and maps as world_view.PH; do not instantiate the railway.
const PH := "res://assets/polyhaven/%s/%s_%s_2k.jpg"
const HDRI := "res://assets/polyhaven/hdri/kloofendal_43d_clear_puresky_2k.hdr"
const VIEWS := [
	{id="overview",eye=Vector3(18,11,19),target=Vector3(2,0,0)},
	{id="ground",eye=Vector3(-5,1.35,3.0),target=Vector3(-5,0,-1.0)},
	{id="road",eye=Vector3(0,1.35,3.0),target=Vector3(0,0,-1.0)},
	{id="station",eye=Vector3(7,2.2,3.5),target=Vector3(5,1,-2)},
	{id="water",eye=Vector3(12,1.8,5.5),target=Vector3(10,0,-2)}
]
var output := "user://extreme-visual-review"
var resolution := Vector2i(1280,720)
var allow_compatibility := false
var settle_frames := 48
var sample_frames := 24
var presets := PackedStringArray(["High","Extreme","High-restored"])
var check_rebase := false
var reflection_diagnostic := false
var diagnostic_state: Dictionary = {}
var reference_path := ""
var reference_captures: Dictionary = {}
var route_origin := Vector3.ZERO
var source_materials: Array[ShaderMaterial] = []
var selected_views := PackedStringArray()
var selected_periods := PackedStringArray()
var report: Dictionary = {}
var scene: Node3D
var viewport: SubViewport
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var sky_material: ShaderMaterial
var lamp: OmniLight3D
var options := Graphics.new()
var assets: Dictionary = {}
var asset_error := ""
var forward_plus := false
var finished := false

func _initialize() -> void:
	# Since Godot 4.4, Engine.time_scale also controls shader TIME. Freeze before
	# the first fixture frame. Some builds additionally expose the explicit API.
	Engine.time_scale=0.0
	if RenderingServer.has_method("set_shader_time_scale"):
		RenderingServer.call("set_shader_time_scale",0.0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--size="):
			var parts:=arg.trim_prefix("--size=").split("x")
			if parts.size()==2:resolution=Vector2i(parts[0].to_int(),parts[1].to_int())
		elif arg=="--allow-compatibility":allow_compatibility=true
		elif arg.begins_with("--settle-frames="):settle_frames=clampi(arg.trim_prefix("--settle-frames=").to_int(),4,240)
		elif arg.begins_with("--sample-frames="):sample_frames=clampi(arg.trim_prefix("--sample-frames=").to_int(),4,240)
		elif arg.begins_with("--presets="):presets=arg.trim_prefix("--presets=").split(",")
		elif arg.begins_with("--compare-high="):reference_path=ProjectSettings.globalize_path(arg.trim_prefix("--compare-high="))
		elif arg=="--check-rebase":check_rebase=true
		elif arg=="--reflection-diagnostic":reflection_diagnostic=true
		elif arg.begins_with("--views="):selected_views=arg.trim_prefix("--views=").split(",")
		elif arg.begins_with("--periods="):selected_periods=arg.trim_prefix("--periods=").split(",")
	call_deferred("_run")

func _run() -> void:
	var run_id: String=Time.get_datetime_string_from_system(true).replace(":","-")+"-"+str(Time.get_ticks_usec())
	output=ProjectSettings.globalize_path(output.path_join(run_id))
	var error:=DirAccess.make_dir_recursive_absolute(output)
	if error!=OK:
		printerr("EXTREME_VISUAL_BLOCKED: Cannot create output directory: ",output," (",error,")")
		quit(2)
		return
	var version:=Engine.get_version_info()
	var method:=RenderingServer.get_current_rendering_method()
	var device:=RenderingServer.get_video_adapter_name()
	forward_plus=method=="forward_plus"
	report={
		capture_status="initializing",output_directory=output,
		resolution=[resolution.x,resolution.y],godot=version,os=OS.get_name(),
		display_server=DisplayServer.get_name(),renderer=method,
		rendering_driver=RenderingServer.get_current_rendering_driver_name(),
		device=device,device_vendor=RenderingServer.get_video_adapter_vendor(),
		device_type=RenderingServer.get_video_adapter_type(),
		rendering_device_available=RenderingServer.get_rendering_device()!=null,
		ssr_supported=forward_plus and RenderingServer.get_rendering_device()!=null,
		captures=[],comparisons=[],high_baseline_comparisons=[],rebase_comparisons=[],assets=assets,
		presets=presets,check_rebase=check_rebase,
		selected_views=selected_views,selected_periods=selected_periods,
		capture_scope="reflection_diagnostic" if reflection_diagnostic else (
			"full_fixture" if selected_views.is_empty() and selected_periods.is_empty() else "subset_smoke"),
		capture_order="lighting period, then preset, then camera",
		shaders=ExtremeVisuals.SURFACE_SHADERS,settle_frames=settle_frames,
		frame_samples=sample_frames,shader_time_frozen=true,
		shader_time_method="Engine.time_scale=0.0 before first fixture frame",
		fixture_overrides={vsync=false,fps_cap=0,taa=false,sky_process="QUALITY"},
		source_sha256={},
		limitations=[
			"Source-material fixture only: no railway, trains, streaming, vegetation or LOD-distance coverage.",
			"Frame intervals are wall-clock render-loop samples, not GPU timings or target-PC performance.",
			"PNG differences quantify pixels, not artistic quality. Human review is still required.",
			"Screen-space effects/radiance history can prevent exact restoration despite identical settings.",
			"Frozen time, fixed cameras and noise seed are repeatable within this run, not cross-device pixel guarantees."
		]
	}
	for path in ExtremeVisuals.SURFACE_SHADERS+[
		"res://game/shaders/extreme_surface_detail.gdshaderinc",
		"res://game/shaders/day_night_sky.gdshader","res://game/extreme_visuals.gd",
		"res://game/graphics_options.gd","res://tools/check_extreme_visuals.gd"]:
		report.source_sha256[path]=FileAccess.get_sha256(path)
	if FileAccess.file_exists("res://fixture-source-manifest.json"):
		var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://fixture-source-manifest.json"))
		if prepared is Dictionary:
			report.fixture_provenance={baseline_ref=prepared.get("baseline_ref",""),baseline_files=prepared.get("baseline_files",[])}
	if DisplayServer.get_name()=="headless" or device.is_empty():
		_fail("No real display/rendering adapter. --headless uses dummy rendering; no screenshots were captured.")
		return
	if forward_plus and RenderingServer.get_rendering_device()==null:
		_fail("Forward+ has no RenderingDevice; cannot produce visual evidence.")
		return
	if not forward_plus:
		if method!="gl_compatibility" or not allow_compatibility:
			_fail("Forward+ required. For explicitly limited Compatibility captures, pass --allow-compatibility.")
			return
		report.limitations.append("COMPATIBILITY: SSR, SSAO and SSIL are unsupported/disabled. These images cannot validate Extreme reflections.")
	if int(version.major)<4 or (int(version.major)==4 and int(version.minor)<4):
		if not RenderingServer.has_method("set_shader_time_scale"):
			_fail("This Godot version cannot freeze shader TIME reliably; use Godot 4.4 or newer.")
			return
	if resolution.x<320 or resolution.y<180 or resolution.x>7680 or resolution.y>4320:
		_fail("Invalid --size; use 320x180 through 7680x4320.")
		return
	if presets!=PackedStringArray(["High"]) and presets!=PackedStringArray(["High","Extreme","High-restored"]):
		_fail("Use --presets=High or --presets=High,Extreme,High-restored.")
		return
	if (presets.has("Extreme") or check_rebase) and not Graphics.PRESETS.has("Extreme"):
		_fail("This is a parent-baseline options file. Use --presets=High without --check-rebase.")
		return
	if reflection_diagnostic and (not forward_plus or check_rebase or not reference_path.is_empty()
		or not selected_views.is_empty() or not selected_periods.is_empty() or not presets.has("Extreme")):
		_fail("--reflection-diagnostic requires current Forward+ options, without baseline/rebase/subset arguments.")
		return
	for view_id in selected_views:
		if view_id not in ["overview","ground","road","station","water"]:
			_fail("Unknown --views entry: "+view_id);return
	for period_id in selected_periods:
		if period_id not in ["daylight","dusk","night"]:
			_fail("Unknown --periods entry: "+period_id);return
	if not reference_path.is_empty() and not _load_reference():return
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# Wall-clock watchdog remains active while Engine.time_scale is zero.
	create_timer(840.0,true,false,true).timeout.connect(func():_fail("Capture timed out before completion."))
	_build_fixture()
	if not asset_error.is_empty():
		_fail(asset_error)
		return
	report.capture_status="capturing"
	if not _write_report():return
	if reflection_diagnostic:
		await _capture_reflection_diagnostic()
		return
	for period in [{id="daylight",hour=12.0},{id="dusk",hour=18.25},{id="night",hour=22.0}]:
		if not selected_periods.is_empty() and not selected_periods.has(period.id):continue
		_set_lighting(period.hour)
		lamp.light_energy=0.0 if period.id=="daylight" else 3.0
		var baseline_by_view: Dictionary={}
		var extreme_by_view: Dictionary={}
		# Keep the same preset while visiting all cameras. This avoids rebuilding
		# 256/512 sky radiance for every view, without changing capture settings.
		for preset in presets:
			_apply_preset("High" if preset=="High-restored" else preset)
			for view in VIEWS:
				if not selected_views.is_empty() and not selected_views.has(view.id):continue
				camera.position=view.eye
				camera.look_at(view.target)
				var label: String=period.id+"-"+view.id+"-"+preset.to_lower()
				var captured: Image=await _capture(label,period,view,preset)
				if captured==null:return
				if preset=="High":
					baseline_by_view[view.id]=captured
					if not reference_path.is_empty() and not _compare_reference(label,captured):return
				elif preset=="Extreme":extreme_by_view[view.id]=captured
				else:
					report.comparisons.append({
						period=period.id,view=view.id,
						high_vs_extreme=_difference(baseline_by_view[view.id],extreme_by_view[view.id]),
						high_vs_restored=_difference(baseline_by_view[view.id],captured)
					})
					if not _write_report():return
	if check_rebase and not await _capture_rebase():return
	report.capture_status="captured_requires_visual_review" if forward_plus else "captured_unsupported_ssr"
	report.all_high_restored_pixels_equal=null if report.comparisons.is_empty() else true
	for comparison in report.comparisons:
		if not comparison.high_vs_restored.exact_equal:report.all_high_restored_pixels_equal=false
	report.all_baseline_high_pixels_equal=null if report.high_baseline_comparisons.is_empty() else true
	for comparison in report.high_baseline_comparisons:
		if not comparison.high_vs_baseline.exact_equal:report.all_baseline_high_pixels_equal=false
	finished=true
	if not _write_report():return
	print("EXTREME_VISUAL_CAPTURED: ",output,"; High-restored exact equality: ",report.all_high_restored_pixels_equal,
		"; visual quality is NOT automatically approved.")
	quit(0)

func _capture_reflection_diagnostic() -> void:
	# Diagnostic materials never leave this optional fixture process. Keep the
	# same sky resolution and detail while changing ONLY SSR for each pair.
	var water:=scene.get_node("Water") as MeshInstance3D
	var source:=water.material_override as ShaderMaterial
	var period:={id="daylight",hour=12.0}
	var view: Dictionary=VIEWS[4]
	_set_lighting(period.hour);lamp.light_energy=0.0
	_apply_preset("Extreme")
	camera.position=view.eye;camera.look_at(view.target)
	report.diagnostic_comparisons=[]
	report.limitations.append("DIAGNOSTIC ONLY: six water-camera images, not the 49-frame source review. Full-image SSR differences do not prove a water reflection hit.")
	report.limitations.append("Normal RGB views are unshaded in-memory copies of the source shader, still display-tonemapped. They are not final game materials.")
	var mirror:=StandardMaterial3D.new()
	mirror.albedo_color=Color(.8,.8,.8);mirror.metallic=1.0;mirror.roughness=.02
	for material_case in [{id="source-water",material=source},{id="standard-metal-mirror",material=mirror}]:
		water.material_override=material_case.material
		ExtremeVisuals.apply_surface(water,true)
		var off: Image
		for enabled in [false,true]:
			environment.ssr_enabled=enabled
			options.values.reflections=enabled
			diagnostic_state={material=material_case.id,ssr=enabled,surface_detail=true,
				sky_radiance_fixed_512=true,normal_visualization=false}
			var label: String="diagnostic-"+material_case.id+("-ssr-on" if enabled else "-ssr-off")
			var captured: Image=await _capture(label,period,view,"Diagnostic-Extreme-fixed")
			if captured==null:return
			if not enabled:off=captured
			else:report.diagnostic_comparisons.append({material=material_case.id,ssr_off_vs_on=_difference(off,captured)})
	water.material_override=source
	for view_space in [false,true]:
		var normal_material:=_diagnostic_normal_material(source,view_space)
		if normal_material==null:return
		water.material_override=normal_material
		# The generated debug shader still declares the original instance slot,
		# but intentionally is not a supported runtime source-material path.
		water.set_instance_shader_parameter("extreme_detail",1.0)
		environment.ssr_enabled=false;options.values.reflections=false
		diagnostic_state={material="source-water-normal-debug",ssr=false,surface_detail=true,
			normal_visualization="view-space reconstructed mapped normal" if view_space else "tangent-space NORMAL_MAP RGB"}
		var label: String="diagnostic-water-"+("view-normal" if view_space else "normal-map")
		if await _capture(label,period,view,"Diagnostic-normal") == null:return
	report.capture_status="diagnostic_captured_requires_review"
	finished=true
	if not _write_report():return
	print("EXTREME_REFLECTION_DIAGNOSTIC_CAPTURED: ",output,"; not a production visual-review pass.")
	quit(0)

func _diagnostic_normal_material(source: ShaderMaterial,view_space: bool) -> ShaderMaterial:
	var code:=source.shader.code
	# This fixture's water shader ends with fragment(); fail if that contract
	# changes rather than inserting diagnostics into an unrelated function.
	var fragment_start:=code.find("void fragment()")
	var end:=code.rfind("}")
	if fragment_start<0 or end<fragment_start or code.find("void ",fragment_start+5)>=0:
		_fail("Cannot inject normal diagnostic into changed source-water shader.");return null
	var render_mode:=RegEx.new()
	render_mode.compile("render_mode[^;]*;")
	code=render_mode.sub(code,"render_mode unshaded;",true)
	code=code.replace('#include "extreme_surface_detail.gdshaderinc"',
		'#include "res://game/shaders/extreme_surface_detail.gdshaderinc"')
	# Mirrors Godot 4.7.2 Forward+ normal-map reconstruction (unnormalized TBN):
	# servers/rendering/renderer_rd/shaders/forward_clustered/scene_forward_clustered.glsl
	var visualization:="ALBEDO = NORMAL_MAP;\n"
	if view_space:
		visualization="""vec3 diagnostic_q = vec3(NORMAL_MAP.xy * 2.0 - 1.0, 0.0);
		diagnostic_q.z = sqrt(max(0.0, 1.0 - dot(diagnostic_q.xy, diagnostic_q.xy)));
		vec3 diagnostic_n = normalize(mix(NORMAL, TANGENT * diagnostic_q.x +
			BINORMAL * diagnostic_q.y + NORMAL * diagnostic_q.z, NORMAL_MAP_DEPTH));
		ALBEDO = diagnostic_n * 0.5 + 0.5;
		"""
	end=code.rfind("}")
	code=code.substr(0,end)+visualization+"\nNORMAL_MAP=vec3(0.5,0.5,1.0); NORMAL_MAP_DEPTH=0.0;\n"+code.substr(end)
	var material:=source.duplicate() as ShaderMaterial
	var shader:=Shader.new();shader.code=code
	material.shader=shader
	if not shader.get_shader_uniform_list().any(func(uniform):return str(uniform.name)=="route_origin"):
		_fail("Diagnostic normal shader did not compile.");return null
	return material

func _load_reference() -> bool:
	if not FileAccess.file_exists(reference_path):
		_fail("Missing requested baseline manifest: "+reference_path);return false
	var reference: Variant=JSON.parse_string(FileAccess.get_file_as_string(reference_path))
	if not reference is Dictionary or not str(reference.get("capture_status","")).begins_with("captured_"):
		_fail("Requested baseline has no completed real captures.");return false
	# JSON consistently normalizes integer/float values before deep comparison.
	var normalized: Dictionary=JSON.parse_string(JSON.stringify(report))
	for key in ["resolution","godot","renderer","rendering_driver","device","fixture_overrides","settle_frames","frame_samples"]:
		if reference.get(key)!=normalized.get(key):
			_fail("Baseline comparison requires matching "+key+".");return false
	for entry in reference.get("captures",[]):
		if entry.get("preset")=="High":reference_captures[entry.id]=entry
	for period in ["daylight","dusk","night"]:
		if not selected_periods.is_empty() and not selected_periods.has(period):continue
		for view in VIEWS:
			if not selected_views.is_empty() and not selected_views.has(view.id):continue
			if not reference_captures.has(period+"-"+view.id+"-high"):
				_fail("Requested baseline is missing a required High capture.");return false
	report.baseline_manifest=reference_path
	report.baseline_source_sha256=reference.get("source_sha256",{})
	report.baseline_fixture_provenance=reference.get("fixture_provenance",{})
	return true

func _compare_reference(label: String,current: Image) -> bool:
	var entry: Dictionary=reference_captures[label]
	var filename: String=entry.get("file","")
	if filename.is_empty() or filename!=filename.get_file():
		_fail("Baseline capture has an invalid relative filename.");return false
	var path:=reference_path.get_base_dir().path_join(filename)
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=entry.get("png_sha256"):
		_fail("Missing or hash-mismatched baseline PNG: "+path);return false
	var original:=Image.load_from_file(path)
	if original==null or original.is_empty() or original.get_size()!=current.get_size():
		_fail("Baseline PNG cannot be compared: "+path);return false
	original.convert(Image.FORMAT_RGBA8)
	report.high_baseline_comparisons.append({
		id=label,baseline_file=filename,baseline_png_sha256=entry.png_sha256,
		high_vs_baseline=_difference(original,current)
	})
	return _write_report()

func _capture_rebase() -> bool:
	var period:={id="daylight",hour=12.0}
	var far_origin:=Vector3(300000,0,-300000)
	var shift:=Vector3(1024,0,1024)
	_set_lighting(12.0);lamp.light_energy=0.0
	_apply_preset("Extreme")
	for view in VIEWS:
		if view.id not in ["road","station"]:continue
		scene.position=Vector3.ZERO;_set_route_origin(far_origin)
		camera.position=view.eye;camera.look_at(view.target)
		var before: Image=await _capture("far-route-"+view.id+"-before",period,view,"Extreme")
		if before==null:return false
		# All geometry, lights and the camera move together. The material origin
		# advances by the opposite amount, retaining identical absolute samples.
		scene.position=-shift;_set_route_origin(far_origin+shift)
		camera.position=view.eye;camera.look_at(view.target+scene.position)
		var after: Image=await _capture("far-route-"+view.id+"-after",period,view,"Extreme")
		if after==null:return false
		report.rebase_comparisons.append({
			view=view.id,origin_before=_xyz(far_origin),origin_after=_xyz(far_origin+shift),
			local_translation=_xyz(-shift),same_absolute_point=true,
			before_vs_after=_difference(before,after),
			limitation="Includes photographic projection, shadow and screen-space history. Differences are measured, not automatically attributed to microdetail."
		})
		if not _write_report():return false
	scene.position=Vector3.ZERO;_set_route_origin(Vector3.ZERO)
	return true

func _set_route_origin(value: Vector3) -> void:
	route_origin=value
	for material in source_materials:
		var names: Array=[]
		for uniform in material.shader.get_shader_uniform_list():names.append(str(uniform.name))
		if names.has("extreme_route_origin"):material.set_shader_parameter("extreme_route_origin",value)
		if names.has("route_origin"):material.set_shader_parameter("route_origin",value)

func _build_fixture() -> void:
	viewport=SubViewport.new()
	viewport.size=resolution
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.use_taa=false
	root.add_child(viewport)
	var preview:=TextureRect.new()
	preview.texture=viewport.get_texture()
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(preview);preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene=Node3D.new()
	viewport.add_child(scene)
	camera=Camera3D.new()
	camera.fov=55.0;camera.near=.05;camera.far=300.0
	scene.add_child(camera);camera.make_current()
	sky_material=ShaderMaterial.new()
	sky_material.shader=load("res://game/shaders/day_night_sky.gdshader")
	sky_material.set_shader_parameter("daylight_panorama",_texture(HDRI))
	var sky:=Sky.new()
	sky.sky_material=sky_material;sky.radiance_size=Sky.RADIANCE_SIZE_256
	sky.process_mode=Sky.PROCESS_MODE_QUALITY
	environment=Environment.new()
	environment.background_mode=Environment.BG_SKY;environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_AGX
	environment.ssao_radius=1.5;environment.ssao_intensity=1.1
	environment.glow_intensity=.28;environment.glow_hdr_threshold=1.2
	var world_environment:=WorldEnvironment.new()
	world_environment.environment=environment;scene.add_child(world_environment)
	sun=DirectionalLight3D.new()
	sun.light_angular_distance=.6;sun.shadow_blur=1.2
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits=true;scene.add_child(sun)
	moon=DirectionalLight3D.new();moon.name="Moonlight"
	moon.light_color=Color(.64,.73,.91);moon.set_meta("no_night_shadow",true);scene.add_child(moon)
	lamp=OmniLight3D.new()
	lamp.position=Vector3(4,3,0);lamp.light_color=Color(1,.72,.38)
	lamp.omni_range=18.0;lamp.shadow_enabled=true;scene.add_child(lamp)

	var ground:=_shader("geographic_ground")
	for pair in [["grass_albedo","leafy_grass","diff"],["grass_normal","leafy_grass","nor_gl"],
		["soil_albedo","red_laterite_soil_stones","diff"],["soil_normal","red_laterite_soil_stones","nor_gl"]]:
		ground.set_shader_parameter(pair[0],_ph(pair[1],pair[2]))
	# Synchronous source-equivalent macro noise avoids NoiseTexture2D worker timing.
	var noise:=FastNoiseLite.new()
	noise.seed=7;noise.frequency=.012;noise.fractal_octaves=4
	ground.set_shader_parameter("macro_noise",ImageTexture.create_from_image(noise.get_seamless_image(512,512)))
	_plane("Ground",Vector2(5,12),Vector3(-5,0,0),ground,true)
	var road:=_shader("scenery_road")
	_bind_maps(road,"aerial_asphalt_01")
	road.set_shader_parameter("metres",5.0)
	_plane("Road",Vector2(5,12),Vector3(0,.01,0),road)
	_plane("Pavers",Vector2(5,12),Vector3(5,.02,0),_station(1,Color(.57,.54,.48),1.2))
	_plane("Water",Vector2(7,12),Vector3(11,.01,0),_shader("geographic_water"))
	_box("StationWall",Vector3(4,2.6,.3),Vector3(5,1.3,-5),_station(0,Color(.84,.79,.60),2.0,"plastered_wall"))
	_box("StationRoof",Vector3(5,.12,2.2),Vector3(5,2.8,-4.5),_station(2,Color(.43,.46,.44),1.2))
	_box("ConcreteBlock",Vector3(.7,.7,.7),Vector3(4,.35,-1.5),_station(3,Color(.67,.67,.62),2.0))
	_box("PaintedPost",Vector3(.15,2.2,.15),Vector3(6,1.1,-2),_station(6,Color(.12,.25,.65),2.0))
	var metal:=StandardMaterial3D.new()
	metal.albedo_color=Color(.45,.48,.5);metal.metallic=.9;metal.roughness=.18
	_box("MetalReflectionTarget",Vector3(1.2,2.2,1.2),Vector3(10,1.1,-3),metal)
	var ochre:=StandardMaterial3D.new()
	ochre.albedo_color=Color(.8,.24,.045)
	_box("WaterReflectionTarget",Vector3(.65,3,.65),Vector3(12,1.5,-2),ochre)
	_box("GroundShadowBlocker",Vector3(.4,1.2,.4),Vector3(-5,.6,-2),ochre)
	_box("RoadShadowBlocker",Vector3(.3,1.4,.3),Vector3(1,.7,-2),metal)

func _set_lighting(hour: float) -> void:
	# Same representative equinox/noon as sim/daylight, but no simulation or
	# runtime scene dependency. These fixed values never advance a game clock.
	var angle: float=(hour-(12.0+20.0/60.0))*PI/12.0
	var latitude:=deg_to_rad(9.6)
	var direction:=Vector3(-sin(angle),cos(latitude)*cos(angle),sin(latitude)*cos(angle)).normalized()
	var elevation:=rad_to_deg(asin(clampf(direction.y,-1.0,1.0)))
	var day:=smoothstep(-8.0,10.0,elevation)
	var night:=1.0-smoothstep(-5.0,3.0,elevation)
	var twilight: float=smoothstep(-10.0,-1.0,elevation)*(1.0-smoothstep(1.0,16.0,elevation))
	var warmth:=1.0-smoothstep(0.0,25.0,elevation)
	sun.basis=Basis.looking_at(-direction,Vector3.UP)
	sun.light_energy=1.55*smoothstep(-.8,9.0,elevation)
	sun.light_color=Color(1,.96,.89).lerp(Color(1,.43,.16),warmth*.8)
	moon.basis=Basis.looking_at(direction,Vector3.UP);moon.light_energy=.055*night
	sky_material.set_shader_parameter("sun_direction",direction)
	sky_material.set_shader_parameter("daylight",day)
	sky_material.set_shader_parameter("twilight",twilight)
	sky_material.set_shader_parameter("night",night)
	environment.ambient_light_energy=lerpf(.65,.42,day)

func _apply_preset(label: String) -> void:
	options.preset(label)
	options.apply_tree(scene) # Calls ExtremeVisuals per-instance/environment helpers.
	viewport.scaling_3d_scale=options.values.scale
	viewport.msaa_3d=options.values.msaa
	viewport.screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if options.values.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.mesh_lod_threshold=options.values.mesh_detail
	RenderingServer.directional_shadow_atlas_set_size(options.values.shadows,true)
	RenderingServer.directional_soft_shadow_filter_set_quality(options.values.shadow_filter)
	if not forward_plus:
		environment.ssr_enabled=false;environment.ssao_enabled=false;environment.ssil_enabled=false

func _capture(label: String,period: Dictionary,view: Dictionary,preset: String) -> Image:
	for i in settle_frames:await process_frame
	var samples: Array[float]=[]
	await RenderingServer.frame_post_draw
	var previous:=Time.get_ticks_usec()
	for i in sample_frames:
		await process_frame
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		samples.append(float(now-previous)/1000.0);previous=now
	var image:=viewport.get_texture().get_image()
	if image==null or image.is_empty() or image.get_size()!=resolution:
		_fail("Missing or wrong-sized viewport image for "+label+". No valid PNG was saved.")
		return null
	image.convert(Image.FORMAT_RGBA8)
	var stats:=_image_stats(image)
	var draws:=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	if draws<=0 or stats.rgb_range<2 or stats.maximum_rgb<3:
		_fail("Empty/flat/black viewport or no geometry draw calls for "+label+". No valid PNG was saved.")
		return null
	var path:=output.path_join(label+".png")
	var error:=image.save_png(path)
	if error!=OK:
		_fail("PNG write failed for "+label+" (error "+str(error)+").")
		return null
	samples.sort()
	report.captures.append({
		id=label,file=label+".png",capture_status="captured",period=period.id,hour=period.hour,
		preset=preset,preset_values=options.values.duplicate(true),
		resolution=[image.get_width(),image.get_height()],camera_eye=_xyz(view.eye),
		camera_target=_xyz(view.target),camera_fov=camera.fov,shader_time_frozen=true,
		ssr_requested=options.values.get("reflections",false),ssr_enabled=environment.ssr_enabled,
		route_origin=_xyz(route_origin),scene_local_translation=_xyz(scene.position),
		radiance_size_enum=environment.sky.radiance_size,draw_calls=draws,
		primitives=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		frame_ms_median=samples[sample_frames/2],frame_ms_p95=samples[ceili(sample_frames*.95)-1],
		frame_timing="wall-clock frame_post_draw intervals; uncapped/vsync disabled; not GPU duration",
		png_sha256=FileAccess.get_sha256(path),image_stats=stats
	})
	if reflection_diagnostic:report.captures[-1].diagnostic=diagnostic_state.duplicate(true)
	if not _write_report():return null
	print("EXTREME_VISUAL_FRAME: ",label)
	return image

func _difference(a: Image,b: Image) -> Dictionary:
	var left:=a.get_data();var right:=b.get_data()
	var pixels:=a.get_width()*a.get_height()
	if left==right:
		return {exact_equal=true,changed_rgb_pixels=0,total_pixels=pixels,
			changed_rgb_fraction=0.0,mean_absolute_rgb_error_255=0.0,max_rgb_error_255=0}
	var changed:=0;var total:=0;var maximum:=0
	for i in range(0,left.size(),4):
		var pixel_changed:=false
		for channel in 3:
			var delta:=absi(int(left[i+channel])-int(right[i+channel]))
			total+=delta;maximum=maxi(maximum,delta)
			if delta>0:pixel_changed=true
		if pixel_changed:changed+=1
	return {exact_equal=left==right,changed_rgb_pixels=changed,total_pixels=pixels,
		changed_rgb_fraction=float(changed)/pixels,mean_absolute_rgb_error_255=float(total)/(pixels*3),
		max_rgb_error_255=maximum}

func _image_stats(image: Image) -> Dictionary:
	var data:=image.get_data()
	var low: Array[int]=[255,255,255];var high: Array[int]=[0,0,0]
	var sum:=0;var samples:=0
	# A deterministic grid is enough to reject blank readbacks cheaply. Pixel
	# equality below still checks every byte, not this validation sample.
	var step:=maxi(1,(image.get_width()*image.get_height())/8192)
	for i in range(0,data.size(),4*step):
		for channel in 3:
			var value:=int(data[i+channel])
			low[channel]=mini(low[channel],value);high[channel]=maxi(high[channel],value);sum+=value
		samples+=1
	var spread:=maxi(high[0]-low[0],maxi(high[1]-low[1],high[2]-low[2]))
	return {minimum_rgb=mini(low[0],mini(low[1],low[2])),maximum_rgb=maxi(high[0],maxi(high[1],high[2])),
		rgb_range=spread,mean_rgb_255=float(sum)/(samples*3),validation_sample_pixels=samples}

func _texture(path: String) -> Texture2D:
	var texture:=load(path) as Texture2D
	if texture==null:asset_error="Missing/import-failed source texture: "+path
	elif not assets.has(path):assets[path]=FileAccess.get_sha256(path)
	return texture

func _ph(asset: String,map: String) -> Texture2D:
	return _texture(PH % [asset,asset,map])

func _shader(name: String) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=load("res://game/shaders/"+name+".gdshader")
	if material.shader==null:asset_error="Missing source shader: "+name
	else:
		var required: String={"geographic_ground":"grass_albedo","scenery_road":"surface_albedo",
			"station_surface":"surface_kind","geographic_water":"route_origin"}[name]
		if not material.shader.get_shader_uniform_list().any(func(uniform):return str(uniform.name)==required):
			asset_error="Source shader failed to expose its required uniform: "+name
	source_materials.append(material)
	return material

func _bind_maps(material: ShaderMaterial,asset: String) -> void:
	for pair in [["surface_albedo","diff"],["surface_normal","nor_gl"],["surface_rough","rough"]]:
		material.set_shader_parameter(pair[0],_ph(asset,pair[1]))

func _station(kind: int,color: Color,metres: float,asset: String="brushed_concrete") -> ShaderMaterial:
	var material:=_shader("station_surface")
	material.set_shader_parameter("surface_kind",kind);material.set_shader_parameter("base_color",color)
	material.set_shader_parameter("metres",metres);_bind_maps(material,asset)
	return material

func _plane(label: String,size: Vector2,position: Vector3,material: Material,ground: bool=false) -> void:
	var source:=PlaneMesh.new();source.size=size
	var arrays:=source.get_mesh_arrays()
	if ground:
		var colors:=PackedColorArray()
		var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in uv.size():
			uv[i]=Vector2(vertices[i].x+position.x,vertices[i].z+position.z)/3.5
			colors.append(Color(.72,.80,.60,.12))
		arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance:=MeshInstance3D.new()
	instance.name=label;instance.mesh=mesh;instance.material_override=material;instance.position=position
	scene.add_child(instance)

func _box(label: String,size: Vector3,position: Vector3,material: Material) -> void:
	var mesh:=BoxMesh.new();mesh.size=size
	var instance:=MeshInstance3D.new()
	instance.name=label;instance.mesh=mesh;instance.material_override=material;instance.position=position
	scene.add_child(instance)

func _xyz(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _write_report() -> bool:
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	if file==null:
		finished=true;printerr("EXTREME_VISUAL_BLOCKED: Cannot write manifest: ",FileAccess.get_open_error())
		quit(2);return false
	file.store_string(JSON.stringify(report,"\t"))
	return true

func _fail(reason: String) -> void:
	if finished:return
	finished=true;report.capture_status="blocked";report.failure=reason
	_write_report()
	printerr("EXTREME_VISUAL_BLOCKED: ",reason," Manifest: ",output.path_join("manifest.json"))
	quit(2)
