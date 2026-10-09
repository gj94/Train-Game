extends RefCounted
## One detached 512 m geographic tile. Mapped footprints/roads/water are geometry;
## facade details and planting are deterministic artistic reconstruction.
const MeshBuilder := preload("res://game/geographic_mesh.gd")
const Foundations := preload("res://game/geographic_foundations.gd")
const StationSites := preload("res://game/coastal_station_sites.gd")
const Data := preload("res://game/geographic_data.gd")
const Library := preload("res://game/scenery_library.gd")
const Context := preload("res://game/world_view.gd")
var geo
var materials: Dictionary
var assets
var origin := Vector3.ZERO
var batch
var mask := PackedByteArray()
var rng := RandomNumberGenerator.new()
var root: Node3D
var water_levels := []
var ground_samples := {}
var wet_samples := {}
var shore_bins := {}
var near_tiles: Array = []
var mapped_rails: Array = []
var library
var occupancy:=preload("res://game/geographic_scenery_occupancy.gd").new()
const BuildingLayout:=preload("res://game/geographic_building_layout.gd")
const Kerala:=preload("res://game/kerala_scenery.gd")
var tile_features: Array=[]

func _init(data, shared_materials: Dictionary, shared_assets) -> void:
	geo=data
	materials=shared_materials
	assets=shared_assets

func build(key: Vector2i, far_tile: bool=false, holes: Array=[]) -> Dictionary:
	near_tiles=holes
	origin=Vector3(key.x*(2048 if far_tile else 512),0,key.y*(2048 if far_tile else 512))
	root=Node3D.new()
	root.name=("DistantTerrain_" if far_tile else "Geography_")+"%d_%d" % [key.x,key.y]
	batch=MeshBuilder.new()
	if far_tile:
		_terrain(2048,16,true)
		batch.finish(root,materials,"Terrain")
		return {node=root,origin=origin}
	var tile: Dictionary=geo.tile(key)
	tile_features=tile.get("features",[])
	mask=Marshalls.base64_to_raw(tile.get("mask",""))
	rng.seed=hash(str(key))
	for feature in tile.get("features",[]):
		if feature.kind=="water":
			water_levels.append({geometry=feature.geometry,height=feature.get("water_height",0.0)})
	_index_shores()
	_terrain(512,64,false)
	var context:=Context.new()
	context.root=root
	library=Library.new(context)
	library.meshes=assets.meshes
	library.finishes=assets.finishes
	_register_occupied(tile.get("features",[]))
	for feature in tile.get("features",[]):
		match feature.kind:
			"water": _water(feature)
			"road": _road(feature)
			"stream": _stream(feature)
			"building": _building(feature)
			"rail": _mapped_rail(feature)
	Kerala.dress(self,tile_features)
	batch.finish(root,materials,"Geography")
	_planting()
	library.flush()
	library=null
	return {node=root,origin=origin}

func _class_at(x: float,z: float) -> int:
	if mask.size()!=4096: return 0
	return mask[clampi(floori(z/8),0,63)*64+clampi(floori(x/8),0,63)]

func _ground(x: float,z: float) -> float:
	var key:=Vector2(x,z)
	if ground_samples.has(key):return ground_samples[key]
	var height: float=geo.ground_at(origin.x+x,origin.z+z)
	# The precise water polygon overrides the coarser land-cover raster. Otherwise
	# small canals and pond edges can be covered by dry raster cells.
	wet_samples[key]=false
	if not water_levels.is_empty() and not StationSites.contains(geo.station_sites,origin.x+x,origin.z+z):
		for water in water_levels:
			if _inside(key,water.geometry):
				height=minf(height,water.height-.5);wet_samples[key]=true
		if not wet_samples[key] and geo.nearest_rail(origin.x+x,origin.z+z).distance>32:
			# SRTM and flat mapped water have different resolutions. Grade the last
			# 10 m of bank to the water datum instead of exposing staircase cliffs.
			var distance:=10.0;var level:=height
			for segment in shore_bins.get(Vector2i(floori(x/32),floori(z/32)),[]):
				var d: float=preload("res://game/geographic_scenery_occupancy.gd").distance(key,segment.a,segment.b)
				if d<distance:distance=d;level=segment.height+.22
			if distance<10 and height>level:height=lerpf(level,height,smoothstep(0,10,distance))
	ground_samples[key]=height
	return height

func _index_shores() -> void:
	for water in water_levels:
		var polygons: Array=water.geometry.coordinates if water.geometry.type=="MultiPolygon" else [water.geometry.coordinates]
		for poly in polygons:
			for ring in poly:
				for i in range(1,ring.size()):
					var a:=Vector2(ring[i-1][0],ring[i-1][1]);var b:=Vector2(ring[i][0],ring[i][1])
					# Clipped tile borders are not real shorelines.
					if (is_equal_approx(a.x,b.x) and (is_zero_approx(a.x) or is_equal_approx(a.x,512))) or (is_equal_approx(a.y,b.y) and (is_zero_approx(a.y) or is_equal_approx(a.y,512))):continue
					var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(10)
					for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
						for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
							var key:=Vector2i(x,z)
							if not shore_bins.has(key):shore_bins[key]=[]
							shore_bins[key].append({a=a,b=b,height=water.height})

func _inside(point: Vector2,geometry: Dictionary) -> bool:
	var polygons: Array=geometry.coordinates if geometry.type=="MultiPolygon" else [geometry.coordinates]
	for poly in polygons:
		if poly.is_empty(): continue
		var outer:=PackedVector2Array()
		for p in poly[0]: outer.append(Vector2(p[0],p[1]))
		if not Geometry2D.is_point_in_polygon(point,outer): continue
		var hole:=false
		for i in range(1,poly.size()):
			var ring:=PackedVector2Array()
			for p in poly[i]: ring.append(Vector2(p[0],p[1]))
			if Geometry2D.is_point_in_polygon(point,ring): hole=true; break
		if not hole: return true
	return false

func _terrain(size: float,steps: int,far_tile: bool) -> void:
	var vertices:=PackedVector3Array()
	var colors:=PackedColorArray()
	for z in steps+1:
		for x in steps+1:
			var p:=Vector2(x*size/steps,z*size/steps)
			var height: float=geo.height_at(origin.x+p.x,origin.z+p.y)-.35 if far_tile else _ground(p.x,p.y)
			vertices.append(Vector3(p.x,height,p.y))
			var land:=_class_at(p.x,p.y)
			var color:=Color(.30,.49,.23,.04)
			if land==1 or land in [6,7,8]: color=Color(.38,.46,.30,.21)
			elif land==2: color=Color(.36,.58,.20,.03)
			elif land==3: color=Color(.22,.39,.20,.02)
			elif land==4: color=Color(.36,.39,.29,.9)
			elif land==5: color=Color(.88,.77,.52,.85)
			colors.append(color)
	for z in steps:
		for x in steps:
			if far_tile and Vector2i(floori((origin.x+(x+.5)*size/steps)/512),floori((origin.z+(z+.5)*size/steps)/512)) in near_tiles: continue
			var i:=z*(steps+1)+x
			var a:=vertices[i]; var b:=vertices[i+1]; var c:=vertices[i+steps+2]; var d:=vertices[i+steps+1]
			if not far_tile:
				var wet:=0
				for corner in [a,b,c,d]:
					if wet_samples.get(Vector2(corner.x,corner.z),false):wet+=1
				if wet>0 and wet<4:
					_shore_cell(Vector2(a.x,a.z),size/steps,[a,b,c,d])
					continue
			var normal: Vector3=(d-a).cross(b-a).normalized()
			var farmland:=not far_tile
			for corner in [a,b,c,d]:
				if _class_at(corner.x,corner.z)!=2:farmland=false;break
			var surface: SurfaceTool=batch.surface("paddy" if farmland else "ground")
			for index in [i,i+1,i+steps+2,i,i+steps+2,i+steps+1]:
				var p: Vector3=vertices[index]
				surface.set_normal(normal)
				var tint:=colors[index]
				if farmland:tint.a=Kerala.parcel_stage(Vector2((a.x+c.x)*.5+origin.x,(a.z+c.z)*.5+origin.z))
				surface.set_color(tint)
				surface.set_uv(Vector2(p.x+origin.x,p.z+origin.z)/3.5)
				surface.add_vertex(p)

func _shore_cell(start: Vector2,width: float,corners: Array) -> void:
	# Refine only mixed wet/dry terrain cells to 2 m. The rest stays at 8 m;
	# this avoids angular 8 m bites through canal banks without a global mesh hike.
	for z in 4:
		for x in 4:
			var points:=[];var uvs:=[]
			for offset in [Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:
				var p: Vector2=start+offset*width*.25
				var height:=_ground(p.x,p.y)
				# Keep subdivided perimeter vertices on the neighbouring 8 m edge.
				# Otherwise the curved bank creates T-junction cracks against dry cells.
				if offset.y==0:height=lerpf(corners[0].y,corners[1].y,offset.x*.25)
				elif offset.y==4:height=lerpf(corners[3].y,corners[2].y,offset.x*.25)
				elif offset.x==0:height=lerpf(corners[0].y,corners[3].y,offset.y*.25)
				elif offset.x==4:height=lerpf(corners[1].y,corners[2].y,offset.y*.25)
				points.append(Vector3(p.x,height,p.y));uvs.append((p+Vector2(origin.x,origin.z))/3.5)
			var normal: Vector3=(points[3]-points[0]).cross(points[1]-points[0]).normalized()
			batch.quad("ground",points[0],points[1],points[2],points[3],normal,Color(.32,.44,.23,.18),uvs)

func _water(feature: Dictionary) -> void:
	var y: float=feature.get("water_height",0.0)+.06
	for tri in feature.get("triangles",[]):
		batch.triangle("water",Vector3(tri[0][0],y,tri[0][1]),Vector3(tri[1][0],y,tri[1][1]),Vector3(tri[2][0],y,tri[2][1]),Vector3.UP)

func _lines(geometry: Dictionary) -> Array:
	return geometry.coordinates if geometry.type=="MultiLineString" else ([geometry.coordinates] if geometry.type=="LineString" else [])

func _road(feature: Dictionary) -> void:
	var tags: Dictionary=feature.tags
	if tags.get("highway","") in ["proposed","construction"]: return
	var width: float={"motorway":10.0,"trunk":9.0,"primary":8.0,"secondary":6.5,"tertiary":5.5,"residential":4.5,"service":3.6,"footway":1.5,"path":1.0,"track":2.8}.get(tags.get("highway",""),4.0)
	var bridge: bool=tags.get("bridge","no")!="no"
	for line in _lines(feature.geometry):
		for i in range(1,line.size()):
			var a:=Vector3(line[i-1][0],0,line[i-1][1])
			var b:=Vector3(line[i][0],0,line[i][1])
			var steps:=maxi(1,ceili(a.distance_to(b)/8.0))
			for j in steps:
				var p:=a.lerp(b,j/float(steps)); var q:=a.lerp(b,(j+1)/float(steps))
				if not bridge and StationSites.road_blocked(geo.station_sites,(p.x+q.x)*.5+origin.x,(p.z+q.z)*.5+origin.z,width*.5):continue
				p.y=_ground(p.x,p.z)+.07; q.y=_ground(q.x,q.z)+.07

				if bridge: p.y+=5.8; q.y+=5.8
				var side: Vector3=(q-p).normalized().cross(Vector3.UP)*width*.5
				var normal: Vector3=(q-p).cross(side).normalized()
				if normal.y<0: normal=-normal
				batch.quad("road",p-side,q-side,q+side,p+side,normal,Color.WHITE,[Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(1,0)])
				if not bridge:
					for signum in [-1,1]:
						var outer: Vector3=side+side.normalized()*.65
						batch.quad("road_shoulder",p+side*signum-Vector3.UP*.02,q+side*signum-Vector3.UP*.02,q+outer*signum-Vector3.UP*.03,p+outer*signum-Vector3.UP*.03,Vector3.UP)
				if bridge:
					for signum in [-1,1]:
						batch.beam("concrete",p+side*signum+Vector3.UP*.55,q+side*signum+Vector3.UP*.55,.18)
				elif width>5:
					var mid:=p.lerp(q,.5)
					var along: Vector3=(q-p).normalized()*minf(2.0,p.distance_to(q)*.35)
					var stripe:=side.normalized()*.06
					batch.quad("paint",mid-along-stripe+Vector3.UP*.015,mid+along-stripe+Vector3.UP*.015,mid+along+stripe+Vector3.UP*.015,mid-along+stripe+Vector3.UP*.015,Vector3.UP,Color(.70,.67,.54))

func _stream(feature: Dictionary) -> void:
	for line in _lines(feature.geometry):
		for i in range(1,line.size()):
			var a:=Vector3(line[i-1][0],0,line[i-1][1]); var b:=Vector3(line[i][0],0,line[i][1])
			a.y=_ground(a.x,a.z)+.09; b.y=_ground(b.x,b.z)+.09
			var side: Vector3=(b-a).normalized().cross(Vector3.UP)*(4.0 if feature.tags.get("waterway")=="river" else 1.2)
			batch.quad("water",a-side,b-side,b+side,a+side,Vector3.UP)

func _building(feature: Dictionary) -> void:
	if feature.tags.get("building","") in ["train_station","station"]: return
	var geometry: Dictionary=feature.geometry
	var polygons: Array=geometry.coordinates if geometry.type=="MultiPolygon" else [geometry.coordinates]
	var seed_value:=absi(hash(feature.id))
	for poly in polygons:
		if poly.is_empty() or poly[0].size()<4: continue
		var ring:=PackedVector2Array()
		for p in poly[0]: ring.append(Vector2(p[0],p[1]))
		if ring[0].is_equal_approx(ring[-1]): ring.remove_at(ring.size()-1)
		if StationSites.intersect(geo.station_sites,ring,origin):continue
		var centre:=Vector2.ZERO
		for p in ring: centre+=p
		centre/=ring.size()
		var rail: Dictionary=geo.nearest_rail(origin.x+centre.x,origin.z+centre.y)
		if rail.distance<(60 if rail.get("depot",false) else 22): continue # reconstructed track/workshop clearance
		var levels:=clampi(int(feature.tags.get("building:levels","2" if seed_value%4==0 else "1")),1,18)
		var height:=maxf(2.8,float(feature.tags.get("height",str(levels*3.1)).trim_suffix(" m")))
		var footing:=Foundations.outline(ring,_ground)
		var y: float=maxf(Foundations.surface_height(_ground,centre.x,centre.y),footing.map(func(p):return p.y).max())
		Foundations.skirt(batch,footing,y)
		var front:=Kerala.frontage(self,centre,tile_features)
		var detail_tags: Dictionary=feature.tags
		# Sparse roadside commerce only for otherwise unclassified OSM buildings.
		# Explicit houses and surveyed storeys retain their known use/envelope.
		if levels==1 and feature.tags.get("building","")=="yes" and front.length()>3 and front.length()<19 and seed_value%7==0:
			detail_tags=feature.tags.duplicate();detail_tags.shop="reconstructed"
		var detail:=BuildingLayout.fit(ring,levels,detail_tags,seed_value,assets.catalog,front)
		if not detail.is_empty():
			# Fill the retaining skirt. Detailed verandas/steps expose the base that
			# a solid extrusion used to hide; grass must not remain inside it.
			var pad:=Geometry2D.triangulate_polygon(ring)
			for j in range(0,pad.size(),3):
				var pa:=ring[pad[j]];var pb:=ring[pad[j+1]];var pc:=ring[pad[j+2]]
				batch.triangle("forecourt",Vector3(pa.x,y,pa.y),Vector3(pb.x,y,pb.y),Vector3(pc.x,y,pc.y),Vector3.UP)
			var position: Vector3=detail.position;position.y=y
			library.place(detail.kind,position,detail.angle,detail.scale)
			continue
		var color: Color=[Color(.68,.68,.56),Color(.60,.69,.66),Color(.72,.59,.51),Color(.60,.64,.73),Color(.74,.71,.62)][seed_value%5]
		color.a=1.0/15.0
		var reversed:=Geometry2D.is_polygon_clockwise(ring)
		for i in ring.size():
			var a:=Vector3(ring[i].x,y,ring[i].y); var b:=Vector3(ring[(i+1)%ring.size()].x,y,ring[(i+1)%ring.size()].y)
			var along: Vector3=(b-a).normalized()
			var normal: Vector3=along.cross(Vector3.UP)*(1.0 if reversed else -1.0)
			batch.quad("architecture",a,b,b+Vector3.UP*height,a+Vector3.UP*height,normal,color)
			var span:=a.distance_to(b)
			if span<2.6: continue
			var columns:=maxi(1,floori(span/3.0))
			for floor_index in mini(levels,8):
				for column in columns:
					var p:=a.lerp(b,(column+.5)/columns)+Vector3.UP*(floor_index*3.1+1.65)+normal*.035
					var right:=along*minf(.68,span/columns*.31)
					var up:=Vector3.UP*.68
					var glass:=Color(.10,.17,.18,4.0/15.0)
					batch.quad("architecture",p-right-up,p+right-up,p+right+up,p-right+up,normal,glass)
					if rail.distance>420: continue
					var frame:=Color(.24,.24,.20,0) if seed_value%3 else Color(.51,.50,.43,0)
					batch.beam("architecture_detail",p-right-up,p-right+up,.075,frame)
					batch.beam("architecture_detail",p+right-up,p+right+up,.075,frame)
					batch.beam("architecture_detail",p-right+up,p+right+up,.075,frame)
					batch.beam("architecture_detail",p-right-up,p+right-up,.10,frame)
					batch.beam("architecture_detail",p-up,p+up,.035,frame)
					batch.beam("architecture_detail",p-right,p+right,.032,frame)
					if floor_index==0 or seed_value%3==0:
						var shade:=p+up+Vector3.UP*.14+normal*.28
						batch.box("architecture_detail",shade,Vector3(right.length()*2+.35,.10,.65),Color(.50,.51,.45,1.0/15.0),Basis.looking_at(-normal))
		var indices:=Geometry2D.triangulate_polygon(ring)
		var roof_color:=Color(.55,.51,.42,1.0/15.0)
		for i in range(0,indices.size(),3):
			var a: Vector2=ring[indices[i]]; var b: Vector2=ring[indices[i+1]]; var c: Vector2=ring[indices[i+2]]
			batch.triangle("architecture",Vector3(a.x,y+height,a.y),Vector3(b.x,y+height,b.y),Vector3(c.x,y+height,c.y),Vector3.UP,roof_color)
		if levels<=2 and ring.size()==4 and seed_value%3!=0:
			preload("res://game/geographic_roof.gd").draw(batch,ring,centre,y+height)
		elif rail.distance<420:
			for i in ring.size():
				var a:=Vector3(ring[i].x,y+height+.30,ring[i].y)
				var b:=Vector3(ring[(i+1)%ring.size()].x,y+height+.30,ring[(i+1)%ring.size()].y)
				batch.beam("architecture",a,b,.14,roof_color,.6)
			if seed_value%2==0: batch.box("architecture",Vector3(centre.x,y+height+.65,centre.y),Vector3(1.2,1.3,1.2),Color(.045,.055,.05,0))

func _mapped_rail(feature: Dictionary) -> void:
	if feature.tags.get("railway")!="rail": return
	for line in _lines(feature.geometry):
		for i in range(1,line.size()):
			var a:=Vector3(line[i-1][0],0,line[i-1][1])
			var b:=Vector3(line[i][0],0,line[i][1])
			mapped_rails.append([Vector2(a.x,a.z),Vector2(b.x,b.z)])
			if geo.operating_ways.has(str(feature.id)):continue
			var count:=maxi(1,ceili(a.distance_to(b)/5.0))
			for j in count:
				var p:=a.lerp(b,j/float(count)); var q:=a.lerp(b,(j+1)/float(count))
				var centre:=p.lerp(q,.5)
				if geo.nearest_rail(origin.x+centre.x,origin.z+centre.z).distance<26: continue
				p.y=_ground(p.x,p.z)+.12; q.y=_ground(q.x,q.z)+.12
				var side: Vector3=(q-p).normalized().cross(Vector3.UP)
				batch.quad("ballast",p-side*2.1,q-side*2.1,q+side*2.1,p+side*2.1,Vector3.UP)
				for signum in [-1,1]:
					batch.beam("metal",p+side*signum*.838+Vector3.UP*.20,q+side*signum*.838+Vector3.UP*.20,.075,Color.WHITE,.14)
				var sleepers:=maxi(1,ceili(p.distance_to(q)/.75))
				for k in sleepers:
					var c:=p.lerp(q,k/float(sleepers))+Vector3.UP*.07
					batch.beam("concrete",c-side*1.35,c+side*1.35,.20,Color.WHITE,.13)

func _near_mapped_rail(p: Vector2,clearance: float) -> bool:
	for segment in mapped_rails:
		var a: Vector2=segment[0]; var b: Vector2=segment[1]
		var weight:=clampf((p-a).dot(b-a)/maxf(.001,(b-a).length_squared()),0,1)
		if p.distance_squared_to(a.lerp(b,weight))<clearance*clearance: return true
	return false

func _register_occupied(features: Array) -> void:
	for feature in features:
		if feature.kind=="building":
			var geometry: Dictionary=feature.geometry
			var polygons: Array=geometry.coordinates if geometry.type=="MultiPolygon" else [geometry.coordinates]
			for poly in polygons:
				if poly.is_empty():continue
				var ring:=PackedVector2Array()
				for p in poly[0]:ring.append(Vector2(p[0],p[1]))
				occupancy.add_polygon(ring,.6)
		elif feature.kind in ["road","stream"]:
			var half_width: float={"motorway":5.0,"trunk":4.5,"primary":4.0,"secondary":3.25,"tertiary":2.75,"residential":2.25,"service":1.8,"footway":.75,"path":.5,"track":1.4}.get(feature.tags.get("highway",""),2.0)
			for line in _lines(feature.geometry):
				for i in range(1,line.size()):
					occupancy.add_road(Vector2(line[i-1][0],line[i-1][1]),Vector2(line[i][0],line[i][1]),half_width+1)
func _planting() -> void:
	for i in 1800:
		var p:=Vector3(rng.randf_range(0,512),0,rng.randf_range(0,512))
		var kind:=_class_at(p.x,p.z)
		if kind in [4,5,6,7,8]: continue
		if StationSites.contains(geo.station_sites,p.x+origin.x,p.z+origin.z,12):continue
		var rail: Dictionary=geo.nearest_rail(p.x+origin.x,p.z+origin.z)
		if rail.distance<14 or _near_mapped_rail(Vector2(p.x,p.z),9):continue
		if geo.vegetation_clearance!=null and not geo.vegetation_clearance.clear(Vector2(p.x+origin.x,p.z+origin.z),5.5):continue
		# Cultivated land stays open; palms belong on the planted bunds.
		if kind==2 and (Kerala.parcel_edge(Vector2(p.x+origin.x,p.z+origin.z))>3.5 or i%3!=0):continue
		if not occupancy.clear(Vector2(p.x,p.z),3.5):continue
		p.y=Foundations.surface_height(_ground,p.x,p.z)
		var choice: String=["coconut_palm","coconut_palm","young_palm","tree_small_02","tree_small_02","mango_tree","mango_tree","rain_tree","rain_tree"][rng.randi_range(0,8)]
		if kind==3 and rng.randf()<.55: choice="rain_tree"
		# Coconut-rich lowlands give way to the more mixed, cultivated southern
		# approach. Existing DEM and mapped forests still control the terrain.
		if kind!=3 and rail.get("s",0.0)<165000 and p.y<12 and i%4==0:choice="coconut_palm"
		var banana_interval:=3 if rail.get("s",0.0)>230000 else 5
		if kind in [0,1,2] and rail.distance<350 and i%banana_interval==0 and Kerala.dry_clear(self,Vector2(p.x,p.z),3.3):choice="banana_clump"
		elif kind==2:choice="coconut_palm" if i%2==0 else "young_palm"
		var scale:=rng.randf_range(.72,1.28)
		library.place(choice,p,rng.randf()*TAU,Vector3.ONE*scale)
	for i in 2200:
		var p:=Vector3(rng.randf_range(0,512),0,rng.randf_range(0,512))
		var kind:=_class_at(p.x,p.z)
		if kind in [5,6,7,8,4]: continue
		if kind==2 and Kerala.parcel_edge(Vector2(p.x+origin.x,p.z+origin.z))>2:continue
		if StationSites.contains(geo.station_sites,p.x+origin.x,p.z+origin.z,2):continue
		var rail: Dictionary=geo.nearest_rail(p.x+origin.x,p.z+origin.z)
		if rail.distance<8 or rail.distance>130:continue
		if geo.vegetation_clearance!=null and not geo.vegetation_clearance.clear(Vector2(p.x+origin.x,p.z+origin.z),2.5):continue
		if not occupancy.clear(Vector2(p.x,p.z),2.5) or _near_mapped_rail(Vector2(p.x,p.z),5):continue
		p.y=Foundations.surface_height(_ground,p.x,p.z)
		var choice: String="shrub" if i%3!=0 else "reeds"
		library.place(choice,p,rng.randf()*TAU,Vector3.ONE*rng.randf_range(.7,1.25))
	preload("res://game/coastal_vegetation.gd").groundcover(self)
	Kerala.crops(self)
