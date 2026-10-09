extends RefCounted
const Plan := preload("res://sim/track_speed_boards.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")

func straight(speeds: Array, lengths: Array=[]) -> RailWorld:
	var w:=RailWorld.new();var x:=0.0
	w.graph.add_node("N0",Vector3.ZERO)
	for i in speeds.size():
		x+=lengths[i] if not lengths.is_empty() else 2000.0
		w.graph.add_node("N"+str(i+1),Vector3(x,0,0))
		w.graph.add_edge("E"+str(i),"N"+str(i),"N"+str(i+1),[],speeds[i]/3.6)
	return w

func test_signs_mark_exact_reduction_and_full_rake_release_in_both_directions():
	var w:=straight([110,40,110]);var signs:=Plan.build(w)
	var starts:=signs.filter(func(b):return b.kind=="speed")
	var ends:=signs.filter(func(b):return b.kind=="termination")
	var warnings:=signs.filter(func(b):return b.kind=="caution")
	if starts.size()!=2 or ends.size()!=2 or warnings.size()!=2:return "Incorrect bidirectional indicator count"
	for b in starts:
		if b.source!="E1" or not is_equal_approx(b.limit*3.6,40):return "Wrong speed board"
		if b.s!=w.graph.exit_s(b.edge,b.dir):return "Start not at physical limit boundary"
	for b in ends:
		if not is_equal_approx(absf(b.s-w.graph.entry_s(b.edge,b.dir)),600):return "T/P does not clear longest supported formation"
	for b in warnings:
		if not is_equal_approx(absf(b.s-w.graph.exit_s(b.edge,b.dir)),1200):return "Advance caution is not 1200 m away"
	return true

func test_equal_speed_blocks_do_not_produce_duplicate_indicators():
	var w:=straight([110,110,40,40,110,110],[700,700,300,300,300,1300])
	var signs:=Plan.build(w)
	if signs.filter(func(b):return b.kind=="speed").size()!=2:return "Board at a same-speed block boundary"
	var tp:=signs.filter(func(b):return b.kind=="termination" and b.dir==1)
	return tp.size()==1 and tp[0].edge=="E5" and is_equal_approx(tp[0].s,300)

func test_one_way_directions_and_buffer_ends():
	var w:=straight([110,40,110],[100,100,100])
	for e in w.graph.edges.values():e.allowed_dir=1
	var signs:=Plan.build(w)
	return signs.size()==1 and signs[0].kind=="speed" and signs[0].dir==1

func test_subsequent_lower_limit_suppresses_premature_termination():
	var w:=straight([40,110,30,110],[2000,300,400,2000])
	var signs:=Plan.build(w)
	var tp:=signs.filter(func(b):return b.kind=="termination" and b.dir==1)
	return tp.size()==1 and tp[0].edge=="E3" and is_equal_approx(tp[0].s,600)

func fork() -> RailWorld:
	var w:=straight([110])
	w.graph.add_node("N2",Vector3(4000,0,0));w.graph.add_node("N3",Vector3(4000,0,6))
	w.graph.add_edge("MAIN","N1","N2",[],110/3.6)
	w.graph.add_edge("LOOP_P3","N1","N3",[],35/3.6)
	w.graph.add_switch("N1","E0","MAIN","LOOP_P3")
	return w

func test_facing_fork_has_road_qualified_speed_and_ignores_live_switch_state():
	var w:=fork();var signs:=Plan.build(w)
	var starts:=signs.filter(func(b):return b.kind=="speed" and b.dir==1)
	if starts.size()!=1 or starts[0].route!="LOOP P3" or starts[0].source!="LOOP_P3":return "Loop limit would be mistaken for the through-line limit"
	w.graph.switches.N1.reversed=true
	return var_to_bytes(signs)==var_to_bytes(Plan.build(w)) and Plan.adjacent(w.graph,"LOOP_P3",-1,true).size()==1

func test_merge_from_slower_branch_cannot_inherit_early_release():
	var w:=straight([35,110,110],[2000,200,2000])
	w.graph.add_node("SIDE",Vector3(2000,0,6))
	w.graph.add_edge("SIDE","SIDE","N2",[],25/3.6)
	w.graph.add_switch("N2","E2","E1","SIDE")
	var signs:=Plan.build(w)
	var tp:=signs.filter(func(b):return b.kind=="termination" and b.dir==1)
	return tp.size()==1 and tp[0].edge=="E2" and is_equal_approx(tp[0].s,600)

func test_longer_supported_train_extends_termination_clearance():
	var w:=straight([35,110])
	var t:=Train.new("LONG",900);w.place_train(t,"E0",1000,1)
	return Plan.clearance_length(w)==950 and Plan.build(w).any(func(b):return b.kind=="termination" and b.dir==1 and b.s==950)

func test_all_builtin_services_use_formation_cap_and_k1_can_exceed_65():
	var traffic:=Kerala.build_traffic()
	for t: Train in traffic.trains.values():
		var reference:=Train.new("REFERENCE",1);Stock.configure(reference,t.stock_kind.trim_prefix("ported:"),t.rake_profile)
		if t.max_speed!=reference.max_speed or t.max_speed<110/3.6-.001:return "Artificial cap on "+t.id
	for auto in [false,true]:
		var w:=straight([160],[100000]);var t: Train=traffic.trains.K1
		t.timetable=null;t.speed=0;t.automatic=auto;t.controller=1;t.emergency=false
		w.place_train(t,"E0",1000,1)
		for i in 2400:w.step(.25)
		if t.speed*3.6<108 or t.speed>t.max_speed+.1:return "K1 failed uncapped equipment-limited running, automatic="+str(auto)
	return true

func test_restricted_track_remains_in_force_until_tail_leaves():
	var w:=straight([35,110]);var t:=Train.new("LONG",500)
	w.place_train(t,"E0",1900,1);t.speed=10;t.controller=0
	for i in 20:w.step(1)
	if t.path[0].edge!="E1" or not is_equal_approx(w.speed_limit_for(t)*3.6,35):return "Front released speed while rear occupied restriction"
	for i in 60:w.step(1)
	return is_equal_approx(w.speed_limit_for(t)*3.6,110)

func test_legacy_builtin_checkpoint_cap_upgrades_but_authored_caps_survive():
	var w:=Kerala.build_traffic();w.trains.K1.max_speed=65/3.6
	var old:=Snapshot.capture(w,{authored_pack=false,meta={route="kerala_coast"}})
	var original:=var_to_bytes(old)
	var upgraded:=Snapshot.restore(old)
	if not upgraded.ok:return upgraded.reason
	if not is_equal_approx(upgraded.world.trains.K1.max_speed*3.6,110) or var_to_bytes(old)!=original:return "Legacy upgrade missing or mutated checkpoint"
	old.session.authored_pack=true
	var custom:=Snapshot.restore(old)
	if not custom.ok or not is_equal_approx(custom.world.trains.K1.max_speed*3.6,65):return "Custom cap overwritten"
	old.session.authored_pack=false;old.session.meta.service_pack={}
	custom=Snapshot.restore(old)
	return custom.ok and is_equal_approx(custom.world.trains.K1.max_speed*3.6,65)

func test_kerala_boards_are_finite_legal_and_every_release_is_tail_safe():
	var w:=Kerala.build();var before:=var_to_bytes(w.graph.switches);var signs:=Plan.build(w)
	var starts:=0;var ends:=0
	for b in signs:
		if not is_finite(b.s) or b.s<0 or b.s>w.graph.edges[b.edge].length+.001 or not w.graph.allows(b.edge,b.dir):return "Invalid board position "+b.id
		if b.kind=="speed":starts+=1
		if b.kind=="termination":
			ends+=1
			if not Plan.tail_clear(w.graph,b.edge,b.s,b.dir,b.clearance,b.limit):return "Premature T/P "+b.id
	return starts>100 and ends>100 and before==var_to_bytes(w.graph.switches)

func test_rendered_posts_clear_every_track_platform_and_signal_footprint():
	var w:=Kerala.build()
	var footprint=preload("res://game/vegetation_clearance.gd").build(w)
	var view:=preload("res://game/track_speed_board_view.gd").new(w,footprint)
	var rails:=preload("res://game/scenery_clearance.gd").new(w.graph)
	for job in view.jobs:
		if not rails.clear_point(job.point,3.04) or not footprint.clear(Vector2(job.point.x,job.point.z),.79):
			return "Sign footprint obstruction: "+job.id
	return true
