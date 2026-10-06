extends RefCounted
## Deterministic metre-scale settlement and land-use plan. No rendering objects.
const Clearance := preload("res://game/scenery_clearance.gd")
const SHAPES := {
	"shop_row":Vector2(13.6,13),"shop_house":Vector2(11.8,14),
	"corner_shop":Vector2(14.6,14),"townhouse":Vector2(9.4,14),
	"apartments_3":Vector2(18.6,16),"apartments_4":Vector2(20,17),
	"railway_quarters":Vector2(16.5,12),"school_block":Vector2(23.8,14),
	"tiled_house":Vector2(10.8,11.5),"courtyard_house":Vector2(14.8,14),
	"tiled_cottage":Vector2(8.6,11),"warehouse":Vector2(22,34),
	"workshop":Vector2(14,23),"rice_mill":Vector2(28,43),
	"water_tower":Vector2(6.2,6.2),
	"temple_gateway":Vector2(9,6),"temple_hall":Vector2(16,23)}
var world
var clearance
var rng:=RandomNumberGenerator.new()
var buildings:=[]
var props:=[]
var roads:=[]
var surfaces:=[]
var fields:=[]
var tree_sites:=[]
var districts:=[]
var traffic_loops:=[]
var bus_bays:=[]
var _occupied:=[]
var land_bins:={}
func build(source) -> void:
	world=source
	clearance=Clearance.new(world.graph)
	rng.seed=2026100701
	for index in world.stations.size(): _town(world.stations[index],index)
	for index in world.scenery.get("villages",[]).size(): _village(world.scenery.villages[index],index)
	_agriculture()
	_index_land()
func _index_land() -> void:
	var rectangles: Array=[]
	for item in buildings+roads+fields+bus_bays: rectangles.append(item.rect)
	for rect: Rect2 in rectangles:
		for x in range(floori(rect.position.x/64),floori(rect.end.x/64)+1):
			for z in range(floori(rect.position.y/64),floori(rect.end.y/64)+1):
				var key:=Vector2i(x,z)
				if not land_bins.has(key): land_bins[key]=[]
				land_bins[key].append(rect)
func curb_sections(road: Dictionary,offset: float,half_width: float=.15) -> Array:
	# Clip raised furniture where another carriageway or a bus lay-by joins it.
	var a: Vector3=road.a
	var d: Vector3=(road.b-road.a).normalized()
	var origin:=a+d.cross(Vector3.UP)*offset
	var length: float=a.distance_to(road.b)
	var cutouts: Array=[]
	for other in roads:
		if absf((other.b-other.a).normalized().dot(d))>.5: continue
		cutouts.append(other.rect.grow(.3))
	for bay in bus_bays: cutouts.append(bay.rect.grow(.2))
	var sections: Array=[Vector2(0,length)]
	for rect: Rect2 in cutouts:
		var low: float
		var high: float
		if absf(d.x)>.5:
			if origin.z+half_width<rect.position.y or origin.z-half_width>rect.end.y: continue
			low=(rect.position.x-a.x)/d.x
			high=(rect.end.x-a.x)/d.x
		else:
			if origin.x+half_width<rect.position.x or origin.x-half_width>rect.end.x: continue
			low=(rect.position.y-a.z)/d.z
			high=(rect.end.y-a.z)/d.z
		var start:=minf(low,high)
		var finish:=maxf(low,high)
		var remaining: Array=[]
		for section: Vector2 in sections:
			if finish<=section.x or start>=section.y:
				remaining.append(section)
			else:
				if start>section.x: remaining.append(Vector2(section.x,start))
				if finish<section.y: remaining.append(Vector2(finish,section.y))
		sections=remaining
	return sections
func clear_land_point(point: Vector3,margin: float=2) -> bool:
	var p:=Vector2(point.x,point.z)
	for x in range(floori((p.x-margin)/64),floori((p.x+margin)/64)+1):
		for z in range(floori((p.y-margin)/64),floori((p.y+margin)/64)+1):
			for rect: Rect2 in land_bins.get(Vector2i(x,z),[]):
				if rect.grow(margin).has_point(p): return false
	return true
func track_at(x: float) -> Vector3:
	for edge in world.graph.edges.values():
		if edge.allowed_dir!=1 or x<edge.points[0].x or x>edge.points[-1].x: continue
		for i in range(1,edge.points.size()):
			var a: Vector3=edge.points[i-1]
			var b: Vector3=edge.points[i]
			if b.x>=x: return a.lerp(b,(x-a.x)/maxf(.0001,b.x-a.x))+Vector3(0,0,3)
	return Vector3(x,0,0)
func _road(a: Vector3,b: Vector3,width: float=6,kind: String="asphalt") -> void:
	if a.distance_squared_to(b)<1: return
	var rect:=Rect2(Vector2(minf(a.x,b.x),minf(a.z,b.z)),Vector2(absf(a.x-b.x),absf(a.z-b.z))).grow(width*.5)
	if not clearance.clear_rect(rect,7.0): return
	roads.append({a=a,b=b,width=width,kind=kind,rect=rect})
func _surface(rect: Rect2,kind: String="soil") -> void:
	surfaces.append({rect=rect,kind=kind})
func _reserved(rect: Rect2) -> bool:
	if not clearance.clear_rect(rect,18): return true
	for canal in world.scenery.get("canals",[]):
		if rect.grow(28).has_point(Vector2(canal,rect.get_center().y)) and absf(rect.get_center().y)<400: return true
	for bridge in world.scenery.get("overbridges",[]):
		if rect.intersects(Rect2(bridge-20,-460,40,920)): return true
	for occupied: Rect2 in _occupied:
		if rect.grow(.65).intersects(occupied): return true
	for road in roads:
		if rect.grow(.8).intersects(road.rect): return true
	return false
func _building(kind: String,p: Vector3,angle: float,zone: String) -> bool:
	var size: Vector2=SHAPES[kind]
	var footprint:=Vector2(absf(cos(angle))*size.x+absf(sin(angle))*size.y,absf(sin(angle))*size.x+absf(cos(angle))*size.y)
	var rect:=Rect2(Vector2(p.x,p.z)-footprint*.5,footprint)
	if _reserved(rect): return false
	_occupied.append(rect)
	buildings.append({kind=kind,position=p,angle=angle,rect=rect,zone=zone})
	_surface(rect.grow(.65),"yard")
	return true
func _prop(kind: String,p: Vector3,angle: float=0.0) -> void:
	if kind in ["hatchback","auto_rickshaw","motorcycle","utility_pole"]:
		for bay in bus_bays:
			if bay.rect.grow(2).has_point(Vector2(p.x,p.z)): return
	if clearance.clear_point(p,26): props.append({kind=kind,position=p,angle=angle})
func _tree(p: Vector3,kind: String="mango_tree",scale: float=1.0) -> void:
	for bay in bus_bays:
		if bay.rect.grow(3).has_point(Vector2(p.x,p.z)): return
	if clearance.clear_point(p,28): tree_sites.append({kind=kind,position=p,scale=scale,angle=rng.randf()*TAU})
func _town(station: Dictionary,index: int) -> void:
	var cx: float=station.origin.x
	var outward: float=signf(station.building.z)
	# Keep the existing station entrance/forecourt and all platform circulation.
	_occupied.append(Rect2(cx-67,station.building.z-39,134,78))
	for side in [outward,-outward]:
		var primary: bool=side==outward
		var street: float=79 if primary else 67
		var rows: int=4 if primary else 3
		var spacing:=33.0
		var length: float=660 if primary else 555
		var zone: String=station.code+("_front" if primary else "_back")
		districts.append({rect=Rect2(cx-length-35,minf(side*(street-10),side*(street+rows*spacing+26)),length*2+70,rows*spacing+36),zone=zone})
		for row in rows:
			var z: float=side*(street+row*spacing)
			_road(Vector3(cx-length,.1,z),Vector3(cx+length,.1,z),8.0 if row==0 else 5.0)
		for offset in [-590,-375,-165,165,375,590]:
			if absf(offset)>length: continue
			_road(Vector3(cx+offset,.1,side*street),Vector3(cx+offset,.1,side*(street+(rows-1)*spacing)),5.0)
		# Public landmarks have reserved plots before ordinary houses are placed.
		if primary:
			var bay_rect:=Rect2(cx+77,minf(side*(street-4),side*(street-8.8)),91,4.8)
			bus_bays.append({rect=bay_rect,side=-side,street_z=side*street})
			_occupied.append(bay_rect)
			_building("school_block",Vector3(cx+475,0,side*(street+80)),PI if side<0 else 0,zone)
			if index!=1: _temple(cx+165,side*(street+(rows-1)*spacing+62),side,zone,side*(street+(rows-1)*spacing))
			_building("water_tower",Vector3(cx-455,0,side*(street+82)),0,zone)
			_prop("bus_shelter",Vector3(cx+150,0,side*(street-13)),0 if side<0 else PI)
			_prop("local_bus",Vector3(cx+125,.08,side*(street-6.3)),-side*PI*.5)
			_prop("local_bus",Vector3(cx+95,.08,side*(street-6.3)),-side*PI*.5)
			_prop("tea_kiosk",Vector3(cx+181,0,side*(street-12)),0 if side<0 else PI)
			for offset in [-2.3,2.3]: _prop("passenger_seated",Vector3(cx+150+offset,.25,side*(street-13.5)),0 if side<0 else PI)
			_prop("passenger_phone",Vector3(cx+183,0,side*(street-14.5)),PI if side<0 else 0)
		for row in rows:
			var z: float=side*(street+row*spacing)
			var x: float=cx-length+14
			var lot:=0
			while x<cx+length-20:
				var choices: Array
				if row==0 and primary:
					choices=["shop_row","shop_house","shop_house","corner_shop","townhouse"]
				elif row==0:
					choices=["tiled_house","railway_quarters","townhouse","shop_row"]
				else:
					choices=["townhouse","tiled_house","tiled_house","courtyard_house","railway_quarters","apartments_3","tiled_cottage"]
					if index==1: choices=["townhouse","townhouse","courtyard_house","tiled_house","apartments_3","railway_quarters"]
					if index==2: choices=["townhouse","apartments_3","apartments_4","courtyard_house","tiled_house"]
				var kind: String=choices[rng.randi_range(0,choices.size()-1)]
				var size: Vector2=SHAPES[kind]
				var centre:=Vector3(x+size.x*.5,0,z+side*(6.5+size.y*.5+rng.randf_range(.1,1.3)))
				var angle: float=(PI if side<0 else 0)+rng.randf_range(-.018,.018)
				if _building(kind,centre,angle,zone):
					if primary and row==0 and lot%10==2:
						_prop("produce_cart",Vector3(centre.x+size.x*.23,.18,z+side*6.6),angle)
					if primary and row==0 and lot%2==0:
						_prop(["passenger_man","passenger_sari","passenger_phone","passenger_sari_blue"][lot%4],Vector3(centre.x-size.x*.25,.18,z+side*5.15),angle+rng.randf_range(-.9,.9))
					if row==0 and lot%3==0:
						_prop("motorcycle",Vector3(centre.x+size.x*.28,0,z+side*5.0),-side*PI*.4)
						if primary and lot%6==0: _prop("auto_rickshaw",Vector3(centre.x-3,0,z-side*5.0),PI*.5)
					elif row==1 and lot%7==0:
						_prop("hatchback",Vector3(centre.x,0,z+side*5.0),PI*.5)
				if lot%4==0:
					var point:=Vector3(x,0,z-side*6.8)
					if absf(x-cx)>77 or row>0: _tree(point,("tree_small_02" if lot%12==0 else "rain_tree") if lot%8==0 else "coconut_palm",rng.randf_range(.85,1.2))
				x+=size.x+rng.randf_range(1.5,3.2)
				lot+=1
			# Streets carry sagging utility lines and occasional transformers.
			for pole in range(-int(length)+12,int(length),42):
				var p:=Vector3(cx+pole,0,z+side*5.4)
				if absf(p.x-cx)<67 and row==0 and primary: continue
				_prop("utility_pole",p,PI*.5)
			if row==2: _prop("transformer",Vector3(cx+length-28,0,z-side*7.5))
		# Closed road loop supports lightweight purely decorative road traffic.
		var turn: float=590 if primary else 375
		traffic_loops.append(PackedVector3Array([Vector3(cx-turn,.14,side*street),Vector3(cx+turn,.14,side*street),Vector3(cx+turn,.14,side*(street+spacing)),Vector3(cx-turn,.14,side*(street+spacing))]))
		# Industrial fringe faces a service lane and contributes a separate skyline.
		var yard_x: float=cx+length+110
		var yard_z: float=side*150
		if primary: _prop("telecom_mast",Vector3(yard_x+78,0,yard_z+side*57))
		_road(Vector3(cx+length-20,.1,side*street),Vector3(yard_x+100,.1,side*street),6)
		_road(Vector3(yard_x+92,.1,side*street),Vector3(yard_x+92,.1,yard_z+side*72),6)
		_road(Vector3(yard_x-65,.1,yard_z-side*26),Vector3(yard_x+92,.1,yard_z-side*26),6)
		for k in 3:
			var p:=Vector3(yard_x-45+k*47,0,yard_z)
			_building("rice_mill" if index==1 and k==1 else ("warehouse" if k%2==0 else "workshop"),p,PI if side<0 else 0,zone+"_industry")
			_prop("goods_lorry",p+Vector3(9,0,-side*24),PI*.5)
			_tree(p+Vector3(-17,0,side*27),"rain_tree",.9)
func _temple(x: float,z: float,side: float,zone: String,street_z: float) -> void:
	var angle: float=PI if side<0 else 0
	_road(Vector3(x,.1,street_z),Vector3(x,.1,z-side*7),5.0)
	_building("temple_gateway",Vector3(x,0,z),angle,zone+"_temple")
	_building("temple_hall",Vector3(x,0,z+side*20),angle,zone+"_temple")
	var court:=Rect2(x-12,minf(z-side*5,z+side*34),24,39)
	_occupied.append(court)
	_surface(court,"paving")
func _village(x: float,index: int) -> void:
	var centre:=track_at(x)
	var side: float=-1 if index%2==0 else 1
	var zone: String="village_%d"%index
	var xmin:=x-310
	var xmax:=x+310
	for canal in world.scenery.get("canals",[]):
		if canal>x and canal<xmax+40: xmax=canal-44
		if canal<x and canal>xmin-40: xmin=canal+44
	for row in 3:
		var z: float=centre.z+side*(66+row*33)
		_road(Vector3(xmin,.1,z),Vector3(xmax,.1,z),5.4 if row==0 else 3.6,"asphalt" if row==0 else "lane")
	for cross_x in [x-205,x,x+195]:
		if cross_x<xmin or cross_x>xmax: continue
		_road(Vector3(cross_x,.1,centre.z+side*66),Vector3(cross_x,.1,centre.z+side*132),4.0,"lane")
	var min_z:=minf(centre.z+side*55,centre.z+side*164)
	districts.append({rect=Rect2(xmin-18,min_z,xmax-xmin+36,109),zone=zone})
	for row in 3:
		var road_z: float=centre.z+side*(66+row*33)
		var position_x:=xmin+10
		var lot:=0
		while position_x<xmax-25:
			var choices:=["tiled_house","tiled_cottage","courtyard_house","railway_quarters","townhouse"]
			var kind: String=choices[rng.randi_range(0,choices.size()-1)]
			if row==0 and lot%8==2: kind="shop_house"
			var size: Vector2=SHAPES[kind]
			var p:=Vector3(position_x+size.x*.5,0,road_z+side*(5.5+size.y*.5+rng.randf_range(0,1.9)))
			_building(kind,p,PI if side<0 else 0,zone)
			if lot%4==0:
				_tree(Vector3(position_x,0,road_z-side*6),"mango_tree",.8)
				_prop("utility_pole",Vector3(position_x+5,0,road_z+side*4),PI*.5)
			if row==0 and lot%6==0: _prop("motorcycle",Vector3(p.x,0,road_z+side*4),-side*PI*.5)
			position_x+=size.x+rng.randf_range(2.0,5.0)
			lot+=1
	_prop("bus_shelter",Vector3(x+25,0,centre.z+side*53),0 if side<0 else PI)
	_prop("tea_kiosk",Vector3(x+40,0,centre.z+side*53),0 if side<0 else PI)
	_building("water_tower",Vector3(xmax-18,0,centre.z+side*147),0,zone)
	for k in 18:
		var p:=Vector3(rng.randf_range(xmin,xmax),0,centre.z+side*rng.randf_range(166,202))
		_tree(p,"coconut_palm",rng.randf_range(.76,1.05))
func _agriculture() -> void:
	var xmin: float=world.scenery.get("x_min",-500)+80
	var xmax: float=world.scenery.get("x_max",22200)-80
	for x in range(int(xmin),int(xmax),155):
		var c:=track_at(x)
		for side in [-1,1]:
			for row in 4:
				var w:=rng.randf_range(104,144)
				var d:=rng.randf_range(46,74)
				var centre:=Vector2(x+rng.randf_range(-7,7),c.z+side*(47+row*83+d*.5))
				var rect:=Rect2(centre-Vector2(w,d)*.5,Vector2(w,d))
				if not clearance.clear_rect(rect,19): continue
				var blocked:=false
				for district in districts:
					if rect.grow(5).intersects(district.rect): blocked=true; break
				for canal in world.scenery.get("canals",[]):
					if absf(rect.get_center().x-canal)<w*.5+38: blocked=true
				for bridge in world.scenery.get("overbridges",[]):
					if absf(rect.get_center().x-bridge)<w*.5+26: blocked=true
				for occupied: Rect2 in _occupied:
					if rect.intersects(occupied): blocked=true; break
				for road in roads:
					if rect.grow(2.5).intersects(road.rect): blocked=true; break
				if blocked: continue
				fields.append({rect=rect,stage=rng.randi_range(0,4),rows_along_x=rng.randf()>.4})
				if row==2 and x%5==0: _tree(Vector3(rect.position.x-4,0,rect.position.y-3),"mango_tree",.85)
