extends "res://game/body_v2_audio.gd"
## Native, pooled port of the enhanced platform acoustics. The old adapter remains
## available solely as a golden reference. No waveform synthesis in the frame loop.
const Acoustics := preload("res://game/platform_acoustics.gd")
const EnhancedData := preload("res://game/platform_enhanced_data.gd")
const Contacts := preload("res://game/track_contacts.gd")
const Sweep := preload("res://game/contact_sweep.gd")
const History := preload("res://game/acoustic_history.gd")
const Timing := preload("res://game/audio_output_timing.gd")
const MAX_IMPACT_CHANNELS := 128
const MAX_JOINT_ROUTES := 24
const MAX_SQUEAL_VOICES := 12
# Native impacts already stop at 1.6 km. This guard also covers a fast listener
# approaching during the ~4.7 s propagation delay and short start lookahead.
const IMPACT_PREFETCH_DISTANCE := 2600.0
var culled_impacts := 0
var last_process_ms := 0.0
signal contact_event(event: Dictionary)
var listener_owner: Node
var reference_mode := false
var squeal_amount := .6
var layout
var _sweep := Sweep.new()
var _history := History.new()
var _time := 0.0
var simulation_rate := 1.0
var _last_history := -1.0
var _events := []
var _recent := {}
var _routes := []
var _squeals := []
var _squeal_waves := []
var _buses := []
var _hiss: AudioEffectHighShelfFilter
var _hiss_db := 0.0
var _roll_gain := 0.0
var _owner_context := {}
var _receiver_velocity := Vector3.ZERO
var _previous_target := Vector3.ZERO
var _last_speed := 0.0
var _last_cab := 1
var engine
var _route_signature := ""
var _paused := false
var _voice_serial := 0
var _perspective := -1
var debug_events := []
var active_squeal := []
var _start_window := .16
var output_delay_ms := 0.0

func horn() -> void:
	if is_instance_valid(engine): engine.horn()

func setup(t: Train,w: RailWorld,listener: Node3D,axles: Array) -> void:
	layout=Contacts.new(w.graph)
	super.setup(t,w,listener,axles)
	_track.stop(); _track.stream.polyphony=128; _track.play(); _track_pb=_track.get_stream_playback()
	_hiss=AudioEffectHighShelfFilter.new()
	_hiss.cutoff_hz=900; _hiss.resonance=.5; _hiss.db=AudioEffectFilter.FILTER_6DB; _hiss.gain=1.0
	var rolling_bus := _make_filter_bus("rolling",_hiss)
	# Desktop streaming ignores play_stream's per-substream bus argument.
	# Route the owning AudioStreamPlayer so the shelf reaches the actual PCM.
	_rolling.bus=rolling_bus
	for i in _bogies.size():
		var b: Dictionary=_bogies[i]
		for id in b.ids: _roll_pb.stop_stream(id)
		b.ids=[]
		for side in 2: b.ids.append(_roll_pb.play_stream(_rolling_waves[side],fmod(i*.731,8),-100,1,0,rolling_bus))
	for i in 4:
		var pair := []
		for side in ["left","right"]:
			var wav: AudioStreamWAV=load(EnhancedData.ROOT+"squeal-%d-%s.wav"%[i,side]).duplicate()
			wav.loop_mode=AudioStreamWAV.LOOP_FORWARD; wav.loop_begin=0; wav.loop_end=EnhancedData.SQUEAL_FRAMES
			pair.append(wav)
		_squeal_waves.append(pair)
	_last_cab=train.cab_end

func set_axles(axles: Array) -> void:
	super.set_axles(axles)
	var described := Acoustics.describe(axles)
	_identities=described.axles
	for b in _bogies:
		for detail in described.bogies:
			if detail.car==b.car and absf(detail.x-b.x)<.00001: b.merge(detail,true); break
	_bogies.sort_custom(func(a,b): return a.x<b.x)
	# set_axles after setup must also preserve the rolling filter route.
	if _hiss!=null:
		for i in _bogies.size():
			var b: Dictionary=_bogies[i]
			for id in b.ids: _roll_pb.stop_stream(id)
			b.ids=[]
			for side in 2: b.ids.append(_roll_pb.play_stream(_rolling_waves[side],fmod(i*.731,8),-100,1,0,_buses[0]))

func reset_positions() -> void:
	super.reset_positions()
	_sweep.reset(); _history.clear(); _last_history=-1
	_cancel_events(true)
	_recent.clear(); _owner_context.clear()
	for voice in _squeals: _stop_squeal(voice)
	_squeals.clear(); active_squeal.clear()

func set_paused(value: bool) -> void:
	_paused=value
	reset_positions()
	for player in get_children():
		if player is AudioStreamPlayer: player.stream_paused=value

func _make_filter_bus(label: String,effect: AudioEffect) -> String:
	var name := "P%s-%s"%[get_instance_id(),label]
	AudioServer.add_bus()
	var index := AudioServer.bus_count-1
	AudioServer.set_bus_name(index,name)
	AudioServer.set_bus_send(index,BUS)
	AudioServer.add_bus_effect(index,effect)
	_buses.append(name)
	return name

func _listener() -> Dictionary:
	if camera.get_meta("on_platform",false):
		return {position=camera.global_position,forward=-camera.global_basis.z,up=camera.global_basis.y}
	return super._listener()

func _onboard() -> bool:
	return _cab or ("mode" in camera and camera.mode!=0)

func _passenger() -> bool:
	return "mode" in camera and (camera.mode==2 or (camera.mode==4 and camera.get_meta("passenger_interior",false)))

func _enclosed_cab() -> bool:
	return _onboard() and not _passenger() and not ("mode" in camera and camera.mode==3)

func _locate_at(back: float,dt: float=0) -> Dictionary:
	var distance := back-train.speed*dt
	if distance>=0: return _locate(distance)
	var loc: Dictionary=_locate(0)
	var ahead := -distance
	for i in 32:
		var available := absf(world.graph.exit_s(loc.edge,loc.dir)-loc.s)
		if ahead<=available:
			loc.s+=loc.dir*ahead; return loc
		ahead-=available
		var next := world.graph.next(loc.edge,loc.dir)
		if next.is_empty(): loc.s=world.graph.exit_s(loc.edge,loc.dir); return loc
		loc={edge=next.edge,dir=next.dir,s=world.graph.entry_s(next.edge,next.dir)}
	return loc

func _point_at(back: float,dt: float=0) -> Vector3:
	var loc := _locate_at(back,dt)
	return world.graph.position(loc.edge,loc.s)

func _prepare_receiver() -> void:
	_owner_context.clear()
	if not _onboard(): return
	var owner: Node=listener_owner if is_instance_valid(listener_owner) else self
	if owner._bogies.is_empty(): return
	var best := INF
	var own: Dictionary={}
	for b in owner._bogies:
		var point: Vector3=owner._point_at(b.x)
		var score := point.distance_squared_to(_ear.position)
		if score<best: best=score; own=b
	var same: Array=owner._bogies.filter(func(b): return b.car==own.car)
	if same.size()<2: return
	var front: Vector3=owner._point_at(same[0].x)
	var rear: Vector3=owner._point_at(same[-1].x)
	var tangent := (front-rear).normalized()
	var middle := (front+rear)*.5
	var local: Vector3 = _ear.position-middle
	_owner_context={owner=owner,car=own.car,front=same[0].x,rear=same[-1].x,along=local.dot(tangent),
		side=local.dot(tangent.cross(Vector3.UP)),height=local.y,back=(same[0].x+same[-1].x)*.5-local.dot(tangent)}

func _receiver_at(dt: float) -> Vector3:
	if _owner_context.is_empty(): return _ear.position+_receiver_velocity*dt
	var ctx := _owner_context
	var front: Vector3=ctx.owner._point_at(ctx.front,dt)
	var rear: Vector3=ctx.owner._point_at(ctx.rear,dt)
	var tangent := (front-rear).normalized()
	return (front+rear)*.5+tangent*ctx.along+tangent.cross(Vector3.UP)*ctx.side+Vector3.UP*ctx.height

func _process(delta: float) -> void:
	last_process_ms=0
	if train==null or _paused or _track.stream_paused: return
	var started := Time.get_ticks_usec()
	_track_sound(train.speed,train.speed*3.6,delta*simulation_rate)
	last_process_ms=(Time.get_ticks_usec()-started)*.001

func _track_sound(v: float,kmh: float,delta: float=1.0/60.0) -> void:
	if layout==null or _paused: return
	_time+=delta
	Timing.refresh()
	_start_window=maxf(.16,Timing.prediction_seconds(delta,simulation_rate)+.02)
	var perspective := 2 if _passenger() else (1 if _enclosed_cab() else (3 if _onboard() else 0))
	if _perspective!=perspective:
		reset_positions()
		for route in _routes: route.key=""; route.until=0.0
		_perspective=perspective
	var focus: Vector3=camera.global_position if _onboard() else camera.pivot
	if not joint_override.is_empty(): _selection=joint_override
	elif not _onboard() or reference_mode:
		if _selection.is_empty() or focus.distance_squared_to(_focus)>.25:
			if is_instance_valid(listener_owner) and listener_owner!=self and not listener_owner._selection.is_empty() and listener_owner._focus.distance_squared_to(focus)<.25:
				_selection=listener_owner._selection; _focus=listener_owner._focus
			else:
				_selection=Model.listening_joint(world.graph,focus); _focus=focus
	elif _selection.is_empty():
		# Onboard receivers use camera position and swept real contacts. A whole-
		# corridor nearest-joint search has no role in their mix.
		_selection={edge=train.path[0].edge,joint=0}
	if _selection.is_empty(): return
	var target := _listener()
	if _ear.is_empty(): _ear=target.duplicate(); _previous_target=target.position
	_receiver_velocity=(target.position-_previous_target)/maxf(.00001,delta)
	if _receiver_velocity.length()>100: _receiver_velocity=Vector3.ZERO
	_previous_target=target.position
	var smooth := 1-exp(-delta/(.008 if _onboard() else .035))
	_ear.position=_ear.position.lerp(target.position,smooth)
	_ear.forward=_ear.forward.lerp(target.forward,smooth).normalized(); _ear.up=target.up
	_prepare_receiver()
	var positions := []
	for a in _sched.axles: positions.append(_locate_at(a.x))
	var hits := _sweep.advance(positions,layout,delta)
	if _sweep.discontinuity or train.cab_end!=_last_cab:
		_cancel_events(true); _history.clear(); _recent.clear()
		for voice in _squeals: _stop_squeal(voice)
		_squeals.clear()
	_last_cab=train.cab_end
	# Predict far enough ahead for the measured device buffer and full attack.
	# Cancel unsounded predictions when
	# braking/route edits invalidate them; physical swept hits can schedule anew.
	var signature := str(train.path[0]) if not train.path.is_empty() else ""
	if absf(v-_last_speed)>.08 or signature!=_route_signature or v<=.001:
		_cancel_events(false)
	_last_speed=v; _route_signature=signature
	_update_events(delta)
	for h in hits: _schedule(h.axle,h.contact,h.relative)
	if v>.001:
		var lead := Timing.prediction_seconds(delta,simulation_rate)
		for i in positions.size():
			var now: Dictionary=positions[i]
			var ahead := _locate_at(_sched.axles[i].x,lead)
			var predictor := Sweep.new()
			predictor.previous=[now]
			for h in predictor.advance([ahead],layout,lead): _schedule(i,h.contact,lead+h.relative)
	if _time-_last_history>=.025 or _history.frames.is_empty():
		_record_history(positions,v); _last_history=_time
	_update_rolling(v,delta)
	_update_squeal(v,delta)

func _cancel_events(all: bool) -> void:
	for i in range(_events.size()-1,-1,-1):
		var event: Dictionary=_events[i]
		if not all and event.contact_time<=_time: continue
		for id in event.ids: event.playback.stop_stream(id)
		_recent.erase(event.key)
		_events.remove_at(i)

func _schedule(axle: int,contact: Dictionary,relative: float) -> void:
	if reference_mode and (contact.edge!=_selection.edge or contact.id!=_selection.joint): return
	var key: String = str(axle)+"/"+contact.key
	if _recent.has(key):
		if relative<=0:
			for previous in _events:
				if previous.key==key and not previous.started: previous.contact_time=_time+relative
		return
	_recent[key]=_time
	var source: Vector3=contact.source
	if source.distance_squared_to(_ear.position)>IMPACT_PREFETCH_DISTANCE*IMPACT_PREFETCH_DISTANCE:
		culled_impacts += 1
		return
	var time := _time+relative
	var arrival: float
	if _onboard(): arrival=_time+Acoustics.curved_arrival(source,relative,_receiver_at)
	else: arrival=time+Model.propagation(source,_ear.position)
	var jid: int=0 if reference_mode else contact.id
	var identity: Dictionary=_identities[axle]
	var variant := Acoustics.variant(identity,jid)
	var gain: float=identity.load*contact.strength*Data.MASTER*track_level
	if identity.order==1: gain*=db_to_linear(clang_balance_db)
	if _passenger(): gain*=sqrt(2)
	if not _owner_context.is_empty() and _owner_context.owner==self and train.speed>.01:
		var leading := -1
		var balance := false
		if _passenger():
			var pair := Acoustics.passenger_pair(_bogies,_owner_context.car,_owner_context.back)
			if axle==pair.x: leading=pair.y; balance=true
		elif identity.locomotive and identity.vehicle==_owner_context.car:
			for i in _identities.size():
				if _identities[i].vehicle==identity.vehicle and (leading<0 or _identities[i].x<_identities[leading].x): leading=i
		if leading>=0 and leading!=axle:
			var own := Acoustics.body_level(identity,jid,source,relative,_receiver_at)
			var other: Dictionary=_identities[leading]
			var front := Acoustics.body_level(other,jid,source,relative+(other.x-identity.x)/train.speed,_receiver_at)
			gain*=Acoustics.passenger_gain(own,front) if balance else Acoustics.cab_gain(own,front)
	var priority := gain*Model.falloff(source.distance_to(_ear.position),false)
	var event := {key=key,axle=axle,contact=contact,contact_time=time,arrival=arrival,source=source,variant=variant,gain=gain,
		ids=[],end=arrival-Data.KERNEL_LEAD+Data.KERNEL_SECONDS,heard=false,virtual=false,route="",started=false,priority=priority,bypass=not _onboard() and jid==0}
	# Retained contacts keep physical identity even when voice-budget virtualized.
	# Inaudible remote contacts never enter the costly retarded-arrival queue.
	_events.append(event)
	if arrival-_time<=_start_window: _start_event(event)

func _start_event(event: Dictionary) -> void:
	var source: Vector3=event.source
	var delay: float=event.arrival-_time-Data.KERNEL_LEAD
	event.started=true
	var channels := 0
	for pending in _events: channels+=pending.ids.size()
	if source.distance_to(_ear.position)>1600 or delay< -.04 or channels+2>MAX_IMPACT_CHANNELS:
		event.virtual=true
		return
	var route := _route_for(event.contact,event.priority,event.bypass)
	if route.is_empty():
		event.virtual=true
	else:
		event.route=route.bus; event.playback=route.playback
		route.player.volume_db=_track.volume_db
		var gains: Vector2 = Acoustics.stereo(source,_ear.position,_ear.forward,_ear.up,600 if event.bypass else 1600)*event.gain
		var buffered := Timing.delay_seconds()*simulation_rate
		output_delay_ms=Timing.delay_seconds()*1000
		var offset := maxf(0,Data.PAD-delay+buffered)
		event.output_delay=buffered; event.offset=offset; event.scheduled_at=_time
		for side in 2:
			event.ids.append(event.playback.play_stream(_routed[event.variant][side],offset,linear_to_db(maxf(.000001,gains[side])),1))
		route.until=maxf(route.until,event.end); route.priority=event.priority
		if -1 in event.ids:
			for id in event.ids:
				if id>=0: event.playback.stop_stream(id)
			event.ids=[]; event.virtual=true

func _route_for(contact: Dictionary,priority: float,bypass: bool) -> Dictionary:
	for route in _routes:
		if route.key==contact.key: return route
	var slot: Dictionary={}
	for route in _routes:
		if route.until<_time: slot=route; break
	if slot.is_empty() and _routes.size()<MAX_JOINT_ROUTES:
		var filter := AudioEffectLowPassFilter.new()
		# Web Audio low-pass Q is decibels: Q=.5 -> linear 10^(.5/20).
		filter.resonance=pow(10,.5/20); filter.db=AudioEffectFilter.FILTER_6DB
		var bus := _make_filter_bus("joint%d"%_routes.size(),filter)
		var player := _poly_player(32)
		player.bus=bus
		slot={bus=bus,filter=filter,player=player,playback=player.get_stream_playback(),until=0.0,priority=0.0}
		_routes.append(slot)
	if slot.is_empty():
		for route in _routes:
			if slot.is_empty() or route.priority<slot.priority: slot=route
		if priority<=slot.priority: return {}
		for event in _events:
			if event.route==slot.bus:
				for id in event.ids: event.playback.stop_stream(id)
				event.ids=[]; event.virtual=true
	var index := AudioServer.get_bus_index(slot.bus)
	# Recreate the filter instance to prevent a previous joint's IIR tail leaking.
	AudioServer.remove_bus_effect(index,0)
	slot.filter=slot.filter.duplicate()
	AudioServer.add_bus_effect(index,slot.filter)
	slot.filter.cutoff_hz=Acoustics.impact_cutoff(contact.source,_ear.position,_onboard(),_enclosed_cab(),_owner_context.get("side",.4))
	AudioServer.set_bus_effect_enabled(index,0,not bypass)
	slot.key=contact.key; slot.source=contact.source; slot.bypass=bypass; slot.until=_time; slot.priority=priority
	return slot

func _update_events(delta: float) -> void:
	var onboard:=_onboard()
	var receiver: Vector3=_receiver_at(0.0) if onboard else _ear.position
	var window:=_start_window+.02
	var receiver_travel:=_receiver_velocity.length()*window
	if not _owner_context.is_empty():
		# The bogie midpoint travels at most v*dt. Its offset can rotate by
		# at most twice its length, including a turnout/coach-end transition.
		receiver_travel=_owner_context.owner.train.speed*window+2*(absf(_owner_context.along)+absf(_owner_context.side))+1.0
	for key in _recent.keys():
		if _time-_recent[key]>5.5: _recent.erase(key)
	for i in range(_events.size()-1,-1,-1):
		var event: Dictionary=_events[i]
		if not event.started:
			if onboard:
				if not Acoustics.impact_can_arrive(event.source,receiver,_time-event.contact_time,window,receiver_travel): continue
				event.arrival=_time+Acoustics.curved_arrival(event.source,event.contact_time-_time,_receiver_at)
				event.end=event.arrival-Data.KERNEL_LEAD+Data.KERNEL_SECONDS
			if event.arrival-_time<=_start_window: _start_event(event)
		if not event.heard and event.arrival<=_time:
			event.heard=true
			contact_event.emit(event.duplicate())
			if event.contact.id<100000: joint_hit.emit(event.contact.edge,event.contact.id,_sched.axles[event.axle].cls)
			debug_events.append({axle=event.axle,contact=event.contact.key,physical=event.contact_time,arrival=event.arrival,variant=event.variant,virtual=event.virtual})
			if debug_events.size()>2048: debug_events.pop_front()
		if event.end<=_time:
			for id in event.ids: event.playback.stop_stream(id)
			_events.remove_at(i); continue
		if not event.ids.is_empty():
			var gains: Vector2 = Acoustics.stereo(event.source,_ear.position,_ear.forward,_ear.up)*event.gain
			for side in event.ids.size(): event.playback.set_stream_volume(event.ids[side],linear_to_db(maxf(.000001,gains[side])))
	for route in _routes:
		if route.until<_time: continue
		var cutoff := Acoustics.impact_cutoff(route.source,_ear.position,_onboard(),_enclosed_cab(),_owner_context.get("side",.4))
		route.filter.cutoff_hz=lerpf(route.filter.cutoff_hz,cutoff,1-exp(-delta/.05))

func _update_rolling(v: float,delta: float) -> void:
	var distances := []
	for b in _bogies:
		var loc := _locate_at(b.x)
		b.target=world.graph.position(loc.edge,loc.s)+Vector3.UP*.7
		b.velocity=world.graph.tangent(loc.edge,loc.s,loc.dir)*v
		distances.append(b.target.distance_to(_ear.position))
	last_normalizer=Model.normalizer(distances)
	var mix := Acoustics.rolling_mix(v*3.6)
	_roll_gain=lerpf(_roll_gain,last_normalizer*mix.x,1-exp(-delta/.035))
	_hiss_db=lerpf(_hiss_db,mix.y,1-exp(-delta/.08))
	# Godot's shelf gain is RBJ A=10^(dB/40), not the amplitude ratio.
	if _hiss!=null: _hiss.gain=pow(10,_hiss_db/40)
	for i in _bogies.size():
		var b: Dictionary=_bogies[i]
		b.position=b.position.lerp(b.target,1-exp(-delta/(.008 if _onboard() else .04))) if b.started else b.target
		b.started=true
		var radial: float=0 if _onboard() else b.velocity.dot(b.target-_ear.position)/maxf(.001,distances[i])
		b.pitch=lerpf(b.pitch,Model.rolling_pitch(radial),1-exp(-delta/.04))
		var gains := Acoustics.stereo(b.position,_ear.position,_ear.forward,_ear.up,600)*_roll_gain*Data.MASTER*track_level
		for side in 2:
			_roll_pb.set_stream_volume(b.ids[side],linear_to_db(maxf(gains[side],.000001)))
			_roll_pb.set_stream_pitch_scale(b.ids[side],b.pitch)

func _record_history(positions: Array,v: float) -> void:
	var points := PackedVector3Array()
	var tangents := PackedVector3Array()
	var curves := PackedFloat32Array()
	for loc in positions:
		points.append(world.graph.position(loc.edge,loc.s))
		# Reverse BOTH tangent and signed curvature: their normal product keeps
		# the same physical inner rail and stays continuous across oriented edges.
		tangents.append(world.graph.tangent(loc.edge,loc.s,loc.dir))
		curves.append(layout.curvature(loc.edge,loc.s)*loc.dir)
	_history.append(_time,v,points,tangents,curves)

func _heard_state(bogie: Dictionary) -> Dictionary:
	var local_bogie := bogie.duplicate()
	local_bogie.indices=range(bogie.indices.size())
	var emission := _time
	var state := {}
	for i in 8:
		var sample := _history.sample(emission,bogie.indices)
		if sample.is_empty(): return {}
		state=Acoustics.squeal_state(emission,sample.speed,local_bogie,sample.positions,sample.tangents,sample.curvatures)
		var next_emission: float=_time-state.source.distance_to(_ear.position)/343.0
		if absf(next_emission-emission)<.00000001:
			emission=next_emission
			break
		emission=next_emission
	var sample := _history.sample(emission,bogie.indices)
	if sample.is_empty(): return {}
	state=Acoustics.squeal_state(emission,sample.speed,local_bogie,sample.positions,sample.tangents,sample.curvatures)
	state.distance=state.source.distance_to(_ear.position)
	state.received=state.level*Model.falloff(state.distance,false)
	state.velocity=sample.tangents[state.axle]*sample.speed
	state.axle=bogie.indices[state.axle]
	state.variant=posmod(bogie.car*3+bogie.index,4)
	return state

func _update_squeal(v: float,delta: float) -> void:
	var candidates := []
	var power := 0.0
	if v>.001 and squeal_amount>0 and not reference_mode:
		for b in _bogies:
			# Even at the maximum recent speed, a five-second history cannot
			# bring these distant sources into the 1.6 km audible region.
			if b.target.distance_squared_to(_ear.position)>pow(1600+500,2): continue
			var state := _heard_state(b)
			if state.is_empty() or state.received<=.0015 or state.distance>1600: continue
			power+=state.received*state.received; candidates.append(state)
	candidates.sort_custom(func(a,b): return a.received>b.received)
	if candidates.size()>MAX_SQUEAL_VOICES: candidates.resize(MAX_SQUEAL_VOICES)
	active_squeal=candidates
	var norm := 1/maxf(1,sqrt(power))
	for voice in _squeals: voice.wanted=false
	for state in candidates:
		var voice := {}
		for existing in _squeals:
			if existing.id==state.id and existing.release<0: voice=existing; break
		if voice.is_empty():
			# Tails occupy slots until their 300 ms release finishes; avoid an
			# unbounded bank of releasing voices during rapid curve re-entry.
			if _squeals.size()>=MAX_SQUEAL_VOICES: continue
			var filter := AudioEffectLowPassFilter.new()
			filter.resonance=pow(10,.5/20); filter.db=AudioEffectFilter.FILTER_6DB
			_voice_serial+=1
			var texture := AudioEffectHighShelfFilter.new()
			texture.cutoff_hz=4800; texture.resonance=.5; texture.db=AudioEffectFilter.FILTER_6DB
			texture.gain=pow(10,state.edge_db/40)
			var bus := _make_filter_bus("squeal%d"%_voice_serial,texture)
			AudioServer.add_bus_effect(AudioServer.get_bus_index(bus),filter)
			var player := _poly_player(2)
			player.bus=bus
			var playback := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
			var ids := []
			for side in 2: ids.append(playback.play_stream(_squeal_waves[state.variant][side],fposmod(state.emission+state.variant*.731,EnhancedData.SQUEAL_SECONDS),-100,1))
			voice={id=state.id,ids=ids,bus=bus,player=player,playback=playback,filter=filter,texture=texture,edge_db=state.edge_db,gain=0.0,pitch=1.0,position=state.source,release=-1.0,cutoff=12000.0,wanted=true}
			_squeals.append(voice)
		voice.wanted=true; voice.state=state
	for i in range(_squeals.size()-1,-1,-1):
		var voice: Dictionary=_squeals[i]
		if not voice.wanted and voice.release<0: voice.release=_time
		if voice.release>=0 and _time-voice.release>=.3:
			_stop_squeal(voice); _squeals.remove_at(i); continue
		var state: Dictionary=voice.get("state",{})
		var goal: float=squeal_amount*state.get("level",0)*norm*(.85 if _enclosed_cab() else 1.0) if voice.wanted else 0.0
		voice.gain=lerpf(voice.gain,goal,1-exp(-delta/(.075 if voice.wanted else .055)))
		if not state.is_empty():
			voice.position=voice.position.lerp(state.source,1-exp(-delta/.012))
			var radial: float=0 if _onboard() else state.velocity.dot(state.source-_ear.position)/maxf(.1,state.distance)
			voice.pitch=lerpf(voice.pitch,343/(343+radial),1-exp(-delta/.06))
			var cutoff: float=(3200 if _enclosed_cab() else 12000)/(1+maxf(0,state.distance-4)/30)
			voice.cutoff=lerpf(voice.cutoff,cutoff,1-exp(-delta/.06))
			voice.filter.cutoff_hz=voice.cutoff
			voice.edge_db=lerpf(voice.edge_db,state.edge_db,1-exp(-delta/.08))
			voice.texture.gain=pow(10,voice.edge_db/40)
		var gains: Vector2 = Acoustics.stereo(voice.position,_ear.position,_ear.forward,_ear.up)*voice.gain*Data.MASTER*track_level
		for side in 2:
			voice.playback.set_stream_volume(voice.ids[side],linear_to_db(maxf(.000001,gains[side])))
			voice.playback.set_stream_pitch_scale(voice.ids[side],voice.pitch)

func _stop_squeal(voice: Dictionary) -> void:
	voice.player.stop()
	voice.player.free()
	var index := AudioServer.get_bus_index(voice.bus)
	if index>=0: AudioServer.remove_bus(index)
	_buses.erase(voice.bus)

func _exit_tree() -> void:
	for player in get_children():
		if player is AudioStreamPlayer: player.stop()
	super._exit_tree()
	for name in _buses:
		var index := AudioServer.get_bus_index(name)
		if index>=0: AudioServer.remove_bus(index)
	_buses.clear()