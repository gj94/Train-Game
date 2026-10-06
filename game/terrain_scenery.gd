extends RefCounted
## Bounded terrain tiles and a metre-space land-use mask, independent of simulation.
const TILE:=400.0
const STEP:=25.0
func build(view) -> void:
	var xmin: float=view.world.scenery.get("x_min",-500.0)-1100
	var xmax: float=view.world.scenery.get("x_max",5300.0)+1100
	var bounds:=Rect2(xmin,-1700,xmax-xmin,3400)
	var material:=ShaderMaterial.new()
	material.shader=load("res://game/shaders/ground.gdshader")
	for pair in [["grass_albedo","leafy_grass","diff"],["grass_normal","leafy_grass","nor_gl"],["grass_rough","leafy_grass","rough"],["soil_albedo","red_laterite_soil_stones","diff"],["soil_normal","red_laterite_soil_stones","nor_gl"]]:
		material.set_shader_parameter(pair[0],view.ph_tex(pair[1],pair[2]))
	material.set_shader_parameter("noise_tex",view._noise_tex)
	material.set_shader_parameter("land_use",_land_use(view,bounds))
	material.set_shader_parameter("land_bounds",Vector4(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y))
	for x in range(floori(xmin/TILE),ceili(xmax/TILE)):
		for z in range(floori(-1700/TILE),ceili(1700/TILE)):
			var x0:=maxf(x*TILE,xmin)
			var x1:=minf((x+1)*TILE,xmax)
			var z0:=maxf(z*TILE,-1700)
			var z1:=minf((z+1)*TILE,1700)
			var xs:=PackedFloat32Array()
			var zs:=PackedFloat32Array()
			for i in range(ceili((x1-x0)/STEP)+1): xs.append(minf(x0+i*STEP,x1))
			for j in range(ceili((z1-z0)/STEP)+1): zs.append(minf(z0+j*STEP,z1))
			# Sample the canal's bed, waterline and bank explicitly, not at a 25 m guess.
			for canal in view.world.scenery.get("canals",[]):
				for offset in [-35,-26,-19,-10,0,10,19,26,35]:
					var coordinate: float=canal+offset
					if coordinate>x0 and coordinate<x1 and not xs.has(coordinate): xs.append(coordinate)
			xs.sort()
			var st:=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var origin:=Vector3(x0,0,z0)
			for zz in zs:
				for xx in xs:
					st.set_uv(Vector2(xx,zz))
					st.add_vertex(Vector3(xx,view.terrain_height(xx,zz),zz)-origin)
			for j in zs.size()-1:
				for i in xs.size()-1:
					var a:=j*xs.size()+i
					var b:=a+1
					var c:=a+xs.size()
					var d:=c+1
					for index in [a,b,c,c,b,d]: st.add_index(index)
			st.generate_normals()
			st.generate_tangents()
			var chunk:=MeshInstance3D.new()
			chunk.name="Terrain_%d_%d"%[x,z]
			chunk.mesh=st.commit()
			chunk.material_override=material
			chunk.position=origin
			chunk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			view.root.add_child(chunk)
func _land_use(view,bounds: Rect2) -> Texture2D:
	var image:=Image.create(4096,576,false,Image.FORMAT_R8)
	image.fill(Color.BLACK)
	if view.scenery_plan!=null:
		for item in view.scenery_plan.buildings+view.scenery_plan.roads:
			_paint(image,item.rect.grow(4.0),bounds,Color.WHITE)
		for item in view.scenery_plan.fields:
			_paint(image,item.rect.grow(1.8),bounds,Color(.4,.4,.4))
		for station in view.world.stations:
			_paint(image,Rect2(station.building.x-64,station.building.z-23,128,46),bounds,Color.WHITE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
func _paint(image: Image,rect: Rect2,bounds: Rect2,colour: Color) -> void:
	var size:=Vector2(image.get_width(),image.get_height())
	var start: Vector2=(rect.position-bounds.position)/bounds.size*size
	var end: Vector2=(rect.end-bounds.position)/bounds.size*size
	image.fill_rect(Rect2i(floori(start.x),floori(start.y),maxi(1,ceili(end.x)-floori(start.x)),maxi(1,ceili(end.y)-floori(start.y))),colour)
