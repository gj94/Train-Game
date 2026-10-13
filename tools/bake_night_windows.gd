extends SceneTree
## Bake window-only masks from the same geometry/cameras as the daytime atlases.
## No replacement artwork: opaque walls and roofs occlude the original glazing.
const TILE:=256
var view
var library

func _initialize() -> void:call_deferred("bake")

func mask_material(source: Material) -> Material:
	var mat:=ShaderMaterial.new();var shader:=Shader.new()
	var architecture: bool=source is ShaderMaterial and source.shader.resource_path.ends_with("scenery_architecture.gdshader")
	var glass: bool=source!=null and source.get_meta("scenery_window",false)
	var shutter: bool=source!=null and source.get_meta("shuttered_window",false)
	shader.code="shader_type spatial; render_mode unshaded, cull_disabled; void fragment() { ALBEDO=vec3("+(
		"float(int(floor(COLOR.a*15.0+.5))==4)" if architecture else ("0.07" if shutter else ("1.0" if glass else "0.0")))+ "); }"
	mat.shader=shader;return mat

func bake() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	var viewport:=SubViewport.new();viewport.size=Vector2i(TILE,TILE)
	viewport.own_world_3d=true;viewport.transparent_bg=false
	viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage:=Node3D.new();viewport.add_child(stage)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color.BLACK
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR;stage.add_child(environment)
	view=preload("res://game/world_view.gd").new();view.root=stage
	library=preload("res://game/scenery_library.gd").new(view)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.near=.05;camera.far=150;stage.add_child(camera)
	var masks:=[]
	for collection in ["scenery","trackside"]:
		var folder: String="res://assets/models/"+collection+"/impostors/"
		var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+("buildings_catalog.json" if collection=="scenery" else "catalog.json")))
		for kind: String in catalogue:
			if collection=="trackside" and not kind.begins_with("tf3_BLD_"):continue
			var entry: Dictionary=catalogue[kind]
			var model:=Node3D.new();stage.add_child(model)
			for part in library.asset(kind):
				var node:=MeshInstance3D.new();node.mesh=part.mesh;node.transform=part.transform;model.add_child(node)
				for surface in node.mesh.get_surface_count():
					node.set_surface_override_material(surface,mask_material(node.mesh.surface_get_material(surface)))
			var centre:=Vector3(entry.centre[0],entry.centre[1],entry.centre[2]);camera.size=entry.width
			var atlas:=Image.create(TILE*4,TILE*2,false,Image.FORMAT_RGBA8);atlas.fill(Color.BLACK)
			for angle in 8:
				var theta:=angle*TAU/8
				camera.position=centre+Vector3(sin(theta),0,cos(theta))*65;camera.look_at(centre)
				for frame in 4:await process_frame
				await RenderingServer.frame_post_draw
				var tile:=viewport.get_texture().get_image();tile.convert(Image.FORMAT_RGBA8)
				atlas.blit_rect(tile,Rect2i(0,0,TILE,TILE),Vector2i((angle%4)*TILE,(1-angle/4)*TILE))
			var path: String=folder+kind.trim_prefix("tf3_")+"_windows.png"
			atlas.save_png(path);masks.append(path)
			model.free();print("WINDOW_MASK ",path)
	FileAccess.open("res://.local/overnight-2026-10-14/window-masks.json",FileAccess.WRITE).store_string(JSON.stringify(masks,"\t"))
	quit(0)
