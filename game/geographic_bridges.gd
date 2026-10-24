extends RefCounted
## Continuous deck, abutments and piers across mapped/inferred water crossings.
## Every parallel road shares the same deck; guard rails stay outside all tracks.
static func intervals(edge: Dictionary,start: float,end: float,spans: Array) -> Array:
	var result:=[]
	for span in spans:
		var lo: float=maxf(start,(span.start-edge.chainage_start)/(edge.chainage_end-edge.chainage_start)*edge.length)
		var hi: float=minf(end,(span.end-edge.chainage_start)/(edge.chainage_end-edge.chainage_start)*edge.length)
		if hi>lo:result.append({start=lo,end=hi,span=span})
	return result

static func draw(batch,graph: TrackGraph,geo,layout,eid: String,start: float,end: float,origin: Vector3) -> void:
	var edge: Dictionary=graph.edges[eid]
	for approach in approaches(edge,start,end,geo.bridges):
		var mid: float=(approach.x+approach.y)*.5
		var chain: float=lerpf(edge.chainage_start,edge.chainage_end,mid/edge.length)
		var section: Dictionary=layout.section(eid,chain,origin)
		if section.is_empty():continue
		var p:=graph.position_relative(eid,mid,origin)
		var a:=graph.position_relative(eid,approach.x,origin);var b:=graph.position_relative(eid,approach.y,origin)
		var left: float=(section.points[0]-p).dot(section.right)-4.2
		var right: float=(section.points[-1]-p).dot(section.right)+4.2
		var bottom: float=minf(geo.height_at(p.x+origin.x,p.z+origin.z)-1.0,p.y-3.0)
		var top: float=minf(a.y,b.y)-.18
		var centre: float=(left+right)*.5
		var ring:=PackedVector2Array()
		for q in [a+section.right*left,b+section.right*left,b+section.right*right,a+section.right*right]:ring.append(Vector2(q.x+origin.x,q.z+origin.z))
		if not preload("res://game/geographic_bridge_clearance.gd").clear(geo,ring,top,bottom):continue
		# A short, grounded landward abutment closes the terrain interpolation
		# wedge immediately beyond the deck. It never extends into the opening.
		a+=section.right*centre;b+=section.right*centre
		a.y=(top+bottom)*.5;b.y=a.y
		batch.beam("concrete",a,b,right-left,Color.WHITE,top-bottom)
	for interval in intervals(edge,start,end,geo.bridges):
		preload("res://game/geographic_bridge_deck.gd").draw(batch,graph,geo,layout,eid,interval,origin)

static func approaches(edge: Dictionary,start: float,end: float,spans: Array) -> Array:
	var result:=[]
	var scale: float=edge.length/(edge.chainage_end-edge.chainage_start)
	for span in spans:
		for side in [-1,1]:
			var boundary: float=((span.start if side<0 else span.end)-edge.chainage_start)*scale
			var lo: float=maxf(start,boundary-3 if side<0 else boundary)
			var hi: float=minf(end,boundary if side<0 else boundary+3)
			if hi<=lo:continue
			var pieces:=[Vector2(lo,hi)]
			# Very close bridge openings must not be blocked by a neighbouring
			# abutment. Clip against every true deck interval on this edge.
			for opening in intervals(edge,lo,hi,spans):
				var next:=[]
				for piece in pieces:
					if opening.end<=piece.x or opening.start>=piece.y:next.append(piece);continue
					if opening.start>piece.x:next.append(Vector2(piece.x,opening.start))
					if opening.end<piece.y:next.append(Vector2(opening.end,piece.y))
				pieces=next
			for piece in pieces:
				# Float32 edge coordinates can leave a sub-millimetre clipping
				# sliver at another span boundary. Never turn it into a wall.
				if piece.y-piece.x>.05:result.append(piece)
	return result
