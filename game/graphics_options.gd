extends RefCounted
## Local presentation preferences. Never alter timetables, passengers or physics.
const GROUPS := {"display":"DISPLAY & IMAGE", "lighting":"LIGHT & SHADOW", "scenery":"SCENERY", "trains":"TRAINS & PASSENGERS"}
const OPTIONS := {
	"scale": {group="display",label="3D render scale",values=[0.5,0.67,0.75,0.85,1.0],labels=["50%","67%","75%","85%","100% / native"],default=1.0,help="Lower resolution reduces GPU pixel work. FSR spatial upscaling is used below native; menus stay sharp at full resolution."},
	"msaa": {group="display",label="Edge anti-aliasing",values=[0,1,2,3],labels=["Off","2× MSAA","4× MSAA","8× MSAA"],default=3,help="Smooths rails, wires and silhouettes. 8× is expensive, particularly at high resolution."},
	"fxaa": {group="display",label="FXAA",values=[false,true],labels=["Off","On"],default=true,help="A lightweight smoothing pass. Can soften small details; works alongside MSAA."},
	"vsync": {group="display",label="V-sync",values=[false,true],labels=["Off","On"],default=true,help="Prevents screen tearing. Disable to measure uncapped performance."},
	"fps": {group="display",label="Frame limit",values=[0,30,60,90,120,144],labels=["Unlimited","30 FPS","60 FPS","90 FPS","120 FPS","144 FPS"],default=0,help="Caps rendered frames to reduce heat and power use. Simulation speed is unchanged. V-sync may impose a lower limit."},
	"shadows": {group="lighting",label="Shadow resolution",values=[0,2048,4096,8192],labels=["Off","2048 / Low","4096 / Medium","8192 / High"],default=8192,help="Higher resolution sharpens shadows but consumes more GPU time and memory. Off removes sun shadows."},
	"shadow_distance": {group="lighting",label="Shadow distance",values=[100.0,200.0,300.0],labels=["100 m","200 m","300 m"],default=300.0,help="Shorter distances reduce the amount of scenery and rolling stock drawn into the sun shadow map."},
	"shadow_filter": {group="lighting",label="Shadow filtering",values=[0,1,3],labels=["Hard / fastest","Soft / Low","Soft / High"],default=3,help="Smoother soft shadow edges cost additional samples. Has no effect when shadows are off."},
	"ssao": {group="lighting",label="Contact shading (SSAO)",values=[false,true],labels=["Off","On"],default=true,help="Adds contact shading around sleepers, cab fittings and nearby surfaces."},
	"ssil": {group="lighting",label="Indirect lighting (SSIL)",values=[false,true],labels=["Off","On"],default=true,help="Adds screen-space bounced light. Switching it off is a useful GPU saving."},
	"glow": {group="lighting",label="Light bloom",values=[false,true],labels=["Off","On"],default=true,help="Adds a subtle halo around bright lights."},
	"view_distance": {group="scenery",label="Maximum view distance",values=[1500.0,1800.0,2200.0],labels=["1.5 km","1.8 km","2.2 km"],default=2200.0,help="Moves the far clip and matching haze together. Terrain remains continuous and the 60 m free-camera ceiling stays in place."},
	"vegetation_density": {group="scenery",label="Vegetation density",values=[0.5,0.75,1.0],labels=["50%","75%","100%"],default=1.0,help="Reduces visible tree, shrub, crop and grass instances. Matching detail levels retain the same plants. Does not change collision or the railway."},
	"vegetation_distance": {group="scenery",label="Vegetation detail distance",values=[0.5,0.75,1.0],labels=["Short","Medium","Full"],default=1.0,help="Uses simpler trees and distant image silhouettes sooner; reduces grass reach. Vegetation was the largest measured GPU category."},
	"building_distance": {group="scenery",label="Building detail distance",values=[0.5,0.75,1.0],labels=["Short","Medium","Full"],default=1.0,help="Switches supported houses to baked silhouettes sooner and shortens detail range for other scenery buildings. Station platforms stay present."},
	"mesh_detail": {group="scenery",label="Automatic mesh detail",values=[4.0,2.0,1.0],labels=["Performance","Balanced","High"],default=1.0,help="Allows progressively more screen-space simplification on meshes with imported LODs, including trains. Full source assets remain available nearby."},
	"train_detail": {group="trains",label="Other train detail distance",values=[0.5,0.75,1.0],labels=["Short","Medium","Full"],default=1.0,help="Shortens detailed train shadow and external interior range. The cab or coach you occupy always retains its interior; seated passengers remain hidden in pilot view."},
	"passengers": {group="trains",label="Visible passenger budget",values=[0.25,0.5,1.0],labels=["Low / 35 seated + 20 moving","Medium / 70 seated + 40 moving","High / 140 seated + 80 moving"],default=1.0,help="Limits nearby rendered people across all trains and platforms. Every passenger journey, load, boarding event and dwell still runs normally."}
}
const PRESETS := {
	"High": {},
	"Balanced": {msaa=2,shadows=4096,shadow_filter=1,mesh_detail=2.0},
	"Performance": {scale=0.85,msaa=1,shadows=2048,shadow_distance=100.0,shadow_filter=1,ssil=false,view_distance=1800.0,vegetation_density=0.75,vegetation_distance=0.5,building_distance=0.5,mesh_detail=4.0,train_detail=0.5,passengers=0.5}
}
var settings_path := "user://graphics.cfg"
var values: Dictionary = {}
var game
var notice := ""

func _init() -> void:
	preset("High")

func preset(label: String) -> void:
	if not PRESETS.has(label):return
	for key in OPTIONS:values[key]=PRESETS[label].get(key,OPTIONS[key].default)

func preset_name() -> String:
	for label in PRESETS:
		var matches:=true
		for key in OPTIONS:
			if values[key]!=PRESETS[label].get(key,OPTIONS[key].default):matches=false;break
		if matches:return label
	return "Custom"

func set_option(key: String,value: Variant) -> bool:
	if not OPTIONS.has(key) or not OPTIONS[key].values.has(value):return false
	# Reject numeric/bool coercion in hand-edited config files.
	if typeof(value)!=typeof(OPTIONS[key].default):return false
	values[key]=value
	return true

func restore() -> void:
	preset("High")
	var config:=ConfigFile.new()
	if config.load(settings_path)!=OK:return
	for key in OPTIONS:set_option(key,config.get_value("graphics",key,OPTIONS[key].default))

func save() -> Error:
	var config:=ConfigFile.new()
	for key in OPTIONS:config.set_value("graphics",key,values[key])
	return config.save(settings_path)

func label_for(key: String) -> String:
	return OPTIONS[key].labels[OPTIONS[key].values.find(values[key])]

func apply() -> void:
	if game==null:return
	var vp: Viewport=game.get_viewport()
	vp.scaling_3d_mode=Viewport.SCALING_3D_MODE_FSR if values.scale<1.0 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale=values.scale
	vp.msaa_3d=values.msaa
	vp.screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if values.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
	vp.mesh_lod_threshold=values.mesh_detail
	Engine.max_fps=values.fps
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)
		RenderingServer.directional_shadow_atlas_set_size(maxi(2048,values.shadows),true)
		RenderingServer.directional_soft_shadow_filter_set_quality(values.shadow_filter)
	if game.cam!=null:game.cam.far=values.view_distance
	if game.wv!=null and game.wv.root!=null:apply_tree(game.wv.root)
	# Train visibility re-evaluates camera distance on each presentation update.
	if game.passenger_crowd!=null:game.passenger_crowd.render_budget=values.passengers

func apply_tree(node: Node) -> void:
	if node is WorldEnvironment:
		var env: Environment=node.environment
		env.ssao_enabled=values.ssao;env.ssil_enabled=values.ssil;env.glow_enabled=values.glow
		env.fog_depth_begin=values.view_distance*(1000.0/2200.0)
		env.fog_depth_end=values.view_distance*(2050.0/2200.0)
	elif node is DirectionalLight3D:
		node.shadow_enabled=values.shadows>0
		node.directional_shadow_max_distance=values.shadow_distance
	elif node is GeometryInstance3D:
		apply_geometry(node)
	for child in node.get_children():apply_tree(child)

func apply_geometry(node: GeometryInstance3D) -> void:
	var kind:=str(node.get_meta("scenery_kind","")).to_lower()
	# Legacy tree silhouettes predate scenery_kind; they must match their mesh LOD.
	if kind.is_empty() and str(node.name).begins_with("Canopy_"):kind=str(node.name).trim_prefix("Canopy_").to_lower()
	if kind.is_empty():return
	var vegetation:=false
	for token in ["grass","verge","palm","tree","shrub","reeds","banana","rice","coconut","jackfruit"]:
		if token in kind:vegetation=true;break
	var building: bool=node.has_meta("house_lod_role") or "bld_" in kind or kind in ["kerala_veranda","laterite_cottage","coastal_shop","workshop"]
	if not vegetation and not building:return
	if not node.has_meta("graphics_original"):
		node.set_meta("graphics_original",{
			begin=node.visibility_range_begin,end=node.visibility_range_end,
			begin_margin=node.visibility_range_begin_margin,end_margin=node.visibility_range_end_margin,
			count=node.multimesh.visible_instance_count if node is MultiMeshInstance3D else -1})
	var base: Dictionary=node.get_meta("graphics_original")
	var factor: float=values.vegetation_distance if vegetation else values.building_distance
	node.visibility_range_begin=base.begin*factor
	# Preserve distant image silhouettes: only the mesh-to-image transition moves.
	var silhouette: bool=node.get_meta("impostor",false) or str(node.name).begins_with("Canopy_")
	node.visibility_range_end=base.end if silhouette else base.end*factor
	node.visibility_range_begin_margin=base.begin_margin*factor
	node.visibility_range_end_margin=base.end_margin if silhouette else base.end_margin*factor
	if vegetation and node is MultiMeshInstance3D:
		var total: int=node.multimesh.instance_count if base.count<0 else base.count
		node.multimesh.visible_instance_count=base.count if values.vegetation_density==1.0 else maxi(1,floori(total*values.vegetation_density)) if total>0 else 0

func action(command: String) -> void:
	var parts:=command.split(":")
	if parts.size()<2:return
	game._set_paused(true)
	if parts[1]=="preset" and parts.size()==3 and PRESETS.has(parts[2]):
		preset(parts[2]);_commit()
		_show("graphics")
	elif parts[1]=="set" and parts.size()==4 and OPTIONS.has(parts[2]):
		var key: String=parts[2]
		var index:=parts[3].to_int()
		if index<0 or index>=OPTIONS[key].values.size():return
		set_option(key,OPTIONS[key].values[index]);_commit()
		_show("graphics:"+OPTIONS[key].group,"graphics:option:"+key)
	elif parts[1]=="back":
		back()
	elif parts[1]=="resume":
		game._set_paused(false);game.hud.show_modal("")
	else:
		_show(command)

func _commit() -> void:
	apply()
	var error:=save()
	notice="Applied and saved." if error==OK else "Applied for this run. Could not save preferences (error %d)." % error

func _show(kind: String,focus_action: String="") -> void:
	game.hud.show_modal(kind)
	if not focus_action.is_empty():game.hud.call_deferred("focus_action",focus_action)

func back() -> void:
	var parts: PackedStringArray=game.hud.modal.split(":")
	if parts.size()>2 and parts[1]=="option":_show("graphics:"+OPTIONS[parts[2]].group,"graphics:option:"+parts[2])
	elif parts.size()>1:_show("graphics","graphics:"+parts[1])
	else:game.hud.show_modal("pause",game.labels_enabled)
