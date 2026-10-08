extends Node3D
## Bounded, native positional coach-body cues. The sound lab owns the PCM.
const Event := preload("res://sim/coach_rattle.gd")
const BUS := "CoachBody"
const MAX_VOICES := 4
static var _waves: Array[AudioStreamWAV] = []
var game
var view
var track
var states := []
var voices := []
var emitted := 0
var amount := 1.0

func setup(owner,train_view,track_sound) -> void:
	game=owner;view=train_view;track=track_sound
	if _waves.is_empty():
		for i in 8:_waves.append(load("res://assets/sounds/coach_rattle/rattle-%d.wav"%i))
	if AudioServer.get_bus_index(BUS)<0:
		AudioServer.add_bus()
		var index:=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,BUS);AudioServer.set_bus_send(index,"Master")
	for car in view.formation.size():
		var model: String=view.formation[car].model
		if not model.begins_with("icf_") and not model.begins_with("lhb_"):continue
		states.append({car=car,events=Event.new(hash(view.train.id+"/"+str(car)),model.get_slice("_",0))})
	if states.is_empty():set_process(false);return
	for i in MAX_VOICES:
		var player:=AudioStreamPlayer3D.new()
		player.bus=BUS;player.unit_size=2.5;player.max_distance=80;player.max_db=0
		player.doppler_tracking=AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(player);voices.append({player=player,car=0,local=Vector3.ZERO,level=0.0})

func _process(delta: float) -> void:
	if game==null:return
	var quiet: bool=track._paused or track.reference_mode
	for voice in voices:
		voice.player.stream_paused=quiet
		if not voice.player.playing:continue
		voice.player.global_position=view.cars[voice.car].to_global(voice.local)
		if view.train.speed<.25:
			voice.level=move_toward(voice.level,0,delta*1.5)
			voice.player.volume_db=linear_to_db(maxf(.0001,voice.level))
			if voice.level<=.0001:voice.player.stop()
	if quiet:return
	var at: float=view.motion.odometer() if view.motion!=null else view.train.odometer
	for state in states:
		var jolt: float=view.ride.bodies[state.car].velocity.length() if view.ride!=null else 0.0
		var event: Dictionary=state.events.advance(at,view.train.speed,jolt,delta*track.simulation_rate)
		if event.is_empty():continue
		if view.cars[state.car].global_position.distance_to(game.cam.global_position)>80:continue
		play_event(state.car,event)

func play_event(car: int,event: Dictionary) -> bool:
	if track._paused or track.reference_mode or amount<=0:return false
	var available:={}
	for voice in voices:
		if not voice.player.playing:available=voice;break
	if available.is_empty():return false
	var aboard: bool=game.train==view.train and game.cam.mode in [1,2,4] and not game.cam.get_meta("on_platform",false)
	var passenger: bool=aboard and (game.cam.mode==2 or (game.cam.mode==4 and game.walker.passenger_interior()))
	var gain: float=float(event.gain)*amount*(1.0 if passenger else (.12 if aboard else .65))
	available.car=car;available.local=Vector3(.9 if int(event.variant)%2 else -.9,2.0,event.position)
	available.level=gain
	available.player.unit_size=5 if passenger else 2.5
	available.player.global_position=view.cars[car].to_global(available.local)
	available.player.stream=_waves[event.variant]
	available.player.volume_db=linear_to_db(maxf(.0001,gain))
	available.player.pitch_scale=1.0
	available.player.play()
	emitted+=1
	return true
