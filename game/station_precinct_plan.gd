extends RefCounted
## Shared station civil footprint. Absolute coordinates; no rendering dependency.
const Placement:=preload("res://game/coastal_station_placement.gd")
static func plans(world: RailWorld,station: Dictionary) -> Array:
	var road: String=station.platform_tracks[0]
	var mid: float=world.graph.edges[road].length*.5
	var p:=world.graph.position(road,mid)
	var f:=world.graph.tangent(road,mid,1);f=Vector3(f.x,0,f.z).normalized()
	var r:=f.cross(Vector3.UP)
	var left:=0.0;var right:=0.0
	for detail in station.operating_roads:
		left=minf(left,detail.offset);right=maxf(right,detail.offset)
	var code: String=station.code
	var source_path: String="res://assets/models/ported/station_"+Placement.asset_code(code).to_lower()+"_detail/provenance.json"
	if not FileAccess.file_exists(source_path):return []
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	var bounds: Array=source.source_bounds
	var assembly: Dictionary
	if Placement.available(code):
		var site:=Placement.site(world,station,Vector3.ZERO)
		assembly=Placement.layout(site.position,site.forward,site.right,bounds,source.placement)
		f=assembly.basis.x;r=assembly.basis.z
	else:
		# Same rigid source transform as AuthoredStation.add_building().
		var anchor: Vector3=p+r*(left-26)
		var source_centre:=Vector3((bounds[0][0]+bounds[1][0])*.5,0,-(bounds[0][1]+bounds[1][1])*.5)
		var basis:=Basis(-f,Vector3.UP,-r)
		assembly={position=anchor+basis*source_centre+Vector3.UP*float(bounds[0][2]),footprint=Vector2(bounds[1][0]-bounds[0][0]+2,bounds[1][1]-bounds[0][1]+2)}
	var result:=[_plan(code,code,assembly.position,Basis(f,Vector3.UP,r),assembly.footprint,station.major,station.get("through_halt",false))]
	if code=="ERS":
		var east: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/station_ers_east_detail/provenance.json"))
		var b: Array=east.source_bounds
		result.append(_plan("ERS_EAST",code,p+r*(right+24)+Vector3.UP*float(b[0][2]),Basis(-f,Vector3.UP,-r),Vector2(b[1][0]-b[0][0]+2,b[1][1]-b[0][1]+2),true,false))
	return result

static func _plan(id: String,station: String,p: Vector3,basis: Basis,size: Vector2,major: bool,halt: bool) -> Dictionary:
	var forecourt_depth:=0.0 if halt else (31.0 if major else 23.0)
	var half:=size.x*.5 if halt else maxf(27,size.x*.5+7)
	var front: float=-size.y*.5
	var back: float=size.y*.5
	var outer: float=front-forecourt_depth
	var centre: Vector3=p+basis.z*(back+outer)*.5
	var extent:=Vector2(half*2,back-outer)
	return {id=id,code=station,centre=centre,basis=basis,extent=extent,
		solid_centre=p,solid_extent=size,height=p.y-.09,building=p,footprint=size,
		half=half,front=front,outer=outer,back=back,major=major,halt=halt,access=[]}

static func build(world: RailWorld) -> Dictionary:
	var bins:={}
	var data=preload("res://game/geographic_data.gd").new(world.scenery.route)
	var tile_cache:={}
	for station in world.stations:
		for zone: Dictionary in plans(world,station):
			if not zone.halt:zone.access=_access(zone,data,tile_cache)
			var radius: float=zone.extent.length()*.5+24
			var centre: Vector3=zone.centre
			for x in range(floori((centre.x-radius)/512),floori((centre.x+radius)/512)+1):
				for z in range(floori((centre.z-radius)/512),floori((centre.z+radius)/512)+1):
					var key:=Vector2i(x,z)
					if not bins.has(key):bins[key]=[]
					bins[key].append(zone)
			# Access spurs reserve their corridor against procedural clutter too.
			for connection in zone.access:
				var a: Vector3=connection[0];var b: Vector3=connection[1]
				var delta: Vector3=b-a;delta.y=0
				if delta.length()<.1:continue
				var link:={id=zone.id+"_ACCESS",code=zone.code,centre=(a+b)*.5,basis=Basis.looking_at(delta),extent=Vector2(8,delta.length()+4),solid_centre=(a+b)*.5,solid_extent=Vector2.ZERO,height=zone.height,access_zone=true}
				for x in range(floori((minf(a.x,b.x)-12)/512),floori((maxf(a.x,b.x)+12)/512)+1):
					for z in range(floori((minf(a.z,b.z)-12)/512),floori((maxf(a.z,b.z)+12)/512)+1):
						var key:=Vector2i(x,z)
						if not bins.has(key):bins[key]=[]
						bins[key].append(link)
	return bins

static func entries(bins: Dictionary,station: Dictionary) -> Array:
	var found:=[]
	var p: Vector3=station.origin
	for x in range(floori(p.x/512)-1,floori(p.x/512)+2):
		for z in range(floori(p.z/512)-1,floori(p.z/512)+2):
			for zone in bins.get(Vector2i(x,z),[]):
				if zone.code==station.code and not zone.get("access_zone",false) and not found.has(zone):found.append(zone)
	return found

static func ground(bins: Dictionary,x: float,z: float,height: float) -> float:
	var best:=0.0
	var target:=height
	for zone in bins.get(Vector2i(floori(x/512),floori(z/512)),[]):
		if zone.get("access_zone",false):continue
		var delta: Vector3=Vector3(x,zone.centre.y,z)-zone.centre
		var along: float=absf(delta.dot(zone.basis.x))-zone.extent.x*.5
		var across: float=delta.dot(zone.basis.z)
		# No earthwork ramp toward the running lines or beneath open shelters.
		if across>zone.extent.y*.5 or zone.get("halt",false):continue
		var outside:=maxf(along,-across-zone.extent.y*.5)
		var weight:=1.0-smoothstep(0,12,outside)
		if weight>best:
			best=weight;target=zone.height
	return lerpf(height,target,best)

static func _access(zone: Dictionary,data,tile_cache: Dictionary) -> Array:
	# Connect front/side gates to nearby mapped roads on the city side.
	# Only accepted paths entirely outside the building and mapped water/houses.
	var gate: Vector3=zone.building+zone.basis.z*zone.outer
	var features:=[]
	var tile_origins:=[]
	for x in range(floori(gate.x/512)-1,floori(gate.x/512)+2):
		for z in range(floori(gate.z/512)-1,floori(gate.z/512)+2):
			var key:=Vector2i(x,z)
			if not tile_cache.has(key):tile_cache[key]=data.tile(key)
			for feature in tile_cache[key].get("features",[]):
				if feature.kind in ["road","building","water"]:
					features.append(feature);tile_origins.append(Vector2(x*512,z*512))
	var candidates:=[]
	for i in features.size():
		var feature: Dictionary=features[i]
		if feature.kind!="road" or feature.tags.get("bridge","no")!="no":continue
		if feature.tags.get("highway","") not in ["service","residential","unclassified","tertiary","secondary"]:continue
		var lines: Array=feature.geometry.coordinates if feature.geometry.type=="MultiLineString" else [feature.geometry.coordinates]
		for line in lines:
			for j in range(1,line.size()):
				var a: Vector2=Vector2(line[j-1][0],line[j-1][1])+tile_origins[i]
				var b: Vector2=Vector2(line[j][0],line[j][1])+tile_origins[i]
				candidates.append_array(_road_candidates(zone,data,a,b))

	return preload("res://game/station_road_access.gd").clear_links(candidates,features,tile_origins)


static func _road_candidates(zone: Dictionary,data,a: Vector2,b: Vector2) -> Array:
	return preload("res://game/station_road_access.gd").candidates(zone,data,a,b)
