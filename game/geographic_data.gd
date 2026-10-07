extends RefCounted
## Read-only geographic data adapter. Each scenery worker owns its DEM cache.
const ROOT := "res://data/routes/kerala_coast/"
const CELL := 256.0
var route: Dictionary
var elevation := {}
var elevation_order: Array = []
var rail_bins := {}
var segments := []
var tile_keys := {}
var station_bins := {}
var operating_ways := {}

func _init(data: Dictionary = {}) -> void:
	route = data if not data.is_empty() else preload("res://sim/layouts/kerala_coast.gd").source()
	for key in route.get("scenery_tiles",[]): tile_keys[Vector2i(key[0],key[1])] = true
	var operations: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"operations.json"))
	for i in operations.stations.size():
		var width:=32.0
		for road in operations.stations[i].roads:
			width=maxf(width,absf(road.offset)+28)
			operating_ways["w"+str(int(road.osm_way))]=true
		var s: float=route.stations[i].s
		for key in range(floori((s-850)/500),ceili((s+850)/500)+1):
			station_bins[key]=maxf(station_bins.get(key,32),width)
	var points: Array = route.alignment
	var bridges := []
	for span in route.spans:
		if span.tags.get("bridge","no") != "no": bridges.append(Vector2(span.start,span.end))
	for i in range(0,points.size()-1,10):
		var j := mini(i+10,points.size()-1)
		var a := Vector3(points[i][0],points[i][1],points[i][2])
		var b := Vector3(points[j][0],points[j][1],points[j][2])
		var chain: float = route.chainage[i]
		var bridge := false
		for span in bridges:
			if chain>=span.x-30 and chain<=span.y+30: bridge=true; break
		var index := segments.size()
		segments.append({a=a,b=b,s=chain,bridge=bridge})
		for x in range(floori(minf(a.x,b.x)/CELL)-1,floori(maxf(a.x,b.x)/CELL)+2):
			for z in range(floori(minf(a.z,b.z)/CELL)-1,floori(maxf(a.z,b.z)/CELL)+2):
				var key := Vector2i(x,z)
				if not rail_bins.has(key): rail_bins[key] = []
				rail_bins[key].append(index)

func tile(key: Vector2i) -> Dictionary:
	if not tile_keys.has(key): return {}
	var file := ROOT+"tiles/%d_%d.json" % [key.x,key.y]
	return JSON.parse_string(FileAccess.get_file_as_string(file))

func height_at(x: float, z: float) -> float:
	var key := Vector2i(floori(x/4096),floori(z/4096))
	if not elevation.has(key):
		var path := ROOT+"elevation/%d_%d.bin" % [key.x,key.y]
		if not FileAccess.file_exists(path): return 0.0
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size()!=4+129*129*2: return 0.0
		elevation[key] = bytes
		elevation_order.append(key)
		if elevation_order.size()>32:
			elevation.erase(elevation_order.pop_front())
	var local := Vector2(x-key.x*4096,z-key.y*4096)/32.0
	var col := clampi(floori(local.x),0,127)
	var row := clampi(floori(local.y),0,127)
	var bytes: PackedByteArray = elevation[key]
	var a := _height(bytes,col,row)
	var b := _height(bytes,col+1,row)
	var c := _height(bytes,col,row+1)
	var d := _height(bytes,col+1,row+1)
	return lerpf(lerpf(a,b,local.x-col),lerpf(c,d,local.x-col),local.y-row)

func _height(bytes: PackedByteArray, x: int, z: int) -> float:
	var value := bytes.decode_u16(4+(z*129+x)*2)
	return (value-65536 if value>=32768 else value)*.1

func nearest_rail(x: float,z: float) -> Dictionary:
	var p := Vector2(x,z)
	var best := {distance=INF,height=0.0,s=0.0,bridge=false}
	for index in rail_bins.get(Vector2i(floori(x/CELL),floori(z/CELL)),[]):
		var segment: Dictionary = segments[index]
		var a := Vector2(segment.a.x,segment.a.z)
		var b := Vector2(segment.b.x,segment.b.z)
		var along := clampf((p-a).dot(b-a)/maxf(.001,(b-a).length_squared()),0,1)
		var d := p.distance_to(a.lerp(b,along))
		if d<best.distance:
			best={distance=d,height=lerpf(segment.a.y,segment.b.y,along),s=segment.s+along*a.distance_to(b),bridge=segment.bridge}
	return best

func ground_at(x: float,z: float) -> float:
	var height := height_at(x,z)
	var rail := nearest_rail(x,z)
	var width: float=station_bins.get(floori(rail.s/500),32)
	if rail.distance<width+58:
		if rail.bridge:
			# SRTM can capture bridge/embankment tops. Keep natural lower ground,
			# but never let those radar returns bury the reconstructed deck.
			height=minf(height,lerpf(rail.height-.8,height,smoothstep(width,width+58,rail.distance)))
		else:height=lerpf(rail.height-.15,height,smoothstep(width,width+58,rail.distance))
	return height
