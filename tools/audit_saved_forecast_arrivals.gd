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
var all_trains:=false
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
        elif arg=="--all-trains":all_trains=true
    if folder.is_empty() or output.is_empty():printerr("Required --folder and --output");quit(1);return
    if not FileAccess.file_exists(folder+"/times/catalogue.json"):
        printerr("Wait for the original replay to write its final timeline catalogue");quit(1);return
    var starts=JSON.parse_string(FileAccess.get_file_as_string(folder+"/starts/catalogue.json"))
    var times=JSON.parse_string(FileAccess.get_file_as_string(folder+"/times/catalogue.json"))
    if not starts is Dictionary or not times is Dictionary:printerr("Missing replay catalogues");quit(1);return
    if not starts.get("complete",false) or not times.get("complete",false):fail("Expected a completed prepared day")
    if starts.get("dispatcher","")!="predictive" or times.get("dispatcher","")!="predictive":fail("Expected a Predictive V2 prepared day")
    if not starts.get("sources") is Dictionary or starts.get("sources")!=times.get("sources"):fail("Mismatched source manifests")
    if starts.get("layout_signature")!=times.get("layout_signature"):fail("Mismatched layout signatures")
    if times.get("departure_catalogue_sha256")!=FileAccess.get_sha256(folder+"/starts/catalogue.json"):fail("Departure catalogue hash mismatch")
    if not failures.is_empty():quit(1);return
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
    var state:=saved(ref_path);var finished:={}
    for service: Dictionary in starts.services:
        if not all_trains and service.id!=train_id:continue
        var matches: Array=state.get("trains",[]).filter(func(t):return t.id==service.id)
        if matches.size()!=1 or not matches[0].service_complete:fail("Reference working has not finished: "+service.id);continue
        var t: Dictionary=matches[0]
        var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
        if not tt is Dictionary or tt.stops.is_empty() or tt.stops.size()!=tt.actual_arrivals.size():fail("Missing actual calls for "+service.id);continue
        finished[service.id]={train=t,timetable=tt}
    if finished.is_empty():fail("No selected completed services")
    if not failures.is_empty():quit(1);return
    var network:=InputData.topology(Layout.build());var roads:={}
    for station: Dictionary in network.stations:
        for road: Dictionary in station.roads:roads[road.id]=road
    var rows:=[];var excluded:=[];var checked:=0;var fingerprints:=[]
    for meta: Dictionary in times.states:
        if not all_trains and meta.clock>finished[train_id].timetable.actual_arrivals[-1]:continue
        var path: String=folder+"/times/"+meta.file
        if FileAccess.get_sha256(path)!=meta.sha256:fail("Checkpoint hash mismatch "+meta.id);break
        var snapshot:=saved(path)
        if snapshot.is_empty():break
        if snapshot.get("layout_signature")!=starts.layout_signature:fail("Checkpoint layout mismatch "+meta.id);break
        if absf(snapshot.world.clock_start+snapshot.world.time-meta.clock)>.001:fail("Checkpoint clock mismatch "+meta.id);break
        checked+=1;fingerprints.append({id=meta.id,sha256=meta.sha256})
        var plans: Dictionary=snapshot.get("predictive",{}).get("plans",{})
        for id: String in plans:
            if finished.has(id):compare_advice(meta,snapshot,plans[id],id,finished[id],roads,rows,excluded)
        if FileAccess.get_sha256(path)!=meta.sha256:fail("Audit changed checkpoint "+meta.id);break
        if all_trains and checked%40==0:print("SAVED_ETA progress ",checked,"/",times.states.size()," samples=",rows.size())
    if FileAccess.get_sha256(ref_path)!=ref_rows[0].sha256:fail("Audit changed reference checkpoint")
    if rows.is_empty():fail("No comparable future booked arrivals")
    if all_trains and checked!=times.states.size():fail("Incomplete timeline traversal")
    var report:={ok=failures.is_empty(),failures=failures,source_folder=folder,train="all" if all_trains else train_id,
        reference=reference,reference_sha256=ref_rows[0].sha256,source_hashes=starts.sources.size(),
        starts_catalogue_sha256=FileAccess.get_sha256(folder+"/starts/catalogue.json"),times_catalogue_sha256=FileAccess.get_sha256(folder+"/times/catalogue.json"),
        selected_services=finished.size(),checked_states=checked,state_fingerprints=fingerprints,samples=rows,excluded=excluded,
        summary=statistics(rows),by_direction=grouped(rows,"direction"),by_stock=grouped(rows,"stock"),by_rake=grouped(rows,"rake"),
        interpretation="Actual minus predicted arrival: positive is optimistic. Sparse saved advice may later be replaced; external traffic holds are included. Matching actual road and marker only. Repeated forecasts of an arrival are not independent. Not a safety or full-day certification."}
    var file:=FileAccess.open(output,FileAccess.WRITE)
    if file==null:printerr("Cannot write audit output");quit(1);return
    file.store_string(JSON.stringify(report,"\t"));file.close()
    print("SAVED_ETA ",JSON.stringify(report.summary)," excluded=",excluded.size());quit(0 if report.ok else 1)

func compare_advice(meta: Dictionary,snapshot: Dictionary,plan: Dictionary,id: String,complete: Dictionary,roads: Dictionary,rows: Array,excluded: Array) -> void:
    if plan.is_empty() or plan.get("action","pass")!="pass" or not plan.get("stop",false) or plan.get("at_station",false):return
    var age: float=snapshot.world.time-plan.time
    if age<0 or age>15:excluded.append({train=id,checkpoint=meta.id,reason="Advice expired",age=age});return
    var tt: Dictionary=complete.timetable;var indices:=[]
    # A station can appear twice on a working. Match the future call after the
    # input call index, rather than silently choosing its first historical call.
    for i in range(maxi(0,plan.get("call_index",0)),tt.stops.size()):
        if tt.stops[i].block.get_slice("_P",0)==plan.station and tt.actual_arrivals[i]>=meta.clock:indices.append(i)
    if indices.size()!=1:excluded.append({train=id,checkpoint=meta.id,reason="Missing or ambiguous future booked call",station=plan.station});return
    var index: int=indices[0];var stop: Dictionary=tt.stops[index];var actual: float=tt.actual_arrivals[index]
    if stop.block!=plan.road:
        excluded.append({train=id,checkpoint=meta.id,reason="Actual road differs",planned=plan.road,actual=stop.block});return
    if not roads.has(plan.road):fail("Unknown proposed road "+plan.road);return
    var t: Dictionary=complete.train
    var mark:=Solver.marker(roads[plan.road],{direction=plan.direction,length=t.length},true)
    if absf(mark-stop.s)>.1:excluded.append({train=id,checkpoint=meta.id,reason="Stopping markers differ",metres=mark-stop.s});return
    var lead: float=plan.slow_clear-plan.created
    var manual: bool=plan.get("inputs",{}).get(id,{}).get("manual",false)
    rows.append({train=id,call_index=index,direction=plan.direction,stock=t.stock_kind,rake=t.rake_profile,
        checkpoint=meta.id,sha256=meta.sha256,created=plan.created,age=age,station=plan.station,road=plan.road,other=plan.other,
        predicted_arrival=plan.slow_clear,actual_arrival=actual,error_seconds=actual-plan.slow_clear,
        lead_seconds=lead,margin=plan.margin,forecast_uncertainty_seconds=maxf(15,lead*.1)+(30 if manual else 0),manual=manual})

func statistics(rows: Array) -> Dictionary:
    if rows.is_empty():return {}
    var errors: Array=rows.map(func(r):return r.error_seconds);errors.sort()
    var arrivals:={};var trains:={};var positive:=0;var beyond:=0
    for row: Dictionary in rows:
        arrivals["%s:%d:%.3f" % [row.train,row.call_index,row.actual_arrival]]=true;trains[row.train]=true
        if row.error_seconds>0:positive+=1
        if row.error_seconds>row.forecast_uncertainty_seconds:beyond+=1
    return {count=errors.size(),distinct_arrivals=arrivals.size(),distinct_trains=trains.size(),minimum=errors[0],median=errors[errors.size()/2],
        p90=errors[mini(errors.size()-1,ceili(errors.size()*.9)-1)],maximum=errors[-1],optimistic_samples=positive,
        beyond_own_arrival_uncertainty=beyond}

func grouped(rows: Array,key: String) -> Dictionary:
    var groups:={};var result:={}
    for row: Dictionary in rows:
        var label:=str(row[key])
        if not groups.has(label):groups[label]=[]
        groups[label].append(row)
    for label: String in groups:result[label]=statistics(groups[label])
    return result
