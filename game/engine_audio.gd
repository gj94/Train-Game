extends Node
## Electric auxiliaries and traction, independent of the approved track bank.
## Native cached loops avoid per-frame sample synthesis for multi-train traffic.
const RATE := 24000
const BUS := "Traction"
static var _loops: Array[AudioStreamWAV] = []
var game
var view
var train: Train
var track
var sources := []
var horn_player: AudioStreamPlayer3D
var _level := Vector3.ZERO
var _pitch := 1.0
const Layers := preload("res://game/audio_layers.gd")
const Space := preload("res://game/listening_space.gd")
var acoustic_bus := {}
var channel_buses := {}
var _horn_seen := 0
var _horn_blocked_through := 0
var _horn_end := -1.0
var _clock := 0.0
var _compressor: AudioStreamPlayer3D
var _is_vb := false

static func parameters(speed: float,handle: float,max_speed: float,emergency: bool=false) -> Dictionary:
	var kmh:=maxf(0,speed)*3.6
	var moving:=smoothstep(0,1.5,speed)
	var load:=maxf(0,handle) if speed<.5 else absf(handle)
	if emergency: load=0
	var whine:=(.018+.14*load)*lerpf(1,.55,clampf(speed/maxf(1,max_speed),0,1))*maxf(moving,.35*load)
	return {level=Vector3(.045,whine,.045*load*(1-smoothstep(12,35,kmh))),pitch=(70+kmh*8.5)/200}

static func _make_loops() -> void:
	if not _loops.is_empty(): return
	for layer in 3:
		var pcm:=PackedByteArray();pcm.resize(RATE*2)
		for i in RATE:
			var t:=float(i)/RATE
			var sample:=0.0
			match layer:
				0: sample=.65*sin(TAU*100*t)+.2*sin(TAU*200*t)+.10*sin(TAU*317*t)+.05*sin(TAU*563*t)
				1: sample=.62*sin(TAU*200*t)+.27*sin(TAU*400*t)+.11*sin(TAU*600*t)
				2: sample=.8*sin(TAU*820*t)+.2*sin(TAU*1640*t)
			pcm.encode_s16(i*2,roundi(sample*32760))
		var wav:=AudioStreamWAV.new()
		wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=RATE;wav.stereo=false
		wav.loop_mode=AudioStreamWAV.LOOP_FORWARD;wav.loop_begin=0;wav.loop_end=RATE;wav.data=pcm
		_loops.append(wav)

func setup(owner,train_view,track_sound) -> void:
	game=owner;view=train_view;train=view.train;track=track_sound
	_horn_seen=train.horn_sequence
	_departure_horn_due(true,game.world.clock_seconds())
	_is_vb=str(view.formation[0].model).begins_with("vb_")
	acoustic_bus=Layers.filtered_bus(self,"traction",BUS)
	channel_buses[BUS]=acoustic_bus
	for destination in ["TrainFans","TrainHorn","TrainCompressor"]:
		channel_buses[destination]=Layers.filtered_bus(self,destination,destination)
	_make_loops()
	if AudioServer.get_bus_index(BUS)<0:
		AudioServer.add_bus()
		var index:=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,BUS)
		AudioServer.set_bus_send(index,"Master")
	for car in view.formation.size():
		var model: String=view.formation[car].model
		if model!="wap7" and model not in ["vb_mc","vb_mc2"]: continue
		var players: Array[AudioStreamPlayer3D]=[]
		for layer in 3:
			var player:=_player(Layers.wave("fan-vb" if _is_vb else "fan-wap",true) if layer==0 else _loops[layer],view.cars[car],"TrainFans" if layer==0 else BUS)
			player.position=Vector3(0,1.0,0)
			player.volume_db=-80;player.play(float(car%5)*.17)
			players.append(player)
		sources.append({car=car,players=players})
	_compressor=_player(Layers.wave("compressor",true),view.cars[0],"TrainCompressor")
	_compressor.position=Vector3(0,.7,-4);_compressor.volume_db=-80;_compressor.play()
	horn_player=_player(load("res://assets/sounds/horn_1.ogg"),view.cars[0],"TrainHorn")
	horn_player.unit_size=30;horn_player.volume_db=-10

func _player(stream: AudioStream,parent: Node3D,destination: String=BUS) -> AudioStreamPlayer3D:
	var player:=AudioStreamPlayer3D.new()
	player.stream=stream;player.bus=channel_buses[destination].name;player.unit_size=8;player.max_distance=1600
	player.max_db=0
	# The camera rides the train; no false Doppler from rebasing or fast forward.
	player.doppler_tracking=AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	parent.add_child(player)
	return player

func horn() -> void:
	if not track._paused:
		var car: int=view.cars.size()-1 if train.cab_end==2 else 0
		horn_player.reparent(view.cars[car],false)
		horn_player.position=Vector3(0,2,0)
		horn_player.play();_horn_end=-1.0

func _departure_horn_due(paused: bool, now: float) -> bool:
	# Consume automatic cues even in manual mode. Taking over also cancels
	# the remainder of this pair, including a second call not yet emitted.
	if not train.automatic:
		_horn_blocked_through=maxi(_horn_blocked_through,train.horn_sequence+(1 if train.horn_pending_at>=0 else 0))
	if _horn_seen==train.horn_sequence:return false
	_horn_seen=train.horn_sequence
	var age:=now-train.horn_emitted_at
	return train.automatic and not paused and _horn_seen>_horn_blocked_through and age>=0 and age<.6

func _process(delta: float) -> void:
	if game==null: return
	var paused: bool=track._paused
	var state:=parameters(train.speed,train.controller,train.max_speed,train.emergency)
	var blend:=1-exp(-5*delta)
	_level=_level.lerp(state.level,blend)
	_pitch=lerpf(_pitch,state.pitch,blend)
	var own: bool=game.train==train
	var response:=Space.response(game.audio_space,own,"traction") if not game.audio_options.reference else Vector2(.6 if own and game.cam.mode in [1,2,4] else 1,18000)
	var cutoff:=response.y
	if game.audio_options.headphones:cutoff=minf(cutoff,Space.directional_cutoff(view.cars[0].global_position,game.cam.global_position,-game.cam.global_basis.z))
	for channel in channel_buses.values():channel.filter.cutoff_hz=lerpf(channel.filter.cutoff_hz,cutoff,blend)
	var cabin_gain:=response.x
	var loc: Dictionary=view.motion.locate(0)
	var velocity: Vector3=game.world.graph.tangent(loc.edge,loc.s,loc.dir)*train.speed
	var receiver: Vector3=game.audio_space.get("velocity",Vector3.ZERO)
	var shift:=Space.doppler(view.cars[0].global_position,game.cam.global_position,velocity,receiver)
	_clock=game.world.clock_seconds()
	if _departure_horn_due(paused,_clock):
		horn();_horn_end=_clock+1.15
	# A manual button horn uses _horn_end=-1 and is never stopped here.
	if _horn_end>=0 and (not train.automatic or _clock>=_horn_end):
		horn_player.stop();_horn_end=-1.0
	_compressor.stream_paused=paused
	var cycle:=fposmod(_clock+posmod(hash(train.id),71),71)
	var compressor_gain:=smoothstep(0,1,cycle)*(1-smoothstep(7,9,cycle))*.32*cabin_gain
	_compressor.volume_db=linear_to_db(maxf(.0001,compressor_gain if not game.audio_options.reference else 0))
	_compressor.pitch_scale=shift
	for source in sources:
		for layer in 3:
			var player: AudioStreamPlayer3D=source.players[layer]
			player.stream_paused=paused
			player.volume_db=linear_to_db(maxf(.0001,_level[layer]*cabin_gain*(4.0 if layer==0 else 1.0)))
			player.pitch_scale=(clampf(_pitch*(1.25 if _is_vb else 1),.3,8) if layer==1 else 1.0)*shift
	horn_player.stream_paused=paused
	horn_player.pitch_scale=shift
	var release:=clampf((_horn_end-_clock)/.18,0,1) if _horn_end>=0 else 1.0
	horn_player.volume_db=-10+linear_to_db(maxf(.0001,Space.response(game.audio_space,own,"horn").x*release))

func _exit_tree() -> void:
	# These native emitters belong to the car nodes, not this node.
	for source in sources:
		for player in source.players:
			if is_instance_valid(player):player.stop();player.queue_free()
	for player in [horn_player,_compressor]:
		if is_instance_valid(player):player.stop();player.queue_free()
	for channel in channel_buses.values():Layers.remove_bus(channel)
