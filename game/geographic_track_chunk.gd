extends RefCounted
## Worker-owned detached permanent-way chunk. Shared mesh/material resources
## are immutable; only the main thread attaches the returned scene tree.
const Track := preload("res://game/track_view.gd")
const LocalGraph := preload("res://game/local_track_graph.gd")
var resources
var source: TrackGraph

func _init(template, graph: TrackGraph) -> void:
	resources = template
	source = graph

func build(eid: String, start: float, end: float, nodes: Array) -> Dictionary:
	var origin := source.position(eid,(start+end)*.5)
	origin = Vector3(floorf(origin.x/256)*256,0,floorf(origin.z/256)*256)
	var selected := {eid:true}
	# Full neighbouring roads are needed only for shared stock-rail decisions.
	for node in [source.edges[eid].a,source.edges[eid].b]:
		if source.switches.has(node):
			for edge in source.nodes[node].edges: selected[edge]=true
	for node in nodes:
		for edge in source.nodes[node].edges: selected[edge]=true
	var graph := LocalGraph.new(source,origin,selected.keys())
	var adapter := Track.new()
	adapter.graph = graph
	adapter.root = Node3D.new()
	adapter.root.name = "Track_"+eid+"_"+str(roundi(start))
	adapter.materials = resources.materials
	for property in ["sleeper","bearer","fastening","stone","fishplate","single_fishplate"]:
		adapter.set(property,resources.get(property))
	adapter._find_junctions()
	for s in range(roundi(start),ceili(end),64):
		adapter._build_chunk(eid,float(s),minf(s+64.0,end))
	# Only the job owning a toe makes its points/check rails, without duplicates.
	for edge in adapter.junctions.keys():
		adapter.junctions[edge] = adapter.junctions[edge].filter(func(j): return j.node in nodes)
	graph.switches = graph.switches.duplicate()
	for node in graph.switches.keys():
		if node not in nodes: graph.switches.erase(node)
	adapter._build_check_rails()
	adapter._build_points()
	return {node=adapter.root,origin=origin,adapter=adapter}
