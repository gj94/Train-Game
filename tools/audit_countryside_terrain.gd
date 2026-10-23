extends SceneTree
## Static render-only route audit. No train time advances or timetable replay.
const Foundations:=preload("res://game/geographic_foundations.gd")
var geo
var report:={samples=[],rail_samples=0,new_exposure=[],baseline_exposure=[],profiles=[]}
var output:="res://.local/map-2026-10-24/terrain-audit.json"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	call_deferred("run")

func old_ground(x: float,z: float) -> float:
	var height: float=geo.height_at(x,z)
	var rail: Dictionary=geo.nearest_rail(x,z)
	var width: float=12.0 if rail.get("depot",false) or rail.get("yard",false) else geo.station_bins.get(floori(rail.s/500),32)
	var target: float=rail.height-(.8 if rail.bridge else .15)
	var graded:=lerpf(target,height,smoothstep(width,width+58,rail.distance))
	height=minf(height,graded) if rail.bridge else graded
	return preload("res://game/coastal_station_sites.gd").ground(geo.station_sites,x,z,height)

func run() -> void:
	var started:=Time.get_ticks_msec()
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	geo=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world,geo)
	var new_worst:=0.0;var old_worst:=0.0
	for id: String in world.graph.edges:
		var edge: Dictionary=world.graph.edges[id]
		for s in range(10,int(edge.length),75):
			var p:=world.graph.position(id,s)
			if geo.nearest_rail(p.x,p.z).bridge:continue
			report.rail_samples+=1
			var previous:=Foundations.surface_height(old_ground,p.x,p.z)
			var current:=Foundations.surface_height(geo.ground_at,p.x,p.z)
			var old_error:=absf(previous-(p.y-.15));var new_error:=absf(current-(p.y-.15))
			old_worst=maxf(old_worst,old_error);new_worst=maxf(new_worst,new_error)
			if new_error>old_error+.10:report.new_exposure.append({edge=id,s=s,previous=previous,current=current,rail=p.y,nearest=geo.nearest_rail(p.x,p.z),lateral=edge.lateral,x=p.x,z=p.z})
			if old_error>.5:report.baseline_exposure.append({edge=id,s=s,error=old_error})
	# Representative cross sections every kilometre are also parity fixtures for
	# the offline road generator, with natural, graded and station-adjusted ground.
	for i in range(0,geo.route.alignment.size()-1,50):
		var a: Array=geo.route.alignment[i];var b: Array=geo.route.alignment[mini(i+1,geo.route.alignment.size()-1)]
		var along:=Vector2(b[0]-a[0],b[2]-a[2]).normalized();var side:=Vector2(-along.y,along.x)
		var profile:=[]
		for offset in [-100.0,-60.0,-32.0,-24.0,-14.0,0.0,14.0,24.0,32.0,60.0,100.0]:
			var point: Vector2=Vector2(a[0],a[2])+side*offset
			var sample:={x=point.x,z=point.y,old=old_ground(point.x,point.y),height=geo.ground_at(point.x,point.y),natural=geo.height_at(point.x,point.y)}
			report.samples.append(sample);profile.append(sample.height)
		if geo.formation_regions.is_empty():continue
		report.profiles.append({s=geo.route.chainage[i],heights=profile})
	report.seconds=(Time.get_ticks_msec()-started)*.001;report.maximum_old_rail_error=old_worst;report.maximum_new_rail_error=new_worst
	report.railway_time=world.time
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TERRAIN_AUDIT ",JSON.stringify({rail_samples=report.rail_samples,parity_samples=report.samples.size(),new_exposure=report.new_exposure.size(),old_worst=old_worst,new_worst=new_worst,seconds=report.seconds}))
	quit(0 if report.new_exposure.is_empty() else 1)
