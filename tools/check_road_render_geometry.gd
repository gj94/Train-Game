extends SceneTree
## Export actual generated road triangles around every station (or --all) for an
## independent Shapely intersection audit. No timetable steps or rendering.
class AuditChunk:
	extends "res://game/geographic_scenery_chunk.gd"
	var road_support_records: Array=[]
class Capture:
	extends RefCounted
	var triangles:=[]
	var piers:=[]
	var triangle_count:=0
	var capture_triangles:=true
	func triangle(kind,a,b,c,_normal,_color=Color.WHITE,_uv=[],_uv2=[]):
		if kind in preload("res://game/geographic_road_finishes.gd").KINDS+["road_shoulder","paint"]:
			triangle_count+=1
			if capture_triangles:triangles.append({kind=kind,points=[[a.x,a.y,a.z],[b.x,b.y,b.z],[c.x,c.y,c.z]]})
	func quad(_kind,_a,_b,_c,_d,_normal,_color=Color.WHITE,_uv=[]):pass
	func beam(_kind,_a,_b,_width,_color=Color.WHITE,_depth=-1):pass
	func box(kind,p,size,_color=Color.WHITE,_basis=Basis.IDENTITY):
		if kind=="concrete" and is_equal_approx(size.x,1.1):piers.append([p.x,p.y,p.z,size.y])
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var all_tiles:="--all" in OS.get_cmdline_user_args()
	var supports_only:="--supports-only" in OS.get_cmdline_user_args()
	var tile_filter:=PackedStringArray()
	var output:="res://.local/road-render-triangles.jsonl"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--tiles="):tile_filter=arg.trim_prefix("--tiles=").split(",",false)
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo:=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world)
	geo.vegetation_clearance=preload("res://game/vegetation_clearance.gd").build(world)
	geo.road_profiles=preload("res://game/geographic_road_profiles.gd").new()
	geo.road_reservations=preload("res://game/geographic_road_reservations.gd").new(world,geo.station_sites)
	var keys:={}
	if not tile_filter.is_empty():
		for value in tile_filter:
			var parts:=value.split("_")
			if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				printerr("Invalid scenery tile: ",value);quit(2);return
			keys[Vector2i(int(parts[0]),int(parts[1]))]=true
	elif all_tiles:
		for key in geo.tile_keys:keys[key]=true
	else:
		for station in world.stations:
			var p: Vector3=station.origin
			for x in range(floori(p.x/512)-1,floori(p.x/512)+2):
				for z in range(floori(p.z/512)-1,floori(p.z/512)+2):keys[Vector2i(x,z)]=true
	var file:=FileAccess.open(output,FileAccess.WRITE)
	var started:=Time.get_ticks_msec();var tiles:=0;var triangles:=0;var piers:=0
	for key: Vector2i in keys:
		var tile: Dictionary=geo.tile(key)
		if tile.is_empty():continue
		var chunk=AuditChunk.new(geo,{},null)
		chunk.origin=Vector3(key.x*512,0,key.y*512);chunk.tile_features=tile.get("features",[])
		chunk.batch=Capture.new()
		chunk.batch.capture_triangles=not supports_only
		for feature in chunk.tile_features:
			if feature.kind=="water":chunk.water_levels.append({geometry=feature.geometry,height=feature.get("water_height",0)})
		chunk._index_shores()
		for feature in chunk.tile_features:
			if feature.kind!="road":continue
			chunk._road(feature)
			triangles+=chunk.batch.triangle_count;chunk.batch.triangle_count=0
			if chunk.batch.triangles.is_empty() and chunk.road_support_records.is_empty() and chunk.batch.piers.is_empty():continue
			var supports:=[]
			for support in chunk.road_support_records:
				var row:={kind=support.kind,top=[],foot=[],bank=[]}
				for p in support.top:row.top.append([p.x,p.y,p.z])
				for p in support.foot:row.foot.append([p.x,p.y,p.z])
				for p in support.bank:row.bank.append([p.x,p.y,p.z])
				supports.append(row)
			file.store_line(JSON.stringify({tile=[key.x,key.y],way=feature.id,triangles=chunk.batch.triangles,piers=chunk.batch.piers,supports=supports}))
			piers+=chunk.batch.piers.size()
			chunk.batch.triangles=[];chunk.batch.piers=[]
			chunk.road_support_records=[]
		tiles+=1
		if tiles%25==0:print("ROAD_RENDER tiles=",tiles," triangles=",triangles," elapsed_ms=",Time.get_ticks_msec()-started)
	file.close()
	print("ROAD_RENDER_COMPLETE tiles=",tiles," triangles=",triangles," piers=",piers," supports_only=",supports_only," elapsed_ms=",Time.get_ticks_msec()-started)
	quit()
