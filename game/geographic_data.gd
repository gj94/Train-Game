extends RefCounted
## Read-only geographic data adapter. Each scenery worker owns its DEM cache.
const ROOT := "res://data/routes/kerala_coast/"
const CELL := 256.0
const Earthworks := preload("res://game/geographic_earthworks.gd")
var route: Dictionary
var elevation := {}
var elevation_order: Array = []
var rail_bins := {}
var segments := []
var tile_keys := {}
var station_bins := {}
var formation_regions: Array = []
var formation_bins := {}
var station_sites := {}
var vegetation_clearance
var road_profiles
var road_reservations
var operating_ways := {}
var bridge_bins := {}
var bridges: Array = []
var formation_support
var shore_context:=preload("res://game/geographic_shore_context.gd").new()

func _init(data: Dictionary = {}) -> void:
	route = data if not data.is_empty() else preload("res://sim/layouts/kerala_coast.gd").source()
	for key in route.get("scenery_tiles",[]): tile_keys[Vector2i(key[0],key[1])] = true
	var operations: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"operations.json"))
	formation_regions=Earthworks.regions(route,operations)
	formation_bins=Earthworks.index(formation_regions)
	for i in operations.stations.size():
		var width:=32.0
		for road in operations.stations[i].roads:
			width=maxf(width,absf(road.offset)+28)
			if road.get("osm_way")!=null:operating_ways["w"+str(int(road.osm_way))]=true
		var s: float=route.stations[i].s
		for key in range(floori((s-850)/500),ceili((s+850)/500)+1):
			station_bins[key]=maxf(station_bins.get(key,32),width)
	bridges=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"structures.json")).bridges
	for span in bridges:
		for key in range(floori(span.start/500),floori(span.end/500)+1):
			if not bridge_bins.has(key):bridge_bins[key]=[]
			bridge_bins[key].append(span)
	var points: Array = route.alignment

	for i in range(0,points.size()-1,5):
		var j := mini(i+5,points.size()-1)
		var a := Vector3(points[i][0],points[i][1],points[i][2])
		var b := Vector3(points[j][0],points[j][1],points[j][2])
		var chain: float = route.chainage[i]
		var bridge := false

		var index := segments.size()
		segments.append({a=a,b=b,s=chain,end_s=route.chainage[j],bridge=bridge})
		for x in range(floori(minf(a.x,b.x)/CELL)-1,floori(maxf(a.x,b.x)/CELL)+2):
			for z in range(floori(minf(a.z,b.z)/CELL)-1,floori(maxf(a.z,b.z)/CELL)+2):
				var key := Vector2i(x,z)
				if not rail_bins.has(key): rail_bins[key] = []
				rail_bins[key].append(index)
	preload("res://game/geographic_depot_ground.gd").install(self,route)

## Ground outer platform roads and longer station ladders beyond the ordinary
## 32 m formation. Keep the inexpensive main-line/depot index, and share the
## additions with workers rather than rebuilding their immutable geometry.
func install_railway(world: RailWorld) -> void:
	formation_support=preload("res://game/geographic_formation_support.gd").new()
	formation_support.build(world,self)
	Earthworks.include_running_roads(formation_regions,world.graph.edges,world.graph.nodes)
	formation_bins=Earthworks.index(formation_regions)
	for id: String in world.graph.edges:
		var edge: Dictionary=world.graph.edges[id]
		if "_DEPOT_" in id:continue # already installed from route.depot_alignment
		var lateral: float=maxf(absf(edge.lateral),maxf(absf(world.graph.nodes[edge.a].lateral),absf(world.graph.nodes[edge.b].lateral)))
		var terminal: bool=world.graph.nodes[edge.a].edges.size()==1 or world.graph.nodes[edge.b].edges.size()==1
		var include_all:=lateral>24 or terminal
		var count:=maxi(1,ceili(edge.length/25.0))
		for i in count:
			var start: float=edge.length*i/float(count)
			var end: float=edge.length*(i+1)/float(count)
			var sa: float=lerpf(edge.chainage_start,edge.chainage_end,i/float(count))
			var sb: float=lerpf(edge.chainage_start,edge.chainage_end,(i+1)/float(count))
			# Near an abutment the decimated reference alignment can project an
			# outer road several metres back into the bridge. Index the actual
			# road there so its dry approach keeps the correct ground height.
			if not include_all and not _near_bridge_end(sa,sb):continue
			var a:=world.graph.position(id,start);var b:=world.graph.position(id,end)
			var index:=segments.size()
			segments.append({a=a,b=b,s=sa,end_s=sb,bridge=false,depot=false,yard=include_all})
			for x in range(floori(minf(a.x,b.x)/CELL)-1,floori(maxf(a.x,b.x)/CELL)+2):
				for z in range(floori(minf(a.z,b.z)/CELL)-1,floori(maxf(a.z,b.z)/CELL)+2):
					var key:=Vector2i(x,z)
					if not rail_bins.has(key):rail_bins[key]=[]
					rail_bins[key].append(index)

func _near_bridge_end(a: float,b: float) -> bool:
	var lo:=minf(a,b)-28;var hi:=maxf(a,b)+28
	for key in range(floori(lo/500),floori(hi/500)+1):
		for span in bridge_bins.get(key,[]):
			if (span.start>=lo and span.start<=hi) or (span.end>=lo and span.end<=hi):return true
	return false

func share_railway(source) -> void:
	segments=source.segments;rail_bins=source.rail_bins
	formation_regions=source.formation_regions;formation_bins=source.formation_bins
	formation_support=source.formation_support

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
			best={distance=d,height=lerpf(segment.a.y,segment.b.y,along),s=lerpf(segment.s,segment.get("end_s",segment.s+a.distance_to(b)),along),bridge=segment.bridge,depot=segment.get("depot",false),yard=segment.get("yard",false)}
	best.bridge=not best.get("depot",false) and not bridge_at(best.s).is_empty()
	return best

func bridge_at(s: float) -> Dictionary:
	for span in bridge_bins.get(floori(s/500),[]):
		if s>=span.start and s<=span.end:return span
	return {}

func ground_at(x: float,z: float) -> float:
	var height := height_at(x,z)
	var rail := nearest_rail(x,z)
	var width: float=12.0 if rail.get("depot",false) or rail.get("yard",false) else Earthworks.half_width(formation_bins,rail.s)
	height=Earthworks.grade(height,rail,width)
	return preload("res://game/coastal_station_sites.gd").ground(station_sites,x,z,height)
