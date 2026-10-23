extends RefCounted
## Joined ribbons with connected grades, protected station envelopes and
## actual bridge decks. Presentation reconstruction, not drivable road physics.
const WIDTHS:={"motorway":10.0,"trunk":9.0,"primary":8.0,"secondary":6.5,"tertiary":5.5,"residential":4.5,"service":3.6,"footway":1.5,"path":1.0,"track":2.8}
const Support:=preload("res://game/geographic_road_support.gd")
const Finishes:=preload("res://game/geographic_road_finishes.gd")

static func draw(c,feature: Dictionary) -> void:
	var tags: Dictionary=feature.tags
	if tags.get("highway","") in ["proposed","construction","steps"] or tags.get("tunnel","no")!="no" or tags.get("railway","")=="platform" or float(tags.get("layer","0"))<0:return
	var width: float=WIDTHS.get(tags.get("highway",""),4.0)
	var profiles=c.geo.road_profiles
	var finish: String=Finishes.classify(tags) if profiles==null else profiles.finishes.material(feature.id,tags)
	# Existing station civil geometry supplies connected footbridges/stairs.
	# Rendering the same OSM walkway as a raised road leaves duplicate decks.
	if profiles!=null and profiles.station_walkways.has(feature.id):return
	if c.road_water==null:c.road_water=preload("res://game/geographic_road_water.gd").new(c.tile_features)
	for line in c._lines(feature.geometry):
		var points: Array[Vector3]=[]
		for i in range(1,line.size()):
			var a:=Vector3(line[i-1][0],0,line[i-1][1]);var b:=Vector3(line[i][0],0,line[i][1])
			var steps:=maxi(1,ceili(a.distance_to(b)/4.0))
			var fractions: Array[float]=[]
			for j in steps:
				fractions.append(j/float(steps))
			if profiles!=null:
				fractions.append_array(profiles.split_fractions(feature.id,Vector2(a.x+c.origin.x,a.z+c.origin.z),Vector2(b.x+c.origin.x,b.z+c.origin.z)))
			fractions.sort()
			for fraction in fractions:
				var p:=a.lerp(b,fraction)
				if points.is_empty() or points[-1].distance_squared_to(p)>.000001:points.append(p)
		if line.size()>1:points.append(Vector3(line[-1][0],0,line[-1][1]))
		if points.size()<2:continue
		# Test cheap corridor eligibility before DEM/profile work. A tile's
		# mapped streets can extend far outside the visible railway strip.
		# Retain endpoint neighbours for the same joined miter geometry.
		var active: Array[bool]=[]
		for i in range(1,points.size()):
			var mid:=points[i-1].lerp(points[i],.5)
			active.append(c._corridor(mid.x,mid.z))
		if not active.has(true):continue
		var ground: Array[float]=[]
		var profiled: Array[bool]=[]
		for i in points.size():
			if (i==0 or not active[i-1]) and (i>=active.size() or not active[i]):
				ground.append(0.0);profiled.append(false);continue
			var p:=points[i];var y: float=c._ground(p.x,p.z)+.07
			ground.append(y)
			var sample: Dictionary={} if profiles==null else profiles.sample(feature.id,Vector2(p.x+c.origin.x,p.z+c.origin.z))
			points[i].y=sample.get("height",y)
			profiled.append(not sample.is_empty())
		var along:=0.0
		for i in range(1,points.size()):
			var p:=points[i-1];var q:=points[i]
			var horizontal:=Vector3(q.x-p.x,0,q.z-p.z)
			var length:=horizontal.length()
			if length<.001:continue
			var mid:=p.lerp(q,.5)
			var phase:=along;along+=length
			if not active[i-1]:continue
			var sample: Dictionary={} if profiles==null else profiles.sample(feature.id,Vector2(mid.x+c.origin.x,mid.z+c.origin.z))
			# Keep the engineered deck continuous. Ground support is decided
			# separately against the whole footprint, including roads underneath.
			var bridge: bool=sample.get("bridge",false) or (not sample.is_empty() and maxf(p.y-ground[i-1],q.y-ground[i])>1.2)
			if not bridge and c.road_water.wet(Vector2(mid.x,mid.z)):continue
			if tags.get("bridge","no")!="no" and sample.is_empty():continue
			var left:=_miter(points,i-1)*width*.5
			var right:=_miter(points,i)*width*.5
			var corners: Array[Vector3]=[p-left,q-right,q+right,p+left]
			var drape: bool=not bridge and not profiled[i-1] and not profiled[i]
			# Fade the cross-slope into an engineered approach over its last ground
			# segment, so the terrain-following edge meets the planar deck exactly.
			var conform:=Vector2(0 if profiled[maxi(0,i-2)] else 1,0 if profiled[mini(profiled.size()-1,i+1)] else 1)
			var area:=_surface(c,finish,corners,p,q,Color.WHITE,bridge,drape,conform)
			var full:=area>=length*width*.98
			if bridge:
				if full:_bridge(c,feature,p,q,left,right,phase,length,sample.get("bridge",false) or tags.get("bridge","no")!="no")
			else:
				for side in [-1,1]:
					var outer_a:=left+left.normalized()*.65;var outer_b:=right+right.normalized()*.65
					_surface(c,"road_shoulder",[p+left*side-Vector3.UP*.02,q+right*side-Vector3.UP*.02,q+outer_b*side-Vector3.UP*.03,p+outer_a*side-Vector3.UP*.03],p-Vector3.UP*.025,q-Vector3.UP*.025,Color.WHITE,false,drape,conform)
					# Retained approaches reach the ground, rather than hanging
					# over a 5.8 m vertical step at the end of a bridge.
					if full and maxf(p.y-ground[i-1],q.y-ground[i])>.2:
						var a: Vector3=p+outer_a*side;var b: Vector3=q+outer_b*side
						var ga:=a;var gb:=b
						ga.y=minf(a.y,c._ground(a.x,a.z));gb.y=minf(b.y,c._ground(b.x,b.z))
						c.batch.quad("concrete",ga,gb,b,a,outer_a.normalized()*side)
			if width>5.0 and Finishes.marked(finish):
				# Continuous dash phase along the mapped line, not one dash
				# per arbitrary source segment or streaming subdivision.
				var cursor:=phase
				while cursor<along-.001:
					var stop:=minf(along,(floorf(cursor/3)+1)*3)
					if posmod(floori(cursor/3),2)==0:
						var a:=p.lerp(q,(cursor-phase)/length)+Vector3.UP*.015
						var b:=p.lerp(q,(stop-phase)/length)+Vector3.UP*.015
						var side:=horizontal.normalized().cross(Vector3.UP)*.065
						var marking_conform:=Vector2(lerpf(conform.x,conform.y,(cursor-phase)/length),lerpf(conform.x,conform.y,(stop-phase)/length))
						_surface(c,"paint",[a-side,b-side,b+side,a+side],a,b,Color(.70,.67,.54),bridge,drape,marking_conform)
					cursor=stop
	if c.get("road_supports")!=null:c.road_supports.flush(c)

static func _miter(points: Array[Vector3],i: int) -> Vector3:
	var before:=points[i]-points[maxi(0,i-1)]
	var after:=points[mini(points.size()-1,i+1)]-points[i]
	before.y=0;after.y=0
	if before.length_squared()<.000001:before=after
	if after.length_squared()<.000001:after=before
	var normal:=after.normalized().cross(Vector3.UP)
	var bisector: Vector3=(before.normalized().cross(Vector3.UP)+normal).normalized()
	if bisector.length_squared()<.1:return normal
	return bisector/maxf(.5,bisector.dot(normal))

static func _surface(c,kind: String,corners: Array[Vector3],a: Vector3,b: Vector3,color: Color,over_water: bool=false,drape: bool=false,conform: Vector2=Vector2.ONE) -> float:
	var ring:=PackedVector2Array()
	for p in corners:ring.append(Vector2(p.x,p.z))
	if Geometry2D.is_polygon_clockwise(ring):ring.reverse()
	var pieces: Array=[ring]
	if c.geo.road_reservations!=null:pieces=c.geo.road_reservations.clip(ring,c.origin,minf(a.y,b.y)-.45,maxf(a.y,b.y)+.02)
	if not over_water and c.road_water!=null:pieces=c.road_water.clip(pieces)
	var axis:=Vector2(b.x-a.x,b.z-a.z);var squared:=maxf(.000001,axis.length_squared())
	var across:=Vector2(-axis.y,axis.x).normalized()
	var width:=maxf(.001,absf(Vector2(corners[3].x-corners[0].x,corners[3].z-corners[0].z).dot(across)))
	var area:=0.0
	var offset:=Vector2(c.origin.x,c.origin.z)
	var is_road:=kind in Finishes.KINDS
	for part in pieces:
		var projected:=[]
		if drape:
			var lift:=.045 if kind=="road_shoulder" else (.085 if kind=="paint" else .07)
			projected=preload("res://game/geographic_ground_ribbon.gd").project(c,part,lift)
			if conform!=Vector2.ONE:
				for index in projected.size():
					var triangle: PackedVector3Array=projected[index]
					for k in 3:
						var v:=Vector2(triangle[k].x,triangle[k].z)
						var t:=clampf((v-Vector2(a.x,a.z)).dot(axis)/squared,0,1)
						var point:=triangle[k]
						point.y=lerpf(lerpf(a.y,b.y,t),point.y,smoothstep(0,1,lerpf(conform.x,conform.y,t)))
						triangle[k]=point
					projected[index]=triangle
		else:
			var triangles:=Geometry2D.triangulate_polygon(part)
			for j in range(0,triangles.size(),3):
				var positions:=PackedVector3Array()
				for k in 3:
					var v: Vector2=part[triangles[j+k]]
					var t: float=(v-Vector2(a.x,a.z)).dot(axis)/squared
					positions.append(Vector3(v.x,lerpf(a.y,b.y,t),v.y))
				projected.append(positions)
		for positions: PackedVector3Array in projected:
			var first:=Vector2(positions[0].x,positions[0].z)
			var second:=Vector2(positions[1].x,positions[1].z)
			var third:=Vector2(positions[2].x,positions[2].z)
			var triangle_area:=absf((second-first).cross(third-first))*.5
			if triangle_area<.000001:continue
			area+=triangle_area
			var normal: Vector3=(positions[2]-positions[0]).cross(positions[1]-positions[0]).normalized()
			if normal.y<0:normal=-normal
			# UV carries absolute metre coordinates so rebasing cannot jump
			# the asphalt texture. UV2 carries the independent across-road
			# coordinate for dust; world X is not a road-edge mask.
			var uvs:=[];var edge_uvs:=[]
			for v in [first,second,third]:
				uvs.append((v+offset)/(1.0 if is_road else 3.5))
				if is_road:edge_uvs.append(Vector2(clampf((v-Vector2(a.x,a.z)).dot(across)/width+.5,0,1),0))
			c.batch.triangle(kind,positions[0],positions[1],positions[2],normal,color,uvs,edge_uvs)
	return area

static func _bridge(c,feature: Dictionary,p: Vector3,q: Vector3,left: Vector3,right: Vector3,phase: float,length: float,open_span: bool=true) -> void:
	# Closed slab, coping and connected guardrails. There is no lateral soil
	# ribbon on a span over a canal or the running railway.
	var down:=Vector3.DOWN*.4
	c.batch.quad("concrete",p-left+down,q-right+down,q+right+down,p+left+down,Vector3.DOWN)
	for side in [-1,1]:
		var a: Vector3=p+left*side;var b: Vector3=q+right*side
		c.batch.quad("concrete",a+down,b+down,b,a,left.normalized()*side)
		if not _bridge_edge_joins_road(c,feature.id,a,b):
			c.batch.beam("concrete",a+Vector3.UP*.12,b+Vector3.UP*.12,.20,Color.WHITE,.24)
			for y in [.55,1.05]:c.batch.beam("metal",a+Vector3.UP*y,b+Vector3.UP*y,.055)
			if floori(phase/2)!=floori((phase+length)/2):c.batch.beam("metal",a+Vector3.UP*.2,a+Vector3.UP*1.05,.055)
	if not open_span:
		if c.road_supports==null:c.road_supports=Support.new(c.tile_features,WIDTHS)
		var top: Array[Vector3]=[p-left+down,q-right+down,q+right+down,p+left+down]
		var plan: Dictionary=c.road_supports.plan(c,feature.id,top,p,q)
		if not plan.is_empty():c.road_supports.pending.append(plan);return
	if floori(phase/24)==floori((phase+length)/24):return
	var mid:=p.lerp(q,.5)
	var absolute: Vector3=mid+c.origin
	if c.geo.vegetation_clearance!=null and not c.geo.vegetation_clearance.clear(Vector2(absolute.x,absolute.z),2):return
	# Never place a bridge pier on a different mapped road beneath the deck.
	for other in c.tile_features:
		if other.kind!="road" or other.id==feature.id:continue
		for line in c._lines(other.geometry):
			for i in range(1,line.size()):
				var a:=Vector2(line[i-1][0],line[i-1][1]);var b:=Vector2(line[i][0],line[i][1])
				if Vector2(mid.x,mid.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(mid.x,mid.z),a,b))<6:return
	var bottom: float=minf(c._ground(mid.x,mid.z)-.4,mid.y-.6)
	var height:=mid.y-.4-bottom
	if height>.4:c.batch.box("concrete",Vector3(mid.x,bottom+height*.5,mid.z),Vector3(1.1,height,1.1))

static func _bridge_edge_joins_road(c,way: String,a: Vector3,b: Vector3) -> bool:
	# Open raised junctions/slip roads instead of putting a coping/guardrail
	# through their carriageway. Use the existing profile grid, not a scan of
	# every road segment per beam. Different levels remain grade-separated.
	var profiles=c.geo.road_profiles
	if profiles==null:return false
	if c.road_barrier_widths.is_empty():
		for feature in c.tile_features:
			if feature.kind!="road" or profiles.station_walkways.has(feature.id):continue
			var width: float=WIDTHS.get(feature.tags.get("highway",""),4.0)
			if width>=3:c.road_barrier_widths[feature.id]=width*.5
	var offset:=Vector2(c.origin.x,c.origin.z)
	var pa:=Vector2(a.x,a.z)+offset;var pb:=Vector2(b.x,b.z)+offset
	var bounds:=Rect2(pa,Vector2.ZERO).expand(pb).grow(5.3)
	for x in range(floori(bounds.position.x/profiles.CELL),floori(bounds.end.x/profiles.CELL)+1):
		for z in range(floori(bounds.position.y/profiles.CELL),floori(bounds.end.y/profiles.CELL)+1):
			for item in profiles.cells.get(Vector2i(x,z),[]):
				if item.way==way or not c.road_barrier_widths.has(item.way):continue
				var radius: float=c.road_barrier_widths[item.way]+.2
				for fraction in [0.0,.5,1.0]:
					var point:=pa.lerp(pb,fraction)
					var t:=clampf((point-item.a).dot(item.b-item.a)/maxf(.000001,item.a.distance_squared_to(item.b)),0,1)
					if point.distance_squared_to(item.a.lerp(item.b,t))>radius*radius:continue
					if absf(lerpf(a.y,b.y,fraction)-lerpf(item.ya,item.yb,t))<.6:return true
	return false
