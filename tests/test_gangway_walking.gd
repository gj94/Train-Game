extends RefCounted
const Link:=preload("res://game/gangway_connection.gd")
const Walker:=preload("res://game/train_walk.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")

class View extends RefCounted:
	var formation:=[]
	var cars:=[]
	var specs:=[]
	var passenger_coach:=0
	var walk_car:=0
	func _apply_glass() -> void:pass

func fixture(model: String, reversed: bool=false, curve: float=0.0) -> Dictionary:
	var root:=Node3D.new();(Engine.get_main_loop() as SceneTree).root.add_child(root)
	var view:=View.new();var pitch: float=Stock.geometry(model).pitch
	view.formation=[{model=model,reverse=false,pitch=pitch},{model=model,reverse=reversed,pitch=pitch}]
	for i in 2:
		var node:=Node3D.new();root.add_child(node)
		node.transform=Transform3D(Basis(Vector3.UP,(PI if i==1 and reversed else 0.0)+curve*i),Vector3(sin(curve*.5)*pitch*i,0,cos(curve*.5)*pitch*i))
		view.cars.append(node);view.specs.append({pitch=pitch})
	var walk:=Walker.new()
	walk._profiles=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/walkways.json"))
	walk.game={tv=view,cam={_look=Vector2(PI,0)}}
	walk.car=0;walk.nav=walk.navigation(0);walk.active=true;walk.platform={outside=false}
	walk.position=Vector2(0,Link.load_profiles()[model].gangway_join-.15)
	return {root=root,walk=walk,view=view}

func dispose(f: Dictionary) -> void:
	f.walk.free();f.root.free()

func test_all_rakes_connect_only_real_passenger_ends():
	for family in Stock.CHOICES:
		var formation:=Stock.formation(family)
		var links:=0
		for i in formation.size():
			for end in [-1,1]:
				var next:=Link.neighbour(formation,i,end)
				if next<0:continue
				links+=1
				if formation[i].model=="wap7" or formation[next].model=="wap7":return "WAP connected to passenger gangway"
				if Link.neighbour(formation,next,Link.end_for(formation,next,i))!=i:return "Asymmetric gangway connection"
		if Link.neighbour(formation,0,-1)!=-1:return "Front of rake is open"
		if links!=2*(formation.size()-(2 if family in ["icf","lhb"] else 1)):return "Missing passenger connections: "+family
	return true

func test_walk_crosses_moving_coach_boundary_without_position_or_look_jump():
	for model in ["icf_sl","lhb_3a","vb_tc_cc"]:
		for reversed in [false,true]:
			var f:=fixture(model,reversed,.055);var walk=f.walk
			var maximum:=0.0;var handoff:=0.0;var angle:=0.0;var previous: Transform3D=walk.camera_transform()
			previous.basis*=Basis.from_euler(Vector3(walk.game.cam._look.y,walk.game.cam._look.x,0))
			for frame in 170:
				var before_car: int=walk.car;var before_bridge: bool=not walk.bridge.is_empty()
				var direction:=Basis(Vector3.UP,walk.game.cam._look.x)*Vector3(0,0,-.015)
				walk.move_inside(Vector2(direction.x,direction.z))
				var now: Transform3D=walk.camera_transform()
				now.basis*=Basis.from_euler(Vector3(walk.game.cam._look.y,walk.game.cam._look.x,0))
				maximum=maxf(maximum,now.origin.distance_to(previous.origin))
				if before_car!=walk.car or before_bridge!=not walk.bridge.is_empty():handoff=maxf(handoff,now.origin.distance_to(previous.origin))
				angle=maxf(angle,now.basis.z.angle_to(previous.basis.z));previous=now
			# The source ICF threshold has a real 47 mm step. Coach ownership
			# changes have a tighter bound and must not produce a position jump.
			var ok: bool=walk.car==1 and walk.bridge.is_empty() and maximum<.065 and handoff<.03 and angle<.015 and walk._fade_time==0
			dispose(f)
			if not ok:return "%s reversed=%s step %.3fm, handoff %.3fm/%.3frad or failed crossing"%[model,reversed,maximum,handoff,angle]
	return true

func test_bridge_allows_turning_back_and_blocks_sideways_fall():
	var f:=fixture("icf_sl");var walk=f.walk
	walk.move_inside(Vector2(0,.4))
	if walk.bridge.is_empty():dispose(f);return "Did not enter bridge"
	walk.move_inside(Vector2(4,0))
	var contained: bool=absf(walk.bridge.lateral)<=.3001
	walk.move_inside(Vector2(-walk.bridge.lateral,0));walk.move_inside(Vector2(0,-.45))
	var returned: bool=walk.bridge.is_empty() and walk.car==0 and walk.nav.allowed(walk.position)
	dispose(f)
	return contained and returned

func test_unconnected_ends_keep_original_collision_and_do_not_reach_locomotive():
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/walkways.json"))
	var formation:=Stock.formation("icf")
	var nav=Link.navigation("icf_gs",Link.connected_ends(formation,1),profiles.icf_gs)
	var p: Vector2=nav.move(Vector2(0,-10),Vector2(0,-3))
	return p.y> -10.4 and Link.neighbour(formation,1,-1)==-1

func test_bridge_frame_tracks_both_moving_ends_and_preserves_reversed_view():
	var a:=Transform3D(Basis(Vector3.UP,.12),Vector3(5,1,9))
	var b:=Transform3D(Basis(Vector3.UP,PI+.18),Vector3(8,1.05,33))
	var x:=Vector3(0,1.325,11.65)
	var first:=Link.frame(a,x,1,b,x,1,0,.2)
	var last:=Link.frame(a,x,1,b,x,1,1,.2)
	if first.origin.distance_to(a*(x+Vector3(.2,0,0)))>.0001:return "First moving floor does not match"
	if last.origin.distance_to(b*(x+Vector3(-.2,0,0)))>.0001:return "Reversed moving floor does not match"
	var look:=Vector2(.7,.25);var changed:=Link.look_in_frame(a.basis,b.basis,look)
	return (a.basis*Basis.from_euler(Vector3(look.y,look.x,0))*Vector3.FORWARD).distance_to(b.basis*Basis.from_euler(Vector3(changed.y,changed.x,0))*Vector3.FORWARD)<.0001

func test_separated_coaches_cannot_be_crossed_as_a_gangway():
	var f:=fixture("icf_sl");f.view.cars[1].position.z+=8
	f.walk.move_inside(Vector2(0,2))
	var safe: bool=f.walk.car==0 and f.walk.bridge.is_empty() and f.walk.position.y<10.8
	dispose(f)
	return safe

func test_every_passenger_model_has_a_continuous_supported_main_passage():
	for model in Link.load_profiles():
		if model=="wap7":continue
		var profile: Dictionary=Link.load_profiles()[model]
		var nav:=preload("res://game/interior_navigation.gd").new(profile)
		var entry:=Vector2(0,profile.gangway_join)
		if not nav.allowed(entry):return model+" bridge is not on a supported floor"
		var cells:=nav.component(entry)
		var reaches_saloon:=false;var reaches_other:=false
		for index in cells:
			var point:=nav.center(index)
			if absf(point.y)<1.0:reaches_saloon=true
			if point.y< -profile.gangway_join:reaches_other=true
		if not reaches_saloon:return model+" saloon is disconnected from its gangway"
		if -1 in profile.gangway_ends and not reaches_other:return model+" lacks a continuous route between both ends"
		for index in cells:
			if not nav.valid(index,true) or nav.floor_height(nav.center(index))<1.2:return model+" passage is not supported"
	return true
