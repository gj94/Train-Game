extends RefCounted
## Remove verge/paint through connected road mouths, preserving different levels.
## Worker-local index; neighbouring tiles are read only when a border is queried.
const Widths:={motorway=10.0,trunk=9.0,primary=8.0,secondary=6.5,tertiary=5.5,residential=4.5,service=3.6,footway=1.5,path=1.0,track=2.8}
const Difference=preload("res://game/geographic_polygon_difference.gd")
var geo
var origin: Vector3
var cells:={}
var loaded:={}
var serial:=0
var widths:={}
func _init(data,offset: Vector3,features: Array):
	geo=data;origin=offset
	var tile:=Vector2i(floori(origin.x/512),floori(origin.z/512))
	loaded[tile]=true;_add(features,Vector2.ZERO)
func _add(features: Array,offset: Vector2) -> void:
	for f in features:
		if f.kind!="road":continue
		if f.geometry.type not in ["LineString","MultiLineString"]:continue
		var tags: Dictionary=f.tags
		if tags.get("highway","") in ["proposed","construction","steps"] or tags.get("tunnel","no")!="no" or tags.get("railway","")=="platform" or float(tags.get("layer","0"))<0:continue
		if geo.road_profiles!=null and geo.road_profiles.station_walkways.has(f.id):continue
		var width: float=Widths.get(tags.get("highway",""),4.0)*.5
		widths[f.id]=width
		var lines: Array=f.geometry.coordinates if f.geometry.type=="MultiLineString" else [f.geometry.coordinates]
		for line in lines:
			for i in range(1,line.size()):
				var a:=Vector2(line[i-1][0],line[i-1][1])+offset;var b:=Vector2(line[i][0],line[i][1])+offset
				if a.distance_squared_to(b)<.00001:continue
				var normal:=(b-a).normalized().orthogonal()*width
				var ring:=PackedVector2Array([a-normal,b-normal,b+normal,a+normal])
				var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(width)
				var item:={id=serial,way=f.id,a=a,b=b,ring=ring,bounds=bounds,width=width,mapped_bridge=tags.get("bridge","no")!="no"};serial+=1
				for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
					for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
						var key:=Vector2i(x,z)
						if not cells.has(key):cells[key]=[]
						cells[key].append(item)
func candidates(bounds: Rect2) -> Array:
	if geo is Object and geo.has_method("tile"):
		var extent:=bounds.grow(6);var offset:=Vector2(origin.x,origin.z)
		for x in range(floori((extent.position.x+offset.x)/512),floori((extent.end.x+offset.x)/512)+1):
			for z in range(floori((extent.position.y+offset.y)/512),floori((extent.end.y+offset.y)/512)+1):
				var key:=Vector2i(x,z)
				if not loaded.has(key):loaded[key]=true;_add(geo.tile(key).get("features",[]),Vector2(x*512,z*512)-offset)
	var used:={};var found:=[]
	for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
		for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
			for item in cells.get(Vector2i(x,z),[]):
				if used.has(item.id) or not bounds.intersects(item.bounds):continue
				used[item.id]=true;found.append(item)
	return found

func crossing_aprons(c,way: String,ring: PackedVector2Array,a: Vector3,b: Vector3) -> Array:
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var own_axis:=Vector2(b.x-a.x,b.z-a.z).normalized();var extension: float=widths.get(way,2.0)+.65
	var result:=[]
	for item in candidates(bounds.grow(extension)):
		var axis: Vector2=(item.b-item.a).normalized()
		if item.way==way or absf(axis.dot(own_axis))>.85:continue
		var q:=Geometry2D.get_closest_point_to_segment(bounds.get_center(),item.a,item.b)
		var sample: Dictionary={} if geo.road_profiles==null else geo.road_profiles.sample(item.way,q+Vector2(origin.x,origin.z))
		if item.mapped_bridge and sample.is_empty():continue
		var y: float=sample.height if sample.has("height") else preload("res://game/geographic_road_support.gd").surface_height(c,q)+.07
		var side: Vector2=axis.orthogonal()*item.width
		var first: Vector2=item.a-axis*extension;var last: Vector2=item.b+axis*extension
		result.append({axis=axis,height=y,ring=PackedVector2Array([first-side,last-side,last+side,first+side])})
	return result

func clip(c,way: String,parts: Array,a: Vector3,b: Vector3) -> Array:
	if parts.is_empty():return parts
	var bounds:=Rect2(parts[0][0],Vector2.ZERO)
	for part in parts:
		for p in part:bounds=bounds.expand(p)
	var axis:=Vector2(b.x-a.x,b.z-a.z);var length:=maxf(.00001,axis.length_squared())
	for item in candidates(bounds):
		if item.way==way:continue
		var next:=[]
		for part in parts:
			var intersections:=Geometry2D.intersect_polygons(part,item.ring)
			if intersections.is_empty():next.append(part);continue
			var at_same_level:=true
			for overlap in intersections:
				for p in overlap:
					var q:=Geometry2D.get_closest_point_to_segment(p,item.a,item.b)
					var sample: Dictionary={} if geo.road_profiles==null else geo.road_profiles.sample(item.way,q+Vector2(origin.x,origin.z))
					if item.mapped_bridge and sample.is_empty():at_same_level=false;break
					var other_height: float=sample.height if sample.has("height") else c._ground(q.x,q.y)+.07
					var t:=clampf((p-Vector2(a.x,a.z)).dot(axis)/length,0,1)
					if absf(other_height-lerpf(a.y,b.y,t))>.35:at_same_level=false;break
				if not at_same_level:break
			if at_same_level:next.append_array(Difference.subtract_convex(part,item.ring))
			else:next.append(part)
		parts=next
		if parts.is_empty():return []
	return parts
