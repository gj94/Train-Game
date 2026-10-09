extends RefCounted
## Hip roofs keep a ridge along the longest facade instead of a pyramid apex.
static func draw(batch,ring: PackedVector2Array,centre: Vector2,height: float) -> void:
	var axis:=Vector2.RIGHT;var longest:=0.0;var shortest:=INF
	for i in ring.size():
		var edge:=ring[(i+1)%ring.size()]-ring[i]
		shortest=minf(shortest,edge.length())
		if edge.length()>longest:longest=edge.length();axis=edge.normalized()
	var half_ridge:=maxf(0,(longest-shortest)*.38)
	var rise:=clampf(shortest*.28,1.0,2.6)
	var roof:=Color(.46,.32,.21,2.0/15.0)
	for i in ring.size():
		var pa: Vector2=centre+(ring[i]-centre)*1.06
		var pb: Vector2=centre+(ring[(i+1)%ring.size()]-centre)*1.06
		var ra:=centre+axis*half_ridge*(1 if (pa-centre).dot(axis)>=0 else -1)
		var rb:=centre+axis*half_ridge*(1 if (pb-centre).dot(axis)>=0 else -1)
		var a:=Vector3(pa.x,height,pa.y);var b:=Vector3(pb.x,height,pb.y)
		var c:=Vector3(rb.x,height+rise,rb.y);var d:=Vector3(ra.x,height+rise,ra.y)
		var normal: Vector3=(b-a).cross(c-a).normalized()
		if normal.y<0:normal=-normal
		batch.triangle("architecture",a,b,c,normal,roof)
		if c.distance_squared_to(d)>.001:batch.triangle("architecture",a,c,d,normal,roof)
		batch.beam("architecture_detail",a,b,.09,Color(.25,.20,.14,9.0/15.0),.15)
	var ra:=centre-axis*half_ridge;var rb:=centre+axis*half_ridge
	batch.beam("architecture_detail",Vector3(ra.x,height+rise+.02,ra.y),Vector3(rb.x,height+rise+.02,rb.y),.16,roof,.12)
