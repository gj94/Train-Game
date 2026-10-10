extends RefCounted
## Shared low-cost, bent 3D blades; no billboard grass cards or flat planes.
static func mesh(material: Material,blades: int=384,width_scale: float=1.0) -> ArrayMesh:
	var batch=preload("res://game/geographic_mesh.gd").new()
	var rng:=RandomNumberGenerator.new();rng.seed=90613
	for i in blades:
		var theta:=rng.randf()*TAU
		var radius:=sqrt(rng.randf())*1.75
		var base:=Vector3(cos(theta)*radius,-.025,sin(theta)*radius)
		var angle:=rng.randf()*TAU
		var direction:=Vector3(cos(angle),0,sin(angle))
		var across:=direction.cross(Vector3.UP)*rng.randf_range(.004,.012)*width_scale
		var height:=rng.randf_range(.09,.29)
		var bend:=direction*rng.randf_range(.035,.13)
		var middle:=base+Vector3.UP*height*.66+bend*.30
		var tip:=base+Vector3.UP*height+bend
		var color:=Color(.075,.145,.028) if i%11 else Color(.16,.15,.052)
		color*=rng.randf_range(.72,1.22);color.a=1
		var normal: Vector3=direction.lerp(Vector3.UP,.45).normalized()
		batch.triangle("grass",base-across,base+across,middle-across*.55,normal,color)
		batch.triangle("grass",base+across,middle+across*.55,middle-across*.55,normal,color)
		batch.triangle("grass",middle-across*.55,middle+across*.55,tip,normal,color)
	var st: SurfaceTool=batch.surfaces.grass
	st.generate_tangents();st.index()
	var result:=st.commit();result.surface_set_material(0,material)
	return result

static func flush(library) -> void:
	var kinds:=["coastal_grass","coastal_grass_medium","coastal_grass_far"]
	var starts:=[0.0,50.0,90.0];var ends:=[50.0,90.0,125.0]
	for group in preload("res://game/spatial_batches.gd").split(library.placements.coastal_grass,48).values():
		for level in 3:
			var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true
			mm.mesh=library.meshes[kinds[level]][0].mesh;mm.instance_count=group.transforms.size()
			for i in group.transforms.size():
				mm.set_instance_transform(i,group.transforms[i])
				var p: Vector3=group.origin+group.transforms[i].origin
				var seed:=float(posmod(roundi(p.x*17+p.z*31),127))/126.0
				mm.set_instance_custom_data(i,Color(seed,.5,.5,1))
			var node:=MultiMeshInstance3D.new();node.multimesh=mm;node.position=group.origin
			node.name="GrassLOD_"+str(level);node.set_meta("grass_lod",level)
			node.set_meta("scenery_kind","coastal_grass")
			node.visibility_range_begin=starts[level];node.visibility_range_end=ends[level]
			node.visibility_range_begin_margin=12;node.visibility_range_end_margin=35 if level==2 else 12
			node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			library.view.root.add_child(node)

static func set_reference(root: Node,enabled: bool) -> void:
	for node in root.find_children("GrassLOD_*","MultiMeshInstance3D",true,false):
		var level: int=node.get_meta("grass_lod")
		if level==0:
			node.visibility_range_end=125.0 if enabled else 50.0
			node.visibility_range_end_margin=35 if enabled else 12
		else:node.visible=not enabled
