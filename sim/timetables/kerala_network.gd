extends RefCounted
## A representative, deliberately busy network day; not a published IR timetable.
## Full journey names describe off-map continuations. Times at portals are map
## entry/exit times, never invented departures from a distant real city.
const Stock := preload("res://sim/stock/ported_stock.gd")
const Berth := preload("res://sim/berth_clearance.gd")
const Pack := preload("res://sim/service_pack.gd")
const Clock := preload("res://sim/world_clock.gd")
const COUNT := 208
const MAIL := ["ERS","SRTL","ALLP","AMPA","HAD","KYJ","KPY","QLN","PVU","VAK","KZK","TVCN","TVC","NYY","PASA","KZT","ERL","NCJ"]
const SUPERFAST := ["ERS","ALLP","KYJ","QLN","VAK","TVC","KZT","NCJ"]
const VB := ["ERS","ALLP","QLN","TVC","NCJ"]
const PRIORITIES := {local=30,mail=55,superfast=75,vb=95}
const NORTH := ["Mangaluru","Kannur","Kozhikode","Shoranur","Thrissur","Guruvayur","Bengaluru","Chennai","Mumbai","Pune","New Delhi","Hyderabad","Ahmedabad","Indore","Patna","Guwahati","Jaipur","Vadodara","Nagpur","Tatanagar"]
const SOUTH := ["Tirunelveli","Madurai","Chennai","Kanniyakumari","Tiruchirappalli","Tuticorin","Rameswaram","Coimbatore"]

static func definitions() -> Array:
	var rows:=[]
	# Forty all-stop workings: two coast-length pairs and eighteen regional pairs.
	pairs(rows,"local","ERS","NCJ",["06:00","16:10"],["05:15","15:35"])
	pairs(rows,"local","ERS","QLN",["04:55","07:10","14:20","18:10"],["05:35","08:10","15:20","19:10"])
	pairs(rows,"local","ALLP","TVC",["05:15","07:40","15:10","18:35"],["05:05","08:25","16:20","19:30"])
	pairs(rows,"local","QLN","NCJ",["04:40","06:50","09:20","13:15","16:40","20:10"],["05:45","07:30","10:10","14:45","17:55","21:20"])
	pairs(rows,"local","TVC","NCJ",["05:40","08:50","17:10","22:10"],["06:10","09:05","18:20","22:40"])
	# Fifty-two mail/express pairs. North/south mean the railway beyond ERS/NCJ.
	pairs(rows,"mail","NORTH","TVC",["00:15","01:25","02:35","03:45","04:45","05:50","07:05","08:20","09:35","10:50","12:10","13:25","14:40","15:55","17:15","18:30","19:45","21:00","22:10","23:20"],["00:40","01:50","03:00","04:10","05:20","06:35","07:50","09:05","10:20","11:35","12:50","14:05","15:20","16:35","17:50","19:05","20:20","21:35","22:45","23:50"])
	pairs(rows,"mail","NORTH","NCJ",["00:55","03:15","05:15","07:45","10:05","12:45","15:15","17:55","20:25","22:50"],["00:20","02:40","05:00","07:20","09:50","12:20","14:50","17:20","19:50","22:20"],4)
	pairs(rows,"mail","NORTH","SOUTH",["02:05","06:25","10:35","14:05","18:05","22:35"],["01:05","04:35","08:35","12:35","16:35","20:35"],7)
	pairs(rows,"mail","TVC","SOUTH",["00:05","02:25","04:55","07:15","09:45","12:15","14:35","17:05","19:35","22:05"],["00:25","02:55","05:25","07:55","10:25","12:55","15:25","17:45","20:15","22:45"],1)
	pairs(rows,"mail","QLN","SOUTH",["01:20","08:05","15:05","21:20"],["01:45","08:55","15:55","23:15"],2)
	pairs(rows,"mail","ALLP","SOUTH",["06:10","18:45"],["06:45","18:55"],3)
	# Twenty-eight superfast pairs, with night through traffic and fewer calls.
	pairs(rows,"superfast","NORTH","TVC",["00:35","02:45","04:25","06:45","08:55","11:15","13:05","15:35","17:35","19:15","21:15","23:40"],["00:10","02:10","04:30","06:10","08:30","10:40","13:10","15:00","17:10","19:30","21:10","23:10"],8)
	pairs(rows,"superfast","NORTH","SOUTH",["01:45","04:05","07:25","10:15","13:45","16:55","20:05","23:00"],["00:45","03:35","06:55","10:05","13:35","16:55","20:05","23:35"],10)
	pairs(rows,"superfast","TVC","SOUTH",["01:05","03:35","06:05","08:45","11:45","15:05","18:05","21:05"],["01:25","04:05","06:15","09:35","11:55","14:55","18:25","21:55"],4)
	# Four daytime VB pairs. The Mangaluru–TVC coastal route is a real reference;
	# extra frequencies and southward regional workings are authored game services.
	pairs(rows,"vb","NORTH","TVC",["07:35","16:25"],["05:55","16:55"],0)
	pairs(rows,"vb","TVC","SOUTH",["06:25","15:45"],["07:05","16:15"],0)
	assert(rows.size()==COUNT)
	return rows

static func pairs(rows: Array, category: String, first: String, last: String, south: Array, north: Array, offset: int=0) -> void:
	assert(south.size()==north.size())
	for i in south.size():
		var first_name: String=NORTH[(i+offset)%NORTH.size()] if first=="NORTH" else first
		var last_name: String=SOUTH[(i+offset)%SOUTH.size()] if last=="SOUTH" else last
		for direction in [1,-1]:
			var id:="%s%03d" % [{local="L",mail="M",superfast="S",vb="V"}[category],rows.filter(func(r):return r.category==category).size()+1]
			if category=="local" and rows.is_empty():id="K1"
			rows.append({id=id,category=category,first=first,last=last,direction=direction,
				origin=first_name if direction>0 else last_name,destination=last_name if direction>0 else first_name,
				departure=south[i] if direction>0 else north[i],stock="vb16" if category=="vb" else ("icf" if category=="local" or (category=="mail" and i%4==1) else "lhb")})

static func station_name(w, code: String) -> String:
	for st in w.stations:
		if st.code==code:return st.name
	return code

static func pack(w, predictive: bool=false) -> Dictionary:
	var services:=[]
	for row in definitions():
		var result:=service(w,row)
		assert(result.ok,str(result))
		if not result.ok:return result
		services.append(result.data)
	return {format="train-game-services",version=1,layout="kerala_coast",boundary_network=true,layout_signature=Pack.signature(w),
		name="Coastal Network 208 · "+("Predictive V2" if predictive else "Classic"),world_start="00:00",day=1,
		dispatcher="predictive" if predictive else "classic",services=services,
		provenance={kind="authored representative operating day",notice="Not a published Indian Railways timetable. Portal times are corridor entry or exit times; distant journey names are off-map continuations. Additional frequencies and southern VB workings are fictional.",reference="20631/20632 Mangaluru–Thiruvananthapuram Vande Bharat coastal route; PIB 6 February 2026. Calling patterns informed by Southern Zone timetable 2018 tables 12–13; times are newly authored."}}

static func service(w, row: Dictionary) -> Dictionary:
	var t:=Train.new(row.id,1)
	var profile: String="fixed" if row.category=="vb" else ("passenger" if row.category=="local" else "express")
	Stock.configure(t,row.stock,profile)
	var codes: Array=w.stations.map(func(s):return s.code)
	var first: int=0 if row.first=="NORTH" else codes.find(row.first)
	var last: int=codes.size()-1 if row.last=="SOUTH" else codes.find(row.last)
	var requested: Array=codes if row.category=="local" else (MAIL if row.category=="mail" else (SUPERFAST if row.category=="superfast" else VB))
	var calls:=[]
	for i in range(first,last+1):
		var st: Dictionary=w.stations[i]
		if not st.passenger_open or (st.code not in requested and i not in [first,last]):continue
		if not st.platform_tracks.any(func(r):return st.platform_details[r].platform_width>0 and w.graph.allows(r,row.direction) and Berth.capacity(w,r)>=t.length):continue
		calls.append(st.code)
	if row.first=="NORTH":calls.push_front("NORTH")
	if row.last=="SOUTH":calls.append("SOUTH")
	if row.direction<0:calls.reverse()
	var stops:=[];var minutes:=0.0;var previous_chainage:=0.0
	for i in calls.size():
		var code: String=calls[i];var road:="";var chainage:=0.0;var boundary:=""
		if code in ["NORTH","SOUTH"]:
			road=("ERS" if code=="NORTH" else "NCJ")+"_PORTAL_"+("D" if row.direction>0 else "U")
			boundary="entry" if i==0 else "exit"
		else:
			var st: Dictionary=w.stations[codes.find(code)]
			var candidates: Array=st.platform_tracks.filter(func(r):return st.platform_details[r].platform_width>0 and w.graph.allows(r,row.direction) and Berth.capacity(w,r)>=t.length)
			var lane: String="D" if row.direction>0 else "U"
			candidates.sort_custom(func(a,b):
				var x: Dictionary=st.platform_details[a];var y: Dictionary=st.platform_details[b]
				var ax: int=(0 if x.lane==lane else 100)+(0 if i==0 and x.road>2 else 10)+int(x.road)
				var ay: int=(0 if y.lane==lane else 100)+(0 if i==0 and y.road>2 else 10)+int(y.road)
				return ax<ay)
			for candidate in candidates:
				if i==0 and not preload("res://sim/depot_workings.gd").terminal_road_compatible(w,st,candidate,row.direction):continue
				var goal:={block=candidate,direction=row.direction,s=Berth.marker(w,t,candidate,row.direction)}
				if not stops.is_empty() and is_inf(w._stop_distance(stops[-1].block,row.direction,stops[-1].position_m,goal,[])):continue
				road=candidate;break
		if road.is_empty():return {ok=false,reason=row.id+": no passenger face for "+code}
		var marker:=Berth.marker(w,t,road,row.direction)
		var edge: Dictionary=w.graph.edges[road]
		chainage=lerpf(edge.chainage_start,edge.chainage_end,marker/edge.length)
		if i>0:minutes+=stops[-1].dwell_minutes+running_minutes(w,t,previous_chainage,chainage)
		var dwell:=0.0 if i==0 or i==calls.size()-1 or not boundary.is_empty() else (3.0 if code=="TVC" else (2.0 if code in ["ERS","ALLP","KYJ","QLN","TVCN","NCJ"] or row.category=="vb" else 1.0))
		var stop:={name=station_name(w,code) if boundary.is_empty() else ("Enters railway north of ERS" if code=="NORTH" and boundary=="entry" else ("Continues north beyond ERS" if code=="NORTH" else ("Enters railway south of NCJ" if boundary=="entry" else "Continues south beyond NCJ"))),block=road,direction=row.direction,position_m=marker,minutes_from_origin=snappedf(minutes,.1),dwell_minutes=dwell}
		if not boundary.is_empty():stop.boundary=boundary
		stops.append(stop);previous_chainage=chainage
	var origin:=station_name(w,row.origin);var destination:=station_name(w,row.destination)
	var category: String={local="Passenger",mail="Mail / Express",superfast="Superfast",vb="Vande Bharat"}[row.category]
	return {ok=true,data={id=row.id,name=origin+"–"+destination+" "+category,stock=row.stock,rake=profile,priority=PRIORITIES[row.category],scheduled_entry=true,departure=row.departure,day=1,stops=stops,
		journey={origin=origin,destination=destination,category=row.category,representative=true}}}

static func running_minutes(w, t: Train, first: float, last: float) -> float:
	# Shared line-based cruise allowance. Categories have no artificial cap or
	# category multiplier: extra calls and the real traction/mass determine time.
	var low:=minf(first,last);var high:=maxf(first,last);var seconds:=0.0;var covered:=0.0
	for i in w.stations.size()-1:
		var metres:=maxf(0,minf(high,w.stations[i+1].s)-maxf(low,w.stations[i].s))
		covered+=metres
		seconds+=metres/((65.0 if w.scenery.route.sections[i].tracks==1 else 78.0)/3.6)
	seconds+=maxf(0,high-low-covered)/(70.0/3.6)
	var cruise:=75.0/3.6
	var acceleration:=maxf(.05,minf(t.max_accel,t.max_power/(t.mass*cruise))*.78-.006-.00004*cruise*cruise)
	seconds+=cruise*.5/acceleration+cruise*.5/(t.service_decel*.4)+8.0
	return seconds/60.0
