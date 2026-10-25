extends SceneTree
## Known kinematic trajectories exercise the actual native audio scheduler and
## floating-origin listener. This isolates propagation; it is not a railway
## safety, rendered-scene, hardware-device or real-time performance benchmark.
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Sound:=preload("res://game/platform_audio.gd")
const Space:=preload("res://game/listening_space.gd")
var output:="res://.local/realism-2026-10-26/moving-sound.json"
var report:={cases=[],failures=[]}
var family:="icf"
var captures:={}
var sounds:=[]
var motions:=[]
var rakes:=[]
var airs:=[]
var camera
var proxy
var world
var context:={}
var origin:=Vector3(100000,0,200000)

func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:report.failures.append(label);printerr("FAIL ",label)
func capture(name: String,bus: String) -> void:
	var effect:=AudioEffectCapture.new();effect.buffer_length=2
	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus),effect);captures[name]=effect
func drain() -> Dictionary:
	var result:={}
	for name in captures:
		var pcm: PackedVector2Array=captures[name].get_buffer(captures[name].get_frames_available())
		var energy:=0.0;var peak:=0.0
		for s in pcm:energy+=s.length_squared()*.5;peak=maxf(peak,maxf(absf(s.x),absf(s.y)))
		result[name]={rms=sqrt(energy/maxi(1,pcm.size())),samples=pcm.size(),peak=peak}
	return result
func place(own_s: float,other_s: float,yaw: float) -> void:
	for i in 2:
		var t: Train=sounds[i].train;t.head_s=own_s if i==0 else other_s
		motions[i].reset();motions[i].coordinate_origin=origin
		for car in rakes[i].size():
			var spec: Dictionary=Stock.formation(family)[car]
			rakes[i][car].position=motions[i].point(spec.center)
			rakes[i][car].rotation.y=-PI/2 if t.path[0].dir>0 else PI/2
	camera.position=world.graph.position("line0",own_s-200)+Vector3(0,2,1.1)-origin
	camera.rotation=Vector3(0,yaw,0);proxy.sync(camera,origin)
func tick(delta: float) -> void:
	for sound in sounds:sound._track_sound(sound.train.speed,sound.train.speed*3.6,delta)
	for air in airs:air._process(delta)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--fleet="):family=arg.trim_prefix("--fleet=")
	Engine.max_fps=120
	var prefs:=preload("res://game/audio_preferences.gd").new("res://.local/realism-2026-10-26/no-audio-preferences.cfg")
	for key in prefs.levels:prefs.levels[key]=0.0;prefs.muted[key]=false
	prefs.quiet=false;prefs.reference=false;prefs.headphones=true;prefs.apply();AudioServer.set_bus_volume_db(0,-80)
	camera=preload("res://game/camera_rig.gd").new();root.add_child(camera);camera.set_process(false);camera.mode=2;camera.make_current()
	proxy=preload("res://game/geographic_audio_listener.gd").new();root.add_child(proxy);proxy.set_process(false)
	world=RailWorld.new()
	var model: String={icf="icf_sl",lhb="lhb_3a",vb16="vb_cc"}[family]
	context={cam=camera,world=world,audio_options=prefs,audio_space=Space.compartment(model,Vector3(1.1,2,0),22.297,0)}
	context.audio_space.velocity=Vector3(10,0,0);context.audio_space.car=8
	for i in 2:
		var edge:="line"+str(i)
		world.graph.add_node(edge+"a",origin+Vector3(0,0,i*5));world.graph.add_node(edge+"b",origin+Vector3(10000,0,i*5));world.graph.add_edge(edge,edge+"a",edge+"b")
		var t:=Train.new(str(i),Stock.length_of(family));Stock.configure(t,family);t.path=[{edge=edge,dir=1}];t.head_s=3000;t.speed=10 if i==0 else 30
		world.trains[t.id]=t
		if i==0:context.train=t
		var motion:=preload("res://game/train_motion.gd").new(t,world.graph);motions.append(motion)
		var rake:=[]
		for spec in Stock.formation(family):
			var car:=Node3D.new();root.add_child(car);rake.append(car)
		rakes.append(rake)
		var sound:=Sound.new();sound.game=context;root.add_child(sound);sound.motion=motion;sound.setup(t,world,proxy,Stock.sound_axles(family));sound.set_process(false);sounds.append(sound)
		if i==0:sound.track_level=0 # Only the neighboring train contributes rail PCM.
		var air:=preload("res://game/train_air_audio.gd").new();root.add_child(air);air.setup(context,{train=t,motion=motion,cars=rake,formation=Stock.formation(family)},sound);air.set_process(false);airs.append(air)
	for sound in sounds:sound.listener_owner=sounds[0]
	capture("rolling",sounds[1]._buses[0]);capture("impacts","RailImpacts");capture("air","PassingAir")
	for opposite in [true,false]:
		for rotating in [false,true]:
			sounds[1].train.path[0].dir=-1 if opposite else 1
			for sound in sounds:sound.reset_positions()
			var label:="%s-%s-%s" % [family,"oncoming" if opposite else "overtaking","turning" if rotating else "fixed"]
			print("MOVING_SOUND_BEGIN ",label)
			var began:=Time.get_ticks_usec();var elapsed:=0.0;var next_bin:=.5;var bins:=[];var rebased:=false;var maximum_frame:=0.0
			for effect in captures.values():effect.clear_buffer()
			while elapsed<40:
				await process_frame
				var next:=(Time.get_ticks_usec()-began)*.000001;var delta:=next-elapsed;elapsed=next;maximum_frame=maxf(maximum_frame,delta)
				# Both runs use the same positions. Rotation is the only comparison
				# variable; a floating-origin rebase occurs in both at 20 seconds.
				if elapsed>=20 and not rebased:origin+=Vector3(1024,0,-1024);rebased=true
				var other_s:=3250-30*elapsed if opposite else 2450+30*elapsed
				place(3000+10*elapsed,other_s,sin(elapsed*1.4)*PI if rotating else 0.0)
				tick(delta)
				if elapsed>=next_bin:
					var nearest:=INF
					for bogie in sounds[1]._bogies:nearest=minf(nearest,bogie.position.distance_to(sounds[1]._ear.position))
					bins.append({seconds=elapsed,pcm=drain(),paused=sounds[1]._paused,events=sounds[1]._events.size(),nearest_bogie_m=nearest,receiver_error=sounds[1]._ear.position.distance_to(camera.position+origin)})
					next_bin+=.5
			var row:={case=label,opposite=opposite,rotating=rotating,bins=bins,maximum_frame_seconds=maximum_frame}
			report.cases.append(row)
			check(bins.size()>=75,label+" native half-second capture grid")
			check(bins.all(func(b):return not b.paused and b.pcm.rolling.samples>1000),label+" no pause or missing mixer data")
			check(bins.slice(2).filter(func(b):return b.nearest_bogie_m<250).all(func(b):return b.pcm.rolling.rms>.0000001),label+" nearby rail never mutes during pass/head turns/rebase")
			check(bins.any(func(b):return b.pcm.impacts.rms>.00001),label+" real swept contacts produce native impacts")
			FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
			print("MOVING_SOUND_END ",label," bins=",bins.size()," maximum_frame=",maximum_frame)
	for air in airs:air.free()
	for sound in sounds:sound.free()
	for rake in rakes:
		for car in rake:car.free()
	proxy.free();camera.free();captures.clear();context.clear();sounds.clear();airs.clear();rakes.clear();motions.clear()
	await create_timer(.3).timeout
	print("MOVING_SOUND failures=",report.failures.size());quit(0 if report.failures.is_empty() else 1)
