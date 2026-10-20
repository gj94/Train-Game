extends SceneTree
## Exercise the actual mixer routing and menu without loading world scenery.
const Prefs:=preload("res://game/audio_preferences.gd")
const Menu:=preload("res://game/audio_menu.gd")
var failures:=0
var checks:=0
var captures:={}
var players:=[]
var prefs

func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr(message)

func energy(capture: AudioEffectCapture) -> float:
	var frames:=capture.get_buffer(capture.get_frames_available())
	var total:=0.0
	for frame in frames:total+=frame.length_squared()
	return total/maxi(1,frames.size())

func run() -> void:
	prefs=Prefs.new("user://mixer-check-absent.cfg")
	prefs.quiet=false;prefs.reference=false;prefs.apply()
	# Headless audio can run the native Dummy driver; mute the hardware output.
	AudioServer.set_bus_volume_db(0,-80)
	var wav:=AudioStreamWAV.new();wav.mix_rate=24000;wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.loop_mode=AudioStreamWAV.LOOP_FORWARD;wav.loop_begin=0;wav.loop_end=24000
	var pcm:=PackedByteArray();pcm.resize(48000)
	for i in 24000:pcm.encode_s16(i*2,roundi(sin(TAU*310*i/24000)*1800))
	wav.data=pcm
	for key in prefs.LAYERS:
		if key=="master":continue
		var player:=AudioStreamPlayer.new();player.stream=wav;player.bus=prefs.LAYERS[key];root.add_child(player);player.play();players.append(player)
		var capture:=AudioEffectCapture.new();capture.buffer_length=.3
		# An effect on the output sees the sum; channel effects are before mute.
		captures[key]=capture;AudioServer.add_bus_effect(AudioServer.get_bus_index(player.bus),capture)
	var output:=AudioEffectCapture.new();output.buffer_length=.3
	AudioServer.add_bus_effect(AudioServer.get_bus_index("TrainOutput"),output)
	for key in prefs.LAYERS:
		if key=="master":continue
		for other in prefs.LAYERS:
			if other!="master":prefs.muted[other]=other!=key
		prefs.apply()
		await create_timer(.15).timeout;output.clear_buffer()
		await create_timer(.1).timeout
		var audible:=energy(output)
		check(audible>.0001,key+" can be heard independently through the output")
		prefs.muted[key]=true;prefs.apply()
		await create_timer(.15).timeout;output.clear_buffer()
		await create_timer(.1).timeout
		check(energy(output)<audible*.001,key+" mute silences only that isolated layer")
	for player in players:player.stop();player.queue_free()
	await create_timer(.2).timeout
	Prefs.new()
	print("Sound mixer native output: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
