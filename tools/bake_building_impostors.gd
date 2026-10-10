extends SceneTree
## Bake the actual game materials, including all six facade palettes.
const KINDS:=["tiled_house","tiled_cottage","kerala_bungalow","townhouse","shop_house","apartments_3","apartments_4","warehouse","balcony_villa"]
const TILE:=256
const OUT:="res://assets/models/scenery/impostors/"
func _initialize() -> void:call_deferred("bake")

func material(source: Material,normal: bool,palette: int) -> Material:
	assert(source is ShaderMaterial,"Building bake expects the game's authored shader")
	var result:=source.duplicate() as ShaderMaterial
	var code: String=source.shader.code
	code=code.replace("render_mode ","render_mode unshaded, ")
	code=code.replace("variation=INSTANCE_CUSTOM;","variation=vec4("+str((palette+.5)/6.0)+",.5,.5,1.0);")
	if normal:
		var start:=code.find("void fragment")
		var opening:=code.find("{",start);var depth:=1;var end:=opening+1
		while depth>0:
			if code[end]=="{":depth+=1
			elif code[end]=="}":depth-=1
			end+=1
		code=code.insert(end-1,"\nALBEDO=normalize((INV_VIEW_MATRIX*vec4(NORMAL,0.0)).xyz)*.5+.5; EMISSION=vec3(0.0);\n")
	var shader:=Shader.new();shader.code=code;result.shader=shader
	for parameter in source.shader.get_shader_uniform_list():
		result.set_shader_parameter(parameter.name,source.get_shader_parameter(parameter.name))
	return result

func bake() -> void:
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var viewport:=SubViewport.new();viewport.size=Vector2i(TILE,TILE)
	viewport.own_world_3d=true;viewport.transparent_bg=true
	viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage:=Node3D.new();viewport.add_child(stage)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0,0,0,0)
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	stage.add_child(environment)
	var view=preload("res://game/world_view.gd").new();view.root=stage
	var library=preload("res://game/scenery_library.gd").new(view)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.near=.05;camera.far=150;stage.add_child(camera)
	var catalog:={}
	for kind in KINDS:
		var model:=Node3D.new();stage.add_child(model)
		var parts: Array=library.asset(kind)
		var bounds:=AABB();var first:=true;var nodes:=[]
		for part in parts:
			var node:=MeshInstance3D.new();node.mesh=part.mesh;node.transform=part.transform
			model.add_child(node);nodes.append(node)
			var box: AABB=part.transform*part.mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var centre:=bounds.get_center()
		var width:=maxf(bounds.size.y,Vector2(bounds.size.x,bounds.size.z).length())*1.08
		camera.size=width
		for normal in [false,true]:
			var atlas:=Image.create(TILE*4,TILE*12,false,Image.FORMAT_RGBA8)
			atlas.fill(Color.TRANSPARENT)
			for palette in 6:
				for node in nodes:
					for surface in node.mesh.get_surface_count():
						node.set_surface_override_material(surface,material(node.mesh.surface_get_material(surface),normal,palette))
				for angle in 8:
					var theta:=angle*TAU/8
					camera.position=centre+Vector3(sin(theta),0,cos(theta))*65
					camera.look_at(centre)
					for frame in 4:await process_frame
					await RenderingServer.frame_post_draw
					var tile:=viewport.get_texture().get_image()
					tile.convert(Image.FORMAT_RGBA8)
					atlas.blit_rect(tile,Rect2i(0,0,TILE,TILE),Vector2i((angle%4)*TILE,(palette*2+1-angle/4)*TILE))
			var suffix:="_normal.png" if normal else "_albedo.png"
			atlas.save_png(OUT+kind+suffix)
		catalog[kind]={width=width,centre=[centre.x,centre.y,centre.z],size=[bounds.size.x,bounds.size.y,bounds.size.z],views=8,palettes=6,tile_pixels=TILE}
		model.free()
		print("BAKED_BUILDING ",kind)
	var file:=FileAccess.open(OUT+"buildings_catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog,"\t"))
	quit()
