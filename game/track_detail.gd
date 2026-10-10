extends RefCounted
## Shared distant silhouettes; original running rails, gaps and pointwork stay intact.
static var meshes:={}
static func prepare() -> void:
	if not meshes.is_empty():return
	var ties:=SurfaceTool.new();ties.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(ties,Vector3(2.75,.201,.29),Vector3(0,.2205,0))
	meshes.sleeper=ties.commit()
	var clips:=SurfaceTool.new();clips.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0,1.0]:
		var x: float=side*.874
		_box(clips,Vector3(.30,.032,.205),Vector3(x,.340,0))
		for outer in [-1.0,1.0]:
			_box(clips,Vector3(.085,.022,.108),Vector3(x+outer*.107,.37,0))
	meshes.fastening=clips.commit()

static func _box(st: SurfaceTool,size: Vector3,position: Vector3) -> void:
	var box:=BoxMesh.new();box.size=size
	st.append_from(box,0,Transform3D(Basis.IDENTITY,position))

static func attach(near_node: MultiMeshInstance3D,label: String,far_distance: float,transforms: Array) -> void:
	if label not in ["Sleepers","TurnoutBearers","Fastenings"]:return
	var transition:=48.0 if label=="Fastenings" else 125.0
	var far:=near_node.duplicate() as MultiMeshInstance3D
	far.name="HLOD_"+label
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
	# Set the source mesh before allocation: worker-built buffers may upload immediately.
	mm.mesh=meshes.fastening if label=="Fastenings" else meshes.sleeper
	mm.instance_count=transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i,transforms[i])
		var tone:=.84+.16*fposmod(i*.618034,1)
		mm.set_instance_color(i,Color(tone,tone,tone))
	far.multimesh=mm
	far.visibility_range_begin=transition;far.visibility_range_begin_margin=18
	far.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	near_node.visibility_range_end=transition
	far.set_meta("full_detail_node",near_node)
	far.set_meta("full_detail_end",far_distance)
	near_node.get_parent().add_child(far)

static func set_reference(root: Node,enabled: bool) -> void:
	for node in root.find_children("HLOD_*","MultiMeshInstance3D",true,false):
		var near_node: MultiMeshInstance3D=node.get_meta("full_detail_node")
		near_node.visibility_range_end=float(node.get_meta("full_detail_end")) if enabled else node.visibility_range_begin
		node.visible=not enabled
