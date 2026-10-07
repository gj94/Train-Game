extends RefCounted
## Reverse shortest paths over directed track states. Topology, never point state,
## determines reachability; interlocking still determines permission to move.
var graph: TrackGraph
var incoming := {}
var cache := {}
var revision := ""

func _init(g: TrackGraph) -> void:
	graph = g

func _key(edge: String, direction: int) -> String:
	return edge + "|" + str(direction)

func distance(edge: String, direction: int, from_s: float, stop: Dictionary) -> float:
	var version := "%d:%d:%d" % [graph.nodes.size(),graph.edges.size(),graph.switches.size()]
	if version != revision:
		revision = version
		_index()
		cache.clear()
	if edge == stop.block and direction == stop.direction:
		var ahead: float = (stop.s-from_s)*direction
		return maxf(0.0,ahead) if ahead >= -1.1 else INF
	var target := "%s|%d|%.6f" % [stop.block,stop.direction,stop.s]
	if not cache.has(target):
		if cache.size() >= 96: cache.clear()
		cache[target] = _solve(stop)
	var entry_distance: float = cache[target].get(_key(edge,direction),INF)
	return entry_distance - absf(from_s-graph.entry_s(edge,direction))

func _index() -> void:
	incoming.clear()
	for id in graph.edges:
		for direction in [-1,1]:
			if not graph.allows(id,direction): continue
			var node := graph.exit_node(id,direction)
			var exits: Array = graph.nodes[node].edges.duplicate()
			if graph.switches.has(node):
				var sw: Dictionary = graph.switches[node]
				exits = [sw.normal,sw.reverse] if id == sw.trunk else [sw.trunk]
			for other in exits:
				if other == id: continue
				var travel := 1 if graph.edges[other].a == node else -1
				if not graph.allows(other,travel): continue
				var key := _key(other,travel)
				if not incoming.has(key): incoming[key] = []
				incoming[key].append([_key(id,direction),graph.edges[id].length])

func _solve(stop: Dictionary) -> Dictionary:
	var target := _key(stop.block,stop.direction)
	var initial: float = absf(stop.s-graph.entry_s(stop.block,stop.direction))
	var distances := {target:initial}
	var heap: Array = [[initial,target]]
	while not heap.is_empty():
		var best: Array = _pop(heap)
		if best[0] > distances[best[1]]: continue
		for previous in incoming.get(best[1],[]):
			var candidate: float = best[0]+previous[1]
			if candidate < distances.get(previous[0],INF):
				distances[previous[0]] = candidate
				_push(heap,[candidate,previous[0]])
	return distances

func _push(heap: Array, value: Array) -> void:
	heap.append(value)
	var i := heap.size()-1
	while i > 0:
		var parent := (i-1)/2
		if heap[parent][0] <= value[0]: break
		heap[i] = heap[parent]
		i = parent
	heap[i] = value

func _pop(heap: Array) -> Array:
	var result: Array = heap[0]
	var tail: Array = heap.pop_back()
	if heap.is_empty(): return result
	var i := 0
	while i*2+1 < heap.size():
		var child := i*2+1
		if child+1 < heap.size() and heap[child+1][0] < heap[child][0]: child += 1
		if tail[0] <= heap[child][0]: break
		heap[i] = heap[child]
		i = child
	heap[i] = tail
	return result
