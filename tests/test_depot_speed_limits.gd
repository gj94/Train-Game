extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Driver := preload("res://sim/automatic_control.gd")
const Boards := preload("res://sim/track_speed_boards.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")
const Pack := preload("res://sim/service_pack.gd")

func test_all_shared_access_roads_match_their_adjacent_running_line():
	var w:=Kerala.build();var count:=0
	for id: String in w.graph.edges:
		if "_DEPOT_" not in id or not id.ends_with("_ACCESS"):continue
		var junction:=id.trim_suffix("_ACCESS")+"_J"
		var main: String=w.graph.nodes[junction].edges.filter(func(e):return "_DEPOT_" not in e)[0]
		if w.graph.edges[id].speed_limit!=w.graph.edges[main].speed_limit:return id+" imposes a depot limit on the running line"
		var dir:=1 if "_DEPOT_R" in id else -1
		var t:=Train.new("TEST",100);w.place_train(t,id,w.graph.entry_s(id,dir)+dir*150,dir)
		if w.speed_limit_for(t)!=w.graph.edges[main].speed_limit:return "Occupied access is slow: "+id
		count+=1
	return count>=20

func fork() -> RailWorld:
	var w:=RailWorld.new()
	for node in [{id="A",p=Vector3.ZERO},{id="J",p=Vector3(2000,0,0)},
		{id="M",p=Vector3(12000,0,0)},{id="D",p=Vector3(10000,0,80)}]:w.graph.add_node(node.id,node.p)
	w.graph.add_edge("ERS_DEPOT_RD_ACCESS","A","J",[],100.0/3.6)
	w.graph.add_edge("MAIN","J","M",[],100.0/3.6)
	w.graph.add_edge("ERS_DEPOT_RD_LEAD","J","D",[],25.0/3.6)
	w.graph.add_switch("J","ERS_DEPOT_RD_ACCESS","MAIN","ERS_DEPOT_RD_LEAD")
	return w

func test_selected_branch_changes_braking_envelope_but_through_route_does_not():
	var w:=fork();var t:=Train.new("TEST",100);t.max_speed=140.0/3.6;t.speed=90.0/3.6
	w.place_train(t,"ERS_DEPOT_RD_ACCESS",1700,1)
	var through:=Driver.speed_envelope(w,t)
	w.graph.switches.J.reversed=true
	var depot:=Driver.speed_envelope(w,t)
	return is_equal_approx(through.target,100.0/3.6-Driver.LIMIT_MARGIN) and not through.must_brake and depot.target<60.0/3.6 and depot.must_brake

func test_full_rake_must_clear_depot_limit_when_rejoining_main():
	var w:=fork();var t:=Train.new("TEST",200);w.graph.switches.J.reversed=true
	w.place_train(t,"ERS_DEPOT_RD_ACCESS",1950,-1)
	if t.path.size()!=2 or w.speed_limit_for(t)!=25.0/3.6:return "Tail on depot lead was released early"
	t.advance(w.graph,160)
	return t.path.size()==1 and w.speed_limit_for(t)==100.0/3.6

func test_depot_speed_board_is_explicitly_branch_qualified():
	var w:=fork();var boards:=Boards.build(w)
	var starts:=boards.filter(func(b):return b.kind=="speed" and b.dir==1)
	return starts.size()==1 and starts[0].route=="ERS DEPOT" and starts[0].source=="ERS_DEPOT_RD_LEAD" and starts[0].limit==25.0/3.6

func test_legacy_save_and_pack_migrate_only_the_access_limits():
	# Reconstruct the exact former signature; all geometry/other rules must match.
	var w:=Kerala.build_traffic();var saved:=Snapshot.capture(w)
	saved.layout_signature=Snapshot.signature(w,true)
	for row in saved.trains:row.erase("horn_ready_at")
	var result:=Snapshot.restore(saved)
	if not result.ok:return result.reason
	var road: String=w.graph.edges.keys().filter(func(id):return "_DEPOT_" in id and id.ends_with("_ACCESS") and w.graph.edges[id].speed_limit==100.0/3.6)[0]
	if result.world.graph.edges[road].speed_limit!=100.0/3.6:return "Loaded save retained old access limit"
	var data:=Pack.defaults("kerala_coast")
	data.layout_signature=Pack.signature(w,true)
	if not Pack.build(data).ok:return "Legacy service pack rejected"
	# An unrelated main-line change is not covered by this migration.
	w.graph.edges[road.trim_suffix("_ACCESS")+"_LEAD"].speed_limit=30.0/3.6
	saved.layout_signature=Snapshot.signature(w,true)
	data.layout_signature=Pack.signature(w,true)
	return not Snapshot.restore(saved).ok and not Pack.build(data).ok
