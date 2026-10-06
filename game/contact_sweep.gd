extends RefCounted
## Physical contacts swept between actual axle positions, with fractional times.
var previous := []
var discontinuity := false

func reset() -> void:
	previous.clear()

func advance(positions: Array, layout, delta: float) -> Array:
	var hits := []
	discontinuity=false
	if previous.size()!=positions.size(): previous=positions.duplicate(true); return hits
	for i in positions.size():
		var before: Dictionary=previous[i]
		var now: Dictionary=positions[i]
		var segments := []
		if before.edge==now.edge:
			if before.dir!=now.dir or (now.s-before.s)*now.dir< -.001: discontinuity=true; continue
			segments.append({edge=now.edge,a=before.s,b=now.s})
		else:
			if layout.graph.exit_node(before.edge,before.dir)!=layout.graph.entry_node(now.edge,now.dir): discontinuity=true; continue
			segments.append({edge=before.edge,a=before.s,b=layout.graph.exit_s(before.edge,before.dir)})
			segments.append({edge=now.edge,a=layout.graph.entry_s(now.edge,now.dir),b=now.s})
		var distance := 0.0
		for segment in segments: distance+=absf(segment.b-segment.a)
		if distance>40: discontinuity=true; continue
		if distance<.000001: continue
		var travelled := 0.0
		for segment in segments:
			for c in layout.between(segment.edge,segment.a,segment.b):
				var fraction := (travelled+absf(c.s-segment.a))/distance
				hits.append({axle=i,contact=c,relative=(fraction-1)*delta})
			travelled+=absf(segment.b-segment.a)
	previous=positions.duplicate(true)
	return [] if discontinuity else hits
