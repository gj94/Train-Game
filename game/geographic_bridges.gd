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
	for interval in intervals(edge,start,end,geo.bridges):
		var lo: float=interval.start;var hi: float=interval.end
		var steps:=maxi(1,ceili((hi-lo)/8))
		for i in steps:
			var sa:=lerpf(lo,hi,float(i)/steps);var sb:=lerpf(lo,hi,float(i+1)/steps)
			var mid:=(sa+sb)*.5
			var chain: float=lerpf(edge.chainage_start,edge.chainage_end,mid/edge.length)
			var section: Dictionary=layout.section(eid,chain,origin)
			if section.is_empty():continue
			var p:=graph.position_relative(eid,mid,origin)
			var a:=graph.position_relative(eid,sa,origin);var b:=graph.position_relative(eid,sb,origin)
			var ar:=graph.tangent(eid,sa,1).cross(Vector3.UP).normalized()
			var br:=graph.tangent(eid,sb,1).cross(Vector3.UP).normalized()
			var left: float=(section.points[0]-p).dot(section.right)-4.2
			var right: float=(section.points[-1]-p).dot(section.right)+4.2
			var centre:=(left+right)*.5
			batch.beam("concrete",a+ar*centre-Vector3.UP*.47,b+br*centre-Vector3.UP*.47,right-left,Color.WHITE,.9)
			for side in [left+.2,right-.2]:
				batch.beam("metal",a+ar*side+Vector3.UP*1.1,b+br*side+Vector3.UP*1.1,.065)
				batch.beam("metal",a+ar*side+Vector3.UP*.55,b+br*side+Vector3.UP*.55,.055)
				batch.beam("metal",a+ar*side,a+ar*side+Vector3.UP*1.1,.065)
				batch.beam("metal",a+ar*side-Vector3.UP*.85,b+br*side-Vector3.UP*.85,.22,Color.WHITE,.8)
			# A continuous supporting wall at the banks, piers at <= 25 m centres.
			var abutment:=absf(chain-interval.span.start)<5 or absf(chain-interval.span.end)<5
			var pier:=floori(lerpf(edge.chainage_start,edge.chainage_end,sa/edge.length)/25)!=floori(lerpf(edge.chainage_start,edge.chainage_end,sb/edge.length)/25)
			if abutment or pier:
				var bottom: float=minf(geo.height_at(p.x+origin.x,p.z+origin.z)-1.5,p.y-3)
				if interval.span.water_height!=null:bottom=minf(bottom,interval.span.water_height-2)
				var height:=p.y-.6-bottom
				var offsets: Array=[centre] if abutment or right-left<12 else [lerpf(left,right,.25),lerpf(left,right,.75)]
				for offset in offsets:
					var base: Vector3=p+section.right*offset;base.y=bottom+height*.5
					batch.box("concrete",base,Vector3((right-left) if abutment else 2.0,height,2.0),Color.WHITE,Basis.looking_at(graph.tangent(eid,mid,1)))
				if not abutment:batch.beam("concrete",p+section.right*(left+.5)-Vector3.UP*.95,p+section.right*(right-.5)-Vector3.UP*.95,1.3,Color.WHITE,.65)
