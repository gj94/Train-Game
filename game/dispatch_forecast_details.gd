extends VBoxContainer
## Presentation only. Read current owner-validated advice; never request routes.
signal station_requested(index: int)
signal service_requested(id: String)
const UI:=preload("res://game/dispatch_theme.gd")
const Clock:=preload("res://sim/world_clock.gd")
var toggle: Button
var body: VBoxContainer
var detail: Label
var station_button: Button
var service_button: Button
var expanded:=false
var inspected:=""
var shown: Dictionary={}

func _ready() -> void:
	add_theme_constant_override("separation",8)
	toggle=UI.button(self,"Forecast details  +",func():set_expanded(not expanded))
	body=VBoxContainer.new();body.add_theme_constant_override("separation",8);add_child(body)
	detail=UI.wrap(body,"",13,UI.MUTED)
	station_button=UI.button(body,"Locate passing station",func():station_requested.emit(shown.station_index))
	service_button=UI.button(body,"Inspect other service",func():service_requested.emit(shown.other_id))
	body.hide()

func set_expanded(value: bool) -> void:
	if not value and is_inside_tree():
		var owner:=get_viewport().gui_get_focus_owner()
		if owner!=null and body.is_ancestor_of(owner):toggle.grab_focus()
	expanded=value;body.visible=value
	toggle.text="Forecast details  −" if value else "Forecast details  +"

func update_plan(w: RailWorld,id: String) -> void:
	if toggle==null:return
	if inspected!=id:set_expanded(false);inspected=id
	var enabled: bool=w.dispatcher().predictive.enabled
	if not enabled:set_expanded(false)
	visible=enabled
	if not enabled:return
	shown=describe(w,id)
	var owner:=get_viewport().gui_get_focus_owner()
	if not shown.available and owner in [station_button,service_button]:toggle.grab_focus()
	detail.text=shown.text
	station_button.visible=shown.available
	service_button.visible=shown.available
	if shown.available:
		station_button.text="Locate "+shown.station_code+" on map"
		service_button.text="Inspect "+shown.other_id+" · keep your train"

static func time_label(value: float,now: float) -> String:
	var text:=Clock.format_time(value)
	if Clock.day(value)!=Clock.day(now):text+=" · day "+str(Clock.day(value))
	return text

static func describe(w: RailWorld,id: String) -> Dictionary:
	var engine=w.dispatcher()
	if not engine.enabled:return {available=false,text="Automatic dispatch is off. Existing movement authorities remain; no new passing plan is being applied."}
	var candidates: Array=[]
	for candidate: Dictionary in engine.predictive.plans.values():
		if id not in [candidate.train,candidate.other]:continue
		var train: Train=w.trains.get(candidate.train)
		if train==null:continue
		var valid: Dictionary=engine.predictive.plan(w,train)
		if not valid.is_empty():candidates.append(valid)
	if candidates.is_empty():return {available=false,text="No current passing proposal. Classic routing continues while V2 reassesses. Signals still govern movement."}
	candidates.sort_custom(func(a,b):return a.fast_entry<b.fast_entry if a.fast_entry!=b.fast_entry else a.train<b.train)
	var p: Dictionary=candidates[0]
	var index:=w.stations.find_custom(func(st):return st.code==p.station)
	var name: String=w.stations[index].name if index>=0 else p.station
	var other: String=p.other if id==p.train else p.train
	var passing: bool=p.get("action","pass")=="pass"
	var lines:=PackedStringArray()
	lines.append(("Planned pass at " if passing else "Keep following order near ")+name+" ("+p.station+")")
	if passing:
		lines.append(p.train+" receiving road: "+p.road+"\n"+p.other+" passing road: "+p.passing_road)
		lines.append(p.train+" clear in receiving road: "+time_label(p.slow_clear,w.clock_seconds())+"\n"+p.other+" reaches station: "+time_label(p.fast_entry,w.clock_seconds()))
		lines.append("Spare entry margin after allowances: %.0f sec" % maxf(0,p.margin))
	else:lines.append("No overtake is proposed; the projected punctuality gain does not justify the extra wait.")
	if p.has("order"):
		lines.append("%s projected lateness at %s:\nFollow %.1f min · Pass %.1f min\nAdded %s detention: %.1f min" % [p.other,p.order.checkpoint,p.order.follow_delay/60,p.order.pass_delay/60,p.train,p.order.slow_extra/60])
	lines.append("Forecast age %.1f sec. Estimates can change with traffic. Signals still govern movement." % maxf(0,w.time-p.time))
	return {available=index>=0,text="\n\n".join(lines),station_index=index,station_code=p.station,other_id=other,plan=p}
