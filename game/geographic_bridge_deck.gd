extends RefCounted
## Actual track footprints own their bridge slabs. Shared chainage is not a
## common cross-section in a yard: diverging roads can be metres ahead/behind.
const HALF_WIDTH:=4.2
const DEPTH:=.9

static func strips(graph: TrackGraph,eid: String,lo: float,hi: float,origin: Vector3) -> Array:
	var e: Dictionary=graph.edges[eid]
	var cuts: Array[float]=[lo]
	for s in e.cum:
		if s>lo and s<hi:cuts.append(s)
	cuts.append(hi)
	var result:=[]
	for j in range(1,cuts.size()):
		var count:=maxi(1,ceili((cuts[j]-cuts[j-1])/8))
		for k in count:
			var sa:=lerpf(cuts[j-1],cuts[j],float(k)/count)
			var sb:=lerpf(cuts[j-1],cuts[j],float(k+1)/count)
			if sb-sa<.001:continue
			var a:=graph.position_relative(eid,sa,origin);var b:=graph.position_relative(eid,sb,origin)
			var ar:=side(graph,eid,sa);var br:=side(graph,eid,sb)
			var ring:=PackedVector2Array()
			for p in [a-ar*HALF_WIDTH,b-br*HALF_WIDTH,b+br*HALF_WIDTH,a+ar*HALF_WIDTH]:ring.append(Vector2(p.x,p.z))
			var bounds:=Rect2(ring[0],Vector2.ZERO)
			for p in ring:bounds=bounds.expand(p)
			result.append({ring=ring,bounds=bounds,a=a,b=b,ar=ar,br=br,lo=sa,hi=sb})
	return result

static func side(graph: TrackGraph,eid: String,s: float) -> Vector3:
	var before:=graph.tangent(eid,maxf(0,s-.01),1);before.y=0;before=before.normalized()
	var after:=graph.tangent(eid,minf(graph.edges[eid].length,s+.01),1);after.y=0;after=after.normalized()
	var normal:=(before+after).normalized().cross(Vector3.UP)
	# Miter the two strips at a polyline vertex rather than leave a triangular
	# slit on the outside of a bend. The route has no reversal within an edge.
	return normal/maxf(.5,normal.dot(after.cross(Vector3.UP)))

static func peers(graph: TrackGraph,layout,eid: String,span: Dictionary,origin: Vector3) -> Array:
	var roads:={};var result:=[]
	for key in range(floori(span.start/250),floori(span.end/250)+1):
		for road: String in layout.bins.get(key,[]):
			if road<eid:roads[road]=true
	var ordered:=roads.keys();ordered.sort()
	for road: String in ordered:
		var e: Dictionary=graph.edges[road]
		var scale: float=e.length/(e.chainage_end-e.chainage_start)
		var lo: float=maxf(0,(span.start-e.chainage_start)*scale)
		var hi: float=minf(e.length,(span.end-e.chainage_start)*scale)
		if hi>lo:result.append_array(strips(graph,road,lo,hi,origin))
	return result

static func visible_parts(strip: Dictionary,others: Array) -> Array:
	var parts: Array=[strip.ring]
	for other in others:
		if not strip.bounds.intersects(other.bounds):continue
		var next:=[]
		for part in parts:next.append_array(subtract_convex(part,other.ring))
		parts=next
		if parts.is_empty():break
	return parts

static func half_plane(poly: PackedVector2Array,a: Vector2,b: Vector2,sign_value: float) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if poly.size()<3:return result
	for i in poly.size():
		var p:=poly[i];var q:=poly[(i+1)%poly.size()]
		var dp: float=(b-a).cross(p-a)*sign_value;var dq: float=(b-a).cross(q-a)*sign_value
		if dp>=0:result.append(p)
		if (dp<0)!=(dq<0):result.append(p.lerp(q,dp/(dp-dq)))
	return result

static func subtract_convex(poly: PackedVector2Array,cut: PackedVector2Array) -> Array:
	# Boolean polygons can return a hole contour when a shorter strip is wholly
	# inside another. Triangulating that contour alone would refill the hole.
	# Peel disjoint convex outside pieces instead, retaining no hole contours.
	var remaining:=poly;var result:=[];var area:=0.0
	for i in cut.size():area+=cut[i].cross(cut[(i+1)%cut.size()])
	var sign_value:=1.0 if area>0 else -1.0
	for i in cut.size():
		var a:=cut[i];var b:=cut[(i+1)%cut.size()]
		var outside:=half_plane(remaining,a,b,-sign_value)
		if outside.size()>=3:result.append(outside)
		remaining=half_plane(remaining,a,b,sign_value)
		if remaining.size()<3:break
	return result

static func height(strip: Dictionary,p: Vector2) -> float:
	var a:=Vector2(strip.a.x,strip.a.z);var b:=Vector2(strip.b.x,strip.b.z)
	var t:=clampf((p-a).dot(b-a)/a.distance_squared_to(b),0,1)
	return lerpf(strip.a.y,strip.b.y,t)-.02

static func slab(batch,strip: Dictionary,ring: PackedVector2Array) -> void:
	var indices:=Geometry2D.triangulate_polygon(ring)
	if indices.is_empty():return
	var top: Array[Vector3]=[]
	for p in ring:top.append(Vector3(p.x,height(strip,p),p.y))
	for i in range(0,indices.size(),3):
		var a:=top[indices[i]];var b:=top[indices[i+1]];var c:=top[indices[i+2]]
		var cross_product:=(c-a).cross(b-a)
		if cross_product.length_squared()<.000000000001:continue
		var normal:=cross_product.normalized()
		if normal.y<0:normal=-normal
		batch.triangle("concrete",a,b,c,normal)
		batch.triangle("concrete",a-Vector3.UP*DEPTH,b-Vector3.UP*DEPTH,c-Vector3.UP*DEPTH,-normal)
	for i in top.size():
		var a:=top[i];var b:=top[(i+1)%top.size()]
		if a.distance_squared_to(b)<.00000001:continue
		# Only exposed longitudinal sides and span/chunk end caps need walls.
		# Boolean partition edges and ordinary polyline joints are internal.
		var pa:=Vector2(a.x,a.z);var pb:=Vector2(b.x,b.z);var exposed:=false
		for edge_index in [0,2]+([1] if strip.get("cap_end",true) else [])+([3] if strip.get("cap_start",true) else []):
			var first: Vector2=strip.ring[edge_index];var last: Vector2=strip.ring[(edge_index+1)%4]
			if pa.distance_squared_to(Geometry2D.get_closest_point_to_segment(pa,first,last))<.00000001 and pb.distance_squared_to(Geometry2D.get_closest_point_to_segment(pb,first,last))<.00000001:exposed=true;break
		if not exposed:continue
		batch.quad("concrete",a,b,b-Vector3.UP*DEPTH,a-Vector3.UP*DEPTH,(b-a).cross(Vector3.DOWN).normalized())

static func railing_clear(layout,a: Vector3,b: Vector3,origin: Vector3) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)))
	for i in range(steps+1):
		if not layout.clearance.clear_point(a.lerp(b,float(i)/steps)+origin,3.0):return false
	return true

static func pier_clear(geo,ring: PackedVector2Array,top: float,bottom: float) -> bool:
	# Road clearance knows carriageway widths; its rendered shoulder extends
	# another 65 cm. Expand the candidate pier for that shoulder plus rounding.
	for expanded in Geometry2D.offset_polygon(ring,.7,Geometry2D.JOIN_MITER):
		if not preload("res://game/geographic_bridge_clearance.gd").clear(geo,expanded,top,bottom):return false
	return true

static func draw(batch,graph: TrackGraph,geo,layout,eid: String,interval: Dictionary,origin: Vector3) -> void:
	var others:=peers(graph,layout,eid,interval.span,origin)
	var edge: Dictionary=graph.edges[eid]
	for strip in strips(graph,eid,interval.start,interval.end,origin):
		strip.cap_start=absf(strip.lo-interval.start)<.001;strip.cap_end=absf(strip.hi-interval.end)<.001
		for part in visible_parts(strip,others):slab(batch,strip,part)
		# Under-track piers stay on each actual centreline, spaced on a common
		# chainage grid. Never span a diverging yard with a misplaced wide wall.
		var ca: float=lerpf(edge.chainage_start,edge.chainage_end,strip.lo/edge.length)
		var cb: float=lerpf(edge.chainage_start,edge.chainage_end,strip.hi/edge.length)
		if floori(ca/25)==floori(cb/25):continue
		var p: Vector3=(strip.a+strip.b)*.5
		var bottom: float=minf(geo.height_at(p.x+origin.x,p.z+origin.z)-1.5,p.y-3)
		if interval.span.water_height!=null:bottom=minf(bottom,interval.span.water_height-2)
		var depth: float=p.y-.6-bottom
		var basis:=Basis.looking_at((strip.b-strip.a).normalized())
		var ring:=PackedVector2Array()
		for corner in [Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(1,0,1),Vector3(-1,0,1)]:
			var q: Vector3=p+basis*corner+origin;ring.append(Vector2(q.x,q.z))
		if pier_clear(geo,ring,p.y-.6,bottom):
			batch.box("concrete",Vector3(p.x,bottom+depth*.5,p.z),Vector3(2,depth,2),Color.WHITE,basis)
	# Guard beams use their own 8 m cadence, not every 2 m rail-polyline knot.
	# Their complete footprints still pass the railway clearance test.
	var count:=maxi(1,ceili((interval.end-interval.start)/8))
	for i in count:
		var sa:=lerpf(interval.start,interval.end,float(i)/count);var sb:=lerpf(interval.start,interval.end,float(i+1)/count)
		var p:=graph.position_relative(eid,sa,origin);var q:=graph.position_relative(eid,sb,origin)
		for sign_value in [-1,1]:
			var a: Vector3=p+side(graph,eid,sa)*(HALF_WIDTH-.2)*sign_value
			var b: Vector3=q+side(graph,eid,sb)*(HALF_WIDTH-.2)*sign_value
			if not railing_clear(layout,a,b,origin):continue
			batch.beam("metal",a+Vector3.UP*1.1,b+Vector3.UP*1.1,.065)
			batch.beam("metal",a+Vector3.UP*.55,b+Vector3.UP*.55,.055)
			var posts:=maxi(1,ceili(a.distance_to(b)/3))
			for j in posts:
				var post:=a.lerp(b,float(j)/posts);batch.beam("metal",post,post+Vector3.UP*1.1,.065)
			batch.beam("metal",a-Vector3.UP*.85,b-Vector3.UP*.85,.22,Color.WHITE,.8)
