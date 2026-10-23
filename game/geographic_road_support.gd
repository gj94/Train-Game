extends RefCounted
## Dry approaches are filled earthworks, not a continuation of the bridge span.
## A worker-local index keeps their entire footprint clear of existing uses.
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
const Ribbon:=preload("res://game/geographic_ground_ribbon.gd")
var obstacles=Occupancy.new()
var roads: Dictionary={}
var pending: Array=[]
var widths: Dictionary={}
var halo: Dictionary={}
var extra_water: Array=[]

func _init(features: Array=[],road_widths: Dictionary={}) -> void:
	widths=road_widths
	_index(features)

func _index(features: Array) -> void:
	for feature in features:
		if feature.kind=="building":
			var polygons: Array=feature.geometry.coordinates if feature.geometry.type=="MultiPolygon" else [feature.geometry.coordinates]
			for polygon in polygons:
				if polygon.is_empty():continue
				var ring:=PackedVector2Array()
				for p in polygon[0]:ring.append(Vector2(p[0],p[1]))
				obstacles.add_polygon(ring,.3)
		elif feature.kind in ["road","rail"]:
			var rail: bool=feature.kind=="rail"
			if rail and feature.tags.get("railway","")!="rail":continue
			if not rail and (feature.tags.get("highway","") in ["proposed","construction"] or feature.tags.get("tunnel","no")!="no"):continue
			var lines: Array=feature.geometry.coordinates if feature.geometry.type=="MultiLineString" else [feature.geometry.coordinates]
			var width: float=3.15 if rail else widths.get(feature.tags.get("highway",""),4.0)*.5+.3
			for line in lines:
				for i in range(1,line.size()):
					var a:=Vector2(line[i-1][0],line[i-1][1]);var b:=Vector2(line[i][0],line[i][1])
					if rail:obstacles.add_road(a,b,width);continue
					var item:={way=feature.id,a=a,b=b,width=width}
					var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(width)
					for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
						for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
							var key:=Vector2i(x,z)
							if not roads.has(key):roads[key]=[]
							roads[key].append(item)

func plan(c,way: String,top: Array[Vector3],a: Vector3,b: Vector3) -> Dictionary:
	var ring:=_ring(top)
	if not clear(c,way,ring,a,b):return {}
	var foot:=PackedVector3Array()
	var highest:=0.0
	for p in top:
		var y:=surface_height(c,Vector2(p.x,p.z))-.18
		foot.append(Vector3(p.x,minf(y,p.y-.05),p.z))
		highest=maxf(highest,p.y-y)
	if highest<.2:return {}
	# Short rural approaches can fit a 1:1.5 earth batter. Taller or confined
	# streets use a retaining wall inside the deck footprint, never a steep
	# pretend earth slope or soil dumped over the neighbouring property.
	var kind:="retained"
	if highest<=4.0:
		var expanded:=PackedVector3Array()
		for i in top.size():
			var centre: Vector3=a if i in [0,3] else b
			var outward: Vector3=(top[i]-centre);outward.y=0;outward=outward.normalized()
			var toe:=top[i]+outward*maxf(.3,(top[i].y-foot[i].y)*1.5)
			toe.y=surface_height(c,Vector2(toe.x,toe.z))-.18
			expanded.append(toe)
		var gentle:=true
		for i in top.size():
			var run:=Vector2(expanded[i].x-top[i].x,expanded[i].z-top[i].z).length()
			if top[i].y-expanded[i].y>run/1.35+.2 or expanded[i].y>top[i].y:gentle=false
		if gentle and clear(c,way,_ring(expanded),a,b):foot=expanded;kind="earth"
	return {kind=kind,top=PackedVector3Array(top),foot=foot,way=way}

func clear(c,way: String,ring: PackedVector2Array,a: Vector3,b: Vector3) -> bool:
	if not valid_ring(ring):return false
	_ensure_halo(c,ring)
	if not obstacles.clear_polygon(ring):return false
	var absolute:=PackedVector2Array()
	var offset:=Vector2(c.origin.x,c.origin.z)
	for p in ring:absolute.append(p+offset)
	if c.geo.vegetation_clearance!=null and not c.geo.vegetation_clearance.clear_polygon(absolute,.45):return false
	if c.geo.road_profiles!=null and not c.geo.road_profiles.support_clearance.clear_polygon(absolute):return false
	if c.road_water!=null:
		# Leave a small dry margin around stream bends as well as straight runs.
		var water_margin:=Geometry2D.offset_polygon(ring,.12,Geometry2D.JOIN_MITER)
		if _area(c.road_water.clip(water_margin))<_area(water_margin)-.002:return false
		for water in extra_water:
			if _area(water.clip(water_margin))<_area(water_margin)-.002:return false
	if c.geo.road_reservations!=null and _area(c.geo.road_reservations.clip(ring,c.origin,-1.0e12,1.0e12))<_area([ring])-.002:return false
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var start:=Vector2(a.x,a.z);var axis:=Vector2(b.x-a.x,b.z-a.z)
	for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
		for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
			for item in roads.get(Vector2i(x,z),[]):
				if item.way==way or not Occupancy._segment_touches_polygon(item.a,item.b,ring,item.width):continue
				# Same-height intersecting roads share the fill. A road below the
				# approach must retain its open underpass across its whole width.
				var probes:=Array(ring);probes.append((start+Vector2(b.x,b.z))*.5)
				for probe: Vector2 in probes:
					var point:=Geometry2D.get_closest_point_to_segment(probe,item.a,item.b)
					if not Occupancy._segment_touches_polygon(point,point,ring,item.width):continue
					var sample: Dictionary={} if c.geo.road_profiles==null else c.geo.road_profiles.sample(item.way,point+offset)
					var y: float=surface_height(c,point)+.07 if sample.is_empty() else sample.height
					var t:=clampf((point-start).dot(axis)/maxf(.000001,axis.length_squared()),0,1)
					if y<lerpf(a.y,b.y,t)-.7:return false
	return true

func _ensure_halo(c,ring: PackedVector2Array) -> void:
	if typeof(c.geo)==TYPE_DICTIONARY or not c.geo.has_method("tile"):return
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	bounds=bounds.grow(6)
	var base:=Vector2i(roundi(c.origin.x/512),roundi(c.origin.z/512))
	for x in range(floori(bounds.position.x/512),floori(bounds.end.x/512)+1):
		for z in range(floori(bounds.position.y/512),floori(bounds.end.y/512)+1):
			var delta:=Vector2i(x,z)
			if delta==Vector2i.ZERO or halo.has(delta):continue
			halo[delta]=true
			var features: Array=c.geo.tile(base+delta).get("features",[]).duplicate(true)
			for feature in features:
				feature.geometry.coordinates=_translate(feature.geometry.coordinates,Vector2(x*512,z*512))
			_index(features)
			extra_water.append(preload("res://game/geographic_road_water.gd").new(features))

static func _translate(value: Array,offset: Vector2) -> Array:
	if value.size()>=2 and typeof(value[0]) in [TYPE_FLOAT,TYPE_INT]:return [value[0]+offset.x,value[1]+offset.y]
	var result:=[]
	for child in value:result.append(_translate(child,offset))
	return result

static func valid_ring(ring: PackedVector2Array) -> bool:
	if ring.size()<3 or _area([ring])<.001:return false
	for i in ring.size():
		var next: int=(i+1)%ring.size()
		if ring[i].distance_squared_to(ring[next])<.000001:return false
		for j in range(i+2,ring.size()):
			var after: int=(j+1)%ring.size()
			if after==i:continue
			if Geometry2D.segment_intersects_segment(ring[i],ring[next],ring[j],ring[after])!=null:return false
	return true

static func draw(c,plan: Dictionary) -> void:
	var top: PackedVector3Array=plan.top;var foot: PackedVector3Array=plan.foot
	var bank:=PackedVector3Array()
	for i in top.size():bank.append(bank_point(top[i],foot[i]))
	plan.bank=bank
	for i in top.size():
		var next: int=(i+1)%top.size()
		# Subdivide the ground contact, so an 8 m DEM triangle ridge cannot
		# leave a gap underneath a long end wall or diagonal road edge.
		var steps:=maxi(1,ceili(foot[i].distance_to(foot[next])/2))
		for j in steps:
			var t0:=j/float(steps);var t1:=(j+1)/float(steps)
			var low_a:=foot[i].lerp(foot[next],t0);var low_b:=foot[i].lerp(foot[next],t1)
			var high_a:=top[i].lerp(top[next],t0);var high_b:=top[i].lerp(top[next],t1)
			low_a.y=minf(high_a.y-.05,surface_height(c,Vector2(low_a.x,low_a.z))-.18)
			low_b.y=minf(high_b.y-.05,surface_height(c,Vector2(low_b.x,low_b.z))-.18)
			# At a narrow/retained neighbour the bank tapers down continuously.
			# A concrete upper wall carries the remaining height; do not paint
			# an impossibly steep earth wedge at the transition.
			var bank_a:=bank_point(high_a,low_a);var bank_b:=bank_point(high_b,low_b)
			_face(c,"road_shoulder",low_a,low_b,bank_b,bank_a)
			_face(c,"concrete",bank_a,bank_b,high_b,high_a)
	var occupied=c.get("occupancy")
	if occupied!=null:occupied.add_polygon(_ring(foot),.2)
	# Present only in the static audit subclass, never retained by game tiles.
	var records=c.get("road_support_records")
	if records!=null:records.append(plan)

func flush(c) -> void:
	# Tiny pockets of available land should not produce isolated pyramids of
	# soil under an otherwise retained street. Keep a useful continuous bank.
	var run: Array=[]
	for plan in pending:
		if plan.kind!="earth" or (not run.is_empty() and (run[-1].top[1].distance_to(plan.top[0])>.01 or run[-1].top[2].distance_to(plan.top[3])>.01)):
			_retain_short_run(run);run=[]
		if plan.kind=="earth":run.append(plan)
	_retain_short_run(run)
	# Adjacent cells share a toe position, even where an obstacle changes the
	# available width or a high retaining wall meets a low earth approach.
	var joins: Dictionary={}
	for plan in pending:
		for i in plan.top.size():
			var point: Vector3=plan.top[i]
			var width:=Vector2(plan.foot[i].x-point.x,plan.foot[i].z-point.z).length()
			if not joins.has(point):joins[point]={count=0,width=width}
			joins[point].count+=1;joins[point].width=minf(joins[point].width,width)
	for plan in pending:
		var earth:=false
		for i in plan.top.size():
			var point: Vector3=plan.top[i];var join: Dictionary=joins[point]
			var width: float=join.width if join.count>1 else 0.0
			var outward: Vector3=plan.foot[i]-point;outward.y=0
			var foot: Vector3=point+outward.normalized()*width
			foot.y=minf(point.y-.05,surface_height(c,Vector2(foot.x,foot.z))-.18)
			plan.foot[i]=foot;earth=earth or width>.05
		plan.kind="earth" if earth else "retained"
		draw(c,plan)
	pending.clear()

static func _retain_short_run(run: Array) -> void:
	var length:=0.0
	for plan in run:length+=((plan.top[1]+plan.top[2])*.5).distance_to((plan.top[0]+plan.top[3])*.5)
	if length>=16:return
	for plan in run:
		plan.kind="retained"
		for i in plan.top.size():plan.foot[i]=Vector3(plan.top[i].x,plan.foot[i].y,plan.top[i].z)

static func bank_point(top: Vector3,foot: Vector3) -> Vector3:
	var run:=Vector2(top.x-foot.x,top.z-foot.z).length()
	return Vector3(top.x,minf(top.y,foot.y+run/1.5),top.z)

static func _face(c,kind: String,a: Vector3,b: Vector3,d: Vector3,e: Vector3) -> void:
	var normal: Vector3=(d-a).cross(b-a)
	if normal.length_squared()<.000001:normal=(e-a).cross(d-a)
	if normal.length_squared()<.000001:return
	c.batch.quad(kind,a,b,d,e,normal.normalized(),Color(.78,.76,.68))

static func surface_height(c,p: Vector2) -> float:
	var key:=Vector2i(floori(p.x/8),floori(p.y/8))
	var cache=c.get("ground_ribbon_cells")
	var cells: Array
	if cache!=null:
		if not cache.has(key):cache[key]=Ribbon._cell(c,Vector2(key.x*8,key.y*8))
		cells=cache[key]
	else:cells=Ribbon._cell(c,Vector2(key.x*8,key.y*8))
	for cell in cells:
		if Geometry2D.is_point_in_polygon(p,cell.ring):return Ribbon.plane_height(cell.plane,p)
	return c._ground(p.x,p.y)

static func _ring(points) -> PackedVector2Array:
	var ring:=PackedVector2Array()
	for p in points:ring.append(Vector2(p.x,p.z))
	if Geometry2D.is_polygon_clockwise(ring):ring.reverse()
	return ring

static func _area(pieces: Array) -> float:
	var result:=0.0
	for ring in pieces:
		var area:=0.0
		for i in ring.size():area+=ring[i].cross(ring[(i+1)%ring.size()])
		result+=absf(area)*.5
	return result
