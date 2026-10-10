extends RefCounted
## Deterministic passenger journeys; independent of scene residency and frame rate.
const Stock := preload("res://sim/stock/ported_stock.gd")
const Berth := preload("res://sim/berth_clearance.gd")
const CAPACITY := {"icf_1a":18,"icf_2a":46,"icf_3a":64,"icf_2s":108,"icf_cc":73,"icf_sl":72,"icf_gs":108,"lhb_1a":24,"lhb_2a":52,"lhb_3a":72,"lhb_2s":102,"lhb_cc":78,"lhb_sl":80,"lhb_gs":100,"vb_dtc":44,"vb_mc":78,"vb_mc2":78,"vb_tc_cc":78,"vb_tc_ec":52,"vb_ndtc_ec":52,"vb_ndtc_ec2":52}
const OPEN_SECONDS := 3.0
const CLOSE_SECONDS := 3.0

static func setup(t: Train) -> void:
	if not t.passengers.is_empty() or not t.stock_kind.begins_with("ported:"):return
	# Free-drive formations carry riders too; only timetabled calls exchange them.
	var calls: int=t.timetable.stops.size() if t.timetable!=null else 2
	var rng:=RandomNumberGenerator.new();rng.seed=t.id.hash()+731
	var cars:=[];var initial:=0;var serial:=0
	for entry in Stock.formation(t.stock_kind.trim_prefix("ported:"),t.rake_profile):
		var seats:=[];var ids:=[]
		for i in int(CAPACITY.get(entry.model,0)):
			# Leave space to board at the origin. Every occupant has a later call.
			var destination:=_destination(rng,0,calls) if rng.randf()<.34 else -1
			seats.append(destination);ids.append(serial);serial+=1
			initial+=int(destination>=0)
		cars.append({model=entry.model,seats=seats,ids=ids})
	t.passengers={cars=cars,initial=initial,boarded=0,alighted=0,onboard=initial,serial=serial,visit=-1,phase="riding",events=[],elapsed=0.0,duration=0.0,door_open=0.0,road="",side=0,revision=0}

static func commit_release(t: Train, release: float) -> void:
	if release<0:return
	var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
	tt.passenger_release=release

## Mutates only this train's passenger data. Timetable release is returned for
## ordered commit, so parallel exchange cannot expose a later train's new dwell
## to the dispatcher/driver before the original sequential update would do so.
static func update(w, t: Train, dt: float, defer_release: bool=false) -> float:
	setup(t)
	if t.passengers.is_empty():return -1.0
	var p:=t.passengers
	if t.completed_timetable!=null and t.depot.get("phase","") in ["working","stabled"]:return -1.0
	var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
	if tt==null:return -1.0
	if p.phase in ["opening","exchange","closing"]:
		# Defensive against teleports or external train movement: close openings
		# and stop transfers. Ordinary controls are traction-interlocked below.
		if t.speed>.05 or t.path[0].edge!=p.road:
			_cancel(p);return -1.0
		p.elapsed+=maxf(0,dt)
		p.door_open=clampf(minf(p.elapsed/OPEN_SECONDS,(p.duration-p.elapsed)/CLOSE_SECONDS),0,1)
		p.phase="opening" if p.elapsed<OPEN_SECONDS else ("closing" if p.elapsed>=p.duration-CLOSE_SECONDS else "exchange")
		for e in p.events:
			if e.state==0 and p.elapsed>=e.begin:
				e.state=1
				if e.kind=="alight":p.cars[e.car].seats[e.seat]=-1
			if e.state==1 and p.elapsed>=e.end:
				e.state=2
				if e.kind=="board":
					p.cars[e.car].seats[e.seat]=e.destination;p.cars[e.car].ids[e.seat]=e.id
					p.onboard+=1;p.boarded+=1
				else:p.onboard-=1;p.alighted+=1
		if p.elapsed>=p.duration:
			p.phase="ready";p.door_open=0.0;p.revision+=1
		return -1.0
	if not tt.at_stop or tt.index==p.visit or t.speed>.001:return -1.0
	if tt.index==0 and w.clock_seconds()<tt.departure-60:return -1.0
	var stop: Dictionary=tt.stops[tt.index]
	if t.path[0].edge!=stop.block or t.path[0].dir!=stop.direction:return -1.0
	var platform:=platform_at(w,stop.block)
	if platform.is_empty() or not Berth.fits(w,t,stop.block,t.head_s,stop.direction):return -1.0
	_begin(t,tt.index,tt.stops.size(),platform)
	var release: float=w.clock_seconds()+p.duration
	if not defer_release:tt.passenger_release=release
	return release

static func _destination(rng: RandomNumberGenerator, call: int, calls: int) -> int:
	# Local journeys dominate the stopping service; some riders stay to terminus.
	if rng.randf()<.22:return calls-1
	return mini(calls-1,call+1+floori(-log(maxf(.000001,1.0-rng.randf()))*2.4))

static func platform_at(w, road: String) -> Dictionary:
	for st in w.stations:
		if road not in st.get("platform_tracks",[]):continue
		var detail: Dictionary=st.get("platform_details",{}).get(road,{})
		if detail.get("platform_width",0)<=0:return {}
		return {road=road,side=detail.platform_side,major=st.get("major",false),name=st.name}
	return {}

static func _begin(t: Train, call: int, calls: int, platform: Dictionary) -> void:
	var p:=t.passengers
	p.visit=call;p.phase="opening";p.elapsed=0.0;p.duration=OPEN_SECONDS+CLOSE_SECONDS
	p.road=platform.road;p.side=platform.side;p.station=platform.name;p.events=[];p.revision+=1
	var rng:=RandomNumberGenerator.new();rng.seed=t.id.hash()+call*7907+919
	for car in p.cars.size():
		var c: Dictionary=p.cars[car]
		var queue:=[OPEN_SECONDS,OPEN_SECONDS]
		var available:=[]
		for seat in c.seats.size():
			if c.seats[seat]>=0 and (c.seats[seat]<=call or call==calls-1):
				var door: int=seat%2
				# Each coach has two independent end-door queues. Allow time to
				# reach the vestibule before passing its threshold.
				var begin: float=queue[door];var end:=begin+22.0
				p.events.append({kind="alight",car=car,seat=seat,door=door,begin=begin,end=end,id=c.ids[seat],destination=-1,state=0})
				queue[door]+=1.2
				available.append(seat)
			elif c.seats[seat]<0:available.append(seat)
		if call<calls-1:
			# Board after the last alighter has crossed; initial and intermediate
			# demand differs, with more passengers at major stations.
			var demand:=mini(available.size(),rng.randi_range(5,14) if call>0 else rng.randi_range(8,20))
			if platform.major:demand=mini(available.size(),demand+4)
			for door in 2:queue[door]+=22.0 if queue[door]>OPEN_SECONDS else 0.0
			for i in demand:
				var at:=rng.randi_range(0,available.size()-1);var seat: int=available.pop_at(at);var door: int=seat%2
				var begin: float=queue[door];var end:=begin+22.0
				p.events.append({kind="board",car=car,seat=seat,door=door,begin=begin,end=end,id=p.serial,destination=_destination(rng,call,calls),state=0})
				p.serial+=1;queue[door]+=1.2
	for e in p.events:p.duration=maxf(p.duration,e.end+CLOSE_SECONDS)

static func _cancel(p: Dictionary) -> void:
	for e in p.events:
		if e.state==1 and e.kind=="alight":p.cars[e.car].seats[e.seat]=p.visit
	p.phase="interrupted";p.door_open=0.0;p.events=[];p.visit=-1;p.revision+=1

static func departure_blocked(t: Train) -> bool:
	return not t.passengers.is_empty() and t.passengers.phase in ["opening","exchange","closing"]

static func snapshot(t: Train) -> Dictionary:
	if t.passengers.is_empty():return {}
	var p:=t.passengers
	return {onboard=p.onboard,boarded=p.boarded,alighted=p.alighted,phase=p.phase,seconds=maxf(0,p.duration-p.elapsed),doors_open=p.door_open>.001}
