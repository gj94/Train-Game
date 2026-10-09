extends SceneTree
## Native mixer regression: fixed orbit pivot, camera near/far, moving receiver
## and floating-origin translation. Approved PCM and its gain law stay unchanged.
const Sound:=preload("res://game/platform_audio.gd")
const Rig:=preload("res://game/camera_rig.gd")
const Proxy:=preload("res://game/geographic_audio_listener.gd")
var failures:=0
var sound
var engine
var camera
var proxy
var world
var train
var car
var origin:=Vector3(200000,0,300000)
var rolling: AudioEffectCapture
var traction: AudioEffectCapture
func _initialize() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;printerr("FAIL: ",label)
func capture(bus: String) -> AudioEffectCapture:
	var effect:=AudioEffectCapture.new();effect.buffer_length=1
	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus),effect)
	return effect
func rms(effect: AudioEffectCapture) -> float:
	var frames:=effect.get_buffer(effect.get_frames_available());var power:=0.0
	for frame in frames:power+=frame.length_squared()*.5
	check(not frames.is_empty(),"native mixer provided PCM")
	return sqrt(power/maxi(1,frames.size()))
func move_to(local: Vector3) -> void:
	camera.position=local;proxy.sync(camera,origin)
	for i in 60:
		sound._track_sound(train.speed,train.speed*3.6,1.0/120)
		engine._process(1.0/120)
func measure() -> Vector2:
	await create_timer(.25).timeout
	rolling.clear_buffer();traction.clear_buffer()
	await create_timer(.30).timeout
	return Vector2(rms(rolling),rms(traction))
func _run() -> void:
	Engine.max_fps=120
	AudioServer.set_bus_volume_db(0,-80)
	world=RailWorld.new()
	world.graph.add_node("a",origin);world.graph.add_node("b",origin+Vector3(1600,0,0))
	world.graph.add_edge("line","a","b")
	train=Train.new("free-camera-probe",24)
	train.path=[{edge="line",dir=1}];train.head_s=250;train.speed=71.6/3.6
	camera=Rig.new();root.add_child(camera);camera.set_process(false);camera.make_current()
	camera.mode=0;camera.follow=false;camera.pivot=Vector3(900,0,700)
	proxy=Proxy.new();root.add_child(proxy);proxy.set_process(false)
	proxy.sync(camera,origin)
	sound=Sound.new();root.add_child(sound)
	sound.setup(train,world,proxy,[{x=3.27,cls=0,car=1},{x=5.83,cls=1,car=1},{x=18.17,cls=2,car=1},{x=20.73,cls=3,car=1}])
	sound.set_process(false);sound.listener_owner=sound
	car=Node3D.new();root.add_child(car);car.position=Vector3(244,0,0)
	engine=preload("res://game/engine_audio.gd").new();root.add_child(engine)
	engine.setup({train=train,cam=camera},{train=train,cars=[car],formation=[{model="wap7"}]},sound)
	engine.set_process(false)
	rolling=capture(sound._buses[0]);traction=capture(engine.BUS)
	move_to(Vector3(244,2,200));var far_pcm: Vector2=await measure()
	move_to(Vector3(244,2,5));var near_pcm: Vector2=await measure()
	# Vector3 is float32: smoothed absolute coordinates at 300 km quantize in centimetres.
	check(sound._ear.position.distance_to(camera.position+origin)<.12,"receiver reaches actual close camera")
	check(not sound._onboard() and not sound._enclosed_cab(),"free camera has exterior acoustics")
	check(near_pcm.x>far_pcm.x*8,"approaching train raises actual rolling PCM, despite distant pivot")
	check(near_pcm.y>far_pcm.y*8,"engine and track use the same physical camera")
	# Moving only the focus must not move the listener or change distance mixing.
	camera.pivot=Vector3(-1000,30,-900)
	move_to(camera.position);var pivot_pcm: Vector2=await measure()
	check(absf(pivot_pcm.x/near_pcm.x-1)<.20,"orbit focus cannot attenuate nearby wheels")
	var shift:=Vector3(1024,0,-2048)
	camera.shift_origin(shift);car.position-=shift;origin+=shift
	move_to(camera.position);var rebase_pcm: Vector2=await measure()
	check(absf(rebase_pcm.x/near_pcm.x-1)<.20,"rebase preserves native rolling level")
	check(absf(rebase_pcm.y/near_pcm.y-1)<.12,"rebase preserves native engine level")
	# A real impact routes to a nearby receiver rather than a remote pivot.
	var contact: Dictionary=sound.layout.contacts.line[0].duplicate()
	contact.source=origin-shift+Vector3(244,.3,0);contact.key="near-camera-impact"
	sound._schedule(0,contact,.08)
	var allocated: bool=not sound._events.is_empty() and sound._events[-1].started and not sound._events[-1].virtual
	check(allocated,"near-camera impact gets a native voice")
	if allocated:
		var event: Dictionary=sound._events[-1]
		var impact:=capture(event.route)
		await create_timer(.45).timeout
		check(rms(impact)>.0001,"near-camera impact produces audible PCM")
	sound.set_paused(true);engine._process(.1)
	var paused_pcm: Vector2=await measure()
	check(paused_pcm.x<.000001 and paused_pcm.y<.000001,"pause silences both native sound layers")
	print("FREE_CAMERA_PCM far=",far_pcm," near=",near_pcm," pivot=",pivot_pcm," rebase=",rebase_pcm," failures=",failures)
	sound.free();engine.free();car.free();proxy.free();camera.free()
	sound=null;engine=null;car=null;proxy=null;camera=null;train=null;world=null
	rolling=null;traction=null
	call_deferred("finish")
func finish() -> void:
	for i in 3:await process_frame
	quit(1 if failures else 0)
