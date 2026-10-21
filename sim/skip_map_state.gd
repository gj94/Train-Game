extends RefCounted
## Detached local diagram. Never expose a RailWorld/Train/graph reference to UI.
const Footprint := preload("res://sim/train_footprint.gd")
const SPAN := 10000.0

static func point(w: RailWorld, edge_id: String, s: float) -> Vector2:
	var e: Dictionary=w.graph.edges[edge_id]
	var f:=clampf(s/e.length,0,1)
	var a: Dictionary=w.graph.nodes[e.a];var b: Dictionary=w.graph.nodes[e.b]
	var lateral:=lerpf(a.get("lateral",a.pos.z),b.get("lateral",b.pos.z),f)
	return Vector2(lerpf(e.get("chainage_start",a.pos.x),e.get("chainage_end",b.pos.x),f),lateral)

static func geometry(w: RailWorld) -> Dictionary:
	var edges:={};var stations:=[];var signals:={}
	for id in w.graph.edges:
		var e: Dictionary=w.graph.edges[id]
		var a:=point(w,id,0);var b:=point(w,id,e.length)
		var lane: float=e.get("lateral",(a.y+b.y)*.5)
		edges[id]={a=a,b=b,lane=lane,length=e.length}
	for s in w.stations:
		stations.append({name=s.name,code=s.code,s=s.get("s",s.origin.x)})
	for id in w.signals:
		var s: Dictionary=w.signals[id]
		signals[id]={p=point(w,s.edge,s.s),direction=s.dir,edge=s.edge}
	return {edges=edges,stations=stations,signals=signals}

static func capture(w: RailWorld, selected: String, layout: Dictionary) -> Dictionary:
	if not w.trains.has(selected):return {}
	var own: Train=w.trains[selected]
	var center:=point(w,own.path[0].edge,own.head_s)
	var lo:=center.x-SPAN*.5;var hi:=center.x+SPAN*.5
	var trains:=[];var signals:={};var reserved:={};var visible_edges:={}
	for id in layout.edges:
		var e: Dictionary=layout.edges[id]
		if maxf(e.a.x,e.b.x)>=lo and minf(e.a.x,e.b.x)<=hi:visible_edges[id]=true
	for t: Train in w.active_trains():
		var segments:=Footprint.intervals(w.graph,t).filter(func(seg):return visible_edges.has(seg.edge))
		if segments.is_empty():continue
		trains.append({id=t.id,name=t.service_name,speed=t.speed,length=t.length,direction=t.path[0].dir,head=point(w,t.path[0].edge,t.head_s),segments=segments})
	for id in layout.signals:
		if not visible_edges.has(layout.signals[id].edge):continue
		signals[id]=int(w.aspect(id))
	for sig in w.routed_signals():
		for road in sig.route:
			if visible_edges.has(road.edge):reserved[road.edge]=true
	return {clock=w.clock_seconds(),center=center,service=selected,trains=trains,signals=signals,reserved=reserved,
		status=own.status,speed=own.speed}
