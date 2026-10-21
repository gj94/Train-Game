extends SceneTree
const Starts:=preload("res://persistence/service_starts.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	var id:="K1"
	var passenger: bool="--driver" not in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--service="):id=arg.trim_prefix("--service=")
	var catalogue:=Starts.catalogue()
	if not catalogue.ok:check(false,catalogue.reason);quit(1);return
	var matches: Array=catalogue.data.services.filter(func(r):return r.id==id)
	if matches.is_empty():check(false,"Unknown fixture service "+id);quit(1);return
	var row: Dictionary=matches[0]
	var choice:=Starts.load_start(row);choice.service=id;choice.passenger_start=passenger;choice.timetable_id="standard"
	if not choice.ok:check(false,choice.reason);quit(1);return
	if not passenger:Starts.select(choice.world,id)
	var expected_clock: float=choice.world.clock_seconds()
	var before:=Snapshot.capture(choice.world)
	preload("res://persistence/operating_days.gd").stage_start(self,choice)
	var game=load("res://game/main.tscn").instantiate()
	game.set_physics_process(false);root.add_child(game);current_scene=game
	game.set_process(false);game.cam.set_process(false)
	game.journey_tools.autosaves=false;game.journey_tools.set_process(false);game.journey_tools.save_directory="res://.local/r45/departure-saves"
	check(game.train.id==id and game._prepared_id==id,"Selected departure retained for restart")
	check(game.paused and (game._passenger_seated() and game.train.automatic if passenger else game.cam.mode==1 and not game.train.automatic and game.train.controller==-1),"Starts paused in chosen role")
	if passenger:check(not game.passenger_bookmark.current().is_empty(),"Initial passenger seat can be recalled")
	check(game.save_load.capture_session().prepared_passenger==passenger,"Save retains departure role for restart")
	check(game.world.clock_seconds()==expected_clock and absf(expected_clock-row.start_clock)<.001,"Departure time unchanged")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(game.world)),"Boarding preserves complete prepared railway state")
	if passenger:
		game._pilot_camera();game.train.automatic=false
		check(game.passenger_bookmark.restore({},false) and game.train.automatic,"Passenger seat recall after pilot visit")
	# Drain the source scenery workers through the real unload path.
	await game._return_to_landing();await process_frame;await process_frame
	print("DEPARTURE_ROLE ",id," passenger=",passenger," · ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
