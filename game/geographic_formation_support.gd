extends RefCounted
## Immutable presentation index of the actual running roads. Water carving must
## respect these formations, including terminal/depot extensions, while genuine
## bridge openings remain open. No simulation geometry is modified.
const CELL:=64.0
const SHOULDER:=7.0
const BATTER_END:=27.0
var bins:={}
var fine_cells:={}

func build(world,geo) -> void:
	for eid: String in world.graph.edges:
		var edge: Dictionary=world.graph.edges[eid]
		var count:=maxi(1,ceili(edge.length/25.0))
		for i in count:
			var a: Vector3=world.graph.position(eid,edge.length*i/float(count))
			var b: Vector3=world.graph.position(eid,edge.length*(i+1)/float(count))
			var segment:={a=a,b=b,start=lerpf(edge.chainage_start,edge.chainage_end,i/float(count)),end=lerpf(edge.chainage_start,edge.chainage_end,(i+1)/float(count))}
			var bounds:=Rect2(Vector2(a.x,a.z),Vector2.ZERO).expand(Vector2(b.x,b.z)).grow(BATTER_END)
			for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
				for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
					var key:=Vector2i(x,z)
					if not bins.has(key):bins[key]=[]
					bins[key].append(segment)
		for span in geo.bridges:
			for chain in [span.start,span.end]:
				if chain<edge.chainage_start or chain>edge.chainage_end:continue
				var distance: float=(chain-edge.chainage_start)/(edge.chainage_end-edge.chainage_start)*edge.length
				_refine(world.graph.position(eid,distance))

func _refine(p: Vector3) -> void:
	# A small detailed patch at abrupt deck/formation transitions. Whole tiles
	# retain their ordinary resolution; adjacent fine cells share their edges.
	for x in range(floori((p.x-24)/8),ceili((p.x+24)/8)):
		for z in range(floori((p.z-24)/8),ceili((p.z+24)/8)):
			if Vector2(x*8+4,z*8+4).distance_to(Vector2(p.x,p.z))<=24:fine_cells[Vector2i(x,z)]=true

func nearest(p: Vector2) -> Dictionary:
	var best:={distance=INF,height=0.0,chain=0.0}
	for segment in bins.get(Vector2i(floori(p.x/CELL),floori(p.y/CELL)),[]):
		var a:=Vector2(segment.a.x,segment.a.z);var b:=Vector2(segment.b.x,segment.b.z)
		var t:=clampf((p-a).dot(b-a)/maxf(.0001,(b-a).length_squared()),0,1)
		var distance:=p.distance_to(a.lerp(b,t))
		if distance<best.distance:best={distance=distance,height=lerpf(segment.a.y,segment.b.y,t),chain=lerpf(segment.start,segment.end,t)}
	return best

func water_ground(geo,p: Vector2,dry: float,wet: float) -> float:
	var rail:=nearest(p)
	if rail.distance>=BATTER_END or not geo.bridge_at(rail.chain).is_empty():return wet
	var formation: float=minf(dry,rail.height-.15)
	return maxf(wet,lerpf(formation,wet,smoothstep(SHOULDER,BATTER_END,rail.distance)))
