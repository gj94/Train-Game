extends RefCounted
## Closed platform retaining faces and correctly connected footbridge stairways.
static func edge(batch,geo,a: Vector3,b: Vector3,right: Vector3,side: float,width: float,origin: Vector3,cap_start: bool,cap_end: bool) -> void:
	var near: Vector3=right*side*2.02
	var far_edge: Vector3=right*side*(2.02+width)
	var far_a:=a+far_edge;var far_b:=b+far_edge
	var ground_a: float=minf(a.y-.18,geo.ground_at(far_a.x+origin.x,far_a.z+origin.z)-.2)
	var ground_b: float=minf(b.y-.18,geo.ground_at(far_b.x+origin.x,far_b.z+origin.z)-.2)
	batch.quad("concrete",Vector3(far_a.x,ground_a,far_a.z),Vector3(far_b.x,ground_b,far_b.z),far_b+Vector3.UP*1.26,far_a+Vector3.UP*1.26,right*side)
	# Close the formerly open strip below the track-facing coping as well.
	batch.quad("concrete",a+near-Vector3.UP*.18,b+near-Vector3.UP*.18,b+near+Vector3.UP*.21,a+near+Vector3.UP*.21,-right*side)
	for end in [0,1]:
		if (end==0 and not cap_start) or (end==1 and not cap_end):continue
		var p: Vector3=a if end==0 else b
		var low: float=ground_a if end==0 else ground_b
		batch.quad("concrete",Vector3(p.x+near.x,low,p.z+near.z),Vector3(p.x+far_edge.x,low,p.z+far_edge.z),p+far_edge+Vector3.UP*1.26,p+near+Vector3.UP*1.26,(a-b).normalized()*(1 if end==0 else -1))

static func perimeter(batch,geo,world: RailWorld,station: Dictionary,origin: Vector3) -> void:
	preload("res://game/station_platform_boundary.gd").draw(batch,geo,world,station,origin)

static func has_bridge(station: Dictionary) -> bool:
	var offsets: Array[float]=[]
	for face in preload("res://sim/platform_faces.gd").entries(station):
		if face.platform_width<2.6:continue
		var offset: float=face.get("offset",0)+face.platform_side*(2.02+face.platform_width*.5)
		var duplicate:=false
		for old: float in offsets:
			if absf(offset-old)<2:duplicate=true
		if not duplicate:offsets.append(offset)
	return offsets.size()>1

static func bridge(batch,world: RailWorld,station: Dictionary,origin: Vector3) -> void:
	var faces: Array=preload("res://sim/platform_faces.gd").entries(station)
	if not has_bridge(station):return
	var road: String=station.platform_tracks[0]
	var mid: float=world.graph.edges[road].length*.5+60
	var p:=world.graph.position_relative(road,mid,origin)
	var f:=world.graph.tangent(road,mid,1);f=Vector3(f.x,0,f.z).normalized()
	var r:=f.cross(Vector3.UP)
	var landings: Array[Vector3]=[]
	for face in faces:
		if face.platform_width<2.6:continue
		var at:=world.graph.position_relative(face.edge,world.graph.edges[face.edge].length*.5+60,origin)
		at+=r*face.platform_side*(2.02+face.platform_width*.5)
		var duplicate:=false
		for previous in landings:
			if absf((at-previous).dot(r))<2.0:duplicate=true
		if not duplicate:landings.append(at)
	if landings.size()<2:return
	landings.sort_custom(func(a,b):return a.dot(r)<b.dot(r))
	var start:=landings[0];var end:=landings[-1]
	var deck:=8.2
	batch.beam("concrete",start+Vector3.UP*(deck-.16),end+Vector3.UP*(deck-.16),3.2,Color.WHITE,.32)
	for signum in [-1,1]:
		batch.beam("station_fence",start+f*signum*1.52+Vector3.UP*(deck+1.05),end+f*signum*1.52+Vector3.UP*(deck+1.05),.055)
		for i in range(ceili(start.distance_to(end)/.32)+1):
			var at: Vector3=start.lerp(end,minf(1,i*.32/maxf(.01,start.distance_to(end))))+f*signum*1.52
			batch.box("station_fence",at+Vector3.UP*(deck+.52),Vector3(.026,1.05,.026))
	for base: Vector3 in landings:
		var basis:=Basis.looking_at(f)
		for signum in [-1,1]:
			var column: Vector3=base+r*signum*.88
			batch.box("metal",column+Vector3.UP*4.55,Vector3(.17,6.6,.17),Color.WHITE,basis)
			batch.box("concrete",column+Vector3.UP*1.38,Vector3(.48,.24,.48),Color.WHITE,basis)
		var steps:=39;var rise: float=(deck-1.26)/steps
		for i in steps:
			var top: float=deck-(i+1)*rise
			var centre: Vector3=base+f*(1.6+(i+.5)*.29)
			batch.box("concrete",centre+Vector3.UP*(top-.065),Vector3(2.12,.13,.30),Color.WHITE,basis)
			batch.box("concrete",centre-f*.14+Vector3.UP*(top+rise*.5),Vector3(2.12,rise,.07),Color.WHITE,basis)
		for signum in [-1,1]:
			var top: Vector3=base+f*1.6+r*signum*1.1+Vector3.UP*(deck+.98)
			var bottom: Vector3=base+f*(1.6+steps*.29)+r*signum*1.1+Vector3.UP*(1.26+.98)
			batch.beam("station_fence",top,bottom,.06)
			batch.beam("metal",top-Vector3.UP*1.2,bottom-Vector3.UP*1.2,.15,Color.WHITE,.24)
			for i in range(0,steps,3):
				var at:=top.lerp(bottom,float(i)/steps)
				batch.box("station_fence",at-Vector3.UP*.48,Vector3(.04,.96,.04))
