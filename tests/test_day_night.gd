extends RefCounted
const Cycle:=preload("res://sim/daylight.gd")

func test_sun_rises_east_sets_west_and_night_has_no_sun():
	var dawn:=Cycle.sample((Cycle.NOON-6)*3600)
	var dusk:=Cycle.sample((Cycle.NOON+6)*3600)
	var noon:=Cycle.sample(Cycle.NOON*3600)
	var midnight:=Cycle.sample(0)
	return dawn.sun.x>.99 and dusk.sun.x<-.99 and absf(dawn.elevation)<.001 and absf(dusk.elevation)<.001 and noon.sun_energy==1.55 and noon.night==0 and midnight.sun_energy==0 and midnight.night==1 and midnight.moon_energy>0

func test_clock_wrap_and_days_repeat_without_a_midnight_jump():
	for seconds in [0,24000,43200,67500,86399]:
		if Cycle.sample(seconds)!=Cycle.sample(seconds+86400*3):return "Day rollover changed the lighting"
	var before:=Cycle.sample(86399.9);var after:=Cycle.sample(86400.1)
	return before.sun.distance_to(after.sun)<.0001 and absf(before.night-after.night)<.0001

func test_loaded_world_clock_reproduces_night_and_the_next_morning():
	var w:=preload("res://sim/layouts/traffic_service.gd").build()
	for clock in [22*3600,86400+7*3600]:
		w.time=clock-w.clock_start
		var saved:=preload("res://sim/world_snapshot.gd").capture(w)
		var loaded:=preload("res://sim/world_snapshot.gd").restore(saved)
		if not loaded.ok:return loaded.reason
		if Cycle.sample(loaded.world.clock_seconds())!=Cycle.sample(w.clock_seconds()):return "Saved clock changed the sky"
	return true

func test_twilight_is_continuous_and_bounded_through_a_whole_day():
	var previous:=Cycle.sample(0)
	for second in range(60,86401,60):
		var value:=Cycle.sample(second)
		for key in ["daylight","night","twilight","warmth"]:
			if value[key]<0 or value[key]>1 or absf(value[key]-previous[key])>.09:return "Abrupt lighting transition: "+key
		if not value.sun.is_finite() or absf(value.sun.length()-1)>.00001:return false
		previous=value
	return true

func scene() -> Dictionary:
	var view:=preload("res://game/world_view.gd").new()
	view.world=RailWorld.new();view.root=Node3D.new();view._build_environment()
	return {view=view,root=view.root}

func test_paused_clock_caches_sky_and_clock_jump_applies_immediately():
	var s:=scene();var cycle=s.view.day_night
	cycle.update(12*3600,true)
	var before: int=cycle.updates
	for i in 100:cycle.update(12*3600)
	var ok: bool=cycle.updates==before and cycle.sun.visible and not cycle.moon.visible
	cycle.update(23*3600) # Large clock jumps bypass the normal refresh throttle.
	ok=ok and not cycle.sun.visible and cycle.moon.visible and cycle.state.night==1
	cycle.update(8*3600,true) # Loading an earlier save is equally immediate.
	ok=ok and cycle.sun.visible and not cycle.moon.visible
	s.root.free();return ok

func test_graphics_changes_preserve_shadow_free_moon_and_night_fog():
	var s:=scene();var cycle=s.view.day_night
	cycle.update(23*3600,true)
	var fog: Color=cycle.environment.fog_light_color
	var options:=preload("res://game/graphics_options.gd").new();options.preset("High");options.apply_tree(s.root)
	var ok: bool=not cycle.moon.shadow_enabled and cycle.sun.shadow_enabled and cycle.environment.fog_light_color==fog
	options.set_option("shadows",0);options.apply_tree(s.root)
	cycle.update(8*3600,true)
	ok=ok and not cycle.sun.shadow_enabled and not cycle.moon.shadow_enabled
	s.root.free();return ok

func test_station_light_budget_day_switch_streaming_and_origin_shift():
	var w:=RailWorld.new()
	w.stations=[{name="Test",code="TEST",origin=Vector3.ZERO,platforms=[Rect2(-400,-7,800,6),Rect2(-400,2,800,6)]}]
	var root:=Node3D.new();var pool:=preload("res://game/station_lighting.gd").new(w,root)
	pool.update(Vector3.ZERO,Vector3.ZERO,1,Callable(),true)
	var count: int=pool.active_lights
	var position: Vector3=pool.lights[0].position
	var ok: bool=count>0 and count<=pool.MAX_LIGHTS and pool.visible_fixtures<=pool.MAX_FIXTURES and pool.lights.all(func(light):return not light.shadow_enabled)
	var origin:=Vector3(100000,0,50000)
	pool.update(Vector3.ZERO,origin,1,Callable(),true)
	ok=ok and pool.lights[0].position==position-origin and pool.active_lights==count
	pool.update(Vector3.ZERO,origin,0,Callable(),true)
	ok=ok and pool.active_lights==0 and pool.lights.all(func(light):return not light.visible)
	pool.update(Vector3.ZERO,origin,1,func(_code):return false,true)
	ok=ok and pool.active_lights==0 and pool.visible_fixtures==0
	root.free();return ok

func test_detailed_route_fixtures_follow_canopies_and_platforms():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var root:=Node3D.new();var pool:=preload("res://game/station_lighting.gd").new(w,root)
	var sites:=0
	for group in pool.groups:
		for site in group.sites:
			sites+=1
			if not site.position.is_finite() or site.position.distance_to(group.origin)>700:
				root.free();return "Fixture outside station: "+group.code
	var observer: Vector3=w.stations[0].origin
	pool.update(observer,Vector3.ZERO,1,Callable(),true)
	var ok: bool=sites>100 and pool.active_lights>0 and pool.active_lights<=24
	root.free();return ok
