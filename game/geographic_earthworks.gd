extends RefCounted
## Render-only formation grading. Absolute chainage keeps tile borders identical;
## smooth station transitions avoid the old 500 m width steps. No track is moved.
const RUNNING_HALF_WIDTH := 14.0
const STATION_TAPER := 280.0
const CELL := 500.0

static func regions(route: Dictionary,operations: Dictionary) -> Array:
	var result:=[]
	for i in operations.stations.size():
		var width:=32.0
		for road in operations.stations[i].roads:width=maxf(width,absf(road.offset)+28)
		var s: float=route.stations[i].s
		# Retain the complete previously protected station/ladder envelope. Only
		# the outside transition changes; detailed precinct grading applies last.
		result.append({start=floorf((s-850)/CELL)*CELL,end=(ceili((s+850)/CELL)+1)*CELL,width=width})
	return result

static func index(regions: Array) -> Dictionary:
	var bins:={}
	for region in regions:
		for key in range(floori((region.start-STATION_TAPER)/CELL),floori((region.end+STATION_TAPER)/CELL)+1):
			if not bins.has(key):bins[key]=[]
			bins[key].append(region)
	return bins

static func include_running_roads(regions: Array,edges: Dictionary,nodes: Dictionary) -> void:
	# Some mapped parallel lines are 16 m from the route reference. Retain the
	# terrain grid around their real position without broadening every rural bank.
	for id: String in edges:
		if "_DEPOT_" in id:continue
		var edge: Dictionary=edges[id]
		var lateral: float=maxf(absf(edge.lateral),maxf(absf(nodes[edge.a].lateral),absf(nodes[edge.b].lateral)))
		if lateral<=6:continue
		var start: float=minf(edge.chainage_start,edge.chainage_end)
		var end: float=maxf(edge.chainage_start,edge.chainage_end)
		var width:=lateral+12.0
		if regions.any(func(region):return region.start<=start and region.end>=end and region.width>=width):continue
		regions.append({start=start,end=end,width=width})

static func half_width(bins: Dictionary,s: float) -> float:
	var width:=RUNNING_HALF_WIDTH
	for region in bins.get(floori(s/CELL),[]):
		var outside:=maxf(region.start-s,s-region.end)
		var weight:=1.0-smoothstep(0,STATION_TAPER,outside)
		width=maxf(width,lerpf(RUNNING_HALF_WIDTH,region.width,weight))
	return width

static func grade(natural: float,rail: Dictionary,width: float) -> float:
	if rail.get("bridge",false):
		# Preserve open space beneath bridge decks, including noisy radar returns.
		return minf(natural,lerpf(rail.height-.8,natural,smoothstep(width,width+58,rail.distance)))
	var formation: float=rail.height-.15
	# Low banks regain natural ground nearby; deep cuttings have wider batters.
	# Existing DEM relief drives the shape, rather than arbitrary hills/noise.
	var run:=clampf(12.0+absf(natural-formation)*2.5,18.0,90.0)
	if rail.get("depot",false) or rail.get("yard",false):run=58.0
	return lerpf(formation,natural,smoothstep(width,width+run,rail.distance))
