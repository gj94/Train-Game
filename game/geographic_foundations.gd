extends RefCounted
## Match the triangles of the rendered 8 m ground grid, not an unrelated centre
## elevation. Skirts follow the terrain around every side of a level building.
static func surface_height(sample: Callable,x: float,z: float) -> float:
	var gx:=floorf(x/8)*8;var gz:=floorf(z/8)*8
	var u:=(x-gx)/8;var v:=(z-gz)/8
	var a: float=sample.call(gx,gz);var b: float=sample.call(gx+8,gz)
	var c: float=sample.call(gx+8,gz+8);var d: float=sample.call(gx,gz+8)
	return a+u*(b-a)+v*(c-b) if v<=u else a+u*(c-d)+v*(d-a)

static func outline(ring: PackedVector2Array,sample: Callable) -> Array:
	var result:=[]
	for i in ring.size():
		var a:=ring[i];var b:=ring[(i+1)%ring.size()]
		var count:=maxi(1,ceili(a.distance_to(b)/3))
		for j in count:
			var p:=a.lerp(b,float(j)/count)
			result.append(Vector3(p.x,surface_height(sample,p.x,p.y),p.y))
	return result

static func skirt(batch,points: Array,floor_y: float,kind: String="architecture") -> void:
	var color:=Color(.42,.43,.39,1.0/15.0) if kind=="architecture" else Color.WHITE
	for i in points.size():
		var a: Vector3=points[i];var b: Vector3=points[(i+1)%points.size()]
		var normal: Vector3=(b-a).normalized().cross(Vector3.UP)
		var low_a:=Vector3(a.x,minf(a.y-.25,floor_y-.15),a.z)
		var low_b:=Vector3(b.x,minf(b.y-.25,floor_y-.15),b.z)
		batch.quad(kind,low_a,low_b,Vector3(b.x,floor_y+.02,b.z),Vector3(a.x,floor_y+.02,a.z),normal,color)
		# Footprint winding varies in OSM; both retaining-wall faces stay visible.
		batch.quad(kind,low_b,low_a,Vector3(a.x,floor_y+.02,a.z),Vector3(b.x,floor_y+.02,b.z),-normal,color)
