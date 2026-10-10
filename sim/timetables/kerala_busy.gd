extends RefCounted
## Authored coastal operating day, not the published Indian Railways timetable.
## Exactly two full-route VBs, one in each direction. No VB commuter shuttles.
## Running allowances set booked times, never equipment or driving speed limits.
const COUNT := 100
const VB_CALLS := ["ERS","ALLP","KYJ","QLN","TVC","KZT","NCJ"]
const EXPRESS_CALLS := ["ERS","SRTL","ALLP","AMPA","HAD","KYJ","KPY","QLN","PVU","VAK","KZK","TVCN","TVC","NYY","PASA","KZT","ERL","NCJ"]
const LIMITED_CALLS := ["ERS","SRTL","ALLP","HAD","KYJ","QLN","VAK","TVCN","TVC","NYY","KZT","NCJ"]
const JUNCTIONS := ["ERS","ALLP","KYJ","QLN","TVCN","TVC","NCJ"]
const PROFILES := {
	"passenger": {priority=30,formation="passenger",single=52.0,double=62.0,stop_allowance=1.7},
	"regional": {priority=45,formation="passenger",single=57.0,double=68.0,stop_allowance=1.7},
	"intercity": {priority=70,formation="passenger",single=62.0,double=75.0,stop_allowance=1.6},
	"express": {priority=75,formation="express",single=62.0,double=75.0,stop_allowance=1.8},
	"limited": {priority=85,formation="express",single=66.0,double=80.0,stop_allowance=1.6},
	"vb": {priority=100,formation="fixed",single=70.0,double=85.0,stop_allowance=1.3}}

static func definitions(w) -> Array:
	var all_calls: Array=w.stations.filter(func(s):return s.passenger_open).map(func(s):return s.code)
	var rows := [["K1","Coastal Stopping Passenger · Ernakulam to Nagercoil","icf",1,all_calls,1,1,"08:00",20,"passenger"]]
	add(rows,"Coastal Vande Bharat · Ernakulam to Nagercoil","vb8",1,VB_CALLS,"08:35","vb")
	# Long-distance workings enter/leave the model at ERS/NCJ. Their names and
	# times are authored; these are not claims about real train numbers/rake links.
	add_group(rows,"Cape Express",["10:00","11:50","12:45","14:05","15:30","16:45","18:00","19:15","20:40","22:10"],1,EXPRESS_CALLS,LIMITED_CALLS,"express","limited")
	add(rows,"Coastal Vande Bharat · Nagercoil to Ernakulam","vb16",-1,VB_CALLS,"09:10","vb")
	add(rows,"Northbound Coastal Passenger · Nagercoil to Ernakulam","icf",-1,all_calls,"08:00","passenger")
	add_group(rows,"Malabar Express",["08:40","10:25","12:00","12:10","14:45","15:15","16:50","17:40","19:20","21:10"],-1,EXPRESS_CALLS,LIMITED_CALLS,"express","limited")
	var intercity: Array=within(w,EXPRESS_CALLS,"ERS","TVC")
	var fast_intercity: Array=within(w,LIMITED_CALLS,"ERS","TVC")
	add_group(rows,"Capital Intercity",["09:05","11:20","13:40","15:55","18:25","21:10"],1,intercity,fast_intercity,"intercity","intercity")
	add_group(rows,"Backwater Intercity",["08:10","10:35","13:00","15:30","18:10","21:05"],-1,intercity,fast_intercity,"intercity","intercity")
	# Regional services call at every open station in their sector. Peak extras
	# concentrate in morning/evening instead of uniform twelve-minute waves.
	add_locals(rows,w,"Coastal Passenger","ERS","KYJ",["10:55","14:28","18:50"],["08:20","13:50","18:30"])
	add_locals(rows,w,"Alappuzha Passenger","ERS","ALLP",["09:30","16:20","19:35"],["08:00","16:40","19:00"])
	# Concentrate frequent all-stop work on the double line. The northern
	# single-line passing places cannot sustain a uniform dense shuttle grid
	# alongside all 24 long-distance workings and the intercity services.
	add_locals(rows,w,"Capital Regional","QLN","TVC",["08:05","08:40","09:15","09:55","10:40","11:20","12:00","12:45","13:30","14:15","15:00","15:40","16:15","16:50","17:25","18:00","18:40","19:25","20:20","21:25"],["08:00","08:35","09:10","09:50","10:25","11:15","11:55","12:40","13:25","14:10","14:55","15:35","16:10","16:45","17:20","17:55","18:35","19:20","20:15","21:15"],"regional")
	# Keep the afternoon local clear of the through passenger/express crossing
	# window. These are departure slots; dispatch still responds to actual trains.
	add_locals(rows,w,"Cape Passenger","TVC","NCJ",["08:25","10:40","14:15","16:25","18:35","21:10"],["09:45","11:15","13:00","16:00","18:30","20:15"])
	assert(rows.size()==COUNT)
	# CSV single-face halts on a double line currently serve only the D road.
	# Do not book an unreachable U-direction call or invent another platform.
	for row in rows:
		row[4]=row[4].filter(func(code):
			var st: Dictionary=w.stations.filter(func(s):return s.code==code)[0]
			return st.platform_tracks.any(func(r):return st.platform_details[r].platform_width>0 and w.graph.allows(r,row[3])))
	return rows

static func add(rows: Array, label: String, stock: String, direction: int, calls: Array, departure: String, profile: String) -> void:
	var stops: Array=calls.duplicate()
	if direction<0:stops.reverse()
	var origin: int=3 if direction>0 else (2 if stops[0]=="NCJ" else 4)
	rows.append(["B%03d" % rows.size(),label,stock,direction,stops,origin,1 if direction>0 else 2,departure,PROFILES[profile].priority,profile])

static func add_group(rows: Array, label: String, times: Array, direction: int, calls: Array, fast_calls: Array, profile: String, fast_profile: String) -> void:
	for i in times.size():
		var limited: bool=i%3==1
		var stops: Array=fast_calls if limited else calls
		var endpoints: String="%s–%s" % [stops[0],stops[-1]] if direction>0 else "%s–%s" % [stops[-1],stops[0]]
		add(rows,"%s %02d · %s" % [label,i+1,endpoints],"icf" if i%4==2 else "lhb",direction,stops,times[i],fast_profile if limited else profile)

static func add_locals(rows: Array, w, label: String, origin: String, destination: String, south: Array, north: Array, profile: String="passenger") -> void:
	var stops: Array=within(w,w.stations.filter(func(s):return s.passenger_open).map(func(s):return s.code),origin,destination)
	for direction in [1,-1]:
		var times: Array=south if direction>0 else north
		for i in times.size():
			var endpoints: String="%s–%s" % [origin,destination] if direction>0 else "%s–%s" % [destination,origin]
			add(rows,"%s %02d · %s" % [label,i+1,endpoints],"icf",direction,stops,times[i],profile)

static func within(w, calls: Array, first: String, last: String) -> Array:
	var codes: Array=w.stations.map(func(s):return s.code)
	var a: int=codes.find(first);var b: int=codes.find(last)
	return calls.filter(func(code):return codes.find(code)>=a and codes.find(code)<=b)

static func dwell(profile: String, code: String) -> float:
	if code=="TVC":return 4.0 if profile in ["express","limited","vb"] else 3.0
	if code in JUNCTIONS:return 2.0
	if profile=="vb":return 2.0
	return 1.0 if profile in ["passenger","regional"] else 1.5

static func running_minutes(w, profile: String, first: Dictionary, last: Dictionary) -> float:
	var low: float=minf(first.s,last.s);var high: float=maxf(first.s,last.s)
	var minutes: float=PROFILES[profile].stop_allowance
	for i in w.stations.size()-1:
		var km: float=maxf(0,minf(high,w.stations[i+1].s)-maxf(low,w.stations[i].s))/1000.0
		var speed: float=PROFILES[profile].single if w.scenery.route.sections[i].tracks==1 else PROFILES[profile].double
		minutes+=km/speed*60.0
	return minutes
