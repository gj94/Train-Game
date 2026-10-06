extends RefCounted
## Exact railway-segment clearance in a small spatial index; rendering only.
const CELL := 64.0
var bins := {}
var segments := []
func _init(graph=null) -> void:
	if graph==null: return
	for edge in graph.edges.values():
		for i in range(1,edge.points.size()):
			var a:=Vector2(edge.points[i-1].x,edge.points[i-1].z)
			var b:=Vector2(edge.points[i].x,edge.points[i].z)
			var index:=segments.size()
			segments.append([a,b])
			for x in range(floori(minf(a.x,b.x)/CELL),floori(maxf(a.x,b.x)/CELL)+1):
				for z in range(floori(minf(a.y,b.y)/CELL),floori(maxf(a.y,b.y)/CELL)+1):
					var cell:=Vector2i(x,z)
					if not bins.has(cell): bins[cell]=[]
					bins[cell].append(index)
func candidates(area: Rect2) -> Dictionary:
	var found:={}
	for x in range(floori(area.position.x/CELL),floori(area.end.x/CELL)+1):
		for z in range(floori(area.position.y/CELL),floori(area.end.y/CELL)+1):
			for index in bins.get(Vector2i(x,z),[]): found[index]=true
	return found
func clear_point(point: Vector3,metres: float) -> bool:
	var p:=Vector2(point.x,point.z)
	for index in candidates(Rect2(p-Vector2.ONE*metres,Vector2.ONE*metres*2)):
		var s: Array=segments[index]
		if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,s[0],s[1]))<metres*metres: return false
	return true
func clear_rect(rect: Rect2,margin: float=0.0) -> bool:
	var expanded:=rect.grow(margin)
	var corners:=[expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]
	for index in candidates(expanded):
		var s: Array=segments[index]
		if expanded.has_point(s[0]) or expanded.has_point(s[1]): return false
		for i in 4:
			if Geometry2D.segment_intersects_segment(s[0],s[1],corners[i],corners[(i+1)%4])!=null: return false
	return true
