extends RefCounted
## Pure geometry shared by the moving bridge, on-foot handoff and its tests.
const Nav := preload("res://game/interior_navigation.gd")
static var profiles: Dictionary = {}

static func load_profiles() -> Dictionary:
	if profiles.is_empty():
		profiles=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/walkways_open.json"))
		for profile in profiles.values():profile.gangway_ends=profile.gangway_ends.map(func(end):return int(end))
	return profiles

static func neighbour(formation: Array, index: int, end: int) -> int:
	var data:=load_profiles()
	if index<0 or index>=formation.size() or end not in [-1,1]:return -1
	var entry: Dictionary=formation[index]
	if not data.has(entry.model) or end not in data[entry.model].gangway_ends:return -1
	var other: int=index+end*(-1 if entry.reverse else 1)
	if other<0 or other>=formation.size():return -1
	var other_end: int=-end*(-1 if entry.reverse else 1)*(-1 if formation[other].reverse else 1)
	if not data.has(formation[other].model) or other_end not in data[formation[other].model].gangway_ends:return -1
	return other

static func end_for(formation: Array, index: int, other: int) -> int:
	return (1 if other>index else -1)*(-1 if formation[index].reverse else 1)

static func connected_ends(formation: Array, index: int) -> Array:
	var result:=[]
	for end in [-1,1]:
		if neighbour(formation,index,end)>=0:result.append(end)
	return result

static func valid_saved_bridge(formation: Array, car: int, bridge) -> bool:
	if not bridge is Dictionary:return false
	if bridge.is_empty():return true
	for key in ["a","b","exit","entry"]:
		if not bridge.get(key) is int:return false
	if car<0 or car>=formation.size() or bridge.b<0 or bridge.b>=formation.size():return false
	if bridge.a!=car or neighbour(formation,car,bridge.exit)!=bridge.b:return false
	if bridge.entry!=end_for(formation,bridge.b,car):return false
	for key in ["u","lateral"]:
		if not (bridge.get(key) is float or bridge.get(key) is int) or not is_finite(bridge[key]):return false
	if bridge.u<0 or bridge.u>1 or absf(bridge.lateral)>.3001:return false
	if not bridge.get("from") is Vector3 or not bridge.get("to") is Vector3:return false
	return bridge.from.is_equal_approx(local_end(formation[car].model,bridge.exit)) and bridge.to.is_equal_approx(local_end(formation[bridge.b].model,bridge.entry))

static func local_end(model: String, end: int) -> Vector3:
	var profile: Dictionary=load_profiles()[model]
	return Vector3(0,profile.gangway_floor,end*profile.gangway_join)

static func frame(a: Transform3D, a_end: Vector3, a_sign: int, b: Transform3D, b_end: Vector3, b_sign: int, u: float, lateral: float=0.0) -> Transform3D:
	# +Z always means onward through this connection, even in the middle of a
	# reversed VB formation. Endpoint frames exactly match their coach floors.
	var from_basis:=a.basis*Basis(Vector3.UP,PI if a_sign<0 else 0.0)
	var to_basis:=b.basis*Basis(Vector3.UP,PI if b_sign>0 else 0.0)
	var basis:=from_basis.orthonormalized().slerp(to_basis.orthonormalized(),clampf(u,0,1))
	return Transform3D(basis,(a*a_end).lerp(b*b_end,clampf(u,0,1))+basis.x*lateral)

static func look_in_frame(old_frame: Basis, new_frame: Basis, look: Vector2) -> Vector2:
	var facing:=new_frame.inverse()*(old_frame*Basis.from_euler(Vector3(look.y,look.x,0))*Vector3.FORWARD)
	return Vector2(atan2(-facing.x,-facing.z),asin(clampf(facing.normalized().y,-1,1)))

static func navigation(model: String, ends: Array, closed: Dictionary):
	var opened: Dictionary=load_profiles()[model].duplicate(true)
	var original:=Nav.new(closed)
	var join: float=opened.gangway_join
	# Closed/unconnected ends keep their original wall and floor boundary. The
	# interior passenger doors can be open without opening a rake end to space.
	for row in opened.standing.size():
		var z: float=opened.origin[1]+(row+.5)*opened.step
		if absf(z)<join-1.2 or signi(z) in ends:continue
		for col in opened.width:
			var p:=Vector2(opened.origin[0]+(col+.5)*opened.step,z)
			opened.standing[row][col]="1" if original.allowed(p) else "0"
			opened.crouching[row][col]="1" if original.allowed(p,true) else "0"
	return Nav.new(opened)
