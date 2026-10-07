extends RefCounted
## Material-batched geometry in metres, with explicit clockwise front faces.
var surfaces := {}
func surface(kind: String) -> SurfaceTool:
	if not surfaces.has(kind):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[kind]=tool
	return surfaces[kind]
func triangle(kind: String,a: Vector3,b: Vector3,c: Vector3,normal: Vector3,color: Color=Color.WHITE,uv: Array=[]) -> void:
	var verts := [a,b,c]
	var coords := uv if uv.size()==3 else [Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)]
	if (b-a).cross(c-a).dot(normal)>0:
		verts=[a,c,b]; coords=[coords[0],coords[2],coords[1]]
	var st := surface(kind)
	for i in 3:
		st.set_normal(normal)
		st.set_color(color)
		st.set_uv(coords[i])
		st.add_vertex(verts[i])
func quad(kind: String,a: Vector3,b: Vector3,c: Vector3,d: Vector3,normal: Vector3,color: Color=Color.WHITE,uv: Array=[]) -> void:
	var coords := uv if uv.size()==4 else [Vector2(a.x+a.z,a.y),Vector2(b.x+b.z,b.y),Vector2(c.x+c.z,c.y),Vector2(d.x+d.z,d.y)]
	triangle(kind,a,b,c,normal,color,[coords[0],coords[1],coords[2]])
	triangle(kind,a,c,d,normal,color,[coords[0],coords[2],coords[3]])
func box(kind: String,p: Vector3,size: Vector3,color: Color=Color.WHITE,basis: Basis=Basis.IDENTITY) -> void:
	var v := []
	for s in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]:
		v.append(p+basis*(s*size*.5))
	for face in [[0,1,2,3,Vector3.FORWARD],[4,5,6,7,Vector3.BACK],[0,4,7,3,Vector3.LEFT],[1,5,6,2,Vector3.RIGHT],[0,1,5,4,Vector3.DOWN],[3,2,6,7,Vector3.UP]]:
		quad(kind,v[face[0]],v[face[1]],v[face[2]],v[face[3]],basis*face[4],color)
func beam(kind: String,a: Vector3,b: Vector3,width: float,color: Color=Color.WHITE,depth: float=-1) -> void:
	if a.distance_squared_to(b)<.000001: return
	var along := (b-a).normalized()
	var up := Vector3.UP if absf(along.dot(Vector3.UP))<.95 else Vector3.RIGHT
	var basis := Basis.looking_at(along,up)
	box(kind,(a+b)*.5,Vector3(width,depth if depth>0 else width,a.distance_to(b)),color,basis)
func finish(parent: Node3D,materials: Dictionary,label: String) -> void:
	for kind in surfaces:
		var st: SurfaceTool=surfaces[kind]
		st.generate_tangents()
		st.index()
		var node := MeshInstance3D.new()
		node.name=label+"_"+kind
		node.mesh=st.commit()
		node.material_override=materials[kind]
		if kind=="architecture_detail":
			node.visibility_range_end=650
			node.visibility_range_end_margin=100
			node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if kind=="water": node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
	surfaces.clear()
