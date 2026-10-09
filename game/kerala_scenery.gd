extends RefCounted
## Contextual reconstruction, NOT surveyed property/boat positions. Uses mapped
## land/water/roads and the same railway/station exclusions as the base renderer.
const ASSETS:=["banana_clump","country_canoe","fishing_skiff","courtyard_well","fishing_net_rack","rice_green","rice_ripe"]
const Sites:=preload("res://game/coastal_station_sites.gd")
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")

static func parcel_edge(p: Vector2) -> float:
	return minf(minf(fposmod(p.x,64),64-fposmod(p.x,64)),minf(fposmod(p.y,96),96-fposmod(p.y,96)))

static func parcel_stage(p: Vector2) -> float:
	return posmod((floori(p.x/64)*73856093)^(floori(p.y/96)*19349663),1000)/1000.0

static func crops(c) -> void:
	# Restrained 3D rice near the observer; the continuous parcel shader carries
	# the field to the horizon. No randomness shared with the tree generator.
	for z in range(3,512,2):
		for x in range(3,512,2):
			if c._class_at(x,z)!=2:continue
			var p:=Vector2(x,z);var absolute:=p+Vector2(c.origin.x,c.origin.z)
			if parcel_edge(absolute)<1.2:continue
			var rail: Dictionary=c.geo.nearest_rail(absolute.x,absolute.y)
			if rail.distance>550 or not dry_clear(c,p,1.4):continue
			var stage:=parcel_stage(absolute)
			if stage<.19 or stage>.92:continue
			var jitter:=Vector2(posmod(x*17+z*13,11)-5,posmod(x*7+z*19,11)-5)*.035
			c.library.place("rice_ripe" if stage>.7 else "rice_green",Vector3(x+jitter.x,c._ground(x,z),z+jitter.y),float(posmod(x*17+z*13,628))*.01,Vector3(1.85,.9,1.85))

static func dry_clear(c,p: Vector2,radius: float=2.5) -> bool:
	# Complete object envelope must belong to this tile; adjacent workers never
	# invent the other half of a prop or need mutable shared placement state.
	if p.x<radius+1 or p.y<radius+1 or p.x>=511-radius or p.y>=511-radius:return false
	for d in [Vector2.ZERO,Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius)]:
		var q: Vector2=p+d
		if c._class_at(q.x,q.y) in [4,5,6,7,8]:return false
		for water in c.water_levels:
			if c._inside(q,water.geometry):return false
	var absolute:=p+Vector2(c.origin.x,c.origin.z)
	if Sites.contains(c.geo.station_sites,absolute.x,absolute.y,radius+3):return false
	if c.geo.nearest_rail(absolute.x,absolute.y).distance<22+radius:return false
	if c._near_mapped_rail(p,10+radius) or not c.occupancy.clear(p,radius):return false
	if c.geo.vegetation_clearance!=null and not c.geo.vegetation_clearance.clear(absolute,radius):return false
	return true

static func frontage(c,p: Vector2,features: Array) -> Vector2:
	var nearest:=Vector2.ZERO;var distance:=55.0
	for feature in features:
		if feature.kind!="road" or feature.tags.get("bridge","no")!="no":continue
		for line in c._lines(feature.geometry):
			for i in range(1,line.size()):
				var a:=Vector2(line[i-1][0],line[i-1][1]);var b:=Vector2(line[i][0],line[i][1])
				var q:=Geometry2D.get_closest_point_to_segment(p,a,b)
				if p.distance_to(q)<distance:distance=p.distance_to(q);nearest=q-p
	return nearest

static func dress(c,features: Array) -> void:
	var counts:={boats=0,shore_groups=0,wells=0,boundaries=0}
	_shores(c,counts)
	_yards(c,features,counts)
	c.root.set_meta("kerala_details",counts)

static func _shores(c,counts: Dictionary) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=hash(str(c.origin)+"shore")
	for water in c.water_levels:
		var polys: Array=water.geometry.coordinates if water.geometry.type=="MultiPolygon" else [water.geometry.coordinates]
		for poly in polys:
			if poly.is_empty():continue
			var ring: Array=poly[0]
			for i in range(1,ring.size()):
				var a:=Vector2(ring[i-1][0],ring[i-1][1]);var b:=Vector2(ring[i][0],ring[i][1])
				var tangent: Vector2=(b-a).normalized();var normal:=Vector2(-tangent.y,tangent.x)
				var steps:=floori(a.distance_to(b)/34.0)
				for j in steps:
					var p:=a.lerp(b,(j+.5)/steps)
					var rail: Dictionary=c.geo.nearest_rail(p.x+c.origin.x,p.y+c.origin.z)
					if rail.distance<42 or rail.distance>360:continue
					if c._inside(p+normal*4,water.geometry):normal=-normal
					var bank:=p+normal*4.5
					if not dry_clear(c,bank,3.3):continue
					var ground: float=c._ground(bank.x,bank.y)
					if absf(ground-water.height)>2.8:continue
					if counts.shore_groups<18:
						c.library.place("banana_clump",Vector3(bank.x,ground,bank.y),rng.randf()*TAU,Vector3.ONE*rng.randf_range(.85,1.15))
						c.occupancy.add_road(bank,bank,3.2)
						counts.shore_groups+=1
					if counts.boats>=3 or rng.randf()>.38:continue
					var boat:=p-normal*3.6
					if not water_envelope(c,boat,tangent,water.geometry):continue
					var kind: String="country_canoe" if rng.randf()<.72 else "fishing_skiff"
					c.library.place(kind,Vector3(boat.x,water.height+.06,boat.y),atan2(tangent.x,tangent.y))
					counts.boats+=1
					# A grounded bamboo net rack belongs on dry bank, away from boat.
					var rack:=bank+tangent*7
					if dry_clear(c,rack,2.3):
						c.library.place("fishing_net_rack",Vector3(rack.x,c._ground(rack.x,rack.y),rack.y),atan2(-tangent.y,tangent.x))
						c.occupancy.add_road(rack-tangent*2,rack+tangent*2,.7)

static func water_envelope(c,p: Vector2,tangent: Vector2,geometry: Dictionary) -> bool:
	var side:=Vector2(-tangent.y,tangent.x)
	var envelope:=PackedVector2Array([p-tangent*3.6-side*1.1,p+tangent*3.6-side*1.1,p+tangent*3.6+side*1.1,p-tangent*3.6+side*1.1])
	var contained:=false
	var polygons: Array=geometry.coordinates if geometry.type=="MultiPolygon" else [geometry.coordinates]
	for poly in polygons:
		if poly.is_empty():continue
		var outer:=PackedVector2Array()
		for v in poly[0]:outer.append(Vector2(v[0],v[1]))
		if not Geometry2D.clip_polygons(envelope,outer).is_empty():continue
		var hole_hit:=false
		for index in range(1,poly.size()):
			var hole:=PackedVector2Array()
			for v in poly[index]:hole.append(Vector2(v[0],v[1]))
			if not Geometry2D.intersect_polygons(envelope,hole).is_empty():hole_hit=true;break
		if not hole_hit:contained=true;break
	if not contained:return false
	for along in [-3.6,0.0,3.6]:
		for across in [-1.1,0.0,1.1]:
			var q: Vector2=p+tangent*along+side*across
			if q.x<2 or q.y<2 or q.x>=510 or q.y>=510:return false
			if not c._inside(q,geometry) or not c.occupancy.clear(q,1.2):return false
			if c._near_mapped_rail(q,30):return false
	return true

static func _yards(c,features: Array,counts: Dictionary) -> void:
	for feature in features:
		if feature.kind!="building" or feature.geometry.type!="Polygon":continue
		if feature.tags.get("building","") in ["train_station","station","industrial","warehouse"]:continue
		var seed_value:=absi(hash(feature.id))
		var ring: Array=feature.geometry.coordinates[0]
		var centre:=Vector2.ZERO
		for v in ring:centre+=Vector2(v[0],v[1])
		centre/=ring.size()
		var rail: Dictionary=c.geo.nearest_rail(centre.x+c.origin.x,centre.y+c.origin.z)
		if rail.distance>300:continue
		var front:=frontage(c,centre,features)
		if front.length()<12:continue
		var forward:=front.normalized();var side:=Vector2(-forward.y,forward.x)
		var p:=centre+front-forward*6.5
		# Side/back walls follow the property's building axes with a small garden
		# setback. Each complete wall is independently validated, so tight urban
		# plots keep their true gaps instead of acquiring intersecting compounds.
		if counts.boundaries<36 and seed_value%3!=1 and ring.size() in [4,5]:
			var edge:=Vector2(ring[1][0]-ring[0][0],ring[1][1]-ring[0][1]).normalized()
			var other:=Vector2(-edge.y,edge.x)
			if absf(edge.dot(forward))>absf(other.dot(forward)):
				other=edge;edge=Vector2(-other.y,other.x)
			if other.dot(forward)<0:other=-other
			var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
			for v in ring:
				var delta:=Vector2(v[0],v[1])-centre
				var local:=Vector2(delta.dot(edge),delta.dot(other));lo=lo.min(local);hi=hi.max(local)
			lo-=Vector2(2.4,2.4);hi+=Vector2(2.4,2.4)
			if hi.x-lo.x<28 and hi.y-lo.y<30:
				var back_left:=centre+edge*lo.x+other*lo.y;var back_right:=centre+edge*hi.x+other*lo.y
				var front_left:=centre+edge*lo.x+other*hi.y;var front_right:=centre+edge*hi.x+other*hi.y
				var segments:=[[back_left,back_right],[back_left,front_left],[back_right,front_right]]
				var accepted:=[]
				for segment in segments:
					var a: Vector2=segment[0];var b: Vector2=segment[1]
					var low:=INF;var high:=-INF;var valid:=true
					var steps:=maxi(1,ceili(a.distance_to(b)/2))
					for k in steps+1:
						var q:=a.lerp(b,k/float(steps))
						if not dry_clear(c,q,.75):valid=false;break
						var h: float=c._ground(q.x,q.y);low=minf(low,h);high=maxf(high,h)
					if valid and high-low<.55:
						c.batch.beam("architecture_detail",Vector3(a.x,high+.43,a.y),Vector3(b.x,high+.43,b.y),.17,Color(.51,.47,.36,1.0/15),.86)
						c.batch.beam("architecture_detail",Vector3(a.x,high+.89,a.y),Vector3(b.x,high+.89,b.y),.25,Color(.36,.28,.19,0),.07)
						for q in [a,b]:c.batch.box("architecture_detail",Vector3(q.x,high+.49,q.y),Vector3(.28,.98,.28),Color(.64,.59,.45,1.0/15))
						accepted.append(segment);counts.boundaries+=1
				for segment in accepted:c.occupancy.add_road(segment[0],segment[1],.65)
		# Low walls and a deliberate opening form a roadside compound, only where
		# the whole span is clear of mapped houses, roads, water and railway sites.
		if counts.boundaries<18 and seed_value%2==0:
			var valid:=true;var low:=INF;var high:=-INF
			for k in range(-3,4):
				var q:=p+side*k*2.5
				if not dry_clear(c,q,.8):valid=false;break
				var h: float=c._ground(q.x,q.y);low=minf(low,h);high=maxf(high,h)
			if valid and high-low<.65:
				for direction in [-1,1]:
					var a: Vector2=p+side*direction*1.6;var b: Vector2=p+side*direction*7.5
					c.batch.beam("architecture_detail",Vector3(a.x,high+.52,a.y),Vector3(b.x,high+.52,b.y),.19,Color(.55,.49,.36,1.0/15),1.05)
					c.batch.beam("architecture_detail",Vector3(a.x,high+1.07,a.y),Vector3(b.x,high+1.07,b.y),.29,Color(.34,.28,.20,0),.09)
					for q in [a,b]:c.batch.box("architecture_detail",Vector3(q.x,high+.65,q.y),Vector3(.34,1.3,.34),Color(.66,.61,.47,1.0/15))
					c.occupancy.add_road(a,b,.7)
				counts.boundaries+=1
		var well:=centre+front*.5+side*4
		if counts.wells<5 and seed_value%7==0 and dry_clear(c,well,1.8):
			var y: float=c._ground(well.x,well.y)
			c.library.place("courtyard_well",Vector3(well.x,y,well.y),atan2(-side.y,side.x))
			c.occupancy.add_road(well,well,1.8);counts.wells+=1
