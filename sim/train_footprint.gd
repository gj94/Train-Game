extends RefCounted
## Exact head-to-tail intervals, including trains spanning turnout/block seams.
static func intervals(graph: TrackGraph, train: Train) -> Array:
	var remaining := train.length
	var result: Array = []
	for i in train.path.size():
		if remaining <= .00001: break
		var seg: Dictionary = train.path[i]
		var start: float = train.head_s if i == 0 else graph.exit_s(seg.edge,seg.dir)
		var length := minf(remaining,train._available_behind(graph,i))
		var finish: float = start-seg.dir*length
		result.append({edge=seg.edge,from_s=start,to_s=finish,direction=seg.dir,length=length})
		remaining-=length
	return result
