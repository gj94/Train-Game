extends "res://game/dispatch_map.gd"
## Chainage schematic: overview of all 277 km, with detailed station scopes.
func _p(s: float, lateral: float=0) -> Vector2:
	var start:=0.0
	var span: float=world.scenery.route.length_m
	if focus_index>=0:
		start=world.stations[focus_index].s-1600
		span=3200
	return Vector2(30+(s-start)/span*(size.x-60),160+lateral*(6.0 if focus_index>=0 else 1.5))

func _edge_p(id: String,fraction: float) -> Vector2:
	var edge: Dictionary=world.graph.edges[id]
	var lateral: float=edge.lateral
	if fraction<=0: lateral=world.graph.nodes[edge.a].lateral
	elif fraction>=1: lateral=world.graph.nodes[edge.b].lateral
	return _p(lerpf(edge.chainage_start,edge.chainage_end,fraction),lateral)

func _draw() -> void:
	if world==null: return
	_hits.clear(); _train_hits.clear()
	var occupied:=world.occupancy()
	var reserved: Dictionary={}
	var preview: Dictionary={}
	for sig in world.signals.values():
		for road in sig.route: reserved[road.edge]=true
	if world.signals.has(selected):
		for option in world.route_options(selected):
			if option.destination==destination:
				for road in option.edges: preview[road.edge]=true
	for index in world.stations.size():
		var st: Dictionary=world.stations[index]
		if focus_index<0 and not st.major: continue
		if focus_index>=0 and index!=focus_index: continue
		var p:=_p(st.s)
		_text(Vector2(clampf(p.x-35,0,size.x-110),28),st.code,GOLD,14)
		_text(Vector2(clampf(p.x-35,0,size.x-110),45),"%.1f km" % ((st.s-world.stations[0].s)/1000),INK,11)
		if focus_index>=0: _text(Vector2(20,68),st.name+" · reconstructed operating yard",GOLD,15)
		draw_line(Vector2(p.x,55),Vector2(p.x,130),Color("24404c"),1)
	for id in world.graph.edges:
		var edge: Dictionary=world.graph.edges[id]
		if focus_index>=0 and (edge.chainage_end<world.stations[focus_index].s-1600 or edge.chainage_start>world.stations[focus_index].s+1600): continue
		var pts:=PackedVector2Array()
		for fraction in [0.0,.2,.8,1.0]: pts.append(_edge_p(id,fraction))
		if preview.has(id): draw_polyline(pts,Color.WHITE,7,true)
		draw_polyline(pts,RED if occupied.has(id) else (TEAL if reserved.has(id) else INK),2 if focus_index<0 else 3,true)
		if focus_index>=0 and "_P" in id:
			_text(_edge_p(id,.5)+Vector2(-20,-8),id,INK,10)
	for sid in world.signals:
		if focus_index<0 and sid!=selected and sid!=destination: continue
		var sig: Dictionary=world.signals[sid]
		var p:=_edge_p(sig.edge,sig.s/world.graph.edges[sig.edge].length)
		if p.x<0 or p.x>size.x: continue
		var lamp:=p+Vector2(0,-14 if sig.dir>0 else 14)
		var color: Color=[RED,GOLD,TEAL][world.aspect(sid)]
		draw_line(p,lamp,INK,1)
		draw_circle(lamp,4.5,color)
		if sid==selected or sid==destination: draw_arc(lamp,9,0,TAU,24,Color.WHITE,1.5,true)
		_text(lamp+Vector2(-20,-9 if sig.dir>0 else 19),sid,color,10)
		_hits[sid]=Rect2(lamp-Vector2(9,9),Vector2(18,18))
	for train in world.trains.values():
		var p:=_edge_p(train.path[0].edge,train.head_s/world.graph.edges[train.path[0].edge].length)
		if p.x<0 or p.x>size.x: continue
		var r:=Rect2(p+Vector2(-16,-6),Vector2(32,13))
		draw_rect(r,GOLD)
		_text(r.position+Vector2(2,10),train.id+(">" if train.path[0].dir>0 else "<"),Color("10252d"),10)
		_train_hits[train.id]=r
	_text(Vector2(8,296),"Station picker enlarges a yard · click service to follow · select entry and exit signals to dispatch",INK,11)
