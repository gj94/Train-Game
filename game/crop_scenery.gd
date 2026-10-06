extends RefCounted
## Close crop geometry is shared in small tiles; distant fields use the ground shader.
const Cells:=preload("res://game/spatial_batches.gd")
const SIZE:=8.0
func build(view,plan) -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=2026100703
	for stage in [2,3]:
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 21:
			for col in 21:
				var p:=Vector3((col+.5)*SIZE/21+rng.randf_range(-.07,.07),0,(row+.5)*SIZE/21+rng.randf_range(-.07,.07))
				var h:=rng.randf_range(.34,.58) if stage==2 else rng.randf_range(.53,.78)
				var colour:=Color(.075,.14,.018) if stage==2 else Color(.20,.19,.040)
				colour=colour.lightened(rng.randf_range(0,.026))
				for blade in 5:
					var angle:=rng.randf()*TAU
					var right:=Vector3(cos(angle),0,sin(angle))*.018
					var bend:=Vector3(-sin(angle),0,cos(angle))*h*.38
					var middle:=p+Vector3.UP*h*.62+bend*.20
					var tip:=p+Vector3.UP*h+bend
					for vertex in [p-right,p+right,middle-right*.65,middle-right*.65,p+right,middle+right*.65,middle-right*.65,middle+right*.65,tip]:
						st.set_color(colour)
						st.add_vertex(vertex)
		st.generate_normals()
		var mesh:=st.commit()
		var material:=ShaderMaterial.new()
		material.shader=load("res://game/shaders/scenery_foliage.gdshader")
		material.set_shader_parameter("height_scale",.85)
		material.set_shader_parameter("wind_strength",.055)
		material.set_shader_parameter("translucency",.12)
		mesh.surface_set_material(0,material)
		var transforms:=[]
		for field in plan.fields:
			if field.stage!=stage: continue
			var rect: Rect2=field.rect
			for x in range(floori((rect.size.x-1.2)/SIZE)):
				for z in range(floori((rect.size.y-1.2)/SIZE)):
					transforms.append(Transform3D(Basis.IDENTITY,Vector3(rect.position.x+.6+x*SIZE,.025,rect.position.y+.6+z*SIZE)))
		for group in Cells.split(transforms,64).values():
			var mm:=MultiMesh.new()
			mm.transform_format=MultiMesh.TRANSFORM_3D
			mm.mesh=mesh
			mm.instance_count=group.transforms.size()
			for i in group.transforms.size(): mm.set_instance_transform(i,group.transforms[i])
			var node:=MultiMeshInstance3D.new()
			node.name="Rice_"+str(stage)
			node.position=group.origin
			node.multimesh=mm
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.visibility_range_end=165
			node.visibility_range_end_margin=24
			node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			view.root.add_child(node)
