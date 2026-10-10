extends RefCounted
## Check presentation data before replacing the running scene.
const Stock:=preload("res://sim/stock/ported_stock.gd")
static func shape(value, schema: Dictionary) -> bool:
	if not value is Dictionary:return false
	for key in schema:
		if not value.has(key) or typeof(value[key])!=schema[key]:return false
		if typeof(value[key])==TYPE_FLOAT and not is_finite(value[key]):return false
	return true

static func check(w: RailWorld, s: Dictionary) -> String:
	if not shape(s,{player=TYPE_STRING,meta=TYPE_DICTIONARY,authored_pack=TYPE_DICTIONARY,followed=TYPE_STRING,geographic_drive=TYPE_BOOL,traffic_drive=TYPE_BOOL,imported_fleet=TYPE_STRING,wap7_drive=TYPE_BOOL,lhb_drive=TYPE_BOOL,labels_enabled=TYPE_BOOL,time_scale=TYPE_INT}):return "Saved scenario information is incomplete"
	if not w.trains.has(s.player) or s.time_scale not in [1,2,4,8,16,32]:return "Invalid saved service or simulation speed"
	if s.geographic_drive!=w.scenery.get("geographic",false):return "Saved scenario does not match the railway"
	if not s.imported_fleet.is_empty() and s.imported_fleet not in Stock.CHOICES:return "Unknown saved solo formation"
	if not shape(s.get("camera"),{mode=TYPE_INT,yaw=TYPE_FLOAT,pitch=TYPE_FLOAT,distance=TYPE_FLOAT,cab_fov=TYPE_FLOAT,head_out_side=TYPE_INT,follow=TYPE_BOOL,_look=TYPE_VECTOR2,pivot=TYPE_VECTOR3}):return "Invalid saved camera"
	if s.camera.mode not in [0,1,2,3,4] or s.camera.distance<=0 or s.camera.head_out_side not in [-1,1] or not s.camera.pivot.is_finite() or not s.camera._look.is_finite():return "Invalid saved camera position"
	if s.camera.has("free_flight"):
		if not shape(s.camera,{free_flight=TYPE_BOOL,free_fov=TYPE_FLOAT}):return "Invalid saved free camera"
		if s.camera.free_fov<18 or s.camera.free_fov>85 or (s.camera.free_flight and (s.camera.mode!=0 or s.camera.follow)):return "Invalid saved free camera mode"
	if not shape(s.get("view"),{passenger_coach=TYPE_INT,passenger_bay=TYPE_INT,passenger_seat=TYPE_BOOL,passenger_seat_index=TYPE_INT,cab_position=TYPE_INT}):return "Invalid saved passenger view"
	if s.view.has("passenger_head_out") and (typeof(s.view.passenger_head_out)!=TYPE_BOOL or (s.view.passenger_head_out and s.camera.mode!=3)):return "Invalid saved passenger head-out view"
	var t: Train=w.trains[s.player]
	var formation:=Stock.formation(t.stock_kind.trim_prefix("ported:"),t.rake_profile)
	if s.view.passenger_coach<0 or s.view.passenger_coach>=formation.size() or s.view.passenger_bay<0 or s.view.cab_position<0 or s.view.cab_position>3:return "Saved viewpoint is outside this train"
	if not shape(s.get("walk"),{active=TYPE_BOOL,car=TYPE_INT,position=TYPE_VECTOR2,crouched=TYPE_BOOL,eye_height=TYPE_FLOAT,lamp_enabled=TYPE_BOOL,outside=TYPE_BOOL}):return "Invalid saved walking state"
	if not s.walk.position.is_finite() or (s.walk.active and (s.walk.car<0 or s.walk.car>=formation.size())) or s.walk.eye_height<.5 or s.walk.eye_height>2:return "Invalid saved walking position"
	if s.walk.active!=(s.camera.mode==4) or (s.walk.outside and not s.walk.active):return "Saved camera and walking state disagree"
	if s.walk.outside:
		if not shape(s.walk,{road=TYPE_STRING,side=TYPE_INT,platform_position=TYPE_VECTOR2}):return "Saved platform information is missing"
		var surface:=preload("res://game/platform_navigation.gd").new(w,s.walk.road,s.walk.side)
		if not surface.allowed(s.walk.platform_position):return "Saved platform position is no longer available"
	if not shape(s.get("desk"),{inspected=TYPE_STRING,source=TYPE_STRING,map=TYPE_DICTIONARY}):return "Invalid saved dispatch view"
	if not w.trains.has(s.desk.inspected) or not w.signals.has(s.desk.source):return "Saved dispatch selection no longer exists"
	if not shape(s.desk.map,{focus_index=TYPE_INT,center_s=TYPE_FLOAT,span=TYPE_FLOAT,vertical_pan=TYPE_FLOAT,follow_train=TYPE_BOOL,show_blocks=TYPE_BOOL}) or s.desk.map.span<=0:return "Invalid saved dispatch map"
	if not shape(s.get("sound"),{track_level=TYPE_FLOAT,clang_balance_db=TYPE_FLOAT,squeal_amount=TYPE_FLOAT}):return "Invalid saved sound settings"
	return ""
