extends Node3D
## Decorative road traffic follows the simulation clock without affecting rail logic.
const SPEED:=5.5
var world
var vehicles:=[]
var routes:=[]
var _last_time:=-1.0
var _last_camera_position:=Vector3.INF
func build(view,plan,library) -> void:
	world=view.world
	name="RoadTraffic"
	view.root.add_child(self)
	for loop in plan.traffic_loops:
		for reverse in [false,true]:
			var route:=make_route(loop,reverse)
			routes.append(route)
			var length:=route.get_baked_length()
			for index in 3:
				var kind: String=["hatchback","auto_rickshaw","motorcycle_rider"][(index+routes.size())%3]
				var car:=Node3D.new()
				car.name=kind
				add_child(car)
				for part in library.asset(kind):
					var mesh:=MeshInstance3D.new()
					mesh.mesh=part.mesh
					mesh.transform=part.transform
					car.add_child(mesh)
				vehicles.append({node=car,route=route,length=length,phase=length*(index+.18)/3.0,speed=SPEED})
	update_at(world.time)
func _process(_delta: float) -> void:
	if world==null: return
	var camera:=get_viewport().get_camera_3d()
	if world.time!=_last_time or (camera!=null and camera.global_position.distance_squared_to(_last_camera_position)>16): update_at(world.time)
func update_at(time: float) -> void:
	_last_time=time
	var camera:=get_viewport().get_camera_3d()
	if camera!=null: _last_camera_position=camera.global_position
	for vehicle in vehicles:
		var pose:=pose_at(vehicle.route,fposmod(time*vehicle.speed+vehicle.phase,vehicle.length))
		vehicle.node.visible=camera==null or pose.origin.distance_squared_to(camera.global_position)<800*800
		if vehicle.node.visible: vehicle.node.transform=pose
static func make_route(points: PackedVector3Array,reverse: bool=false) -> Curve3D:
	var corners:=Array(points)
	if reverse: corners.reverse()
	var curve:=Curve3D.new()
	curve.bake_interval=.65
	var radius:=4.4
	for i in corners.size():
		var corner: Vector3=corners[i]
		var incoming: Vector3=(corner-corners[posmod(i-1,corners.size())]).normalized()
		var outgoing: Vector3=(corners[(i+1)%corners.size()]-corner).normalized()
		var start:=corner-incoming*radius
		var finish:=corner+outgoing*radius
		# Two points per bend, joined by a circular-arc cubic approximation.
		curve.add_point(start,Vector3.ZERO,incoming*radius*.55228475)
		curve.add_point(finish,-outgoing*radius*.55228475,Vector3.ZERO)
	curve.add_point(curve.get_point_position(0))
	return curve
static func pose_at(route: Curve3D,distance: float) -> Transform3D:
	var length:=route.get_baked_length()
	var position:=route.sample_baked(fposmod(distance,length),true)
	var before:=route.sample_baked(fposmod(distance-.18,length),true)
	var after:=route.sample_baked(fposmod(distance+.18,length),true)
	var forward: Vector3=(after-before).normalized()
	position-=forward.cross(Vector3.UP)*1.05 # left-hand traffic
	position.y=.08
	return Transform3D(Basis.looking_at(forward,Vector3.UP),position)
