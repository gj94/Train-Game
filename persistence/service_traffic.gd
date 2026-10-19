extends RefCounted
## Small read-only baseline preview. Never predicts from current saves or grants routes.
const Starts:=preload("res://persistence/service_starts.gd")

static func catalogue(services: Array,directory: String=Starts.DIRECTORY) -> Dictionary:
	var path:=directory.path_join("traffic.json")
	if not FileAccess.file_exists(path):return {ok=false,reason="Traffic preview is unavailable for this timetable.",data={}}
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	return validate(data,services.map(func(row):return row.id),FileAccess.get_sha256(directory.path_join("catalogue.json")))

static func validate(data,ids: Array,source_hash: String) -> Dictionary:
	var invalid:={ok=false,reason="Traffic preview needs updating for this timetable.",data={}}
	if not data is Dictionary or data.get("version")!=1 or not data.get("complete",false):return invalid
	if data.get("start_sha256")!=source_hash or data.get("engine")!=Engine.get_version_info().string:return invalid
	if not data.get("services") is Array or data.services.size()!=ids.size() or not data.get("events") is Array:return invalid
	var unique:={}
	for id in data.services:
		if not id is String or not ids.has(id) or unique.has(id):return invalid
		unique[id]=true
	if not data.get("audit") is Dictionary or not data.audit.get("ok",false) or data.audit.get("safety_events")!=[]:return invalid
	var previous:=-1.0
	for event in data.events:
		if not event is Dictionary or event.get("kind") not in ["crossing","overtake"]:return invalid
		if not unique.has(event.get("a")) or not unique.has(event.get("b")) or event.a==event.b:return invalid
		for key in ["time","chainage_m"]:
			if not (event.get(key) is float or event.get(key) is int) or not is_finite(event[key]):return invalid
		if event.time<previous or event.time<0 or not event.get("location") is String or not event.get("station") is String:return invalid
		if event.kind=="overtake":
			if event.get("overtaker") not in [event.a,event.b]:return invalid
			if not (event.get("cleared") is float or event.get("cleared") is int) or not is_finite(event.cleared) or event.cleared<event.time:return invalid
		previous=event.time
	return {ok=true,reason="",data=data}

static func for_service(data: Dictionary,id: String) -> Array:
	var rows:=[]
	for event in data.get("events",[]):
		if id not in [event.a,event.b]:continue
		var row: Dictionary=event.duplicate()
		row.other=event.b if id==event.a else event.a
		row.role="Crossing" if event.kind=="crossing" else "You overtake" if event.overtaker==id else "Overtakes you"
		rows.append(row)
	return rows

static func summary(rows: Array) -> String:
	var crossing:=0;var passed:=0;var passing:=0
	for row in rows:
		if row.kind=="crossing":crossing+=1
		elif row.role=="You overtake":passing+=1
		else:passed+=1
	return "%d crossings · %d you overtake · %d overtake you" % [crossing,passing,passed]

static func time_text(seconds: float) -> String:
	return "~"+preload("res://persistence/service_briefing.gd").time_text(roundf(seconds/60.0)*60.0)
