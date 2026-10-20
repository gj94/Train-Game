extends RefCounted
## Immutable, rendering-only bridge/approach elevations shared by tile workers.
## Source: tools/maps/road_surfaces.py; simulation never reads these profiles.
const PATH:="res://assets/models/scenery/road-surfaces.json"
const CELL:=64.0
var cells:={}
func _init(data: Dictionary={}) -> void:
	if data.is_empty() and FileAccess.file_exists(PATH):
		data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for row in data.get("segments",[]):
		var a:=Vector2(row[1],row[2]);var b:=Vector2(row[4],row[5])
		var item:={way=row[0],a=a,b=b,ya=row[3],yb=row[6],bridge=bool(row[7])}
		var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(.05)
		for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
			for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
				var key:=Vector2i(x,z)
				if not cells.has(key):cells[key]=[]
				cells[key].append(item)
func sample(way: String,p: Vector2) -> Dictionary:
	var best:=.06*.06
	var result:={}
	for item in cells.get(Vector2i(floori(p.x/CELL),floori(p.y/CELL)),[]):
		if item.way!=way:continue
		var t:=clampf((p-item.a).dot(item.b-item.a)/maxf(.000001,item.a.distance_squared_to(item.b)),0,1)
		var distance: float=p.distance_squared_to(item.a.lerp(item.b,t))
		if distance<=best:
			best=distance;result={height=lerpf(item.ya,item.yb,t),bridge=item.bridge}
	return result
