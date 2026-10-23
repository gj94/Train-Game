extends RefCounted
## Immutable, rendering-only bridge/approach elevations shared by tile workers.
## Source: tools/maps/road_surfaces.py; simulation never reads these profiles.
const PATH:="res://assets/models/scenery/road-surfaces.json"
const CELL:=64.0
var cells:={}
var way_cells:={}
var knot_cells:={}
var profile_ways:={}
var station_walkways:={}
var finishes
var support_clearance=preload("res://game/geographic_scenery_occupancy.gd").new()
func _init(data: Dictionary={}) -> void:
	finishes=preload("res://game/geographic_road_finishes.gd").new({ways={}} if not data.is_empty() else {})
	if data.is_empty() and FileAccess.file_exists(PATH):
		data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for way in data.get("station_pedestrian_ways",[]):station_walkways[way]=true
	for row in data.get("support_posts",[]):
		var p:=Vector2(row[0],row[1])
		support_clearance.add_road(p,p,.85)
	var endpoints:={}
	for row in data.get("segments",[]):
		profile_ways[row[0]]=true
		if not way_cells.has(row[0]):way_cells[row[0]]={};endpoints[row[0]]={}
		var a:=Vector2(row[1],row[2]);var b:=Vector2(row[4],row[5])
		endpoints[row[0]][a]=true;endpoints[row[0]][b]=true
		var item:={way=row[0],a=a,b=b,ya=row[3],yb=row[6],bridge=bool(row[7])}
		var indexed_way: Dictionary=way_cells[row[0]]
		var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(.05)
		for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
			for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
				var key:=Vector2i(x,z)
				if not cells.has(key):cells[key]=[]
				cells[key].append(item)
				if not indexed_way.has(key):indexed_way[key]=[]
				indexed_way[key].append(item)
	# Keep every height/bridge boundary, including level junction aprons. Store
	# each endpoint once, instead of rechecking both ends of duplicated segments
	# in every intersecting cell whenever a road ribbon asks for its split points.
	for way in endpoints:
		var knots:={}
		for point: Vector2 in endpoints[way]:
			var key:=Vector2i(floori(point.x/CELL),floori(point.y/CELL))
			if not knots.has(key):knots[key]=[]
			knots[key].append(point)
		knot_cells[way]=knots
func sample(way: String,p: Vector2) -> Dictionary:
	if not profile_ways.has(way):return {}
	var best:=.06*.06
	var result:={}
	# The general index remains available for roads crossing underneath a deck.
	# A height query only visits its own way, even in a crowded station tile.
	for item in way_cells[way].get(Vector2i(floori(p.x/CELL),floori(p.y/CELL)),[]):
		var t:=clampf((p-item.a).dot(item.b-item.a)/maxf(.000001,item.a.distance_squared_to(item.b)),0,1)
		var distance: float=p.distance_squared_to(item.a.lerp(item.b,t))
		if distance<=best:
			best=distance;result={height=lerpf(item.ya,item.yb,t),bridge=item.bridge}
	return result

func split_fractions(way: String,a: Vector2,b: Vector2) -> Array[float]:
	# Preserve profile corners when the visual ribbon uses a different sample
	# spacing. Otherwise a T-junction at a crest can meet a chord below its deck.
	var axis:=b-a;var squared:=axis.length_squared()
	var result: Array[float]=[]
	if squared<.000001 or not profile_ways.has(way):return result
	var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(.06)
	var seen:={}
	var knots: Dictionary=knot_cells[way]
	var length:=sqrt(squared)
	for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
		for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
			for point: Vector2 in knots.get(Vector2i(x,z),[]):
				var t: float=(point-a).dot(axis)/squared
				if t<=.000001 or t>=.999999 or point.distance_squared_to(a+axis*t)>.06*.06:continue
				var key:=roundi(t*length*1000)
				if not seen.has(key):seen[key]=true;result.append(t)
	result.sort()
	return result
