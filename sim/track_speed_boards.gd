extends RefCounted
## Immutable, directional engineering indicators derived from track limits.
## No renderer dependencies, dispatcher state or artificial service speed caps.
const Stock := preload("res://sim/stock/ported_stock.gd")
const CAUTION_DISTANCE := 1200.0

static func clearance_length(world: RailWorld) -> float:
	var longest := 0.0
	for choice in Stock.CHOICES:
		for profile in Stock.profiles(choice):longest=maxf(longest,Stock.length_of(choice,profile))
	for train: Train in world.trains.values():longest=maxf(longest,train.length)
	return ceilf(longest/50.0)*50.0+50.0

## Legal continuations independent of the current position of the points.
## Reverse search returns predecessors in their actual forward travel direction.
static func adjacent(g: TrackGraph, edge: String, dir: int, forward: bool) -> Array:
	var node := g.exit_node(edge,dir) if forward else g.entry_node(edge,dir)
	var result := []
	for other: String in g.nodes[node].edges:
		if other==edge:continue
		if g.switches.has(node):
			var sw: Dictionary=g.switches[node]
			if edge!=sw.trunk and other!=sw.trunk:continue
		var travel := (1 if g.edges[other].a==node else -1)*(1 if forward else -1)
		if g.allows(other,travel):result.append({edge=other,dir=travel})
	return result

static func label(edge: String) -> String:
	if "_P" in edge and edge.get_slice("_P",1).is_valid_int():return edge.replace("_P"," P")
	if "_DEPOT_" in edge:return edge.get_slice("_",0)+" DEPOT"
	if "_LADDER_" in edge:return edge.get_slice("_",0)+" POINTS"
	if "LEAD" in edge:return edge.get_slice("_",0)+" APPROACH"
	return edge.replace("_"," ")

static func build(world: RailWorld) -> Array:
	var g := world.graph
	var clearance := clearance_length(world)
	var boards := []
	for eid: String in g.edges:
		var limit: float=g.edges[eid].speed_limit
		for dir in [1,-1]:
			if not g.allows(eid,dir):continue
			var previous := adjacent(g,eid,dir,false)
			for prev: Dictionary in previous:
				var before: float=g.edges[prev.edge].speed_limit
				if before>limit+.001:
					# At the boundary, on the approach. A facing fork has road plaques.
					var route := label(eid) if adjacent(g,prev.edge,prev.dir,true).size()>1 else ""
					boards.append(_board("speed",prev.edge,g.exit_s(prev.edge,prev.dir),prev.dir,limit,route,eid))
					for point in walk(g,prev.edge,g.exit_s(prev.edge,prev.dir),prev.dir,CAUTION_DISTANCE,false):
						boards.append(_board("caution",point.edge,point.s,point.dir,0,"",eid))
				elif before<limit-.001:
					for point in walk(g,eid,g.entry_s(eid,dir),dir,clearance,true,limit):
						# A merge can introduce another lower-speed approach after the
						# original restriction. Never release that train prematurely.
						if not tail_clear(g,point.edge,point.s,point.dir,clearance,limit):continue
						var board := _board("termination",point.edge,point.s,point.dir,limit,"",eid)
						board.clearance=clearance
						boards.append(board)
	var unique := {}
	var result := []
	for board: Dictionary in boards:
		var key := "%s:%s:%d:%d:%d:%s" % [board.kind,board.edge,board.dir,roundi(board.s),roundi(board.limit*3.6),board.route]
		if unique.has(key):continue
		unique[key]=true;board.id=key;result.append(board)
	result.sort_custom(func(a,b):return a.id<b.id)
	return result

static func _board(kind: String,edge: String,s: float,dir: int,limit: float,route: String,source: String) -> Dictionary:
	return {kind=kind,edge=edge,s=s,dir=dir,limit=limit,route=route,source=source}

## Walk all legal paths by exact distance, stopping at buffers, cycles and new
## lower restrictions. Backward traversal honours one-way track directions.
static func walk(g: TrackGraph,edge: String,s: float,dir: int,distance: float,forward: bool,minimum: float=0.0) -> Array:
	var pending := [{edge=edge,s=s,dir=dir,left=distance,seen={}}]
	var result := []
	while not pending.is_empty():
		var p: Dictionary=pending.pop_back()
		var key := "%s:%d" % [p.edge,p.dir]
		if p.seen.has(key) or g.edges[p.edge].speed_limit<minimum-.001:continue
		var travel: int=p.dir*(1 if forward else -1)
		var available: float=absf(g.exit_s(p.edge,travel)-p.s)
		if p.left<=available+.001:
			result.append({edge=p.edge,s=clampf(p.s+travel*p.left,0,g.edges[p.edge].length),dir=p.dir})
			continue
		var visited: Dictionary=p.seen.duplicate();visited[key]=true
		for next: Dictionary in adjacent(g,p.edge,p.dir,forward):
			pending.append({edge=next.edge,dir=next.dir,s=g.entry_s(next.edge,next.dir) if forward else g.exit_s(next.edge,next.dir),left=p.left-available,seen=visited})
	return result

static func tail_clear(g: TrackGraph,edge: String,s: float,dir: int,distance: float,limit: float) -> bool:
	var pending := [{edge=edge,s=s,dir=dir,left=distance,seen={}}]
	while not pending.is_empty():
		var p: Dictionary=pending.pop_back()
		if p.left<=.001:continue
		if g.edges[p.edge].speed_limit<limit-.001:return false
		var key := "%s:%d" % [p.edge,p.dir]
		if p.seen.has(key):return false
		var available: float=absf(g.entry_s(p.edge,p.dir)-p.s)
		if p.left<=available+.001:continue
		var visited: Dictionary=p.seen.duplicate();visited[key]=true
		for prev: Dictionary in adjacent(g,p.edge,p.dir,false):
			pending.append({edge=prev.edge,dir=prev.dir,s=g.exit_s(prev.edge,prev.dir),left=p.left-available,seen=visited})
	return true
