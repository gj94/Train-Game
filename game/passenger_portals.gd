extends RefCounted
## Open only the platform-side passenger doors. Closed source geometry is retained.
static var _shaders:={}
static var _materials:={}
static var _doors:={}
var meshes: Array[MeshInstance3D]=[]
var leaves:=[]
var model_key:=""
var last:=Vector2(INF,INF)
var positions:=[]

func _init(model: Node3D, key: String, spec: Dictionary) -> void:
	model_key=key
	if spec.passengers.is_empty():return
	if _doors.is_empty():_doors=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/exterior_doors.json"))
	var floor: float=spec.passengers[0].position[1]-.08
	positions=_doors.get(key,{}).get("doors",[]).filter(func(d):return not (key=="vb_dtc" and absf(d.point[0])>1.61))
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("Shadow_"):continue
		meshes.append(mesh)
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			if not source is ShaderMaterial:continue
			var identity: String=key+"/"+str(mesh.name)+"/"+str(i)
			if not _materials.has(identity):
				var material: ShaderMaterial=source.duplicate()
				var shader_id: String=source.shader.resource_path
				if not _shaders.has(shader_id):
					var shader:=Shader.new()
					var code: String=source.shader.code
					code=code.replace("void vertex() {","uniform mat4 passenger_from_mesh;\nuniform vec2 passenger_vertical;\ninstance uniform vec4 passenger_openings;\nvarying vec3 passenger_local;\nvoid vertex() {\n passenger_local=(passenger_from_mesh*vec4(VERTEX,1.0)).xyz;")
					code=code.replace("void fragment() {","void fragment() {\n if (passenger_openings.y>0.001 && passenger_local.x*passenger_openings.x>1.42 && passenger_local.y>passenger_vertical.x && passenger_local.y<passenger_vertical.y && min(abs(passenger_local.z-passenger_openings.z),abs(passenger_local.z-passenger_openings.w))<0.40*passenger_openings.y) { discard; }")
					shader.code=code;_shaders[shader_id]=shader
				material.shader=_shaders[shader_id]
				material.set_shader_parameter("passenger_from_mesh",model.global_transform.affine_inverse()*mesh.global_transform)
				material.set_shader_parameter("passenger_vertical",Vector2(floor,floor+1.93))
				_materials[identity]=material
			mesh.set_surface_override_material(i,_materials[identity])
	for side in [-1,1]:
		var ds:=indices(side)
		for index in ds:
			var d: Dictionary=positions[index]
			var hinge:=Node3D.new();model.add_child(hinge)
			hinge.position=Vector3(d.point[0],floor,d.point[1]-.39)
			var panel:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.035,1.91,.78);panel.mesh=box
			panel.position=Vector3(0,.955,.39)
			var paint:=StandardMaterial3D.new()
			paint.albedo_color=Color("52667e") if key.begins_with("icf") else (Color("e6e6e2") if key.begins_with("vb") else Color("96282b"))
			paint.roughness=.55;paint.metallic=.3;panel.material_override=paint;hinge.add_child(panel)
			var pane:=MeshInstance3D.new();var window:=BoxMesh.new();window.size=Vector3(.045,.52,.43);pane.mesh=window;pane.position=Vector3(0,1.35,.39)
			var glass:=StandardMaterial3D.new();glass.albedo_color=Color("344c56");glass.metallic=.4;glass.roughness=.22;pane.material_override=glass;hinge.add_child(pane)
			hinge.visible=false
			leaves.append({node=hinge,side=side,z=hinge.position.z})

func indices(side: int) -> Array:
	var found:=[]
	for i in positions.size():
		if signi(positions[i].point[0])==side:found.append(i)
	found.sort_custom(func(a,b):return positions[a].point[1]<positions[b].point[1])
	return [found[0],found[-1]] if found.size()>1 else found

func update(side: int, amount: float) -> void:
	if last.is_equal_approx(Vector2(side,amount)):return
	last=Vector2(side,amount)
	var ds:=indices(side)
	var openings:=Vector4(side,amount,positions[ds[0]].point[1],positions[ds[-1]].point[1]) if not ds.is_empty() else Vector4.ZERO
	for mesh in meshes:mesh.set_instance_shader_parameter("passenger_openings",openings)
	for leaf in leaves:
		leaf.node.visible=leaf.side==side and amount>.001
		if model_key.begins_with("vb"):
			leaf.node.position.z=leaf.z+amount*.88
			leaf.node.position.x=leaf.side*(1.61+amount*.04)
		else:leaf.node.rotation.y=leaf.side*amount*PI*.5
