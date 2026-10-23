extends SceneTree
## Interleaved CPU-only road mesh generation comparison on identical source
## tiles. Baseline is an explicit local script, never part of a release.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var baseline:=""
	var output:="res://.local/road-generation-profile.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):baseline=arg.trim_prefix("--baseline=")
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	if baseline.is_empty() or not FileAccess.file_exists(baseline):
		printerr("Specify --baseline=res://.local/<previous-scenery-script>.gd");quit(2);return
	var scripts:={before=load(baseline),after=preload("res://game/geographic_scenery_chunk.gd")}
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo:=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world)
	geo.road_profiles=preload("res://game/geographic_road_profiles.gd").new()
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world,geo)
	geo.vegetation_clearance=preload("res://game/vegetation_clearance.gd").build(world)
	geo.road_reservations=preload("res://game/geographic_road_reservations.gd").new(world,geo.station_sites)
	var materials:={}
	for kind in preload("res://game/geographic_road_finishes.gd").KINDS+["road_shoulder","concrete","metal","paint"]:materials[kind]=StandardMaterial3D.new()
	var selected:={}
	for station in world.stations:
		if station.code not in ["ERS","KUMM","TUVR","ALLP","KYJ","QLN","VAK","TVC","KZT","NCJ"]:continue
		var centre: Vector3=station.origin
		for x in range(floori(centre.x/512)-1,floori(centre.x/512)+2):
			for z in range(floori(centre.z/512)-1,floori(centre.z/512)+2):
				var key:=Vector2i(x,z)
				if not selected.has(key):selected[key]=geo.tile(key)
	var rows:=[]
	var counter:=0
	for key: Vector2i in selected:
		var tile: Dictionary=selected[key]
		if tile.is_empty() or not tile.features.any(func(f):return f.kind=="road"):continue
		for repeat_index in 3:
			var order:=["before","after"] if (counter+repeat_index)%2==0 else ["after","before"]
			for label: String in order:
				var chunk=scripts[label].new(geo,materials,null)
				chunk.origin=Vector3(key.x*512,0,key.y*512);chunk.tile_features=tile.features
				chunk.batch=preload("res://game/geographic_mesh.gd").new()
				for feature in tile.features:
					if feature.kind=="water":chunk.water_levels.append({geometry=feature.geometry,height=feature.get("water_height",0)})
				chunk._index_shores()
				var start:=Time.get_ticks_usec()
				for feature in tile.features:
					if feature.kind=="road":chunk._road(feature)
				var generated:=Time.get_ticks_usec()
				var holder:=Node3D.new()
				chunk.batch.finish(holder,materials,"RoadProfile")
				var finished:=Time.get_ticks_usec()
				var vertices:=0
				for node in holder.get_children():vertices+=node.mesh.surface_get_array_len(0)
				rows.append({tile=[key.x,key.y],variant=label,repeat=repeat_index,
					generate_ms=(generated-start)*.001,finish_ms=(finished-generated)*.001,
					total_ms=(finished-start)*.001,vertices=vertices,surfaces=holder.get_child_count()})
				holder.free()
		counter+=1
		if counter%10==0:print("ROAD_PROFILE tiles=",counter)
	var report:={tiles=counter,rows=rows,baseline=baseline,
		profiled_ways=geo.road_profiles.profile_ways.size(),
		note="CPU-only interleaved three-pass road mesh generation including engineered road profiles; same terrain/tiles/materials; no simulation or rendered FPS measurement."}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ROAD_PROFILE_COMPLETE ",output);quit()
