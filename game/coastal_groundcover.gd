extends RefCounted
## Shared low-cost, bent 3D blades; no billboard grass cards or flat planes.
static func mesh(material: Material) -> ArrayMesh:
	var batch=preload("res://game/geographic_mesh.gd").new()
	var rng:=RandomNumberGenerator.new();rng.seed=90613
	for i in 384:
		var theta:=rng.randf()*TAU
		var radius:=sqrt(rng.randf())*1.75
		var base:=Vector3(cos(theta)*radius,-.025,sin(theta)*radius)
		var angle:=rng.randf()*TAU
		var direction:=Vector3(cos(angle),0,sin(angle))
		var across:=direction.cross(Vector3.UP)*rng.randf_range(.004,.012)
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
