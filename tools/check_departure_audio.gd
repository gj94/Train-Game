extends SceneTree
## Exercise the production native AudioStreamPlayer3D and sim together.
## Playback-state audit with Dummy output; no claim of a human listening test.
const Fixture := preload("res://tests/test_departure_sequence.gd")
const Sound := preload("res://game/engine_audio.gd")
const Cues := preload("res://sim/departure_cues.gd")
var failures:=0
var results:=[]
class Track extends RefCounted:
	var _paused:=false
class Motion extends RefCounted:
	var train: Train
	func locate(_distance: float) -> Dictionary:return {edge=train.path[0].edge,s=train.head_s,dir=train.path[0].dir}
class View extends RefCounted:
	var train: Train
	var cars: Array=[]
	var formation: Array=[{model="wap7",pitch=20.4}]
	var motion:=Motion.new()
class Owner extends RefCounted:
	var world: RailWorld
	var train: Train
	var cam: Camera3D
	var audio_options:={reference=false,headphones=false}
	var audio_space:={inside=false,exposure=1.0,room=0.0}

func check(value: bool,message: String) -> void:
	if not value:failures+=1;printerr("FAIL "+message)
func _initialize() -> void:call_deferred("run")

func scenario(mode: String,rate: float=1.0) -> void:
	var w:=Fixture.new().fixture();var t: Train=w.trains.AI
	var owner:=Owner.new();owner.world=w;owner.train=t if mode!="other_ai" else Train.new("PLAYER",100)
	owner.cam=Camera3D.new();root.add_child(owner.cam);owner.cam.current=true;owner.cam.position=Vector3(4,3,0)
	var view:=View.new();view.train=t;view.motion.train=t
	var car:=Node3D.new();root.add_child(car);view.cars=[car]
	var track:=Track.new();var sound:=Sound.new();root.add_child(sound)
	sound.setup(owner,view,track);sound.set_process(false)
	AudioServer.set_bus_volume_db(0,-80) # no audible disturbance to the development PC
	if mode=="handover":
		t.automatic=false;w.dispatcher().manual_service=t.id
		w.step(1);sound._process(.05);t.automatic=true
	var start:=w.clock_seconds();var events:=[];var was_playing:=false;var moved:=-1.0
	for i in ceili(8.0/(.05*rate)):
		w.step(.05*rate);sound._process(.05)
		var now: float=w.clock_seconds()-start
		var playing:=sound.horn_player.playing
		if playing!=was_playing:
			events.append({at=now,playing=playing,speed=t.speed,odometer=t.odometer})
			was_playing=playing
		if playing:check(t.speed==0,mode+" horn still playing while moving")
		if t.speed>0 and moved<0:moved=now
		await process_frame
	var calls:=events.filter(func(e):return e.playing)
	check(calls.size()==2,mode+" two native playback starts")
	check(events.size()==4 and not sound.horn_player.playing,mode+" both playback calls stopped")
	if calls.size()==2:check(absf(calls[1].at-calls[0].at-Cues.GAP)<=.05*rate+.001,mode+" simulation-time gap")
	if events.size()==4:check(moved>=events[3].at,mode+" movement after native playback ended")
	results.append({case=mode,rate=rate,events=events,first_movement=moved})
	sound.free();car.free();owner.cam.free()
	# Native mixer releases queued stream playback references asynchronously.
	await create_timer(.2).timeout

func run() -> void:
	Engine.max_fps=60
	await scenario("own_ai")
	await scenario("other_ai")
	await scenario("handover")
	await scenario("fast_forward",4)
	var report:={failures=failures,native_playback_state=true,human_listening_test=false,cases=results}
	FileAccess.open("res://.local/r42-native-horns.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(1 if failures else 0)
