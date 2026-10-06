extends RefCounted
## Common spatial batches for ground planes, walls, lanes and street furniture.
const Cells:=preload("res://game/spatial_batches.gd")
var view
var groups:={}
func _init(world_view) -> void: view=world_view
func box(size: Vector3,p: Vector3,mat: Material,rotation: Vector3=Vector3.ZERO) -> void:
	_add("box",Transform3D(Basis.from_euler(rotation).scaled_local(size),p),mat)
func line(a: Vector3,b: Vector3,width: float,height: float,mat: Material) -> void:
	var delta:=b-a
	if delta.length_squared()<.00001: return
	box(Vector3(width,height,delta.length()),(a+b)*.5,mat,Basis.looking_at(delta,Vector3.UP).get_euler())
func plane(rect: Rect2,y: float,mat: Material) -> void:
	_add("plane",Transform3D(Basis.IDENTITY.scaled(Vector3(rect.size.x,1,rect.size.y)),Vector3(rect.get_center().x,y,rect.get_center().y)),mat)
func road(a: Vector3,b: Vector3,width: float,mat: Material) -> void:
	var delta:=b-a
	if delta.length_squared()<.00001: return
	_add("plane",Transform3D(Basis.looking_at(delta,Vector3.UP).scaled_local(Vector3(width,1,delta.length())),(a+b)*.5),mat)
func _add(kind: String,pose: Transform3D,mat: Material) -> void:
	var key:=kind+str(mat.get_instance_id())
	if not groups.has(key): groups[key]={kind=kind,mat=mat,transforms=[]}
	groups[key].transforms.append(pose)
func flush() -> void:
	for source in groups.values():
		var mesh: Mesh
		if source.kind=="plane":
			mesh=PlaneMesh.new()
			mesh.size=Vector2.ONE
		else:
			mesh=BoxMesh.new()
			mesh.size=Vector3.ONE
		mesh.surface_set_material(0,source.mat)
		for group in Cells.split(source.transforms).values():
			var mm:=MultiMesh.new()
			mm.transform_format=MultiMesh.TRANSFORM_3D
			mm.use_custom_data=true
			mm.mesh=mesh
			mm.instance_count=group.transforms.size()
			for i in group.transforms.size():
				mm.set_instance_transform(i,group.transforms[i])
				var p: Vector3=group.transforms[i].origin+group.origin
				var seed:=float(posmod(roundi(p.x*17+p.z*31),127))/126.0
				mm.set_instance_custom_data(i,Color(seed,float(posmod(roundi(p.x+p.z),7))/6.0,0,1))
			var batch:=MultiMeshInstance3D.new()
			batch.name="District_"+source.kind
			batch.position=group.origin
			batch.multimesh=mm
			batch.visibility_range_end=2000
			batch.visibility_range_end_margin=120
			if source.kind=="plane": batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			view.root.add_child(batch)
