extends SceneTree
## Read saved advice and actual booked arrivals; never step or mutate a railway.
## Five-minute samples are sparse observations, not a dispatch safety certificate.
const Layout:=preload("res://sim/layouts/kerala_coast.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Solver:=preload("res://sim/overtake_solver.gd")
var folder:=""
var output:=""
var reference:=""
var train_id:="K1"
var failures:=[]

func _initialize() -> void:call_deferred("run")
func fail(reason: String) -> void:failures.append(reason);printerr(reason)
func saved(path: String) -> Dictionary:
    var f:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
    if f==null:fail("Cannot read "+path);return {}
    var data=f.get_var(false);f.close()
    if not data is Dictionary:fail("Invalid saved data "+path);return {}
    return data

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--folder="):folder=arg.trim_prefix("--folder=")
        elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
        elif arg.begins_with("--reference="):reference=arg.trim_prefix("--reference=")
        elif arg.begins_with("--train="):train_id=arg.trim_prefix("--train=")
    if folder.is_empty() or output.is_empty():printerr("Required --folder and --output");quit(1);return
    if not FileAccess.file_exists(folder+"/times/catalogue.json"):
        printerr("Wait for the original replay to write its final timeline catalogue");quit(1);return
    var starts=JSON.parse_string(FileAccess.get_file_as_string(folder+"/starts/catalogue.json"))
    var times=JSON.parse_string(FileAccess.get_file_as_string(folder+"/times/catalogue.json"))
    if not starts is Dictionary or not times is Dictionary:printerr("Missing replay catalogues");quit(1);return
    for path: String in starts.sources:
        var digest:=FileAccess.get_sha256("res://"+path) if path.ends_with(".bin") else FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
        if digest!=starts.sources[path]:fail("Changed replay input "+path)
    if not times.get("states") is Array or times.states.is_empty():fail("Empty timeline catalogue");quit(1);return
    if reference.is_empty():reference=times.states[-1].id
    var ref_rows: Array=times.states.filter(func(r):return r.id==reference)
    if ref_rows.size()!=1:fail("Reference checkpoint is absent")
    if not failures.is_empty():quit(1);return
    var ref_path:=folder+"/times/"+reference+".bin"
    if FileAccess.get_sha256(ref_path)!=ref_rows[0].sha256:fail("Reference checkpoint hash mismatch");quit(1);return
    var state:=saved(ref_path)
    var matches: Array=state.get("trains",[]).filter(func(t):return t.id==train_id)
    if matches.size()!=1 or not matches[0].service_complete:fail("Reference working has not finished");quit(1);return
    var finished: Dictionary=matches[0]
    var tt: Dictionary=finished.completed_timetable if finished.completed_timetable!=null else finished.timetable
    var network:=InputData.topology(Layout.build())
    var rows:=[];var excluded:=[];var checked:=0
    for meta: Dictionary in times.states:
        if meta.clock>tt.actual_arrivals[-1]:continue
        var path: String=folder+"/times/"+meta.file
        if FileAccess.get_sha256(path)!=meta.sha256:fail("Checkpoint hash mismatch "+meta.id);break
        var snapshot:=saved(path)
        if snapshot.is_empty():break
        checked+=1
        var plan: Dictionary=snapshot.get("predictive",{}).get("plans",{}).get(train_id,{})
        if plan.is_empty() or plan.get("action","pass")!="pass" or not plan.get("stop",false) or plan.get("at_station",false):continue
        var age: float=snapshot.world.time-plan.time
        if age<0 or age>15:excluded.append({checkpoint=meta.id,reason="Advice expired",age=age});continue
        var index: int=tt.stops.find_custom(func(s):return s.block.get_slice("_P",0)==plan.station)
        if index<0:excluded.append({checkpoint=meta.id,reason="No actual booked call",station=plan.station});continue
        var stop: Dictionary=tt.stops[index]
        var actual: float=tt.actual_arrivals[index]
        if actual<meta.clock:continue
        if stop.block!=plan.road:
            excluded.append({checkpoint=meta.id,reason="Actual road differs",planned=plan.road,actual=stop.block});continue
        var roads: Array=network.stations.filter(func(s):return s.code==plan.station)[0].roads
        var road: Dictionary=roads.filter(func(r):return r.id==plan.road)[0]
        var mark:=Solver.marker(road,{direction=plan.direction,length=finished.length},true)
        if absf(mark-stop.s)>.1:excluded.append({checkpoint=meta.id,reason="Stopping markers differ",metres=mark-stop.s});continue
        rows.append({checkpoint=meta.id,sha256=meta.sha256,created=plan.created,age=age,station=plan.station,road=plan.road,other=plan.other,
            predicted_arrival=plan.slow_clear,actual_arrival=actual,error_seconds=actual-plan.slow_clear,
            lead_seconds=plan.slow_clear-plan.created,margin=plan.margin})
    if rows.is_empty():fail("No comparable future booked arrivals")
    var errors: Array=rows.map(func(r):return r.error_seconds);errors.sort()
    var report:={ok=failures.is_empty(),failures=failures,source_folder=folder,train=train_id,reference=reference,reference_sha256=ref_rows[0].sha256,
        source_hashes=starts.sources.size(),checked_states=checked,samples=rows,excluded=excluded,
        interpretation="Actual minus predicted arrival: positive is optimistic. Sparse saved advice may later be replaced; external traffic holds are included. Matching actual road and marker only. Not a safety or full-day certification."}
    var distinct_arrivals:={}
    for row: Dictionary in rows:distinct_arrivals["%s:%s:%.3f" % [row.station,row.road,row.actual_arrival]]=true
    if not errors.is_empty():report.summary={count=errors.size(),distinct_arrivals=distinct_arrivals.size(),minimum=errors[0],median=errors[errors.size()/2],p90=errors[mini(errors.size()-1,ceili(errors.size()*.9)-1)],maximum=errors[-1]}
    FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
    print("SAVED_ETA ",JSON.stringify(report.get("summary",{}))," excluded=",excluded.size());quit(0 if report.ok else 1)
