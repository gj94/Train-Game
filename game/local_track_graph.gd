extends TrackGraph
## Coordinate-local geometry facade. Simulation topology is never translated.
var source: TrackGraph
var coordinate_origin := Vector3.ZERO

func _init(graph: TrackGraph, origin: Vector3, selected: Array) -> void:
	source = graph
	coordinate_origin = origin
	for id in selected:
		edges[id] = graph.edges[id]
		for node in [graph.edges[id].a,graph.edges[id].b]:
			if not nodes.has(node): nodes[node] = {pos=graph.node_relative(node,origin),edges=[]}
			nodes[node].edges.append(id)
	for node in nodes:
		if graph.switches.has(node) and nodes[node].edges.size()==3:
			switches[node] = graph.switches[node].duplicate(true)

func position(edge_id: String, s: float) -> Vector3:
	return source.position_relative(edge_id,s,coordinate_origin)

func tangent(edge_id: String, s: float, direction: int) -> Vector3:
	return source.tangent(edge_id,s,direction)
