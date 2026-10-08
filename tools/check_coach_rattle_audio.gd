extends "res://tools/check_platform_walking.gd"
## Native PCM check. Run with a graphics device and --write-movie for offline mix.
func capture_frames(capture: AudioEffectCapture,count: int) -> Dictionary:
	var energy:=0.0;var peak:=0.0;var samples:=0
	capture.clear_buffer()
	for frame in count:
		await process_frame
		var pcm:=capture.get_buffer(capture.get_frames_available())
		for value in pcm:
			energy+=value.length_squared();peak=maxf(peak,maxf(absf(value.x),absf(value.y)));samples+=2
	return {rms=sqrt(energy/maxi(1,samples)),peak=peak,samples=samples}

func run() -> void:
	root.size=Vector2i(480,270)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_physics_process(false)
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
	game.set_process(false);game.cam.set_process(false);pad.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false);sound.set_paused(true)
	var body=game.traffic_presentation.roots.K1.get_node("CoachRattleAudio")
	body.set_process(false)
	check(body.states.size()==20 and body.voices.size()==4,"20 ICF coaches use bounded four-voice pool")
	game.tv.passenger_coach=1;game._enter_passenger()
	game.cam.global_transform=game.cam._target()
	game.audio.set_paused(false);game.train.speed=16.667
	var capture:=AudioEffectCapture.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index("CoachBody"),capture)
	AudioServer.set_bus_volume_db(0,-80)
	var event:={variant=0,gain=.16,position=game.tv.cars[1].to_local(game.cam.global_position).z}
	check(body.play_event(1,event),"coach cue can play from its own body")
	var audible:=await capture_frames(capture,30)
	check(audible.samples>0 and audible.rms>.00002 and audible.peak<.4,"native PCM is audible and unclipped")
	check(body.voices[0].player.pitch_scale==1,"cue pitch is independent of train speed")
	check(body.play_event(1,event),"second cue starts")
	await capture_frames(capture,2)
	game.audio.set_paused(true);body._process(.016)
	await capture_frames(capture,3)
	var paused:=await capture_frames(capture,12)
	check(paused.rms<.000001 and not body.play_event(1,event),"pause freezes every coach cue and rejects new sounds")
	game.audio.set_paused(false);game.train.speed=0
	for frame in 30:body._process(1.0/60);await process_frame
	var stopped:=await capture_frames(capture,12)
	check(stopped.rms<.000001,"body settles to silence at a stop")
	game.audio.reference_mode=true
	check(not body.play_event(1,event),"reference comparison excludes added body sounds")
	print("COACH_RATTLE_PCM ",JSON.stringify({audible=audible,paused=paused,stopped=stopped}))
	print("Coach rattle audio: %d checks; %d failures" % [checks,failures])
	game.queue_free();await process_frame;await process_frame
	quit(1 if failures else 0)
