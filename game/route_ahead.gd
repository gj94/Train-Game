extends RefCounted
## Read-only preview on the currently selected route, never authority to proceed.
static func describe(world: RailWorld, train: Train) -> String:
	if train.path.is_empty():return ""
	var current: Dictionary=train.path[0];var graph:=world.graph
	var tangent:=graph.tangent(current.edge,train.head_s,current.dir)
	var grade:=tangent.y/maxf(.001,Vector2(tangent.x,tangent.z).length())*1000
	var text:="Grade %+.1f‰" % grade
	var distance:=absf(graph.exit_s(current.edge,current.dir)-train.head_s)
	var limit: float=graph.edges[current.edge].speed_limit
	var visited:={}
	for i in 32:
		if distance>5000:break
		var next: Dictionary=graph.next(current.edge,current.dir)
		if next.is_empty() or visited.has(next.edge):break
		visited[next.edge]=true
		var next_limit: float=graph.edges[next.edge].speed_limit
		if absf(next_limit-limit)>.1:
			text+=" · %d km/h in %d m" % [roundi(next_limit*3.6),roundi(distance)];break
		current=next;distance+=graph.edges[current.edge].length
	var tt=train.timetable
	if tt!=null and not tt.complete():
		var index: int=mini(tt.index+1,tt.stops.size()-1) if tt.at_stop else tt.index
		var road: String=tt.stops[index].block
		var station:=preload("res://sim/priority_dispatch.gd").station(world,road)
		var detail: Dictionary=station.get("platform_details",{}).get(road,{})
		if not detail.is_empty():
			var side: float=detail.get("platform_side",0)*int(tt.stops[index].direction)
			text+=" · Booked platform "+("both sides" if detail.get("platform_sides",[]).size()>1 else ("right" if side>0 else "left"))
	return text
