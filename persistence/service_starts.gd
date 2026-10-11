extends RefCounted
## Prepared NEW journeys. Never substitutes a baseline for a running game.
const DIRECTORY := "res://data/service_starts"
const VERSION := 1
const Snapshot := preload("res://sim/world_snapshot.gd")

static func catalogue(directory: String=DIRECTORY) -> Dictionary:
	var path:=directory.path_join("catalogue.json")
	if not FileAccess.file_exists(path):return Snapshot.error("Service starts are missing. Reinstall the current release.")
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version")!=VERSION or not data.get("services") is Array:
		return Snapshot.error("Service catalogue is invalid.")
	if not data.get("complete",false):return Snapshot.error("The service catalogue is still being prepared.")
	if data.get("engine")!=Engine.get_version_info().string:return Snapshot.error("Service starts need regeneration for this engine version.")
	if data.services.is_empty():return Snapshot.error("No services are available.")
	var ids:={}
	for row in data.services:
		if not row is Dictionary:return Snapshot.error("Invalid service entry.")
		for key in ["id","name","origin","destination","stock","file","sha256"]:
			if not row.get(key) is String:return Snapshot.error("Incomplete service entry.")
		if row.id.is_empty() or not row.id.is_valid_identifier() or ids.has(row.id) or row.file!=row.id+".bin":return Snapshot.error("Invalid service file.")
		for key in ["departure","start_clock","duration","stops","cars","distance_m","average_kmh"]:
			if not (row.get(key) is float or row.get(key) is int) or not is_finite(row[key]) or row[key]<0:return Snapshot.error("Invalid service timing.")
		if not row.get("calls") is Array or row.calls.size()!=int(row.stops) or row.calls.size()<2:return Snapshot.error("Missing service stops.")
		var previous:=-1.0
		for call in row.calls:
			if not call is Dictionary or not call.get("name") is String:return Snapshot.error("Invalid service stop.")
			for key in ["arrival","departure","distance_m"]:
				if not (call.get(key) is float or call.get(key) is int) or not is_finite(call[key]) or call[key]<0:return Snapshot.error("Invalid calling time.")
			if call.arrival<previous or call.departure<call.arrival:return Snapshot.error("Invalid calling order.")
			previous=call.departure
		ids[row.id]=true
	return {ok=true,reason="",data=data}

static func load_start(row: Dictionary, directory: String=DIRECTORY) -> Dictionary:
	if not row.get("id") is String or not row.id.is_valid_identifier() or row.get("file")!=row.id+".bin":return Snapshot.error("Invalid service file.")
	var path:=directory.path_join(row.file)
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=row.get("sha256",""):return Snapshot.error("Service start checksum failed. Update or reinstall the game.")
	var file:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if file==null or file.get_length()>preload("res://persistence/save_store.gd").MAX_BYTES:return Snapshot.error("Service start could not be read.")
	var data=file.get_var(false);file.close()
	var result:=Snapshot.restore(data)
	if not result.ok:return result
	var w: RailWorld=result.world
	if not w.trains.has(row.id):return Snapshot.error("Selected service is missing.")
	var t: Train=w.trains[row.id]
	if t.lifecycle!="active" or t.service_complete or t.speed>.01 or t.timetable==null or t.timetable.index!=0 or not t.timetable.at_stop:
		return Snapshot.error("Selected service is not ready at its origin.")
	if absf(w.clock_seconds()-float(row.start_clock))>.001 or absf(t.timetable.departure-float(row.departure))>.001:
		return Snapshot.error("Service start does not match the catalogue.")
	return result

static func select(w: RailWorld,id: String) -> void:
	for t: Train in w.trains.values():t.automatic=true
	w.trains[id].automatic=false;w.trains[id].controller=-1.0
	w.dispatcher().enabled=true;w.dispatcher().manual_service=id
