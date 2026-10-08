extends RefCounted
## Detailed vehicles and pooled sound are local to the observer. All services
## continue in RailWorld regardless of whether their presentation is resident.
const View := preload("res://game/ported_train_view.gd")
const Sound := preload("res://game/platform_audio.gd")
const LOAD_DISTANCE := 3200.0
const UNLOAD_DISTANCE := 4500.0
var game
var roots := {}
var followed_service := ""
var _check_in := 0.0

func ensure_view(id: String) -> void:
	if game.train_views.has(id): return
	var parent:=Node3D.new()
	parent.name="Service_"+id
	game.add_child(parent)
	roots[id]=parent
	var view:=View.new()
	view.motion=game.train_motions[id]
	view.build(game.world.trains[id],game.world.graph,parent,game.wv)
	game.train_views[id]=view

func ensure_audio(id: String) -> void:
	if game.train_audio.has(id): return
	ensure_view(id)
	var sound:=Sound.new()
	game.add_child(sound)
	sound.motion=game.train_motions[id]
	sound.setup(game.world.trains[id],game.world,game.geographic_listener if game.geographic_drive else game.cam,game.train_views[id].sound_axles())
	sound.simulation_rate=game.time_scale
	sound.set_paused(game.paused or (game.geographic_drive and game.wv.loading))
	sound.listener_owner=game.audio
	sound.joint_hit.connect(func(edge: String,k: int,_cls: int): game.wv.flash_joint(edge,k))
	game.train_audio[id]=sound
	var engine:=preload("res://game/engine_audio.gd").new()
	engine.name="EngineAudio"
	roots[id].add_child(engine)
	engine.setup(game,game.train_views[id],sound)
	sound.engine=engine

func distance_to(id: String) -> float:
	var motion=game.train_motions[id]
	# Include the tail: long formations must not vanish beside the camera.
	return minf(motion.point(0).distance_to(game.cam.global_position),motion.point(game.world.trains[id].length).distance_to(game.cam.global_position))

func update(delta: float) -> void:
	if not game.geographic_drive: return
	_check_in-=delta
	if _check_in>0: return
	_check_in=.5
	var candidate:=""
	var nearest:=INF
	for id in game.world.trains:
		if id==game.train.id or id==followed_service: continue
		var distance:=distance_to(id)
		if roots.has(id):
			if distance>UNLOAD_DISTANCE: release(id)
		elif distance<LOAD_DISTANCE and distance<nearest:
			candidate=id
			nearest=distance
	# One nearby formation per update avoids a full-fleet startup spike.
	if not candidate.is_empty():
		ensure_view(candidate)
		ensure_audio(candidate)

func release(id: String) -> void:
	if game.train_audio.has(id):
		game.train_audio[id].set_paused(true)
		game.train_audio[id].queue_free()
		game.train_audio.erase(id)
	if roots.has(id):
		roots[id].queue_free()
		roots.erase(id)
	game.train_views.erase(id)
