extends RefCounted
const Presentation:=preload("res://game/traffic_presentation.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")

func test_shared_audio_contacts_keep_separate_playback_and_reject_another_graph():
	var Sound:=preload("res://game/platform_audio.gd")
	var game=_fixture()
	var listener:=Node3D.new();game.add_child(listener)
	var first:=Sound.new();game.add_child(first)
	var second:=Sound.new();game.add_child(second)
	var axles:=[{x=3.27,cls=0,car=1},{x=5.83,cls=1,car=1},{x=18.17,cls=2,car=1},{x=20.73,cls=3,car=1}]
	first.setup(game.world.trains.A,game.world,listener,axles)
	second.layout=first.layout
	second.setup(game.world.trains.B,game.world,listener,axles)
	var valid: bool=second.layout==first.layout and second._sweep!=first._sweep and second._history!=first._history and second._track_pb!=first._track_pb
	var other:=RailWorld.new()
	other.graph.add_node("a",Vector3.ZERO);other.graph.add_node("b",Vector3(200,0,0));other.graph.add_edge("road","a","b")
	var third:=Sound.new();game.add_child(third);third.layout=first.layout
	third.setup(game.world.trains.A,other,listener,axles)
	valid=valid and third.layout!=first.layout and third.layout.graph==other.graph
	game.free()
	return valid

class Fixture extends Node:
	var world:=RailWorld.new()
	var train_views:={}
	var train_motions:={}
	var train_audio:={}
	var traffic_presentation:=Presentation.new()
	func _init() -> void:
		traffic_presentation.game=self
		world.graph.add_node("a",Vector3.ZERO)
		world.graph.add_node("b",Vector3(2000,0,0))
		world.graph.add_edge("road","a","b")
		for id in ["A","B"]:
			var train:=Train.new(id,1)
			Stock.configure(train,"vb8")
			world.trains[id]=train;train_motions[id]=null
			world.place_train(train,"road",1000,1)

func _fixture():
	var game:=Fixture.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func test_partial_formation_is_hidden_and_published_only_when_complete():
	var game=_fixture();var p=game.traffic_presentation
	p.request_view("A",false)
	p.builds.advance(game,"A",true)
	var valid: bool=not game.train_views.has("A") and not p.roots.A.visible and p.builds.pending.A.view.cars.size()==1
	for i in 7:p.builds.advance(game,"A",true)
	valid=valid and game.train_views.has("A") and p.roots.A.visible and p.builds.pending.is_empty()
	var view=game.train_views.A
	valid=valid and view.cars.size()==8 and view.axles.size()==8 and view.interior_meshes.size()==8 and view.sound_axles().size()==32
	game.free()
	return valid

func test_shared_scene_requests_and_explicit_handover_complete_both_trains():
	var game=_fixture();var p=game.traffic_presentation
	p.request_view("A",false);p.request_view("B",false)
	p.builds.advance(game,"A",true)
	p.ensure_view("A");p.ensure_view("B")
	var valid: bool=p.builds.pending.is_empty() and game.train_views.size()==2 and p.builds.completed==2
	valid=valid and game.world.trains.A.head_s==1000 and game.world.trains.B.head_s==1000
	game.free()
	return valid

func test_cancelled_partial_train_cannot_reappear_and_can_be_requested_again():
	var game=_fixture();var p=game.traffic_presentation
	p.request_view("A",false);p.builds.advance(game,"A",true)
	p.release("A")
	var valid: bool=not p.roots.has("A") and not p.builds.pending.has("A") and not game.train_views.has("A")
	p.ensure_view("A")
	valid=valid and game.train_views.A.cars.size()==8 and p.builds.completed==1
	game.free()
	return valid
