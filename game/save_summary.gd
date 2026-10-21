extends RefCounted
## Human-readable save metadata; older saves remain valid without these fields.
static func capture(game,reason: String="") -> Dictionary:
	var progress:=preload("res://sim/service_progress.gd").snapshot(game.world,game.train)
	var viewpoint:="Exterior view"
	if game.walker.active:
		viewpoint="On platform" if game.walker.platform.outside else ("Walking in locomotive" if game.walker.car==0 else "Walking · carriage %d" % game.walker.car)
	elif game.cam.mode==2:
		viewpoint="Passenger seat · carriage %d" % game.tv.passenger_coach
	elif game.cam.mode==1:viewpoint="Pilot seat"
	elif game.cam.mode==3:viewpoint="Head-out view"
	return {service=game.train.id,title=game.train.service_name,clock=game.world.clock_text(),day=game.world.clock_day(),
		saved_at=Time.get_datetime_string_from_system(false,true),stops=progress.get("completed",0),total=progress.get("total",0),
		reason=reason,viewpoint=viewpoint,control="AI driving" if game.train.automatic else "Manual driving",
		timetable=str(game.get_tree().get_meta("timetable_id","")),build=preload("res://game/build_version.gd").current()}

static func describe(summary: Dictionary,backup: bool=false) -> String:
	var text:="%s · Day %d · %s" % [summary.get("service","Service"),summary.get("day",1),summary.get("clock","")]
	if summary.get("total",0)>0:text+="\n%d / %d scheduled stops completed" % [summary.get("stops",0),summary.total]
	if not str(summary.get("viewpoint","")).is_empty():text+="\n"+str(summary.viewpoint)+" · "+str(summary.get("control",""))
	if not str(summary.get("reason","")).is_empty():text+="\nCheckpoint: "+str(summary.reason)
	text+="\nSaved "+str(summary.get("saved_at","Unknown time"))
	if backup:text+="\nPrevious version of this slot; loading it keeps the current save intact."
	return text
