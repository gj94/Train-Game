extends SceneTree
## Read-only physical inventory for reviewing an authoring proposal.
func _initialize() -> void:
	var w: RailWorld=preload("res://sim/layouts/kerala_coast.gd").build(true)
	var stations:=[]
	for station in w.stations:
		var roads:=[]
		for road in station.platform_tracks:
			roads.append({id=road,length=w.graph.edges[road].length,details=station.platform_details.get(road,{})})
		stations.append({code=station.code,s=station.s,half=station.yard_half,through_halt=station.through_halt,roads=roads})
	var out:={kind="physical yard inventory only; not admission or traffic acceptance",stations=stations,sources=preload("res://persistence/prepared_sources.gd").collect()}
	FileAccess.open("res://.local/realism-2026-10-26/planning-yards.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("YARDS ",stations.size());quit()
