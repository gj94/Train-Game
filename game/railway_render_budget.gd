extends RefCounted
## Presentation-only budgets. Simulation and the 2D dispatcher never use these.
const CAMERA_HEIGHT := 60.0
const ORBIT_DISTANCE := 300.0
const VIEW_DISTANCE := 2200.0
const FOG_BEGIN := 1000.0
const FOG_END := 2050.0
const DETAIL_RADIUS := 1150.0
const RAIL_RADIUS := 1650.0
const STATION_RADIUS := 2000.0
const BACKGROUND_RADIUS := 2600.0
const CORRIDOR_WIDTH := 220.0

static func tile_distance_squared(key: Vector2i, size: float, focus: Vector3) -> float:
	var low:=Vector2(key.x*size,key.y*size)
	var p:=Vector2(focus.x,focus.z)
	return p.distance_squared_to(p.clamp(low,low+Vector2.ONE*size))

static func corridor_tiles(segments: Array) -> Dictionary:
	# Conservative segment bounds retain bends, station approaches and depots,
	# including tiles where no track midpoint happens to land.
	var result:={}
	for segment in segments:
		var a:=Vector2(segment.a.x,segment.a.z)
		var b:=Vector2(segment.b.x,segment.b.z)
		var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(CORRIDOR_WIDTH)
		for x in range(floori(bounds.position.x/512),floori(bounds.end.x/512)+1):
			for z in range(floori(bounds.position.y/512),floori(bounds.end.y/512)+1):
				result[Vector2i(x,z)]=true
	return result

static func bound_eye(eye: Vector3, ground: float) -> Vector3:
	eye.y=clampf(eye.y,ground+.35,ground+CAMERA_HEIGHT)
	return eye
