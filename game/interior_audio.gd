extends Node
## Listener-local movement, ventilation and door/brake cues. A single bounded pool.
const Layers := preload("res://game/audio_layers.gd")
var game
var vent: AudioStreamPlayer
var cues: AudioStreamPlayer
var playback: AudioStreamPlaybackPolyphonic
var bus := {}
var cue_players := {}
var cue_buses := {}
const CUE_CHANNELS := {"steps":"TrainFootsteps","door":"TrainDoors","brake-air":"TrainBrakeAir"}
var _position := Vector2.ZERO
var _walk_key := ""
var _steps := 0.0
var _door_phase := ""
var _brake := 0.0
var _cooldown := 0.0
var _car := -1
func _ready() -> void:
	bus=Layers.filtered_bus(self,"inside","TrainAmbience")
	var room:=AudioEffectReverb.new();room.room_size=.28;room.wet=.06;room.damping=.8
	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus.name),room)
	vent=AudioStreamPlayer.new();vent.stream=Layers.wave("vent",true);vent.bus=bus.name;vent.volume_db=-80
	add_child(vent);vent.play()
	# A player per destination: native polyphonic substream bus parameters are
	# ignored on desktop. Keep the same bounded total of six cue voices.
	for channel in CUE_CHANNELS:
		var route:=Layers.filtered_bus(self,channel,CUE_CHANNELS[channel])
		var cue_room:=AudioEffectReverb.new();cue_room.room_size=.28;cue_room.wet=.06;cue_room.damping=.8
		AudioServer.add_bus_effect(AudioServer.get_bus_index(route.name),cue_room)
		cue_buses[channel]=route
		var player:=AudioStreamPlayer.new();var poly:=AudioStreamPolyphonic.new();poly.polyphony=2;player.stream=poly;player.bus=route.name
		add_child(player);player.play();cue_players[channel]=player
	cues=cue_players.door;playback=cues.get_stream_playback()
func play(name: String, gain: float=.5, pitch: float=1) -> void:
	if game.paused or game.audio_options.reference or game.audio.reference_mode:return
	var channel: String="steps" if name.begins_with("step-") else name
	cue_players[channel].get_stream_playback().play_stream(Layers.wave(name),0,linear_to_db(gain),pitch)
func _process(delta: float) -> void:
	if game==null or game.audio==null:return
	var quiet: bool=game.paused or game.audio_options.reference or game.audio.reference_mode or game.audio._paused
	vent.stream_paused=quiet
	for player in cue_players.values():player.stream_paused=quiet
	if quiet:return
	var space: Dictionary=game.audio_space
	var inside: bool=space.get("inside",false)
	var model: String=space.get("model","")
	var ac: bool=model.begins_with("vb_") or model.begins_with("lhb_") or model.begins_with("icf_ac")
	vent.volume_db=lerpf(vent.volume_db,-22.0 if inside and ac else -80.0,1-exp(-delta*4))
	bus.filter.cutoff_hz=6500 if inside else 18000
	for route in cue_buses.values():route.filter.cutoff_hz=bus.filter.cutoff_hz
	var walk=game.walker
	# Coach ownership changes halfway through continuous walking. A train-local
	# distance counter keeps footsteps through the bridge without a door cue.
	var key:="%s/%s" % [game.train.id,walk.platform.outside]
	var position: Vector2=walk.platform.position if walk.platform.outside else Vector2(walk.walked_metres,0)
	if walk.active and key==_walk_key:
		var distance:=position.distance_to(_position)
		if distance<.6:
			_steps+=distance
			if _steps>.68:
				_steps=fmod(_steps,.68);play("step-platform" if walk.platform.outside else "step-floor",.65,1+sin(float(Time.get_ticks_msec()))*.06)
	elif walk.active and not _walk_key.is_empty():play("door",.45)
	_walk_key=key if walk.active else "";_position=position
	var phase: String=game.train.passengers.get("phase","")
	if not _door_phase.is_empty() and phase!=_door_phase and phase in ["opening","closing"] and inside:play("door",.35)
	_door_phase=phase
	var brake: float=maxf(0,-game.train.controller)
	if inside and _cooldown<=0 and _brake-brake>.2:
		play("brake-air",.18);_cooldown=1.5;_brake=brake
	_brake=maxf(_brake,brake) if inside else brake
	_cooldown=maxf(0,_cooldown-delta)
func _exit_tree() -> void:
	if vent!=null:vent.stop()
	for player in cue_players.values():player.stop()
	for route in cue_buses.values():Layers.remove_bus(route)
	Layers.remove_bus(bus)
