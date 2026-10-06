extends SceneTree
const Sound := preload("res://game/platform_audio.gd")
const Data := preload("res://game/platform_enhanced_data.gd")
var failures := 0
class Listener extends Node3D:
	var mode := 2
	var pivot := Vector3.ZERO

func _initialize() -> void: call_deferred("run_check")
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; printerr("FAIL: ",label)

func run_check() -> void:
	var bus_start := AudioServer.bus_count
	var world := RailWorld.new()
	var radius := 250.0
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(radius*sin(1.2),0,radius*(1-cos(1.2))))
	var points := []
	for i in range(1,300): points.append(Vector3(radius*sin(i/radius),0,radius*(1-cos(i/radius))))
	world.graph.add_edge("curve","a","b",points)
	var train := Train.new("curve_probe",24)
	train.path=[{edge="curve",dir=1}]; train.head_s=40; train.speed=30.0/3.6
	var camera := Listener.new(); root.add_child(camera)
	var axles := [{x=3.27,cls=0,car=1},{x=5.83,cls=1,car=1},{x=18.17,cls=2,car=1},{x=20.73,cls=3,car=1}]
	var sound := Sound.new(); root.add_child(sound)
	sound.setup(train,world,camera,axles); sound.set_process(false); sound.listener_owner=sound
	var maximum := 0
	for i in 600:
		train.head_s+=train.speed/120
		camera.global_position=world.graph.position("curve",train.head_s-12)+Vector3(0,3.18,.4)
		sound._track_sound(train.speed,30,1.0/120)
		maximum=maxi(maximum,sound._squeals.size())
		check(sound._squeals.size()<=12,"squeal voice budget")
		if i%30==0: await process_frame
	check(maximum==2,"both coach bogies develop squeal from physical wheel curvature")
	check(sound.debug_events.size()>8,"repeated physical rail contacts produce heard events")
	for voice in sound._squeals:
		check(absf(voice.pitch-1)<.000001,"onboard squeal does not transpose")
		check(voice.texture.cutoff_hz==4800,"new benchmark curve-color shelf")
		check(voice.ids[0]>=0 and voice.ids[1]>=0,"both native squeal channels allocated")
	check(sound._squeal_waves[0][0].loop_end==Data.SQUEAL_FRAMES,"entire periodic FFT bank loops without truncation")
	sound.squeal_amount=0
	for i in 50: sound._track_sound(train.speed,30,1.0/120)
	check(sound._squeals.is_empty(),"squeal-off releases every native loop and tail")
	sound.squeal_amount=.6
	for i in 30: sound._track_sound(train.speed,30,1.0/120)
	check(not sound._squeals.is_empty(),"squeal can re-enter with cached banks")
	sound.set_paused(true)
	check(sound._squeals.is_empty() and sound._events.is_empty(),"pause cancels pending contacts and squeal tails")
	sound.set_paused(false)
	train.speed=0
	for i in 20: sound._track_sound(0,0,1.0/120)
	check(sound._squeals.is_empty() and sound._events.is_empty(),"standstill creates no impacts or squeal")
	sound.free(); camera.free()
	check(AudioServer.bus_count<=bus_start+1,"per-source native buses cleaned after scene exit")
	print("Enhanced native curve/lifecycle: ",failures," failures")
	change_scene_to_file("res://game/main.tscn")
	await process_frame; await process_frame
	var game = current_scene
	game.set_process(false); game.set_physics_process(false); game.cam.set_process(false)
	for audio in game.train_audio.values(): audio.set_process(false)
	var eligible: Array=game.tv.passenger_coaches()
	check(eligible.size()>=3,"default WAP-7 rake has first, middle and last passenger coaches")
	var initial_controller: float=game.train.controller
	var initial_automatic: bool=game.train.automatic
	var views := []
	for preset in 3:
		game._passenger_preset(preset)
		game.cam._blend=1; game.cam._process(1.0/60)
		views.append(game.tv.passenger_coach)
		var expected: Transform3D=game.tv.passenger_transform()
		check(game.cam.global_position.distance_to(expected.origin)<.001,"passenger camera attached to selected coach")
		game.audio.listener_owner=game.audio
		game.audio._track_sound(0,0,1.0/60)
		check(game.audio._ear.position.distance_to(game.cam.global_position)<.001,"passenger audio attached to chosen camera")
		check(game.cam.mode==2,"preset enters passenger view")
		if "--screenshots" in OS.get_cmdline_user_args():
			game._process(0)
			game.hud.hide()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/enhanced-pax-%d.png"%preset)
			game.hud.show()
	check(views==[eligible[0],eligible[(eligible.size()-1)/2],eligible[-1]],"first/middle/last presets select actual passenger stock")
	check(game.train.controller==initial_controller and game.train.automatic==initial_automatic,"passenger views retain driver controls")
	game.hud.show_modal("passengers")
	check(game.hud._buttons.get_child_count()==4,"passenger view menu presents three choices plus back")
	game._set_paused(true); game._set_paused(false)
	print("Enhanced audio and passenger views: ",failures," failures; selected ",views)
	quit(1 if failures else 0)
