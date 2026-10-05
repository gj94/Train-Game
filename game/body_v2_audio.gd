extends Node
## Faithful BODY V2 voice/mix adapter. Approved PCM stays in the sibling sound lab.
## One nearby physical joint; per-bogie rolling, equal-power pan, no added coloration.
const Data := preload("res://game/body_v2_data.gd")
const Model := preload("res://game/body_v2_model.gd")
const AxleJoint := preload("res://game/axle_joint.gd")
const Layout := preload("res://game/rail_joint_layout.gd")
const JOINT_SPACING := Layout.SPACING
const JOINT_OFFSET := Layout.OFFSET
const DRIVER := Vector2(2.0,1.5)
const TRACK_ONLY := true
const BUS := "Train"
const DEFAULT_TRACK_LEVEL := 1.0
signal joint_hit(edge: String,joint: int,cls: int)
var train: Train
var world: RailWorld
var camera: Node3D
var motion
var interior_listener := DRIVER
var track_level := DEFAULT_TRACK_LEVEL
var clang_balance_db := 0.0
var listener_override := {}
var joint_override := {}
var _sched
var _kernels := []
var _routed := []
var _rolling_waves := []
var _identities := []
var _bogies := []
var _voices := []
var _track: AudioStreamPlayer
var _track_pb: AudioStreamPlaybackPolyphonic
var _rolling: AudioStreamPlayer
var _roll_pb: AudioStreamPlaybackPolyphonic
var _cab := false
var _selection := {}
var _focus := Vector3(INF,INF,INF)
var _ear := {}
var last_normalizer := 0.0
var _smooth_normalizer := 0.0

func setup(t: Train,w: RailWorld,listener: Node3D,axles: Array) -> void:
	train=t; world=w; camera=listener
	_make_bus()
	for i in Data.KERNELS:
		_kernels.append(load(Data.ROOT+"impact-%d.wav"%i))
		_routed.append([load(Data.ROOT+"impact-%d-left.wav"%i),load(Data.ROOT+"impact-%d-right.wav"%i)])
	for side in ["left","right"]:
		var wav: AudioStreamWAV = load(Data.ROOT+"rolling-bed-"+side+".wav").duplicate()
		wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin=0; wav.loop_end=Data.RATE*8
		_rolling_waves.append(wav)
	_track=_poly_player(64); _track_pb=_track.get_stream_playback()
	_rolling=_poly_player(128); _roll_pb=_rolling.get_stream_playback()
	_sched=AxleJoint.new()
	set_axles(axles)

func _poly_player(count: int) -> AudioStreamPlayer:
	var poly:=AudioStreamPolyphonic.new()
	poly.polyphony=count
	var p:=AudioStreamPlayer.new()
	p.stream=poly; p.bus=BUS
	add_child(p); p.play()
	return p

func _make_bus() -> void:
	var bus:=AudioServer.get_bus_index(BUS)
	if bus<0:
		AudioServer.add_bus()
		bus=AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,BUS)
	if AudioServer.get_bus_effect_count(bus)>0 and AudioServer.get_bus_effect(bus,0) is AudioEffectCompressor:
		return
	while AudioServer.get_bus_effect_count(bus)>0: AudioServer.remove_bus_effect(bus,0)
	var compressor:=AudioEffectCompressor.new()
	compressor.threshold=-4.0; compressor.ratio=4.0
	compressor.attack_us=2000; compressor.release_ms=150
	# Web Audio's automatic makeup adds 1.255 dB at the approved settings.
	# Measured independently against its bypassed output at 30/71.6/120 km/h.
	compressor.gain=1.255; compressor.mix=1
	AudioServer.add_bus_effect(bus,compressor)

func set_axles(axles: Array) -> void:
	reset_positions()
	_sched.setup(axles,JOINT_SPACING,JOINT_OFFSET)
	for b in _bogies:
		for id in b.ids: _roll_pb.stop_stream(id)
	_smooth_normalizer=0.0
	var described:=Model.describe(axles)
	_identities=described.axles; _bogies=described.bogies
	for i in _bogies.size():
		var b: Dictionary=_bogies[i]
		b.ids=[]; b.pitch=1.0; b.position=Vector3.ZERO; b.started=false
		for side in 2:
			b.ids.append(_roll_pb.play_stream(_rolling_waves[side],fmod(i*Data.LOOP_STAGGER,8.0),-100.0,1.0))

func reset_positions() -> void:
	if _sched != null: _sched.reset()
	for voice in _voices:
		for id in voice.ids: _track_pb.stop_stream(id)
	_voices.clear()
	_ear.clear(); _selection.clear(); _focus=Vector3(INF,INF,INF)

func horn() -> void:
	pass # TRACK_ONLY: retain the approved website's sound layers.

func set_interior(value: bool) -> void:
	_cab=value # Preserve approved timbre inside; do not add the old cab filter/reverb.

func adjust_track_level(db: float) -> float:
	track_level=clampf(track_level*db_to_linear(db),.1,8.0)
	return linear_to_db(track_level)

func adjust_clang_balance(db: float) -> float:
	clang_balance_db=clampf(clang_balance_db+db,-12.0,12.0)
	return clang_balance_db

func _locate(back: float) -> Dictionary:
	return motion.locate(back) if motion != null else train.locate_behind(world.graph,back)

func _listener() -> Dictionary:
	if not listener_override.is_empty(): return listener_override
	var forward: Vector3=-camera.global_basis.z
	var onboard: bool=_cab or ("mode" in camera and camera.mode != 0)
	if onboard:
		return {position=camera.global_position,forward=forward,up=camera.global_basis.y}
	# Overview remains a platform listener near the focus, even when zoomed out.
	var tangent: Vector3=_selection.get("tangent",Vector3.RIGHT)
	var side:=tangent.cross(Vector3.UP)
	var focus: Vector3=camera.pivot
	var ground: float=_selection.get("point",focus).y
	return {position=Vector3(focus.x,ground,focus.z)+tangent*3.8+side*5.8+Vector3.UP*2.73,forward=forward,up=Vector3.UP}

func _process(delta: float) -> void:
	if train == null or _track.stream_paused: return
	_track_sound(train.speed,train.speed*3.6,delta)

func _track_sound(v: float,_kmh: float,delta: float=1.0/60.0) -> void:
	var onboard: bool=_cab or ("mode" in camera and camera.mode != 0)
	var focus: Vector3=camera.global_position if onboard else camera.pivot
	if not joint_override.is_empty():
		_selection=joint_override
	elif _selection.is_empty() or focus.distance_squared_to(_focus)>.25:
		_selection=Model.listening_joint(world.graph,focus)
		_focus=focus
	if _selection.is_empty(): return
	var target:=_listener()
	if _ear.is_empty(): _ear=target.duplicate()
	var smoothing:=1.0-exp(-delta/.035)
	_ear.position=_ear.position.lerp(target.position,smoothing)
	_ear.forward=_ear.forward.lerp(target.forward,smoothing).normalized()
	_ear.up=target.up
	var positions: Array=[]
	var leads: Array=[]
	for a in _sched.axles:
		var lead:=minf(Data.KERNEL_LEAD+Data.LOOKAHEAD,a.x/maxf(v,.001))
		var loc:=_locate(maxf(0.0,a.x-v*lead))
		positions.append({edge=loc.edge,s=loc.s,dir=loc.dir,length=world.graph.edges[loc.edge].length})
		leads.append(lead)
	# Age existing voices first. Early-start padding lets the native mixer land
	# contacts between render frames without cutting their approved attack.
	_update_voices(delta,v)
	for h in _sched.advance(positions,v):
		if h.edge != _selection.edge or h.joint != _selection.joint: continue
		joint_hit.emit(h.edge,h.joint,h.cls)
		var source:=world.graph.position(h.edge,JOINT_OFFSET+h.joint*JOINT_SPACING)+Vector3.UP*.3
		var flight:=minf(Model.propagation(source,_ear.position),1.9)
		var delay: float=leads[h.axle]-Data.KERNEL_LEAD+flight-h.late
		var offset:=Data.PAD-delay
		if offset>=Data.PAD+Data.KERNEL_SECONDS: continue
		var identity: Dictionary=_identities[h.axle]
		var gain: float=identity.load*track_level*Data.MASTER
		if identity.order==1: gain*=db_to_linear(clang_balance_db)
		var stereo:=Model.stereo(source,_ear.position,_ear.forward,_ear.up)*gain
		var ids: Array=[]
		for side in 2:
			ids.append(_track_pb.play_stream(_routed[identity.variant][side],maxf(0.0,offset),linear_to_db(maxf(stereo[side],.00001)),1.0))
		_voices.append({ids=ids,source=source,gain=gain,remaining=delay+Data.KERNEL_SECONDS,pending=maxf(0.0,delay+Data.KERNEL_LEAD-flight)})
	_update_rolling(v,delta)

func _update_voices(delta: float,v: float) -> void:
	for i in range(_voices.size()-1,-1,-1):
		var voice: Dictionary=_voices[i]
		voice.remaining-=delta; voice.pending-=delta
		if voice.remaining<=0.0 or (v<=.001 and voice.pending>0.0):
			for id in voice.ids: _track_pb.stop_stream(id)
			_voices.remove_at(i)
			continue
		var stereo: Vector2=Model.stereo(voice.source,_ear.position,_ear.forward,_ear.up)*voice.gain
		for side in 2: _track_pb.set_stream_volume(voice.ids[side],linear_to_db(maxf(stereo[side],.00001)))

func _update_rolling(v: float,delta: float) -> void:
	var distances: Array=[]
	for b in _bogies:
		var loc:=_locate(b.x)
		b.target=world.graph.position(loc.edge,loc.s)+Vector3.UP*.7
		b.velocity=world.graph.tangent(loc.edge,loc.s,loc.dir)*v
		distances.append(b.target.distance_to(_ear.position))
	last_normalizer=Model.normalizer(distances)
	_smooth_normalizer=lerpf(_smooth_normalizer,last_normalizer,1.0-exp(-delta/.035))
	# The website is approved from 25 km/h up. Only fade below walking speed
	# to extend it safely to departure/stopping; no extra speed gain above this.
	var moving:=smoothstep(0.0,.5,v)
	for i in _bogies.size():
		var b: Dictionary=_bogies[i]
		b.position=b.position.lerp(b.target,1.0-exp(-delta/.04)) if b.started else b.target
		b.started=true
		var radial: float=b.velocity.dot(b.target-_ear.position)/maxf(.001,distances[i])
		var gains:=Model.stereo(b.position,_ear.position,_ear.forward,_ear.up)*_smooth_normalizer*Data.MASTER*track_level*moving
		b.pitch=lerpf(b.pitch,Model.rolling_pitch(radial),1.0-exp(-delta/.04))
		for side in 2:
			_roll_pb.set_stream_volume(b.ids[side],linear_to_db(maxf(gains[side],.000001)))
			_roll_pb.set_stream_pitch_scale(b.ids[side],b.pitch)

func _exit_tree() -> void:
	if is_instance_valid(_track): _track.stop()
	if is_instance_valid(_rolling): _rolling.stop()
	_track_pb=null; _roll_pb=null
