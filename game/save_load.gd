extends RefCounted
## Pause-menu workflow; the railway snapshot itself has no presentation dependencies.
const Snapshot := preload("res://sim/world_snapshot.gd")
const Store := preload("res://persistence/save_store.gd")
const META := ["route","small_test_layout","imported_fleet","wap7_drive","lhb_drive","traffic_drive","traffic_seed","service_pack","player_service"]
const FLAGS := ["geographic_drive","traffic_drive","imported_fleet","wap7_drive","lhb_drive","authored_pack","labels_enabled","time_scale"]
const CAMERA := ["mode","yaw","pitch","distance","cab_fov","head_out_side","follow","_look","free_flight","free_fov"]
const VIEW := ["passenger_coach","passenger_bay","passenger_seat","passenger_seat_index","cab_position","passenger_head_out"]
const WALK := ["active","car","position","crouched","eye_height","lamp_enabled"]
const MAP := ["focus_index","center_s","span","vertical_pan","follow_train","show_blocks"]
var game
var store := Store.new()
var pending := {}
var page := "load"

func _init(owner) -> void:
	game=owner

func capture_session() -> Dictionary:
	var meta:={}
	for key in META:
		if game.get_tree().has_meta(key):meta[key]=game.get_tree().get_meta(key)
	# Persist resolved scenario choices even on a first launch using CLI defaults.
	meta.route=preload("res://sim/service_pack.gd").layout_id(game.world)
	meta.small_test_layout=meta.route=="first_line"
	for key in ["traffic_drive","imported_fleet","wap7_drive","lhb_drive"]:meta[key]=game.get(key)
	var data:=Snapshot.fields(game,FLAGS)
	data.player=game.train.id;data.meta=meta
	data.camera=Snapshot.fields(game.cam,CAMERA)
	data.camera.pivot=game.cam.pivot+(game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO)
	data.view=Snapshot.fields(game.tv,VIEW)
	data.walk=Snapshot.fields(game.walker,WALK)
	data.walk.outside=game.walker.platform.outside
	if data.walk.outside:
		data.walk.road=game.walker.platform.surface.edge
		data.walk.side=int(game.walker.platform.surface.side)
		data.walk.platform_position=game.walker.platform.position
	data.followed=game.traffic_presentation.followed_service
	data.desk={inspected=game.dispatcher.inspected_train,source=game.dispatcher.source,map=Snapshot.fields(game.dispatcher._map,MAP)}
	data.sound=Snapshot.fields(game.audio,["track_level","clang_balance_db","squeal_amount"])
	return data

func save(slot: String) -> Dictionary:
	var was_paused: bool=game.paused
	game._set_paused(true)
	var checkpoint:=Snapshot.capture(game.world,capture_session())
	var progress:=preload("res://sim/service_progress.gd").snapshot(game.world,game.train)
	var summary:={service=game.train.id,title=game.train.service_name,clock=game.world.clock_text(),day=game.world.clock_day(),
		saved_at=Time.get_datetime_string_from_system(false,true),stops=progress.get("completed",0),total=progress.get("total",0)}
	var result:=store.write_slot(slot,checkpoint,summary)
	if not was_paused:game._set_paused(false)
	game.hud.toast(("Quick save" if slot=="quick" else "Slot "+slot)+" saved · "+summary.clock if result.ok else result.reason,not result.ok)
	return result

func open(kind: String) -> void:
	page=kind;pending.clear()
	game._set_paused(true);game.dispatcher.set_open(false);game._restore_ui()
	var options:=[["Back","save:back"],["Open saves folder","save:folder"]]
	for slot in store.slots():
		var label: String="Quick save" if slot.id=="quick" else "Slot "+slot.id
		var detail: String="Empty"
		if slot.ok:
			var s: Dictionary=slot.summary
			detail="%s · day %d %s · %d/%d stops\n%s\nSaved %s" % [s.get("service",""),s.get("day",1),s.get("clock",""),s.get("stops",0),s.get("total",0),s.get("title",""),s.get("saved_at","")]
		elif slot.exists:detail="Unreadable · "+slot.reason
		if kind=="save" or slot.exists:options.append([label+" — "+detail,"save:"+kind+":"+slot.id])
		if kind=="load" and slot.backup:options.append([label+" — previous backup","save:backup:"+slot.id])
	if kind=="load" and options.size()==2:options.append(["No saves yet — save your current journey first","save:back"])
	show("SAVE JOURNEY" if kind=="save" else "LOAD JOURNEY",
		"Five manual slots and a separate quick save. Loading resumes paused.\nEach overwrite keeps the previous save as a backup.\n"+ProjectSettings.globalize_path(store.directory),options)

func show(title: String, body: String, options: Array) -> void:
	game.hud.save_menu={title=title,body=body,options=options}
	game.hud.show_modal("saved_games")

func action(command: String) -> void:
	var parts:=command.split(":")
	match parts[1]:
		"back":back()
		"folder":
			var err:=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(store.directory))
			if err==OK:err=OS.shell_open(ProjectSettings.globalize_path(store.directory))
			if err!=OK:game.hud.toast("Could not open saves folder: "+error_string(err),true)
		"quick":save("quick")
		"menu":open(parts[2])
		"save":
			var slot: String=parts[2]
			if FileAccess.file_exists(store.path(slot)):
				pending={kind="save",slot=slot}
				show("OVERWRITE SAVE?","Replace "+("Quick save" if slot=="quick" else "Slot "+slot)+" with the current journey? The previous save will remain available as a backup.",[["Cancel","save:back"],["Save current journey","save:confirm"]])
			else:
				var result:=save(slot)
				if result.ok:open("save")
		"load","backup":
			var read:=store.read_slot(parts[2],parts[1]=="backup")
			if not read.ok:game.hud.toast(read.reason,true);return
			var result:=Snapshot.restore(read.data.checkpoint)
			if not result.ok:game.hud.toast(result.reason,true);return
			var issue:=validate_session(result)
			if not issue.is_empty():game.hud.toast(issue,true);return
			pending={kind="load",result=result}
			show("LOAD SAVED JOURNEY?","Return to "+str(read.data.summary.get("title","saved journey"))+" at "+str(read.data.summary.get("clock",""))+"?\nUnsaved progress in this run will be replaced. The restored game will be paused.",[["Cancel","save:back"],["Load journey","save:confirm"]])
		"confirm":
			if pending.get("kind")=="save":
				var result:=save(pending.slot)
				if result.ok:open("save")
			elif pending.get("kind")=="load":
				game.get_tree().set_meta("resume_session",pending.result)
				game.get_tree().call_deferred("reload_current_scene")
				pending.clear()

func back() -> void:
	if not pending.is_empty():open(page)
	else:game.hud.show_modal("pause",game.labels_enabled)

static func validate_session(result: Dictionary) -> String:
	return preload("res://game/save_validation.gd").check(result.world,result.session)

static func prepare_metadata(tree: SceneTree, session: Dictionary) -> void:
	for key in META:
		if tree.has_meta(key):tree.remove_meta(key)
	for key in META:
		if session.meta.has(key):tree.set_meta(key,session.meta[key])

func restore_view(session: Dictionary) -> void:
	game._set_paused(true)
	game.labels_enabled=session.labels_enabled
	game._set_time_scale(session.time_scale)
	var view_state: Dictionary={passenger_head_out=false}
	view_state.merge(session.view,true)
	Snapshot.apply(game.tv,view_state,VIEW)
	game._render_trains(1.0)
	var camera_state: Dictionary={free_flight=false,free_fov=65.0}
	camera_state.merge(session.camera,true) # R14-R17 saves predate the platform free view.
	Snapshot.apply(game.cam,camera_state,CAMERA)
	game.cam.pivot=session.camera.pivot-(game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO)
	game.cam._blend=1.0;game.cam._follow_anchor_valid=false
	game._set_cab_visuals(game.cam.mode==1)
	if game.cam.mode==2:
		game.tv.set_passenger_view(true);game._interior_view=true;game.audio.set_interior(true)
	game._passenger_seating_changed()
	if session.walk.active:
		var walk=game.walker
		Snapshot.apply(walk,session.walk,WALK)
		walk._train_id=game.train.id;walk.nav=walk.navigation(walk.car);walk._refresh_exits()
		walk.platform.outside=session.walk.outside
		if walk.platform.outside:
			walk.platform.surface=preload("res://game/platform_navigation.gd").new(game.world,session.walk.road,session.walk.side)
			walk.platform.position=session.walk.platform_position;game.tv.walk_car=-1
			game.cam.set_meta("on_platform",true)
		else:
			game.tv.walk_car=walk.car
			game.tv.walk_eye=Vector3(walk.position.x,walk.nav.floor_height(walk.position)+walk.eye_height,walk.position.y)
		game.tv._apply_glass();walk._lamp.visible=walk.lamp_enabled;walk.neutralize()
		game.audio.set_interior(not walk.platform.outside)
		game.tv._interior_light.visible=not walk.platform.outside
	if not session.followed.is_empty() and game.world.trains.has(session.followed):
		game.traffic_presentation.ensure_view(session.followed)
		game.traffic_presentation.followed_service=session.followed
		game.cam.follow_point=game.train_views[session.followed].overview_position
	Snapshot.apply(game.audio,session.sound,["track_level","clang_balance_db","squeal_amount"])
	game.dispatcher.inspect_train(session.desk.inspected,false)
	game.dispatcher.select_signal(session.desk.source,true)
	Snapshot.apply(game.dispatcher._map,session.desk.map,MAP)
	game.dispatcher._map.queue_redraw()
	game.cam.global_transform=game.cam._target()
	game._last_event=game.world._event_seq
	for event in game.world.events.slice(maxi(0,game.world.events.size()-20)):game.hud.log_event(event)
	for sound in game.train_audio.values():sound.reset_positions();sound.set_paused(true)
	game.hud.show_modal("pause",game.labels_enabled)
	game.hud.toast("Journey restored · "+game.world.clock_text()+" · paused; Resume when ready")
