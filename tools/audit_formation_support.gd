extends SceneTree
## Compare actual rendered ground under unchanged rail samples. Explicit baseline
## scripts are supplied by the development audit, never used by the game.
var output:="res://.local/map-2026-10-24/formation-audit.json"
func _initialize():call_deferred("run")
func chunk(geo,p: Vector3,script,cache: Dictionary):
	var key:=Vector2i(floori(p.x/512),floori(p.z/512))
	if cache.has(key):return cache[key]
	if cache.size()>40:cache.erase(cache.keys()[0])
	var tile: Dictionary=geo.tile(key);var c=script.new(geo,{},null)
	c.origin=Vector3(key.x*512,0,key.y*512)
	for f in tile.get("features",[]):
		if f.kind=="water":c.water_levels.append({geometry=f.geometry,height=f.get("water_height",0)})
	c._index_shores();cache[key]=c;return c
func run():
	var world=preload("res://sim/layouts/kerala_coast.gd").build()
	var before=load("res://.local/map-2026-10-24/formation-baseline-geo.gd").new(world.scenery.route)
	var after=preload("res://game/geographic_data.gd").new(world.scenery.route)
	after.road_profiles=preload("res://game/geographic_road_profiles.gd").new()
	var setup_started:=Time.get_ticks_msec();before.install_railway(world);var baseline_install:=Time.get_ticks_msec()-setup_started
	setup_started=Time.get_ticks_msec();after.install_railway(world);var current_install:=Time.get_ticks_msec()-setup_started
	before.station_sites=preload("res://game/coastal_station_sites.gd").build(world,before)
	after.station_sites=preload("res://game/coastal_station_sites.gd").build(world,after)
	var old_chunk=load("res://.local/map-2026-10-24/formation-baseline-chunk.gd")
	var old_surface=load("res://.local/map-2026-10-24/formation-baseline-support.gd")
	var cache_before:={};var cache_after:={};var worsened:=[];var remaining:=[];var improved:=0;var samples:=0;var abutments:=[];var probes:=[]
	var layout=preload("res://game/geographic_ohe_layout.gd").new(world)
	for eid: String in world.graph.edges:
		var edge: Dictionary=world.graph.edges[eid]
		var approaches: Array=preload("res://game/geographic_bridges.gd").approaches(edge,0,edge.length,after.bridges)
		for approach in approaches:
			var s: float=(approach.x+approach.y)*.5;var chain: float=lerpf(edge.chainage_start,edge.chainage_end,s/edge.length)
			var section: Dictionary=layout.section(eid,chain,Vector3.ZERO)
			if section.is_empty():continue
			var p: Vector3=world.graph.position(eid,s);var a: Vector3=world.graph.position(eid,approach.x);var b: Vector3=world.graph.position(eid,approach.y)
			var left: float=(section.points[0]-p).dot(section.right)-4.2;var right: float=(section.points[-1]-p).dot(section.right)+4.2
			var ring:=[]
			for q in [a+section.right*left,b+section.right*left,b+section.right*right,a+section.right*right]:ring.append([q.x,q.z])
			var top: float=minf(a.y,b.y)-.18;var bottom: float=minf(after.height_at(p.x,p.z)-1,p.y-3)
			var footprint:=PackedVector2Array()
			for point in ring:footprint.append(Vector2(point[0],point[1]))
			if preload("res://game/geographic_bridge_clearance.gd").clear(after,footprint,top,bottom):
				abutments.append({edge=eid,start=approach.x,end=approach.y,chain=chain,ring=ring,top=top,bottom=bottom})
		for s in range(10,int(edge.length),75):
			var p: Vector3=world.graph.position(eid,s)
			var chain: float=lerpf(edge.chainage_start,edge.chainage_end,s/edge.length)
			if not after.bridge_at(chain).is_empty():continue
			var old=chunk(before,p,old_chunk,cache_before)
			var current=chunk(after,p,preload("res://game/geographic_scenery_chunk.gd"),cache_after)
			for offset in [-3.95,0.0,3.95]:
				var q: Vector3=p+world.graph.tangent(eid,s,1).cross(Vector3.UP)*offset-old.origin
				var previous: float=old_surface.surface_height(old,Vector2(q.x,q.z))
				var height: float=preload("res://game/geographic_road_support.gd").surface_height(current,Vector2(q.x,q.z))
				samples+=1
				probes.append({edge=eid,s=s,offset=offset,previous=previous,height=height,rail=p.y,x=q.x+old.origin.x,z=q.z+old.origin.z})
	# A shared bridge wall is emitted once by the section owner and supports all
	# parallel roads. Check actual footprints, not merely matching edge IDs.
	var support_bins:={}
	for abutment in abutments:
		var polygon:=PackedVector2Array();var bounds:=Rect2(Vector2(abutment.ring[0][0],abutment.ring[0][1]),Vector2.ZERO)
		for point in abutment.ring:
			var q:=Vector2(point[0],point[1]);polygon.append(q);bounds=bounds.expand(q)
		for x in range(floori(bounds.position.x/512),floori(bounds.end.x/512)+1):
			for z in range(floori(bounds.position.y/512),floori(bounds.end.y/512)+1):
				var key:=Vector2i(x,z)
				if not support_bins.has(key):support_bins[key]=[]
				support_bins[key].append({ring=polygon,top=abutment.top})
	for probe in probes:
		var covered:=false
		for abutment in support_bins.get(Vector2i(floori(probe.x/512),floori(probe.z/512)),[]):
			if abutment.top>=probe.rail-.6 and Geometry2D.is_point_in_polygon(Vector2(probe.x,probe.z),abutment.ring):covered=true;break
		var old_error: float=maxf(0,probe.rail-.65-probe.previous);var new_error: float=maxf(0,probe.rail-.65-probe.height) if not covered else 0.0
		if new_error<old_error-.05:improved+=1
		if new_error>old_error+.1:worsened.append(probe)
		if new_error>.1:remaining.append(probe)
	var report:={samples=samples,improved=improved,worsened=worsened,remaining=remaining,abutments=abutments,railway_time=world.time,baseline_install_ms=baseline_install,current_install_ms=current_install,refined_cells=after.formation_support.fine_cells.size()}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FORMATION_AUDIT samples=",samples," improved=",improved," worsened=",worsened.size()," remaining=",remaining.size()," abutments=",abutments.size())
	quit(0 if worsened.is_empty() else 1)
