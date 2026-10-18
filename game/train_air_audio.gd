extends Node3D
## Three wind voices per nearby train: nose, nearest body and wake. No per-pax audio.
const Layers := preload("res://game/audio_layers.gd")
const Space := preload("res://game/listening_space.gd")
var game
var view
var track
var voices := []
var bus := {}
var _refresh := 0.0
var nearest := 0
static func air_level(speed: float, distance: float, own: bool, exposure: float) -> float:
	if distance>150:return 0.0
	var level:=pow(clampf(speed/30,0,2),1.7)*.65
	return level*(exposure if own else 1.0)
func setup(owner,train_view,track_sound) -> void:
	game=owner;view=train_view;track=track_sound
	bus=Layers.filtered_bus(self,"air","TrainWind")
	for i in 3:
		var player:=AudioStreamPlayer3D.new();player.stream=Layers.wave("wake" if i==2 else "rush",true)
		player.bus=bus.name;player.unit_size=3.0;player.max_distance=150;player.max_db=0;player.volume_db=-80
		add_child(player);player.play(i*.613);voices.append(player)
func _process(delta: float) -> void:
	if game==null:return
	var quiet: bool=track._paused or track.reference_mode or game.audio_options.reference
	for voice in voices:voice.stream_paused=quiet
	if quiet:return
	_refresh-=delta
	if _refresh<=0:
		_refresh=.1;var best:=INF
		for car in view.cars.size():
			var d: float=view.cars[car].global_position.distance_squared_to(game.cam.global_position)
			if d<best:best=d;nearest=car
	var loc: Dictionary=view.motion.locate(0)
	var velocity: Vector3=game.world.graph.tangent(loc.edge,loc.s,loc.dir)*view.train.speed
	var own: bool=game.train==view.train
	var response:=Space.response(game.audio_space,own,"wind")
	bus.filter.cutoff_hz=lerpf(bus.filter.cutoff_hz,response.y,1-exp(-delta*10))
	var indices:=[0,nearest,view.cars.size()-1]
	for i in 3:
		var car: Node3D=view.cars[indices[i]]
		var length: float=view.formation[indices[i]].pitch
		voices[i].global_position=car.to_global(Vector3(0,1.5,(length*.5 if i==0 else (-length*.5 if i==2 else 0))))
		var distance: float=voices[i].global_position.distance_to(game.cam.global_position)
		var exposure: float=game.audio_space.get("exposure",1.0)
		var level:=air_level(view.train.speed,distance,own,exposure)*response.x
		# Air at coach joins flickers; body rush sustains throughout a long rake.
		if i==1:
			var local: Vector3=car.to_local(game.cam.global_position)
			level*=.65+.35*smoothstep(length*.5-3,length*.5,absf(local.z))
		else:level*=.65 if i==0 else .85
		voices[i].volume_db=lerpf(voices[i].volume_db,linear_to_db(maxf(.0001,level)),1-exp(-delta*14))
		voices[i].pitch_scale=Space.doppler(voices[i].global_position,game.cam.global_position,velocity,game.audio_space.get("velocity",Vector3.ZERO))
func _exit_tree() -> void:
	for voice in voices:voice.stop()
	Layers.remove_bus(bus)
