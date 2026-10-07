extends RefCounted
## Station platforms, electrification and mapped bridge spans. Local geometry.
const MeshBuilder := preload("res://game/geographic_mesh.gd")
const Library := preload("res://game/scenery_library.gd")
const Context := preload("res://game/world_view.gd")
var graph: TrackGraph
var world: RailWorld
var materials: Dictionary
var assets
var geo
var origin := Vector3.ZERO
var root: Node3D
var batch

func _init(w: RailWorld, data, shared_materials: Dictionary, shared_assets) -> void:
	world=w; graph=w.graph; geo=data; materials=shared_materials; assets=shared_assets

func build_station(index: int) -> Dictionary:
	var station: Dictionary=world.stations[index]
	origin=Vector3(floorf(station.origin.x/256)*256,0,floorf(station.origin.z/256)*256)
	root=Node3D.new(); root.name="Station_"+station.code
	batch=MeshBuilder.new()
	for road in station.platform_tracks:
		var detail: Dictionary=station.platform_details[road]
		if detail.platform_width<=0:continue
		var side: float=detail.platform_side
		var platform_far: float=2.02+detail.platform_width
		var e: Dictionary=graph.edges[road]
		var half_platform:=minf(320,e.length*.5-200)
		var start: float=e.length*.5-half_platform
		var end: float=e.length*.5+half_platform
		for s in range(ceili(start),floori(end),8):
			var a:=graph.position_relative(road,s,origin)
			var b:=graph.position_relative(road,minf(s+8,end),origin)
			var right:=graph.tangent(road,s,1).cross(Vector3.UP)
			var near:=right*side*2.02
			var far_edge:=right*side*platform_far
			batch.quad("platform",a+near+Vector3.UP*1.26,b+near+Vector3.UP*1.26,b+far_edge+Vector3.UP*1.26,a+far_edge+Vector3.UP*1.26,Vector3.UP)
			batch.quad("concrete",a+near+Vector3.UP*.20,b+near+Vector3.UP*.20,b+near+Vector3.UP*1.26,a+near+Vector3.UP*1.26,-right*side)
			batch.quad("paint",a+near+right*side*.18+Vector3.UP*1.268,b+near+right*side*.18+Vector3.UP*1.268,b+near+right*side*.37+Vector3.UP*1.268,a+near+right*side*.37+Vector3.UP*1.268,Vector3.UP,Color(.78,.70,.30))
		var shelter_half:=48.0 if station.get("through_halt",false) else 180.0
		for s in range(ceili(e.length*.5-shelter_half),floori(e.length*.5+shelter_half),12):
			var p:=graph.position_relative(road,s,origin)
			var f:=graph.tangent(road,s,1)
			var right:=f.cross(Vector3.UP)
			var centre: Vector3=p+right*side*(2.02+detail.platform_width*.5)
			var basis:=Basis.looking_at(f)
			batch.box("metal",centre+Vector3.UP*3.8,Vector3(.16,5.15,.16),Color.WHITE,basis)
			batch.box("roof",centre+Vector3.UP*6.35,Vector3(minf(4.8,detail.platform_width+1.0),.10,12.25),Color.WHITE,basis)
			batch.beam("metal",centre+Vector3.UP*5.1,centre+right*2.1+Vector3.UP*6.27,.07)
			batch.beam("metal",centre+Vector3.UP*5.1,centre-right*2.1+Vector3.UP*6.27,.07)
			for off in [-1.8,-.6,.6,1.8]:
				batch.beam("metal",centre+right*off-f*6+Vector3.UP*6.24,centre+right*off+f*6+Vector3.UP*6.24,.045)
			if posmod(s,36)<12:
				batch.box("metal",centre+Vector3.UP*1.85,Vector3(2.1,.09,.48),Color.WHITE,basis)
				for x in [-.8,.8]: batch.box("metal",centre+right*x+Vector3.UP*1.54,Vector3(.07,.50,.38),Color.WHITE,basis)
		for s in [e.length*.5-270,e.length*.5+270]:
			var p:=graph.position_relative(road,s,origin)
			var f:=graph.tangent(road,s,1)
			var right:=f.cross(Vector3.UP)
			var position:=p+right*side*(platform_far-.5)
			var basis:=Basis.looking_at(right*side)
			batch.box("sign",position+Vector3.UP*3.45,Vector3(5.6,1.5,.10),Color(.91,.72,.20),basis)
			for x in [-2.4,2.4]: batch.box("concrete",position+basis.x*x+Vector3.UP*2.45,Vector3(.13,2.4,.13))
			var board_text: String=station.get("local_name","")+"\n"+station.name.to_upper()
			_label(board_text,position+Vector3.UP*3.44-basis.z*.065,basis,.0065,Color(.09,.10,.08),330)
	# Frontage runs along the railway, with the distinctive entrance facing out.
	var road: String=station.platform_tracks[0]
	var midpoint: float=graph.edges[road].length*.5
	var p:=graph.position_relative(road,midpoint,origin)
	var f:=graph.tangent(road,midpoint,1)
	var right:=f.cross(Vector3.UP)
	var left_extent:=0.0
	var right_extent:=0.0
	for detail in station.operating_roads:
		left_extent=minf(left_extent,detail.offset)
		right_extent=maxf(right_extent,detail.offset)
	var position:=p+right*(left_extent-26)
	var basis:=Basis(f,Vector3.UP,right)
	var kind: String={"ERS":"kerala_ers_entry","TVC":"kerala_tvc_heritage","NCJ":"kerala_ncj_entry"}.get(station.code,"kerala_coastal_station")
	if station.major or station.code in ["SRTL","VAK","NYY","KZT","ERL"]:
		var footprint: Vector2={"ERS":Vector2(96,22),"TVC":Vector2(114,24),"NCJ":Vector2(84,24)}.get(station.code,Vector2(66,17))
		preload("res://game/geographic_station_foundation.gd").draw(batch,geo,position,basis,footprint,origin)
		for part in assets.asset(kind):
			var model:=MeshInstance3D.new()
			model.mesh=part.mesh
			model.transform=Transform3D(basis,position)*part.transform
			root.add_child(model)
		var name_height: float={"TVC":15.85,"ERS":7.6,"NCJ":9.42}.get(station.code,5.5)
		var front: float={"TVC":4.6,"ERS":8.2,"NCJ":8.1}.get(station.code,7.15)
		_label(station.name.to_upper(),position+Vector3.UP*name_height-right*front,basis,.012 if station.code=="TVC" else .014,Color(.43,.085,.06),500)
	else:
		preload("res://game/geographic_station_foundation.gd").draw(batch,geo,position,basis,Vector2(18,8),origin)
		batch.box("architecture",position+Vector3.UP*2,Vector3(18,4,8),Color(.69,.68,.54,1.0/15.0),basis)
		for x in range(-7,8,3):
			batch.box("architecture",position+f*x-right*4.03+Vector3.UP*1.8,Vector3(1.3,1.8,.06),Color(.1,.16,.17,4.0/15.0),basis)
	if station.get("through_halt",false):
		batch.finish(root,materials,"Railway")
		return {node=root,origin=origin}
	# Passenger bridge with open balustrades and supported stairs, clear of OHE.
	var bridge_s: float=midpoint+60
	var bridge_p:=graph.position_relative(road,bridge_s,origin)
	var bridge_f:=graph.tangent(road,bridge_s,1)
	var bridge_right:=bridge_f.cross(Vector3.UP)
	var left:=left_extent-7
	var width:=right_extent+7
	batch.beam("concrete",bridge_p+bridge_right*left+Vector3.UP*8.05,bridge_p+bridge_right*width+Vector3.UP*8.05,3.2,Color.WHITE,.35)
	for lateral in [left+1,width-1]:
		var base: Vector3=bridge_p+bridge_right*lateral
		for along in [-1.25,1.25]:
			batch.box("metal",base+bridge_f*along+Vector3.UP*4.5,Vector3(.22,8.7,.22))
		for step in 39:
			var y:=1.3+step*.175
			var centre: Vector3=base+bridge_f*(2+step*.28)
			batch.box("concrete",centre+Vector3.UP*y,Vector3(2.1,.16,.30),Color.WHITE,Basis.looking_at(bridge_f))
	for k in range(0,ceili((width-left)/.35)):
		var centre:=bridge_p+bridge_right*(left+k*.35)+Vector3.UP*8.65
		for side in [-1,1]: batch.box("metal",centre+bridge_f*side*1.5,Vector3(.04,1.1,.04))
	for side in [-1,1]: batch.beam("metal",bridge_p+bridge_right*left+bridge_f*side*1.5+Vector3.UP*9.2,bridge_p+bridge_right*width+bridge_f*side*1.5+Vector3.UP*9.2,.06)
	# Forecourt paving, waiting passengers and small platform kiosks.
	batch.box("concrete",position-right*15-Vector3.UP*.02,Vector3(100,.18,13),Color.WHITE,basis)
	preload("res://game/geographic_station_foundation.gd").draw(batch,geo,position-right*15-Vector3.UP*.10,basis,Vector2(100,13),origin)
	var context:=Context.new(); context.root=root
	var props:=Library.new(context); props.meshes=assets.meshes; props.finishes=assets.finishes
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(station.code)
	for eid in station.platform_tracks:
		var edge: Dictionary=graph.edges[eid]
		var detail: Dictionary=station.platform_details[eid]
		if detail.platform_width<=0:continue
		var side: float=detail.platform_side
		for i in (34 if station.major else 12):
			var s: float=edge.length*.5+rng.randf_range(-240,240)
			var forward:=graph.tangent(eid,s,1)
			var at:=graph.position_relative(eid,s,origin)+forward.cross(Vector3.UP)*side*rng.randf_range(2.4,2.02+detail.platform_width-.3)+Vector3.UP*1.27
			props.place(["passenger_man","passenger_sari","passenger_phone","passenger_sari_blue"][i%4],at,rng.randf()*TAU)
		var at:=graph.position_relative(eid,edge.length*.5-110,origin)
		var forward:=graph.tangent(eid,edge.length*.5-110,1)
		if detail.platform_width>=3:
			props.place("tea_kiosk",at+forward.cross(Vector3.UP)*side*(2.02+detail.platform_width*.6)+Vector3.UP*1.27,atan2(forward.x,forward.z))
	for i in 14 if station.major else 5:
		props.place("auto_rickshaw" if i%3==0 else "hatchback",position-right*15+f*(-38+i*5),atan2(right.x,right.z))
	props.flush()
	batch.finish(root,materials,"Railway")
	return {node=root,origin=origin}

func _label(text: String,position: Vector3,basis: Basis,pixel: float,color: Color,distance: float) -> void:
	var label:=Label3D.new()
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Nirmala UI","Arial"])
	label.font=font
	label.text=text; label.font_size=64; label.pixel_size=pixel
	label.modulate=color; label.outline_size=0
	label.position=position; label.basis=basis
	label.visibility_range_end=distance
	root.add_child(label)

func build_ohe(eid: String,start: float,end: float,ohe_layout) -> Dictionary:
	origin=graph.position(eid,(start+end)*.5)
	origin=Vector3(floorf(origin.x/256)*256,0,floorf(origin.z/256)*256)
	root=Node3D.new(); root.name="Electrification_"+eid
	batch=MeshBuilder.new()
	var e: Dictionary=graph.edges[eid]
	for k in range(ceili(start/55),ceili(end/55)):
		var s:=k*55.0
		var p:=graph.position_relative(eid,s,origin)
		var f:=graph.tangent(eid,s,1)
		var right:=f.cross(Vector3.UP)


		var next_s:=minf(s+55,e.length)
		var next:=graph.position_relative(eid,next_s,origin)
		var next_right:=graph.tangent(eid,next_s,1).cross(Vector3.UP)
		for j in 8:
			var t0:=j/8.0; var t1:=(j+1)/8.0
			var a:=p.lerp(next,t0)+Vector3.UP*6.1
			var b:=p.lerp(next,t1)+Vector3.UP*6.1
			a+=right.lerp(next_right,t0)*lerpf(.15 if k%2==0 else -.15,.15 if k%2==1 else -.15,t0)
			b+=right.lerp(next_right,t1)*lerpf(.15 if k%2==0 else -.15,.15 if k%2==1 else -.15,t1)
			batch.beam("wire",a,b,.012)
			batch.beam("wire",a+Vector3.UP*(1.0-.55*sin(PI*t0)),b+Vector3.UP*(1.0-.55*sin(PI*t1)),.012)
			if j%2==0: batch.beam("wire",a,a+Vector3.UP*(1.0-.55*sin(PI*t0)),.009)

	for support in ohe_layout.plans(eid,start,end,origin):
		ohe_layout.draw(batch,support)
	preload("res://game/geographic_bridges.gd").draw(batch,graph,geo,ohe_layout,eid,start,end,origin)

	batch.finish(root,materials,"OHE")
	return {node=root,origin=origin}
