extends "res://game/world_view.gd"
## Bounded streamed presentation of a full-scale geographic simulation.
const GeoData := preload("res://game/geographic_data.gd")
const SceneryChunk := preload("res://game/geographic_scenery_chunk.gd")
const RailwayChunk := preload("res://game/geographic_railway_chunk.gd")
const TrackChunk := preload("res://game/geographic_track_chunk.gd")
const LocalGraph := preload("res://game/local_track_graph.gd")
const Library := preload("res://game/scenery_library.gd")
const JointLayout := preload("res://game/rail_joint_layout.gd")
const StreamWorker := preload("res://game/stream_worker.gd")
const AuthoredStation := preload("res://game/authored_station.gd")
var performance := {}
var _asset_worker
var _prepared_stations := {}
var _activating := {}
var _warm := {} # Hidden scene trees retain uploaded buffers for nearby revisits.
var cache_hits := 0
var completed_jobs := 0
var last_stream_ms := 0.0
var collect_timing := false
var job_trace := []
var coordinate_origin := Vector3.ZERO
var geo
var ohe_layout
var speed_boards
var materials := {}
var assets
var track_template
var loaded := {}
var wanted := {}
var queue: Array = []
var workers: Array = []
var track_index := {}
var track_jobs: Array = []
var _last_cell := Vector2i(999999,999999)
var _last_focus := Vector3(INF,0,INF)
var loading := true
var closing := false
var _loading_label: Label
var _loading_layer: CanvasLayer
var _loading_panel: ColorRect
var _labels_on := false
var _joints_on := false
var _joint_focus := Vector3(INF,0,INF)
var selected_train := ""
var initial_station := ""
var _view_tick := 0
var camera_absolute := Vector3.ZERO

func build(w: RailWorld,parent: Node3D) -> void:
	collect_timing=parent.get_tree().get_meta("benchmark",false)
	world=w
	root=Node3D.new(); root.name="KeralaCoast"
	parent.add_child(root)
	root.tree_exiting.connect(_shutdown)
	var t: Train=world.trains.get(selected_train,world.trains.values()[0])
	var position:=world.graph.position(t.path[0].edge,t.head_s)
	coordinate_origin=Vector3(floorf(position.x/1024)*1024,0,floorf(position.z/1024)*1024)
	geo=GeoData.new(world.scenery.route)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world)
	geo.vegetation_clearance=preload("res://game/vegetation_clearance.gd").build(world)
	_noise_tex=NoiseTexture2D.new()
	_noise_tex.width=256; _noise_tex.height=256; _noise_tex.seamless=true
	var noise:=FastNoiseLite.new(); noise.frequency=.012
	_noise_tex.noise=noise
	_build_environment()
	assets=Library.new(self)
	assets.catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
	for kind in preload("res://game/geographic_building_layout.gd").KINDS+preload("res://game/kerala_scenery.gd").ASSETS+["young_palm","tree_small_02","shrub","reeds"]:
		assets.asset(kind)
	for kind in ["coconut_palm","mango_tree","rain_tree","verge_patch","kerala_tvc_heritage","kerala_ers_entry","kerala_ncj_entry","kerala_coastal_station","passenger_man","passenger_sari","passenger_phone","passenger_sari_blue","tea_kiosk","hatchback","auto_rickshaw","motorcycle"]:
		assets.asset(kind)
	assets.meshes["coastal_grass"]=[{mesh=preload("res://game/coastal_groundcover.gd").mesh(assets.material("grass")),transform=Transform3D.IDENTITY}]
	assets.prepare_impostors()
	_make_materials()
	track_template=TrackView.new()
	track_template.wv=self
	track_template._materials()
	track_template.sleeper=track_template._sleeper_mesh()
	track_template.bearer=track_template._sleeper_mesh(true)
	track_template.fastening=track_template._fastening_mesh()
	track_template.stone=track_template._stone_mesh()
	track_template.fishplate=track_template._fishplate_mesh()
	track_template.single_fishplate=track_template._fishplate_mesh(true)
	track_template.wv=null
	_index_track()
	speed_boards=preload("res://game/track_speed_board_view.gd").new(world,geo.vegetation_clearance)
	for board in speed_boards.jobs:
		var p:=Vector2(board.point.x,board.point.z)
		geo.vegetation_clearance.add_road(p,p,1.2)
	ohe_layout=preload("res://game/geographic_ohe_layout.gd").new(world)
	performance=preload("res://game/performance_profile.gd").settings()
	for i in performance.workers:
		var data:=GeoData.new(world.scenery.route)
		data.station_sites=geo.station_sites
		data.vegetation_clearance=geo.vegetation_clearance
		var runner:=StreamWorker.new()
		workers.append({runner=runner,geo=data})
		runner.start(_worker.bind(i))
	_asset_worker=StreamWorker.new()
	_asset_worker.start(_prepare_station)
	_loading_layer=CanvasLayer.new(); _loading_layer.layer=8
	parent.add_child(_loading_layer)
	_loading_panel=ColorRect.new(); _loading_panel.color=Color(.035,.055,.06,.97)
	_loading_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_layer.add_child(_loading_panel)
	_loading_label=Label.new()
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size",24)
	_loading_panel.add_child(_loading_label)
	_request(position)

func _make_materials() -> void:
	var ground:=ShaderMaterial.new()
	ground.shader=load("res://game/shaders/geographic_ground.gdshader")
	ground.set_shader_parameter("grass_albedo",ph_tex("leafy_grass","diff"))
	ground.set_shader_parameter("grass_normal",ph_tex("leafy_grass","nor_gl"))
	ground.set_shader_parameter("soil_albedo",ph_tex("red_laterite_soil_stones","diff"))
	ground.set_shader_parameter("soil_normal",ph_tex("red_laterite_soil_stones","nor_gl"))
	ground.set_shader_parameter("macro_noise",_noise_tex)
	materials.ground=ground
	var paddy:=ShaderMaterial.new()
	paddy.shader=load("res://game/shaders/kerala_paddy.gdshader")
	paddy.set_shader_parameter("grass_albedo",ph_tex("leafy_grass","diff"))
	paddy.set_shader_parameter("soil_albedo",ph_tex("red_laterite_soil_stones","diff"))
	materials.paddy=paddy
	materials.architecture=assets.material("architecture").duplicate()
	materials.architecture.set_shader_parameter("instanced_palette",false)
	materials.architecture_detail=materials.architecture
	materials.concrete=pbr("brushed_concrete",2.0,Color(.67,.67,.62))
	materials.platform=_station_finish(1,Color(.57,.54,.48),1.2)
	materials.forecourt=_station_finish(1,Color(.43,.44,.42),1.8)
	var road:=ShaderMaterial.new()
	road.shader=load("res://game/shaders/scenery_road.gdshader")
	road.set_shader_parameter("surface_albedo",ph_tex("aerial_asphalt_01","diff"))
	road.set_shader_parameter("surface_normal",ph_tex("aerial_asphalt_01","nor_gl"))
	road.set_shader_parameter("surface_rough",ph_tex("aerial_asphalt_01","rough"))
	road.set_shader_parameter("metres",5.0)
	materials.road=road
	materials.station_asphalt=road.duplicate()
	materials.station_asphalt.set_shader_parameter("road_surface",false)
	materials.station_asphalt.set_shader_parameter("tint",Vector3(.40,.42,.41))
	materials.station_fence=mat(Color(.13,.20,.17))
	materials.station_boundary=ShaderMaterial.new()
	materials.station_boundary.shader=load("res://game/shaders/station_boundary.gdshader")
	materials.station_boundary.set_shader_parameter("concrete_albedo",ph_tex("brushed_concrete","diff"))
	materials.station_boundary.set_shader_parameter("concrete_normal",ph_tex("brushed_concrete","nor_gl"))
	materials.station_white=mat(Color(.78,.77,.69))
	materials.station_drain=mat(Color(.075,.085,.08))
	materials.road_shoulder=pbr("red_laterite_soil_stones",2.5,Color(.40,.37,.30))
	materials.ballast=pbr("gravel_floor_02",2.0,Color(.40,.39,.35))
	materials.metal=steel()
	materials.roof=_station_finish(2,Color(.43,.46,.44),2.0)
	materials.paint=mat(Color(.84,.79,.60))
	materials.sign=mat(Color(.91,.72,.20))
	materials.insulator=mat(Color(.19,.095,.055))
	materials.wire=mat(Color(.11,.12,.11))
	materials.water=ShaderMaterial.new()
	materials.water.shader=load("res://game/shaders/geographic_water.gdshader")
	materials.water.set_shader_parameter("route_origin",coordinate_origin)

func _station_finish(kind: int,color: Color,metres: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=load("res://game/shaders/station_surface.gdshader")
	material.set_shader_parameter("surface_kind",kind)
	material.set_shader_parameter("base_color",color)
	material.set_shader_parameter("metres",metres)
	for pair in [["surface_albedo","diff"],["surface_normal","nor_gl"],["surface_rough","rough"]]:
		material.set_shader_parameter(pair[0],ph_tex("brushed_concrete",pair[1]))
	return material

func _index_track() -> void:
	for eid in world.graph.edges:
		var edge: Dictionary=world.graph.edges[eid]
		for start in range(0,ceili(edge.length),256):
			var end:=minf(start+256,edge.length)
			var p:=world.graph.position(eid,(start+end)*.5)
			var nodes: Array=[]
			# Each point assembly belongs to the last/first chunk of its trunk.
			for node in [edge.a,edge.b]:
				if not world.graph.switches.has(node) or world.graph.switches[node].trunk!=eid: continue
				if (node==edge.a and start==0) or (node==edge.b and end>=edge.length): nodes.append(node)
			var job: Dictionary={id="track:"+eid+":"+str(start),kind="track",edge=eid,start=float(start),end=end,nodes=nodes,point=p}
			var index:=track_jobs.size()
			track_jobs.append(job)
			var cell:=Vector2i(floori(p.x/512),floori(p.z/512))
			if not track_index.has(cell): track_index[cell]=[]
			track_index[cell].append(index)

func _request(focus: Vector3) -> void:
	_last_focus=focus
	var cell:=Vector2i(floori(focus.x/512),floori(focus.z/512))
	_last_cell=cell
	wanted.clear()
	for x in range(cell.x-3,cell.x+4):
		for z in range(cell.y-3,cell.y+4):
			var key:=Vector2i(x,z)
			var p:=Vector3(x*512+256,0,z*512+256)
			var d:=Vector2(p.x-focus.x,p.z-focus.z).length_squared()
			if d>1900*1900: continue
			_add_job({id="tile:"+str(key),kind="tile",key=key,point=p,priority=d+10000})
			for index in track_index.get(key,[]):
				var job: Dictionary=track_jobs[index].duplicate()
				var distance:=Vector2(job.point.x-focus.x,job.point.z-focus.z).length_squared()
				if distance>1650*1650: continue
				job.priority=distance*.70
				_add_job(job)
				var ohe:=job.duplicate(); ohe.id="ohe:"+job.id; ohe.kind="ohe"; ohe.priority+=120000
				_add_job(ohe)
	var near_tiles: Array=[]
	for job in wanted.values():
		if job.kind=="tile": near_tiles.append(job.key)
	var far_cell:=Vector2i(floori(focus.x/2048),floori(focus.z/2048))
	for x in range(far_cell.x-4,far_cell.x+5):
		for z in range(far_cell.y-4,far_cell.y+5):
			var p:=Vector3(x*2048+1024,0,z*2048+1024)
			var d:=Vector2(p.x-focus.x,p.z-focus.z).length_squared()
			if d>9500*9500: continue
			var holes: Array=[]
			for tile in near_tiles:
				if tile.x>=x*4 and tile.x<x*4+4 and tile.y>=z*4 and tile.y<z*4+4: holes.append(tile)
			_add_job({id="far:%d:%d:%s" % [x,z,str(holes).md5_text()],kind="far",key=Vector2i(x,z),holes=holes,point=p,priority=d+9000000})
	for index in world.stations.size():
		var station: Dictionary=world.stations[index]
		var d:=Vector2(station.origin.x-focus.x,station.origin.z-focus.z).length_squared()
		if d<2000*2000: _add_job({id="station:"+station.code,kind="station",index=index,point=station.origin,priority=d+3000})
	for sid in world.signals:
		var sig: Dictionary=world.signals[sid]
		var p:=world.graph.position(sig.edge,sig.s)
		var d:=Vector2(p.x-focus.x,p.z-focus.z).length_squared()
		if d<1650*1650: _add_job({id="signal:"+sid,kind="signal",sid=sid,point=p,priority=d})
	for board in speed_boards.jobs:
		var d:=Vector2(board.point.x-focus.x,board.point.z-focus.z).length_squared()
		if d<1650*1650:
			var job: Dictionary=board.duplicate();job.priority=d;_add_job(job)
	queue.clear()
	for id in wanted:
		if _warm.has(id):
			loaded[id].node.visible=true
			_warm.erase(id)
			cache_hits+=1
		if loaded.has(id) or _activating.has(id) or workers.any(func(worker): return not worker.runner.job.is_empty() and worker.runner.job.id==id): continue
		queue.append(wanted[id])
	queue.sort_custom(func(a,b): return a.priority<b.priority)
	for id in loaded.keys():
		if wanted.has(id): continue
		if not _warm.has(id):
			loaded[id].node.visible=false
			_warm[id]=Time.get_ticks_msec()
	_refresh_loading()

func _add_job(job: Dictionary) -> void:
	if collect_timing:job.requested_usec=Time.get_ticks_usec()
	wanted[job.id]=job

func _remove(id: String) -> void:
	var chunk: Dictionary=loaded[id]
	if id.begins_with("signal:"):
		signal_lamps.erase(id.trim_prefix("signal:"))
	for label in chunk.get("labels",[]): labels.erase(label)
	chunk.node.queue_free()
	loaded.erase(id)
	_warm.erase(id)

func _worker(job: Dictionary,index: int) -> Dictionary:
	var data=workers[index].geo
	match job.kind:
		"tile","far": return SceneryChunk.new(data,materials,assets).build(job.key,job.kind=="far",job.get("holes",[]))
		"station": return RailwayChunk.new(world,data,materials,assets).build_station(job.index)
		"ohe": return RailwayChunk.new(world,data,materials,assets).build_ohe(job.edge,job.start,job.end,ohe_layout)
		"track": return TrackChunk.new(track_template,world.graph).build(job.edge,job.start,job.end,job.nodes)
	return {}

func _prepare_station(job: Dictionary) -> Dictionary:
	var code: String=world.stations[job.index].code
	if AuthoredStation.available(code):AuthoredStation.prepare(code)
	if code=="ERS":AuthoredStation.prepare("ERS_EAST")
	if world.depots.values().any(func(d):return d.station==code):AuthoredStation.prepare("ERS_WORKSHOP")
	return {code=code}

func has_pending_work() -> bool:
	return not queue.is_empty() or not _activating.is_empty() or workers.any(func(w):return not w.runner.job.is_empty()) or (_asset_worker!=null and not _asset_worker.job.is_empty())

func _stage(id: String,result: Dictionary) -> void:
	# Insert small sets of top-level children across frames. Source hierarchy,
	# materials and local transforms survive; only activation is staggered.
	var holder:=Node3D.new()
	holder.name=result.node.name if not str(result.node.name).is_empty() else "StreamedChunk"
	for key in result.node.get_meta_list():holder.set_meta(key,result.node.get_meta(key))
	holder.position=result.origin-coordinate_origin
	root.add_child(holder)
	_activating[id]={result=result,holder=holder}

func _activate() -> void:
	var began:=Time.get_ticks_usec()
	var children:=0
	for id in _activating.keys():
		var pending: Dictionary=_activating[id]
		var result: Dictionary=pending.result
		if not wanted.has(id):
			result.node.free();pending.holder.queue_free();_activating.erase(id)
			continue
		while result.node.get_child_count()>0:
			var child: Node=result.node.get_child(0)
			result.node.remove_child(child)
			pending.holder.add_child(child)
			children+=1
			if children>=performance.activation_children or Time.get_ticks_usec()-began>=performance.activation_usec:return
		result.node.free()
		result.node=pending.holder
		if result.has("adapter"):result.adapter.root=result.node
		loaded[id]=result
		_activating.erase(id)
		completed_jobs+=1
		if collect_timing:job_trace.append({id=id,event="activated",ticks_usec=Time.get_ticks_usec()})

func _trim_warm() -> void:
	if _warm.is_empty():return
	var id: String=_warm.keys()[0]
	var expired: bool=Time.get_ticks_msec()-_warm[id]>performance.warm_seconds*1000
	var pressure:=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)>float(performance.gpu_cache_ceiling)
	# Bound memory and destruction work. Never evict visible scenery for a budget.
	if expired or pressure or _warm.size()>int(performance.warm_chunks):_remove(id)

func _signal(job: Dictionary) -> Dictionary:
	var sig: Dictionary=world.signals[job.sid]
	var origin:=Vector3(floorf(job.point.x/256)*256,0,floorf(job.point.z/256)*256)
	var context=load("res://game/world_view.gd").new()
	context.root=Node3D.new()
	context.world=RailWorld.new()
	context.world.graph=LocalGraph.new(world.graph,origin,[sig.edge])
	context.world.signals={job.sid:sig}
	context.world.automatic_signals=world.automatic_signals
	context._build_signal(job.sid)
	signal_lamps[job.sid]=context.signal_lamps[job.sid]
	labels.append_array(context.labels)
	for label in context.labels: label.visible=_labels_on
	return {node=context.root,origin=origin,labels=context.labels}

func _refresh_loading() -> void:
	var missing:=0
	var required:=0
	for id in wanted:
		var job: Dictionary=wanted[id]
		if job.priority>850000 or job.kind=="far": continue
		required+=1
		if not loaded.has(id): missing+=1
	loading=missing>0
	_loading_panel.visible=loading
	if loading:
		_loading_label.text="KERALA COAST\nErnakulam · Alappuzha · Thiruvananthapuram · Nagercoil\n\nPreparing nearby scenery  %d / %d\n\nMap data © OpenStreetMap contributors · ODbL 1.0\nTerrain: NASA / USGS SRTM" % [required-missing,required]

func update() -> void:
	if closing: return
	var began:=Time.get_ticks_usec()
	var camera:=root.get_viewport().get_camera_3d()
	if camera!=null:
		camera_absolute=camera.global_position+coordinate_origin
		var cell:=Vector2i(floori(camera_absolute.x/512),floori(camera_absolute.z/512))
		if cell!=_last_cell or Vector2(camera_absolute.x-_last_focus.x,camera_absolute.z-_last_focus.z).length_squared()>220*220:
			_request(camera_absolute)
	var prepared: Dictionary=_asset_worker.take()
	if not prepared.is_empty():
		_prepared_stations[prepared.job.id]=true
		_trace_job(prepared,"assets")
	for worker in workers:
		var finished: Dictionary=worker.runner.take()
		if not finished.is_empty():
			_trace_job(finished,"geometry")
			var result: Dictionary=finished.result
			var id: String=finished.job.id
			if not result.is_empty():
				if wanted.has(id):
					_stage(id,result)
				else: result.node.free()
		if worker.runner.job.is_empty() and not queue.is_empty() and _activating.size()<workers.size()*2:
			var job: Dictionary=queue.pop_front()
			if job.kind in ["signal","speed_board"]:
				var result: Dictionary=_signal(job) if job.kind=="signal" else speed_boards.build(job,geo)
				result.node.position=result.origin-coordinate_origin
				root.add_child(result.node); loaded[job.id]=result
			else:
				if job.kind=="station" and not _prepared_stations.has(job.id):
					if _asset_worker.job.is_empty():_asset_worker.submit(job)
					queue.append(job)
				else:worker.runner.submit(job)
	_activate()
	_trim_warm()
	for id in loaded:
		if _warm.has(id):continue
		var chunk: Dictionary=loaded[id]
		if chunk.has("adapter"):
			var adapter=chunk.adapter
			for node in adapter.graph.switches:
				adapter.graph.switches[node].reversed=world.graph.switches[node].reversed
			adapter.update_points()
	_view_tick+=1
	if _view_tick%6==0:
		for sid in signal_lamps:
			if _warm.has("signal:"+sid):continue
			var aspect:=world.aspect(sid)
			if signal_lamps[sid][0].get_meta("aspect",-1)==aspect:continue
			signal_lamps[sid][0].set_meta("aspect",aspect)
			var lit:=0 if aspect==RailWorld.Aspect.GREEN else (1 if aspect==RailWorld.Aspect.YELLOW else 2)
			for i in 3:
				signal_lamps[sid][i].material_override=mat([Color(.1,1,.35),Color(1,.72,.05),Color(1,.08,.05)][i],true) if i==lit else mat(Color(.08,.08,.08))
		_refresh_loading()
	if _joints_on and camera_absolute.distance_squared_to(_joint_focus)>150*150: _make_joint_markers()
	last_stream_ms=(Time.get_ticks_usec()-began)*.001

func _trace_job(finished: Dictionary,role: String) -> void:
	if not collect_timing:return
	job_trace.append({id=finished.job.id,event=role,kind=finished.job.kind,requested_usec=finished.job.get("requested_usec",0),
		submitted_usec=finished.submitted_usec,began_usec=finished.began_usec,finished_usec=finished.finished_usec,
		build_ms=(finished.finished_usec-finished.began_usec)*.001,wanted=wanted.has(finished.job.id)})

func rebase(origin: Vector3) -> void:
	coordinate_origin=origin
	materials.water.set_shader_parameter("route_origin",origin)
	for chunk in loaded.values(): chunk.node.position=chunk.origin-origin
	for pending in _activating.values():pending.holder.position=pending.result.origin-origin
	if _joints_on: _make_joint_markers()

func terrain_height(x: float,z: float) -> float:
	return geo.ground_at(x+coordinate_origin.x,z+coordinate_origin.z)

func build_joints(_spacing: float,_offset: float) -> void:
	_joint_root=Node3D.new(); _joint_root.name="JointInspection"
	root.add_child(_joint_root); _joint_root.visible=false

func _make_joint_markers() -> void:
	if _joint_root==null: return
	for child in _joint_root.get_children(): child.queue_free()
	joint_markers.clear(); _flash.clear()
	_joint_focus=camera_absolute
	var mesh:=BoxMesh.new(); mesh.size=Vector3(2.6,.06,.18)
	for chunk in track_jobs:
		if chunk.point.distance_squared_to(camera_absolute)>650*650: continue
		for k in range(ceili((chunk.start-JointLayout.OFFSET)/JointLayout.SPACING),ceili((chunk.end-JointLayout.OFFSET)/JointLayout.SPACING)):
			var s:=JointLayout.OFFSET+k*JointLayout.SPACING
			var marker:=MeshInstance3D.new(); marker.mesh=mesh
			marker.material_override=mat(Color(1,.8,.05),true)
			marker.position=world.graph.position_relative(chunk.edge,s,coordinate_origin)+Vector3.UP*.54
			marker.basis=Basis.looking_at(world.graph.tangent(chunk.edge,s,1))
			_joint_root.add_child(marker)
			joint_markers["%s|%d" % [chunk.edge,k]]=marker

func set_joints_visible(value: bool) -> void:
	_joints_on=value
	if _joint_root!=null: _joint_root.visible=value
	if value: _make_joint_markers()

func set_labels_visible(value: bool) -> void:
	_labels_on=value
	for label in labels:
		if is_instance_valid(label): label.visible=value

func _shutdown() -> void:
	closing=true
	if _asset_worker!=null:_asset_worker.close()
	for worker in workers:
		var finished: Dictionary=worker.runner.close()
		if not finished.is_empty() and not finished.result.is_empty():finished.result.node.free()
	for pending in _activating.values():pending.result.node.free()
	_activating.clear()
	loaded.clear()
	track_template=null
	assets=null
