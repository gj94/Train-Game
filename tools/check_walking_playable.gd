extends SceneTree
## Actual game/camera/audio/controller integration. No extracted build is run.
var game
var pad
var walk
var checks:=0
var failures:=0
var family:="icf"
const DEVICE:=14

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fleet="): family=arg.trim_prefix("--fleet=")
	set_meta("imported_fleet",family)
	set_meta("traffic_drive",false)
	if "--kerala" in OS.get_cmdline_user_args():
		set_meta("route","kerala_coast")
		set_meta("traffic_seed",0)
		family="kerala"
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+message)

func frames() -> void:
	await process_frame
	await process_frame
	pad._process(.016)
	walk.update(.016)
	game.cam._process(.016)

func button(index: int, pressed: bool) -> void:
	var e:=InputEventJoypadButton.new()
	e.device=DEVICE;e.button_index=index;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()

func tap(index: int) -> void:
	button(index,true);await frames();button(index,false);await frames()

func axis(index: int, value: float) -> void:
	var e:=InputEventJoypadMotion.new()
	e.device=DEVICE;e.axis=index;e.axis_value=value
	Input.parse_input_event(e);Input.flush_buffered_events()

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/walking-"+family+"-"+name+".png")

func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_physics_process(false)
	if game.geographic_drive:
		var start:=Time.get_ticks_msec()
		while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
		check(not game.wv.loading,"Kerala route scenery is ready")
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false)
	pad.set_process(false);game.dispatcher.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	pad.settings_path="res://.local/walking-controller-test.cfg"
	pad.tsw_layout=true;pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true)
	await frames()
	game.train.automatic=false;game.train.controller=.35
	await tap(JOY_BUTTON_Y)
	check(walk.active and game.cam.mode==4,"Y stands in the real driving cab")
	if not walk.active: quit(1);return
	check(game.train.controller==.35,"standing preserves power/brake")
	check(game.audio._cab,"standing keeps onboard acoustics")
	game._process(.016)
	check(not game.audio._passenger() and game.audio._enclosed_cab(),"standing in the driver's compartment keeps cab acoustics")
	check(game.hud._toolbar.get_child(1).text=="DISPATCH  9","HUD shows the on-foot dispatch binding")
	await shot("cab")
	check(walk.sit() and game.cam.mode==1,"driver can immediately sit back at the controls")
	check(walk.stand(),"driver can stand again")
	await frames()
	var pos:Vector2=walk.position
	axis(JOY_AXIS_LEFT_Y,-1);axis(JOY_AXIS_TRIGGER_RIGHT,1)
	for i in 10: walk.update(.1);game._physics_process(.016)
	check(game.train.controller==.35 and not game.train.automatic,"walking/running cannot alter driver/handle")
	check(walk.nav.allowed(walk.position),"cab equipment blocks movement")
	axis(JOY_AXIS_LEFT_Y,0);axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	await tap(JOY_BUTTON_B)
	check(walk.crouched,"B crouches on foot")
	await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_DPAD_UP)
	check(walk.lamp_enabled and walk._lamp.visible,"headlamp is available on foot")
	await tap(JOY_BUTTON_BACK)
	check(game.dispatcher._root.visible and walk.active,"View opens dispatch without leaving on-foot state")
	await tap(JOY_BUTTON_B)
	check(not game.dispatcher._root.visible,"B closes dispatch")
	button(JOY_BUTTON_X,true);button(JOY_BUTTON_B,true);await frames()
	button(JOY_BUTTON_B,false);button(JOY_BUTTON_X,false);await frames()
	check(game.train.emergency,"X+B deliberate emergency works on foot")
	game.train.speed=0;game.train.emergency=false
	# Sample all coaches, including opposite-facing trailing VB cab and EC cars.
	for car in game.tv.passenger_coaches():
		game.tv.passenger_coach=car;game.tv.passenger_seat=true;game.tv.passenger_seat_index=0
		game._enter_passenger();await frames()
		check(walk.stand(),"stand from seat in "+str(game.tv.formation[car].model))
		await frames()
		game._process(.016)
		check(game.audio._passenger() and not game.audio._enclosed_cab(),"walking from a passenger seat keeps passenger acoustics")
		check(walk.car==car and walk.nav.component(walk.position,true).size()>=40,"standing placement avoids isolated floor fragments")
		var previous:Transform3D=game.tv.cars[car].global_transform
		game.tv.cars[car].global_transform=Transform3D(Basis(Vector3.UP,.8),Vector3(300,10,-80))*previous
		var expected:Vector3=game.tv.cars[car].global_transform*Vector3(walk.position.x,walk.nav.floor_height(walk.position)+walk.eye_height,walk.position.y)
		check(walk.camera_transform().origin.distance_to(expected)<.0001,"walking follows moving/rotating/rebased carriage")
		check(walk.audio_position().is_equal_approx(game.tv.interior_audio_position()),"audio listener follows walked position")
		game.tv.cars[car].global_transform=previous
		check(walk.sit(),"nearby real passenger seat can be re-entered")
		check(game.tv.passenger_seat_index>=0 and not walk.active,"sit stores exact selected seat")
	# Aisle movement, view shift, doorway and gangway links.
	game._passenger_preset(1);await frames();walk.stand();await frames()
	game.cam._look=Vector2.ZERO
	pos=walk.position
	axis(JOY_AXIS_LEFT_Y,-1)
	for i in 5:walk.update(.1)
	axis(JOY_AXIS_LEFT_Y,0)
	check(walk.position.distance_to(pos)>.1,"LS moves continuously along the aisle")
	axis(JOY_AXIS_RIGHT_X,1);pad._process(10);axis(JOY_AXIS_RIGHT_X,0)
	check(absf(game.cam._look.x)<=PI,"on-foot look wraps through a full turn")
	game.cam._look=Vector2.ZERO;await shot("aisle")
	var original_car:int=walk.car
	for attempt in 5:
		var entries:Array=walk.nav.room_exits(walk.position)
		var chosen:Dictionary={}
		for entry in entries:
			if entry.direction==1:chosen=entry;break
		if chosen.is_empty():break
		walk.position=chosen.point;walk.crouched=true
		game.cam._look=Vector2(PI,0);walk.update(.016)
		walk.interact();await frames()
		if walk.car!=original_car:break
	check(walk.car==original_car+1,"doorway sequence reaches next passenger coach")
	check(walk.nav.allowed(walk.position,true),"gangway lands on supported interior floor")
	for i in 18:walk.update(.016)
	await shot("gangway")
	var returning_car:int=walk.car
	var return_direction:int=1 if game.tv.formation[walk.car].reverse else -1
	for attempt in 5:
		var chosen:Dictionary={}
		for entry in walk.nav.room_exits(walk.position):
			if entry.direction==return_direction:chosen=entry;break
		if chosen.is_empty():break
		walk.position=chosen.point
		game.cam._look=Vector2(PI if return_direction>0 else 0,0)
		walk.interact();await frames()
		if walk.car!=returning_car:break
	check(walk.car==original_car,"gangway returns correctly through an oppositely-oriented car")
	var started:=Time.get_ticks_usec()
	for i in 200:walk.update(.016)
	print("On-foot update mean: %.3f ms" % ((Time.get_ticks_usec()-started)/200000.0))
	# A held walking key must not become a throttle command when sitting.
	var held:=InputEventKey.new()
	held.physical_keycode=KEY_W;held.pressed=true
	Input.parse_input_event(held);Input.flush_buffered_events()
	game._pilot_camera();game.train.controller=.2
	game._physics_process(.1)
	check(game.train.controller==.2,"held W cannot leak from walking into traction")
	held=held.duplicate();held.pressed=false;Input.parse_input_event(held);Input.flush_buffered_events()
	game._physics_process(.016)
	walk.stand();await frames()
	# Changing view must stop walking and its headlamp; AI is preserved.
	game.train.automatic=true
	await tap(JOY_BUTTON_LEFT_STICK)
	check(not walk.active and game.cam.mode==1 and not walk._lamp.visible,"L3 returns pilot without accidental tap-toggle")
	check(game.train.automatic,"pilot shortcut preserves AI")
	button(JOY_BUTTON_BACK,true);pad._process(.6);button(JOY_BUTTON_BACK,false);await frames()
	check(game.hud.modal=="progress" and not game.dispatcher._root.visible,"hold View shows progress without opening dispatch")
	await tap(JOY_BUTTON_B)
	game.train.automatic=false;game.train.controller=0
	await tap(JOY_BUTTON_START);axis(JOY_AXIS_TRIGGER_RIGHT,1);await tap(JOY_BUTTON_A)
	check(pad.drive_input()==0,"held trigger cannot leak from pause into traction")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames();axis(JOY_AXIS_TRIGGER_RIGHT,1)
	check(pad.drive_input()>0,"neutral then deliberate trigger restores traction")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	game._physics_process(.016) # Release the walking-key guard before driving.
	game.train.controller=0
	var brake_key:=InputEventKey.new()
	brake_key.physical_keycode=KEY_S;brake_key.pressed=true
	Input.parse_input_event(brake_key);Input.flush_buffered_events()
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	game._physics_process(.2)
	check(game.train.controller<-.15,"keyboard brake wins simultaneous controller power")
	brake_key=brake_key.duplicate();brake_key.pressed=false
	Input.parse_input_event(brake_key);Input.flush_buffered_events()
	game.train.controller=1;game.train.automatic=true
	game._physics_process(.016)
	check(not game.train.automatic,"explicit power input takes manual control even at handle limit")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	print("Walking "+family+": %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
