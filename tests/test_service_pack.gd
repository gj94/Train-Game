extends RefCounted
const Pack := preload("res://sim/service_pack.gd")
const Trial := preload("res://sim/service_trial.gd")
const Dispatch := preload("res://sim/dispatch_plan.gd")

func test_default_round_trip_preserves_stock_times_and_physical_placement():
	for layout in ["southern_corridor","first_line"]:
		var pack := Pack.defaults(layout)
		var result := Pack.decode(JSON.stringify(pack),layout)
		if not result.ok: return result.reason
		if result.world.trains.size()!=pack.services.size(): return "Lost services or unexpected default train"
		for definition in pack.services:
			var train: Train = result.world.trains[definition.id]
			if train.path.size()!=1 or not train.automatic or train.controller!=-1: return "Unsafe start"
			if train.timetable.stops[0].s!=train.head_s: return "Origin is not at stopping marker"
			if train.timetable.departure!=result.world.clock_start and layout=="southern_corridor": return "Departure changed"
	return true

func test_custom_ids_and_any_service_can_be_the_manual_working():
	var pack := Pack.defaults()
	for i in pack.services.size(): pack.services[i].id="EXPRESS_%d" % (i+31)
	var result := Pack.build(pack)
	if not result.ok: return result.reason
	var world: RailWorld = result.world
	var selected: String = pack.services[0].id
	world.trains[selected].automatic=false
	world.trains[selected].controller=-.7
	Dispatch.update(world,false,selected)
	return world.aspect("CPM-E1")!=RailWorld.Aspect.RED and world.trains[selected].controller==-.7 and world.trains.values().filter(func(t): return t.automatic).size()==5

func test_invalid_imports_never_return_a_partially_built_world():
	var cases := []
	var bad := Pack.defaults(); bad.services[1].id=bad.services[0].id; cases.append(bad)
	bad=Pack.defaults(); bad.services[1].stops[0]=bad.services[0].stops[0].duplicate(true); cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stock="missing"; cases.append(bad)
	bad=Pack.defaults(); bad.layout_signature="changed"; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[1].block="nowhere"; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[1].block="MRT_P3"; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[0].position_m=10; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[0].position_m=700; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[1].minutes_from_origin=-1; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[1].dwell_minutes=60; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].departure="07:59"; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].stops[1].direction=0; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].day=1.5; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].name=[]; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].rake="icf_3a,lhb_sl"; cases.append(bad)
	bad=Pack.defaults(); bad.services[2].rake="express"; cases.append(bad)
	bad=Pack.defaults(); bad.services[0].rake=22; cases.append(bad)
	for value in [null,[],{"format":"other"},true,{"format":"train-game-services","version":1,"layout":7}]: cases.append(value)
	for value in cases:
		var result := Pack.build(value)
		if result.ok or result.has("world"): return "Invalid data created a partial world: "+str(value)
	return not Pack.decode("{bad").ok and not Pack.decode(" ".repeat(Pack.MAX_BYTES+1)).ok and not Pack.build(Pack.defaults(),"first_line").ok

func test_overnight_departures_and_missing_optional_fields_normalize():
	var pack := Pack.defaults()
	pack.world_start="23:59:00"
	for service in pack.services:
		service.departure="00:01:00"; service.day=2
		for stop in service.stops: stop.erase("name"); stop.erase("dwell_minutes")
	var result := Pack.decode(JSON.stringify(pack))
	if not result.ok: return result.reason
	return result.world.trains.T1.timetable.departure==86460 and result.data.services[0].stops[1].dwell_minutes==1 and result.data.services[0].stops[0].name=="CPM_P1"

func test_import_validation_does_not_mutate_input_or_another_world():
	var pack := Pack.defaults()
	var before := JSON.stringify(pack)
	var first := Pack.build(pack)
	var second := Pack.build(pack)
	first.world.trains.T1.controller=.5
	first.world.trains.T1.timetable.stops[1].name="changed"
	first.data.services[0].name="changed"
	return JSON.stringify(pack)==before and second.world.trains.T1.controller==-1 and second.world.trains.T1.timetable.stops[1].name!="changed"

func test_rehearsal_completes_default_and_reports_an_occupied_terminal():
	var result := Pack.build(Pack.defaults())
	var trial := Trial.new(result.world)
	for i in 8000:
		trial.step()
		if trial.done: break
	if not trial.done or not trial.ok: return trial.report
	var bad := Pack.defaults()
	# Two eastbound trains permanently terminate in the same road.
	bad.services[2].stops[-1].block=bad.services[0].stops[-1].block
	result=Pack.build(bad)
	if not result.ok: return result.reason
	trial=Trial.new(result.world)
	for i in 8000:
		trial.step()
		if trial.done: break
	return trial.done and not trial.ok and "did not finish" in trial.report

func test_rake_profiles_survive_export_and_validate_full_length():
	var stock := preload("res://sim/stock/ported_stock.gd")
	var pack := Pack.defaults()
	pack.services[0].rake="passenger"
	var decoded := Pack.decode(JSON.stringify(pack))
	if not decoded.ok: return decoded.reason
	var train: Train = decoded.world.trains.T1
	if train.rake_profile!="passenger" or train.length!=stock.length_of("lhb","passenger"): return "lost imported formation"
	if decoded.data.services[0].rake!="passenger": return "export lost profile"
	# Old files without a profile get a full-length family default, never seven cars.
	for service in pack.services: service.erase("rake")
	decoded=Pack.build(pack)
	if not decoded.ok: return decoded.reason
	if decoded.world.trains.T1.length!=stock.length_of("lhb"): return "legacy formation was not upgraded"
	pack.services[0].stops[0].position_m=300
	return not Pack.build(pack).ok
