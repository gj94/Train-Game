extends SceneTree
## Rendering geometry only; does not advance the railway or rewrite route data.
func _initialize() -> void:
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo:=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world)
	var sites:=preload("res://game/coastal_station_sites.gd").build(world)
	var zones:=[];var seen:={};var platforms:=[];var rails:=[]
	for entries in sites.values():
		for zone in entries:
			if seen.has(zone.id) or zone.get("access_zone",false):continue
			seen[zone.id]=true
			var ring:=[]
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p: Vector3=zone.centre+zone.basis.x*corner.x*zone.extent.x*.5+zone.basis.z*corner.y*zone.extent.y*.5
				ring.append([p.x,p.z])
			var building:=[]
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p: Vector3=zone.solid_centre+zone.basis.x*corner.x*(zone.solid_extent.x*.5+.5)+zone.basis.z*corner.y*(zone.solid_extent.y*.5+.5)
				building.append([p.x,p.z])
			zones.append({id=zone.id,ring=ring,building=building,height=zone.height,halt=zone.halt,centre=[zone.centre.x,zone.centre.z],extent=[zone.extent.x,zone.extent.y],x=[zone.basis.x.x,zone.basis.x.z],z=[zone.basis.z.x,zone.basis.z.z]})
	for station in world.stations:
		for face in preload("res://sim/platform_faces.gd").entries(station):
			var span:=preload("res://sim/berth_clearance.gd").platform_span(world,face.edge)
			for s in range(floori(span.x),ceili(span.y),12):
				var a:=world.graph.position(face.edge,s)
				var b:=world.graph.position(face.edge,minf(s+12,span.y))
				var r: Vector3=world.graph.tangent(face.edge,s,1).cross(Vector3.UP)*face.platform_side
				var ring:=[]
				for p in [a+r*1.9,b+r*1.9,b+r*(2.02+face.platform_width+.3),a+r*(2.02+face.platform_width+.3)]:ring.append([p.x,p.z])
				platforms.append({station=station.code,ring=ring,height=(a.y+b.y)*.5+1.26})
	for id in world.graph.edges:
		var points:=[]
		for p in world.graph.edges[id].points:points.append([p.x,p.y,p.z])
		rails.append({id=id,points=points})
	var segments:=[]
	for segment in geo.segments:
		var copy: Dictionary=segment.duplicate()
		copy.a=[segment.a.x,segment.a.y,segment.a.z];copy.b=[segment.b.x,segment.b.y,segment.b.z]
		segments.append(copy)
	var overhead:=[]
	var ohe=preload("res://game/geographic_ohe_layout.gd").new(world)
	for eid in world.graph.edges:
		for plan in ohe.plans(eid,0,world.graph.edges[eid].length,Vector3.ZERO):
			if plan.portal:
				var a: Vector3=plan.posts[0];var b: Vector3=plan.posts[-1]
				overhead.append({a=[a.x,a.z],b=[b.x,b.z],height=plan.points.map(func(p):return p.y).max()+8.85})
			else:
				for i in plan.posts.size():
					var a: Vector3=plan.posts[i];var b: Vector3=plan.anchors[0 if i==0 else -1].contact
					overhead.append({a=[a.x,a.z],b=[b.x,b.z],height=maxf(a.y+7.25,b.y+1)})
	var output:={zones=zones,platforms=platforms,rails=rails,ground_segments=segments,station_bins=geo.station_bins,formation_regions=geo.formation_regions,bridges=geo.bridges,overhead=overhead}
	FileAccess.open("res://.local/scenery-context.json",FileAccess.WRITE).store_string(JSON.stringify(output))
	print("SCENERY_CONTEXT ",rails.size()," edges, ",platforms.size()," platform patches, ",zones.size()," precincts")
	quit()
