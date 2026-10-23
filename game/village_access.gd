extends RefCounted
## Small village approaches are artistic reconstruction. They connect a rendered
## front veranda to a mapped street; unsafe or incomplete connections are omitted.
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
const Ribbon:=preload("res://game/geographic_ground_ribbon.gd")
const Foundations:=preload("res://game/geographic_foundations.gd")
const Sites:=preload("res://game/coastal_station_sites.gd")
const Road:=preload("res://game/geographic_road_surface.gd")
const KINDS:=["kerala_veranda","laterite_cottage","tiled_house","tiled_cottage","kerala_bungalow","balcony_villa","townhouse"]
const HALF_WIDTH:=.65

static func add(c,counts: Dictionary) -> void:
	if c.road_water==null:c.road_water=preload("res://game/geographic_road_water.gd").new(c.tile_features)
	for building in c.rendered_buildings:
		if counts.paths>=24:break
		var plan:=plan(c,building)
		if plan.is_empty():continue
		var start: Vector2=plan.a;var end: Vector2=plan.b
		var direction: Vector2=(end-start).normalized()
		var foot: Vector2=start+direction*plan.flight.run
		if plan.flight.count>0:
			stairs(c,start,direction,plan.flight)
			counts.steps+=plan.flight.count
		for triangle: PackedVector3Array in Ribbon.project(c,corridor(foot,end),.06):
			var normal: Vector3=(triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).normalized()
			if normal.y<0:normal=-normal
			var uv:=[]
			for p in triangle:uv.append((Vector2(p.x,p.z)+Vector2(c.origin.x,c.origin.z))/2.5)
			c.batch.triangle("forecourt" if start.distance_to(end)<8 else "road_shoulder",triangle[0],triangle[1],triangle[2],normal,Color(.88,.86,.80),uv)
		c.occupancy.add_road(start,end,HALF_WIDTH+.25)
		building.path=plan
		counts.paths+=1

static func plan(c,building: Dictionary) -> Dictionary:
	var detail: Dictionary=building.detail
	if detail.is_empty() or not detail.kind in KINDS:return {}
	var source: Dictionary=c.library.catalog[detail.kind]
	var basis:=Basis(Vector3.UP,detail.angle)
	# Bounds include the existing entrance steps; join their outer edge instead
	# of drawing a lane through the veranda or starting at the footprint centre.
	var local:=Vector3(0,0,source.godot_min[2]*detail.scale.z)
	var position: Vector3=detail.position+basis*local
	var a:=Vector2(position.x,position.z)
	var forward3: Vector3=basis*Vector3.FORWARD
	var forward:=Vector2(forward3.x,forward3.z)
	var road:=road_end(c,a,forward)
	if road.is_empty():return {}
	var b: Vector2=road.point
	var length:=a.distance_to(b)
	if length<1.5 or length>45:return {}
	var ring:=corridor(a,b)
	if not clear(c,ring,building.id,road.id):return {}
	var direction: Vector2=(b-a)/length
	var flight:=flight(a,direction,length,building.floor_y+.06,c._ground)
	if flight.is_empty():return {}
	var foot: Vector2=a+direction*flight.run
	# No path over a hidden bank/cliff. A gentle ground approach may slope;
	# the initial raised house plinth is handled by real, supported steps.
	var steps:=maxi(1,ceili(foot.distance_to(b)))
	var previous:=ground(c._ground,foot)
	for i in range(1,steps+1):
		var q:=foot.lerp(b,i/float(steps))
		var h:=ground(c._ground,q)
		if absf(h-previous)>foot.distance_to(b)/steps*.28:return {}
		var across:=Vector2(-direction.y,direction.x)*HALF_WIDTH
		if absf(ground(c._ground,q+across)-ground(c._ground,q-across))>.32:return {}
		previous=h
	return {a=a,b=b,road=road.id,flight=flight}

static func road_end(c,p: Vector2,forward: Vector2) -> Dictionary:
	var best:={};var nearest:=45.0
	for feature in c.tile_features:
		if feature.kind!="road":continue
		var tags: Dictionary=feature.tags
		if tags.get("highway","") not in ["residential","service","unclassified","tertiary","secondary","track","path","footway"]:continue
		if tags.get("bridge","no")!="no" or tags.get("tunnel","no")!="no" or float(tags.get("layer","0"))!=0:continue
		var width: float=Road.WIDTHS.get(tags.get("highway",""),4.0)
		for line in c._lines(feature.geometry):
			for i in range(1,line.size()):
				var a:=Vector2(line[i-1][0],line[i-1][1]);var b:=Vector2(line[i][0],line[i][1])
				var q:=Geometry2D.get_closest_point_to_segment(p,a,b)
				var delta:=q-p
				if delta.length()>=nearest or delta.normalized().dot(forward)<.7:continue
				var end:=q-delta.normalized()*(width*.5-.10)
				var profiles=c.geo.road_profiles
				var sample: Dictionary={} if profiles==null else profiles.sample(feature.id,q+Vector2(c.origin.x,c.origin.z))
				# Engineered approaches can sit above ground even without bridge tags.
				if not sample.is_empty() and (sample.get("bridge",false) or absf(sample.height-ground(c._ground,end)-.07)>.12):continue
				nearest=delta.length();best={id=str(feature.id),point=end}
	return best

static func clear(c,ring: PackedVector2Array,building: String,road: String) -> bool:
	for p in ring:
		if p.x<2 or p.y<2 or p.x>510 or p.y>510:return false
	if not c.occupancy.clear_polygon(ring,.18,[building,road]):return false
	if not c.mapped_rail_clearance.clear_polygon(ring,7):return false
	if Sites.intersect(c.geo.station_sites,ring,c.origin):return false
	var absolute:=PackedVector2Array()
	for p in ring:absolute.append(p+Vector2(c.origin.x,c.origin.z))
	if c.geo.vegetation_clearance!=null and not c.geo.vegetation_clearance.clear_polygon(absolute,1):return false
	var dry:=0.0
	for part in c.road_water.clip([ring]):dry+=area(part)
	if dry<area(ring)-.005:return false
	# No islands of path after a railway/platform clearance clips its middle.
	if c.geo.road_reservations!=null:
		var remaining:=0.0
		for part in c.geo.road_reservations.clip(ring,c.origin,-1.0e12,1.0e12):remaining+=area(part)
		if remaining<area(ring)-.005:return false
	return true

static func flight(a: Vector2,direction: Vector2,length: float,top: float,sample: Callable) -> Dictionary:
	var initial:=top-ground(sample,a)-.06
	if initial<-.12 or initial>2.6:return {}
	if initial<.12:return {count=0,run=0.0,top=top,rise=0.0}
	# Search for a supported stair with normal rises/runs. This also handles a
	# hillside falling away from the front door without hanging the stair toe.
	for count in range(1,17):
		var run:=count*.34
		if run>length*.65:break
		var toe:=a+direction*run
		var rise: float=(top-ground(sample,toe)-.06)/count
		if rise<.09 or rise>.19:continue
		var valid:=true
		for i in count:
			var q:=a+direction*(i+.5)*.34
			for side in [-1,0,1]:
				var edge: Vector2=q+Vector2(-direction.y,direction.x)*HALF_WIDTH*side
				if ground(sample,edge)>top-i*rise-.025:valid=false;break
			if not valid:break
		if valid:return {count=count,run=run,top=top,rise=rise}
	return {}

static func stairs(c,start: Vector2,direction: Vector2,flight: Dictionary) -> void:
	var side:=Vector2(-direction.y,direction.x)*HALF_WIDTH
	for i: int in flight.count:
		var a:=start+direction*i*.34;var b:=a+direction*.34
		var corners:=PackedVector2Array([a-side,b-side,b+side,a+side])
		var top: float=flight.top-i*flight.rise
		var points:=Foundations.outline(corners,c._ground)
		Foundations.skirt(c.batch,points,top-.02,"forecourt")
		c.batch.quad("forecourt",Vector3(corners[0].x,top,corners[0].y),Vector3(corners[1].x,top,corners[1].y),Vector3(corners[2].x,top,corners[2].y),Vector3(corners[3].x,top,corners[3].y),Vector3.UP,Color(.76,.74,.67))

static func corridor(a: Vector2,b: Vector2) -> PackedVector2Array:
	var side:=Vector2(-(b-a).y,(b-a).x).normalized()*HALF_WIDTH
	return PackedVector2Array([a-side,b-side,b+side,a+side])

static func ground(sample: Callable,p: Vector2) -> float:
	return Foundations.surface_height(sample,p.x,p.y)

static func area(ring: PackedVector2Array) -> float:
	var twice:=0.0
	for i in ring.size():twice+=ring[i].cross(ring[(i+1)%ring.size()])
	return absf(twice)*.5
