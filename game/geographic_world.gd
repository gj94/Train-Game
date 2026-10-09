extends "res://game/world_view.gd"
## Bounded streamed presentation of a full-scale geographic simulation.
const GeoData := preload("res://game/geographic_data.gd")
const SceneryChunk := preload("res://game/geographic_scenery_chunk.gd")
const RailwayChunk := preload("res://game/geographic_railway_chunk.gd")
const TrackChunk := preload("res://game/geographic_track_chunk.gd")
const LocalGraph := preload("res://game/local_track_graph.gd")
const Library := preload("res://game/scenery_library.gd")
const JointLayout := preload("res://game/rail_joint_layout.gd")
var coordinate_origin := Vector3.ZERO
var geo
var ohe_layout
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
	world=w
	root=Node3D.new(); root.name="KeralaCoast"
	parent.add_child(root)
	root.tree_exiting.connect(_shutdown)
	var t: Train=world.trains.get(selected_train,world.trains.values()[0])
	var position:=world.graph.position(t.path[0].edge,t.head_s)
	coordinate_origin=Vector3(floorf(position.x/1024)*1024,0,floorf(position.z/1024)*1024)
	geo=GeoData.new(world.scenery.route)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world)
	_noise_tex=NoiseTexture2D.new()
	_noise_tex.width=256; _noise_tex.height=256; _noise_tex.seamless=true
	var noise:=FastNoiseLite.new(); noise.frequency=.012
	_noise_tex.noise=noise
	_build_environment()
	assets=Library.new(self)
	assets.catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
	for kind in preload("res://game/geographic_building_layout.gd").KINDS+["young_palm","tree_small_02","shrub","reeds"]:
		assets.asset(kind)
	for kind in ["coconut_palm","mango_tree","rain_tree","verge_patch","kerala_tvc_heritage","kerala_ers_entry","kerala_ncj_entry","kerala_coastal_station","passenger_man","passenger_sari","passenger_phone","passenger_sari_blue","tea_kiosk","hatchback","auto_rickshaw","motorcycle"]:
		assets.asset(kind)
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
	ohe_layout=preload("res://game/geographic_ohe_layout.gd").new(world)
	for i in 2:
		var data:=GeoData.new(world.scenery.route)
		data.station_sites=geo.station_sites
		workers.append({thread=null,job={},geo=data})
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
	queue.clear()
	for id in wanted:
		if loaded.has(id) or workers.any(func(worker): return not worker.job.is_empty() and worker.job.id==id): continue
		queue.append(wanted[id])
	queue.sort_custom(func(a,b): return a.priority<b.priority)
	for id in loaded.keys():
		if wanted.has(id): continue
		_remove(id)
	_refresh_loading()

func _add_job(job: Dictionary) -> void:
	wanted[job.id]=job

func _remove(id: String) -> void:
	var chunk: Dictionary=loaded[id]
	if id.begins_with("signal:"):
		signal_lamps.erase(id.trim_prefix("signal:"))
	for label in chunk.get("labels",[]): labels.erase(label)
	chunk.node.queue_free()
	loaded.erase(id)

func _worker(index: int,job: Dictionary) -> Dictionary:
	var data=workers[index].geo
	match job.kind:
		"tile","far": return SceneryChunk.new(data,materials,assets).build(job.key,job.kind=="far",job.get("holes",[]))
		"station": return RailwayChunk.new(world,data,materials,assets).build_station(job.index)
		"ohe": return RailwayChunk.new(world,data,materials,assets).build_ohe(job.edge,job.start,job.end,ohe_layout)
		"track": return TrackChunk.new(track_template,world.graph).build(job.edge,job.start,job.end,job.nodes)
	return {}

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
	var camera:=root.get_viewport().get_camera_3d()
	if camera!=null:
		camera_absolute=camera.global_position+coordinate_origin
		var cell:=Vector2i(floori(camera_absolute.x/512),floori(camera_absolute.z/512))
		if cell!=_last_cell or Vector2(camera_absolute.x-_last_focus.x,camera_absolute.z-_last_focus.z).length_squared()>220*220:
			_request(camera_absolute)
	for worker in workers:
		if worker.thread!=null and not worker.thread.is_alive():
			var result: Dictionary=worker.thread.wait_to_finish()
			var id: String=worker.job.id
			worker.thread=null; worker.job={}
			if not result.is_empty():
				if wanted.has(id):
					result.node.position=result.origin-coordinate_origin
					root.add_child(result.node)
					loaded[id]=result
				else: result.node.free()
		if worker.thread==null and not queue.is_empty():
			var job: Dictionary=queue.pop_front()
			if job.kind=="signal":
				var result:=_signal(job)
				result.node.position=result.origin-coordinate_origin
				root.add_child(result.node); loaded[job.id]=result
			else:
				if job.kind=="station" and preload("res://game/authored_station.gd").available(world.stations[job.index].code):
					preload("res://game/authored_station.gd").prepare(world.stations[job.index].code)
				if job.kind=="station":
					if world.stations[job.index].code=="ERS":preload("res://game/authored_station.gd").prepare("ERS_EAST")
					if world.depots.values().any(func(d):return d.station==world.stations[job.index].code):preload("res://game/authored_station.gd").prepare("ERS_WORKSHOP")
				worker.job=job; worker.thread=Thread.new()
				worker.thread.start(_worker.bind(workers.find(worker),job))
	for chunk in loaded.values():
		if chunk.has("adapter"):
			var adapter=chunk.adapter
			for node in adapter.graph.switches:
				adapter.graph.switches[node].reversed=world.graph.switches[node].reversed
			adapter.update_points()
	_view_tick+=1
	if _view_tick%6==0:
		for sid in signal_lamps:
			var aspect:=world.aspect(sid)
			var lit:=0 if aspect==RailWorld.Aspect.GREEN else (1 if aspect==RailWorld.Aspect.YELLOW else 2)
			for i in 3:
				signal_lamps[sid][i].material_override=mat([Color(.1,1,.35),Color(1,.72,.05),Color(1,.08,.05)][i],true) if i==lit else mat(Color(.08,.08,.08))
		_refresh_loading()
	if _joints_on and camera_absolute.distance_squared_to(_joint_focus)>150*150: _make_joint_markers()

func rebase(origin: Vector3) -> void:
	coordinate_origin=origin
	materials.water.set_shader_parameter("route_origin",origin)
	for chunk in loaded.values(): chunk.node.position=chunk.origin-origin
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
	for worker in workers:
		if worker.thread!=null:
			var result: Dictionary=worker.thread.wait_to_finish()
			if not result.is_empty(): result.node.free()
			worker.thread=null
	loaded.clear()
	track_template=null
	assets=null
