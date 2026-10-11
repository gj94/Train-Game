extends RefCounted
## Immutable five-minute baseline states. Loading never changes railway authority.
const DIRECTORY:="res://data/railway_times"
const Snapshot:=preload("res://sim/world_snapshot.gd")

static func catalogue(directory: String=DIRECTORY) -> Dictionary:
	var data=JSON.parse_string(FileAccess.get_file_as_string(directory+"/catalogue.json"))
	if not data is Dictionary or data.get("version")!=1 or not data.get("complete",false) or not data.get("states") is Array or data.states.is_empty():return Snapshot.error("Time browser states are unavailable. Update the game.")
	if data.get("engine")!=Engine.get_version_info().string:return Snapshot.error("Time browser needs regeneration for this engine version.")
	var previous:=-1.0
	for row in data.states:
		if not row is Dictionary or not valid_row(row) or (previous>=0 and absf(row.clock-previous-300)>.001):return Snapshot.error("Invalid five-minute timeline.")
		previous=row.clock
	return {ok=true,reason="",data=data}

static func valid_row(row: Dictionary) -> bool:
	return row.get("id") is String and row.id.is_valid_identifier() and row.get("file")==row.id+".bin" and row.get("sha256") is String and (row.get("clock") is float or row.get("clock") is int) and is_finite(row.clock) and row.clock>=0 and fposmod(row.clock,300)<.001

static func load_state(row: Dictionary,directory: String=DIRECTORY) -> Dictionary:
	if not valid_row(row):return Snapshot.error("Invalid time state.")
	var path:=directory.path_join(row.file)
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=row.sha256:return Snapshot.error("Time state checksum failed. Update the game.")
	var file:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if file==null or file.get_length()>preload("res://persistence/save_store.gd").MAX_BYTES:return Snapshot.error("Time state could not be read.")
	var data=file.get_var(false);file.close()
	var result:=Snapshot.restore(data)
	if result.ok and absf(result.world.clock_seconds()-row.clock)>.001:return Snapshot.error("Timeline clock mismatch.")
	return result

static func available(w: RailWorld) -> Array:
	return w.active_trains().filter(func(t):return not t.service_complete and not preload("res://sim/depot_workings.gd").active(t))

static func station_spot(w: RailWorld,index: int) -> Dictionary:
	if index<0 or index>=w.stations.size():return {}
	var station: Dictionary=w.stations[index]
	var spot:=preload("res://game/platform_camera.gd").nearest(w,station.origin)
	# Never silently substitute a different station for a station explicitly chosen.
	if spot.get("station","")!=station.name or not spot.has("road"):return {}
	# A walkable point can still put the camera right against a bench or column.
	# Prefer enough room to look around and begin walking in either direction.
	var nav:=preload("res://game/platform_navigation.gd").new(w,spot.road)
	for offset in [0.0,1.0,-1.0,2.0,-2.0,4.0,-4.0,6.0,-6.0]:
		var point: Vector2=spot.point+Vector2(offset,0)
		if nav.allowed(point) and not nav.obstacles.any(func(r):return r.grow(.8).has_point(point)):
			spot.point=point;spot.eye=nav.point(point)+Vector3.UP*1.65;return spot
	return spot
