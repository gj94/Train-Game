extends SceneTree
## Static geography audit: renders building envelopes/access geometry only.
## Never advances or simulates a railway timetable.
const Chunk:=preload("res://game/geographic_scenery_chunk.gd")
const Access:=preload("res://game/village_access.gd")
class Capture:
	extends RefCounted
	var triangles:=0
	var wall_segments:=[]
	func triangle(_kind,_a,_b,_c,_normal,_color=Color.WHITE,_uv=[],_uv2=[]):triangles+=1
	func quad(_kind,_a,_b,_c,_d,_normal,_color=Color.WHITE,_uv=[]):pass
	func beam(kind,a,b,width,_color=Color.WHITE,depth=-1):
		if kind=="architecture_detail" and width>.24 and width<.28 and is_equal_approx(depth,.07):wall_segments.append([a,b])
	func box(_kind,_p,_size,_color=Color.WHITE,_basis=Basis.IDENTITY):pass
class Assets:
	extends RefCounted
	var catalog:={}
	func place(_kind,_p,_angle=0,_scale=Vector3.ONE):pass
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var output:="res://.local/map-2026-10-24/village-audit.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo:=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world)
	geo.vegetation_clearance=preload("res://game/vegetation_clearance.gd").build(world)
	geo.road_profiles=preload("res://game/geographic_road_profiles.gd").new()
	geo.road_reservations=preload("res://game/geographic_road_reservations.gd").new(world,geo.station_sites)
	var assets:=Assets.new();assets.catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
	var began:=Time.get_ticks_msec();var tiles:=0;var buildings:=0;var paths:=[];var triangle_count:=0;var walls:=[]
	for key: Vector2i in geo.tile_keys:
		var tile: Dictionary=geo.tile(key)
		if not tile.get("features",[]).any(func(f):return f.kind=="building"):continue
		var c=Chunk.new(geo,{},assets)
		c.origin=Vector3(key.x*512,0,key.y*512);c.tile_features=tile.get("features",[])
		c.mask=Marshalls.base64_to_raw(tile.get("mask",""))
		c.library=assets;c.batch=Capture.new();c.root=Node3D.new()
		for feature in c.tile_features:
			if feature.kind=="water":c.water_levels.append({geometry=feature.geometry,height=feature.get("water_height",0)})
		c._index_shores();c._register_occupied(c.tile_features)
		for feature in c.tile_features:
			if feature.kind=="building":c._building(feature)
		buildings+=c.rendered_buildings.size();c.batch.triangles=0;c.batch.wall_segments=[]
		preload("res://game/kerala_scenery.gd").dress(c,c.tile_features);triangle_count+=c.batch.triangles
		for segment in c.batch.wall_segments:
			var a: Vector3=segment[0]+c.origin;var b: Vector3=segment[1]+c.origin
			var rail: Dictionary=geo.nearest_rail(a.x,a.z)
			walls.append({a=[a.x,a.y,a.z],b=[b.x,b.y,b.z],km=rail.s*.001,tile=[key.x,key.y]})
		c.root.free()
		for building in c.rendered_buildings:
			if not building.has("path"):continue
			var plan: Dictionary=building.path
			var a: Vector2=plan.a+Vector2(c.origin.x,c.origin.z);var b: Vector2=plan.b+Vector2(c.origin.x,c.origin.z)
			var rail: Dictionary=geo.nearest_rail(a.x,a.y)
			paths.append({building=building.id,kind=building.detail.kind,road=plan.road,tile=[key.x,key.y],a=[a.x,building.floor_y+.06,a.y],b=[b.x,Access.ground(c._ground,plan.b)+.06,b.y],steps=plan.flight.count,run=plan.flight.run,rise=plan.flight.rise,rail_distance=rail.distance,km=rail.s*.001})
		tiles+=1
		if tiles%100==0:print("VILLAGE_AUDIT tiles=",tiles," buildings=",buildings," paths=",paths.size())
	var report:={tiles=tiles,buildings=buildings,paths=paths,walls=walls,triangles=triangle_count,elapsed_ms=Time.get_ticks_msec()-began}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("VILLAGE_AUDIT_COMPLETE tiles=",tiles," buildings=",buildings," paths=",paths.size()," triangles=",triangle_count)
	quit()
