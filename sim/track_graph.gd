class_name TrackGraph
extends RefCounted
## Track topology and geometry. No rendering.
##
## Nodes are points where edges meet. A node joins 1 edge (buffer stop),
## 2 edges (plain joint) or 3 edges (switch: trunk + normal + reverse branch).
## Edges are polylines from node `a` to node `b`. A position on an edge is a
## distance `s` from `a` (0..length). A travel direction `dir` is +1 (a->b)
## or -1 (b->a).

var nodes := {}     # id -> {pos: Vector3, edges: Array}
var edges := {}     # id -> {id, a, b, points: PackedVector3Array, cum: PackedFloat32Array, length, speed_limit}
var switches := {}  # node id -> {id, trunk, normal, reverse, reversed: bool, clearance: metres}


func add_node(id: String, pos: Vector3) -> void:
	assert(not nodes.has(id), "duplicate node " + id)
	nodes[id] = {pos = pos, edges = []}


## `mid_points` are the polyline points between the two node positions.
## `speed_limit` is in m/s.
func add_edge(id: String, a: String, b: String, mid_points: Array = [], speed_limit: float = 100.0 / 3.6) -> void:
	assert(not edges.has(id), "duplicate edge " + id)
	assert(nodes.has(a) and nodes.has(b), "edge %s: unknown node" % id)
	var pts := PackedVector3Array()
	pts.append(nodes[a].pos)
	for p in mid_points:
		pts.append(p)
	pts.append(nodes[b].pos)
	var cum := PackedFloat32Array()
	cum.append(0.0)
	for i in range(1, pts.size()):
		cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
	edges[id] = {id = id, a = a, b = b, points = pts, cum = cum, length = cum[cum.size() - 1], speed_limit = speed_limit}
	nodes[a].edges.append(id)
	nodes[b].edges.append(id)


func add_switch(node_id: String, trunk: String, normal: String, reverse: String, clearance: float = 12.0) -> void:
	var ne: Array = nodes[node_id].edges
	assert(ne.size() == 3 and trunk in ne and normal in ne and reverse in ne, "bad switch " + node_id)
	switches[node_id] = {id = node_id, trunk = trunk, normal = normal, reverse = reverse, reversed = false, clearance = clearance}


func exit_node(edge_id: String, dir: int) -> String:
	return edges[edge_id].b if dir > 0 else edges[edge_id].a


func entry_node(edge_id: String, dir: int) -> String:
	return edges[edge_id].a if dir > 0 else edges[edge_id].b


## Distance along the edge at which a train travelling in `dir` leaves it.
func exit_s(edge_id: String, dir: int) -> float:
	return edges[edge_id].length if dir > 0 else 0.0


func entry_s(edge_id: String, dir: int) -> float:
	return 0.0 if dir > 0 else edges[edge_id].length


## The edge a train moves onto after leaving `edge_id` in `dir`, following the
## current switch settings. Returns {} at a buffer stop, otherwise
## {edge, dir, switch (node id or ""), against (trailing through a switch set the other way)}.
func next(edge_id: String, dir: int) -> Dictionary:
	var n := exit_node(edge_id, dir)
	var out := ""
	var sw_id := ""
	var against := false
	if switches.has(n):
		var sw: Dictionary = switches[n]
		sw_id = n
		if edge_id == sw.trunk:
			out = sw.reverse if sw.reversed else sw.normal
		else:
			out = sw.trunk
			against = (edge_id == sw.normal and sw.reversed) or (edge_id == sw.reverse and not sw.reversed)
	else:
		for e in nodes[n].edges:
			if e != edge_id:
				out = e
				break
	if out == "":
		return {}
	return {edge = out, dir = 1 if edges[out].a == n else -1, switch = sw_id, against = against}


func position(edge_id: String, s: float) -> Vector3:
	var e: Dictionary = edges[edge_id]
	var i := _segment_index(e, s)
	var seg_len: float = e.cum[i + 1] - e.cum[i]
	var t: float = 0.0 if seg_len <= 0.0 else (s - e.cum[i]) / seg_len
	return e.points[i].lerp(e.points[i + 1], clampf(t, 0.0, 1.0))


## Unit tangent at `s` pointing in travel direction `dir`.
func tangent(edge_id: String, s: float, dir: int) -> Vector3:
	var e: Dictionary = edges[edge_id]
	var i := _segment_index(e, s)
	return (e.points[i + 1] - e.points[i]).normalized() * dir


func _segment_index(e: Dictionary, s: float) -> int:
	var cum: PackedFloat32Array = e.cum
	var i := cum.bsearch(clampf(s, 0.0, e.length)) - 1
	return clampi(i, 0, cum.size() - 2)
