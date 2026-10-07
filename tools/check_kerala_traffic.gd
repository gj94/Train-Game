extends SceneTree
func _init() -> void:
	var world=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var trial=preload("res://sim/service_trial.gd").new(world)
	var priority=preload("res://sim/priority_dispatch.gd")
	var previous:={}
	var encounters:=[]
	for t in world.trains.values():previous[t.id]=priority.chainage(world,t)-priority.chainage(world,world.trains.K1)
	var started:=Time.get_ticks_msec()
	while not trial.done:
		trial.step()
		for t in world.trains.values():
			if t.id=="K1":continue
			var separation: float=priority.chainage(world,t)-priority.chainage(world,world.trains.K1)
			var overtake: bool=t.path[0].dir==1 and previous[t.id]<0 and separation>=0
			var crossing: bool=t.path[0].dir==-1 and previous[t.id]>0 and separation<=0
			if overtake or crossing:
				encounters.append({other=t.id,kind="overtake" if overtake else "crossing",time=world.clock_text(),player_edge=world.trains.K1.path[0].edge})
			previous[t.id]=separation
		if trial.ticks%180==0:
			print("KERALA_TRAFFIC ",world.clock_text()," ",world.trains.values().map(func(t): return [t.id,t.path[0].edge,roundi(t.speed*3.6),t.status]))
	print(trial.report," elapsed=",(Time.get_ticks_msec()-started)*.001)
	print("DYNAMIC_DISPATCH_HISTORY ",JSON.stringify(world.dispatch_history))
	print("PASSENGER_ENCOUNTERS ",JSON.stringify(encounters))
	var enough: bool=encounters.filter(func(e):return e.kind=="crossing").size()>=2 and encounters.filter(func(e):return e.kind=="overtake").size()>=2
	quit(0 if trial.ok and enough else 1)
