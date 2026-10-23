extends RefCounted
## Level masonry panels step down the plot; their bottom follows the terrain.
const Foundations:=preload("res://game/geographic_foundations.gd")
static func draw(c,a: Vector2,b: Vector2,height: float,width: float,color: Color) -> void:
	var count:=maxi(1,ceili(a.distance_to(b)/2.4))
	var side:=Vector2(-(b-a).y,(b-a).x).normalized()*width*.5
	var tops:=[]
	for i in count:
		var p:=a.lerp(b,i/float(count));var q:=a.lerp(b,(i+1)/float(count))
		var ring:=PackedVector2Array([p-side,q-side,q+side,p+side])
		var outline:=Foundations.outline(ring,c._ground)
		var top: float=outline.map(func(v):return v.y).max()+height
		var light:=Color(color.r*.72,color.g*.68,color.b*.60,0)
		for j in outline.size():
			var first: Vector3=outline[j];var last: Vector3=outline[(j+1)%outline.size()]
			var normal: Vector3=(last-first).normalized().cross(Vector3.UP)
			var low_a:=first-Vector3.UP*.18;var low_b:=last-Vector3.UP*.18
			var high_a:=Vector3(first.x,top,first.z);var high_b:=Vector3(last.x,top,last.z)
			c.batch.quad("architecture_detail",low_a,low_b,high_b,high_a,normal,color)
			c.batch.quad("architecture_detail",low_b,low_a,high_a,high_b,-normal,color)
		c.batch.beam("architecture_detail",Vector3(p.x,top+.035,p.y),Vector3(q.x,top+.035,q.y),width+.08,light,.07)
		tops.append(top)
	for i in count+1:
		var p:=a.lerp(b,i/float(count))
		var bottom:=Foundations.surface_height(c._ground,p.x,p.y)-.2
		var top: float=maxf(tops[maxi(0,i-1)],tops[mini(count-1,i)])+.14
		c.batch.box("architecture_detail",Vector3(p.x,(bottom+top)*.5,p.y),Vector3(width+.11,top-bottom,width+.11),color.lightened(.08))
