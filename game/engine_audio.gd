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
			var player:=_player(_loops[layer],view.cars[car])
			player.position=Vector3(0,1.0,0)
			player.volume_db=-80;player.play(float(car%5)*.17)
			players.append(player)
		sources.append({car=car,players=players})
	horn_player=_player(load("res://assets/sounds/horn_1.ogg"),view.cars[0])
	horn_player.unit_size=30;horn_player.volume_db=-10

func _player(stream: AudioStream,parent: Node3D) -> AudioStreamPlayer3D:
	var player:=AudioStreamPlayer3D.new()
	player.stream=stream;player.bus=BUS;player.unit_size=8;player.max_distance=1600
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
		horn_player.play()

func _process(delta: float) -> void:
	if game==null: return
	var paused: bool=track._paused
	var state:=parameters(train.speed,train.controller,train.max_speed,train.emergency)
	var blend:=1-exp(-5*delta)
	_level=_level.lerp(state.level,blend)
	_pitch=lerpf(_pitch,state.pitch,blend)
	var inside: bool=game.train==train and game.cam.mode in [1,2,4] and not game.cam.get_meta("on_platform",false)
	var cabin_gain:=.6 if inside else 1.0
	for source in sources:
		for layer in 3:
			var player: AudioStreamPlayer3D=source.players[layer]
			player.stream_paused=paused
			player.volume_db=linear_to_db(maxf(.0001,_level[layer]*cabin_gain))
			player.pitch_scale=clampf(_pitch,.3,8) if layer==1 else 1.0
	horn_player.stream_paused=paused
