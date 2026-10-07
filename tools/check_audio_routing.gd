extends SceneTree
## Capture native PCM on real destination buses, not only routing metadata.
const Sound := preload("res://game/platform_audio.gd")
var failures := 0
class Listener extends Node3D:
	var mode := 1
	var pivot := Vector3.ZERO
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+message)
func rms(capture: AudioEffectCapture) -> float:
	var frames=capture.get_buffer(capture.get_frames_available())
	var sum:=0.0
	for frame in frames: sum+=frame.length_squared()*.5
	return sqrt(sum/maxi(1,frames.size()))
func capture_bus(name: String) -> AudioEffectCapture:
	var capture:=AudioEffectCapture.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index(name),capture)
	return capture
func run() -> void:
	Engine.max_fps=120
	AudioServer.set_bus_volume_db(0,-80)
	var baseline:=AudioServer.bus_count
	var world:=RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(1000,0,0))
	world.graph.add_edge("line","a","b")
	var train:=Train.new("route_probe",24)
	train.path=[{edge="line",dir=1}]; train.head_s=100; train.speed=60.0/3.6
	var camera:=Listener.new()
	root.add_child(camera)
	camera.position=Vector3(97,3,.4)
	var sound:=Sound.new()
	root.add_child(sound)
	sound.setup(train,world,camera,[{x=3.27,cls=0,car=1},{x=5.83,cls=1,car=1},{x=18.17,cls=2,car=1},{x=20.73,cls=3,car=1}])
	sound.set_process(false)
	sound.listener_owner=sound
	sound._track_sound(train.speed,60,.05)
	var rolling:=capture_bus(sound._buses[0])
	await create_timer(.3).timeout
	var rolling_rms:=rms(rolling)
	check(rolling_rms>.00001,"rolling PCM traverses the real 900 Hz shelf bus")
	sound._rolling.volume_db=-100
	var contact: Dictionary=sound.layout.contacts.line[0].duplicate()
	contact.key="native-routing"; contact.id=1; contact.source=Vector3(97,.3,0)
	sound._schedule(0,contact,.10)
	check(not sound._events.is_empty() and not sound._events[0].virtual,"native impact allocated")
	var event: Dictionary=sound._events[0]
	var route: Dictionary=sound._routes[0]
	var impact:=capture_bus(route.bus)
	await create_timer(.5).timeout
	var impact_rms:=rms(impact)
	check(impact_rms>.00001,"impact PCM traverses its distance/cab filter")
	check(event.playback==route.playback and route.player.bus==route.bus,"impact owns the filtered player")
	check(sound._rolling.bus==sound._buses[0],"rolling player owns shelf route")
	# A high-frequency tone proves the route filter affects actual output.
	var wave:=AudioStreamWAV.new()
	wave.mix_rate=48000; wave.format=AudioStreamWAV.FORMAT_16_BITS
	var bytes:=PackedByteArray(); bytes.resize(48000*2)
	for i in 48000: bytes.encode_s16(i*2,int(sin(i*TAU*6000/48000)*8000))
	wave.data=bytes; wave.loop_mode=AudioStreamWAV.LOOP_FORWARD; wave.loop_end=48000
	route.filter.cutoff_hz=900
	route.playback.play_stream(wave)
	impact.clear_buffer()
	await create_timer(.3).timeout
	var filtered:=rms(impact)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(route.bus),0,false)
	impact.clear_buffer()
	await create_timer(.3).timeout
	var bypassed:=rms(impact)
	check(filtered>0 and filtered<bypassed*.08,"distance filter changes recorded spectrum, not only properties")
	sound.set_paused(true)
	check(sound._events.is_empty(),"pause clears routed impacts")
	for player in sound.get_children():
		if player is AudioStreamPlayer: check(player.stream_paused,"pause reaches all route players")
	sound.free(); camera.free()
	route={}; event={}
	await create_timer(.2).timeout
	check(AudioServer.bus_count<=baseline+1,"routed buses released")
	print("Native route PCM: rolling=",rolling_rms," impact=",impact_rms," filtered/bypass=",filtered/maxf(bypassed,.000001),"; ",failures," failures")
	quit(1 if failures else 0)
