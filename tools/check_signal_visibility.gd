extends SceneTree
## Real renderer checks: colour at distance, rear darkness and depth occlusion.
const Asset:=preload("res://game/signal_asset.gd")
var camera: Camera3D
var env: Environment
var sun: DirectionalLight3D
var lamps: Array
var obstruction: MeshInstance3D
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func mesh(size: Vector3, pos: Vector3, colour: Color, parent: Node3D) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=size;n.mesh=b;n.position=pos
	n.material_override=Asset.material(colour);parent.add_child(n);return n
func capture(name: String) -> Image:
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var im:=root.get_texture().get_image()
	im.save_png("res://.local/signal-"+name+".png")
	return im
func changes(a: Image,b: Image) -> int:
	var count:=0
	for y in range(310,410):
		for x in range(590,690):
			var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
			if Vector3(ca.r-cb.r,ca.g-cb.g,ca.b-cb.b).length()>.16:count+=1
	return count
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+text)
	else:print("PASS "+text)
func run() -> void:
	root.size=Vector2i(1280,720)
	root.msaa_3d=Viewport.MSAA_4X
	var scene:=Node3D.new();root.add_child(scene)
	var world:=WorldEnvironment.new();env=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a4c6d8")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d6e5ec")
	env.ambient_light_energy=.65;world.environment=env;scene.add_child(world)
	env.tonemap_mode=Environment.TONE_MAPPER_AGX
	env.glow_enabled=true;env.glow_intensity=.28;env.glow_hdr_threshold=1.2
	env.fog_enabled=true;env.fog_mode=Environment.FOG_MODE_DEPTH
	env.fog_depth_begin=preload("res://game/railway_render_budget.gd").FOG_BEGIN
	env.fog_depth_end=preload("res://game/railway_render_budget.gd").FOG_END
	env.fog_depth_curve=1.25;env.fog_density=1.0
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.4;scene.add_child(sun)
	mesh(Vector3(1600,.1,1600),Vector3(0,-.2,0),Color("53684f"),scene)
	var head:=Node3D.new();scene.add_child(head);lamps=Asset.build(head)
	mesh(Vector3(.16,5.4,.16),Vector3(0,2.9,0),Color("888c88"),head)
	mesh(Vector3(.6,.4,.6),Vector3(0,.2,0),Color("888880"),head)
	obstruction=mesh(Vector3(20,20,1),Vector3(0,5,-300),Color("888980"),scene);obstruction.hide()
	camera=Camera3D.new();camera.fov=70;camera.far=2200;scene.add_child(camera);camera.current=true
	for night in [false,true]:
		env.background_color=Color("070c15") if night else Color("a4c6d8")
		env.fog_light_color=Color(.055,.075,.115) if night else Color(.78,.84,.85)
		env.ambient_light_energy=.02 if night else .65;sun.light_energy=0 if night else 1.4
		for distance in [20,200,600]:
			camera.position=Vector3(0,3,-distance);camera.look_at(Vector3(0,5.6,0))
			for lamp in lamps:lamp.material_override=Asset.unlit
			lamps[0].set_meta("aspect",-1)
			var off: Image=await capture("%s-%dm-off" % ["night" if night else "day",distance])
			for aspect in 3:
				Asset.apply(lamps,aspect)
				var lit: Image=await capture("%s-%dm-%s" % ["night" if night else "day",distance,["red","yellow","green"][aspect]])
				var pixels:=changes(off,lit)
				check(pixels>=2,"%s %dm aspect %d has %d visible pixels" % ["night" if night else "day",distance,aspect,pixels])
		camera.position=Vector3(0,3,600);camera.look_at(Vector3(0,5.6,0))
		Asset.apply(lamps,0);var rear_on: Image=await capture("rear-on")
		for lamp in lamps:lamp.material_override=Asset.unlit
		lamps[0].set_meta("aspect",-1)
		var rear_off: Image=await capture("rear-off")
		check(changes(rear_on,rear_off)==0,"no lit aspect visible from rear")
		camera.position=Vector3(0,3,-600);camera.look_at(Vector3(0,5.6,0));obstruction.show()
		Asset.apply(lamps,2);var blocked_on: Image=await capture("blocked-on")
		for lamp in lamps:lamp.material_override=Asset.unlit
		lamps[0].set_meta("aspect",-1)
		var blocked_off: Image=await capture("blocked-off")
		check(changes(blocked_on,blocked_off)==0,"wall occludes the signal optics")
		obstruction.hide()
	print("Signal optics: %d checks, %d failures" % [checks,failures])
	scene.queue_free();await process_frame;quit(1 if failures else 0)
