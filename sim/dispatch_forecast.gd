extends RefCounted
## Detached numerical railway forecast. No RailWorld, scenes, signals or mutation
## of live trains. A worker owns this instance and its route cache exclusively.
const SAMPLE_METRES := 60.0
const MAX_DISTANCE := 60000.0
var topology: Dictionary
var _paths := {}

func _init(network: Dictionary) -> void:topology=network

## Shortest legal directional route; branch joins cannot jump between switch arms.
## The input adjacency already excludes depot spurs and incompatible directions.
func route(edge: String, direction: int, target: String) -> Array:
	var cache_key:=edge+":"+str(direction)+":"+target
	if _paths.has(cache_key):return _paths[cache_key]
	var start:=edge+":"+str(direction)
	var queue: Array=[{key=start,edge=edge,dir=direction,cost=0.0}]
	var costs:={start:0.0};var previous:={};var states:={start:{edge=edge,dir=direction}}
	var found:=""
	while not queue.is_empty():
		var current: Dictionary=_pop(queue)
		if current.cost>costs.get(current.key,INF):continue
		if current.edge==target:found=current.key;break
		if current.cost>MAX_DISTANCE:continue
		for next: Dictionary in topology.edges[current.edge].next[str(current.dir)]:
			var key: String=next.edge+":"+str(next.dir)
			var cost: float=current.cost+topology.edges[next.edge].length
			if cost>=costs.get(key,INF):continue
			costs[key]=cost;previous[key]=current.key;states[key]=next
			_push(queue,{key=key,edge=next.edge,dir=next.dir,cost=cost})
	var result:=[]
	while not found.is_empty():
		result.push_front(states[found]);found=previous.get(found,"")
	_paths[cache_key]=result
	return result

func _push(heap: Array, value: Dictionary) -> void:
	heap.append(value);var i:=heap.size()-1
	while i>0:
		var parent: int=(i-1)/2
		if heap[parent].cost<=value.cost:break
		heap[i]=heap[parent];i=parent
	heap[i]=value

func _pop(heap: Array) -> Dictionary:
	var result: Dictionary=heap[0];var last: Dictionary=heap.pop_back()
	if heap.is_empty():return result
	var i:=0
	while i*2+1<heap.size():
		var child:=i*2+1
		if child+1<heap.size() and heap[child+1].cost<heap[child].cost:child+=1
		if last.cost<=heap[child].cost:break
		heap[i]=heap[child];i=child
	heap[i]=last;return result

func pieces(edge: String, direction: int, from_s: float, target: String, target_s: float) -> Array:
	var path:=route(edge,direction,target)
	if path.is_empty():return []
	var result:=[]
	for i in path.size():
		var entry: Dictionary=path[i];var e: Dictionary=topology.edges[entry.edge]
		var a: float=from_s if i==0 else (0.0 if entry.dir==1 else e.length)
		var b: float=target_s if i==path.size()-1 else (e.length if entry.dir==1 else 0.0)
		if (b-a)*entry.dir<-.01:return []
		result.append({length=absf(b-a),limit=e.limit,edge=entry.edge,dir=entry.dir})
	return result

## A bounded spatial speed envelope: line/equipment limits, full-rake restriction
## release, comfort braking, power/mass traction and Davis resistance. It predicts
## unconstrained running; observed occupied/locked routes are checked separately.
func running(train: Dictionary, sections: Array, start_speed: float, stop: bool, cautious: bool=true) -> Dictionary:
	if sections.is_empty():return {ok=false}
	var lengths:=[];var ceilings: Array[float]=[];var total:=0.0
	var prior:=[]
	for tail: Dictionary in train.get("tail_limits",[]):prior.append({end=-float(tail.behind),limit=float(tail.limit)})
	for section: Dictionary in sections:
		var end: float=total+section.length
		while total<end-.001:
			var length:=minf(SAMPLE_METRES,end-total)
			var limit: float=minf(train.max_speed,section.limit)-.4
			for previous: Dictionary in prior:
				if total-previous.end<train.length:limit=minf(limit,previous.limit-.4)
			lengths.append(length);ceilings.append(maxf(.5,limit));total+=length
		prior.append({end=end,limit=section.limit})
		prior=prior.filter(func(p):return end-p.end<train.length)
	if lengths.is_empty():return {ok=true,seconds=0.0,speed=0.0 if stop else start_speed,distance=0.0}
	var brake: float=maxf(.08,train.decel*(.40 if cautious else .50))
	var envelope: Array[float]=[];envelope.resize(lengths.size()+1)
	envelope[-1]=0.0 if stop else ceilings[-1]
	for i in range(lengths.size()-1,-1,-1):
		envelope[i]=minf(ceilings[i],sqrt(envelope[i+1]*envelope[i+1]+2*brake*lengths[i]))
	var speed:=maxf(0,start_speed);var seconds:=0.0
	for i in lengths.size():
		var traction: float=minf(train.accel,train.power/maxf(1.0,train.mass*maxf(speed,5.0)))
		var accel: float=maxf(.02,traction*(.78 if cautious else 1.0)-(.006+.00004*speed*speed))
		var next:=minf(envelope[i+1],sqrt(speed*speed+2*accel*lengths[i]))
		next=minf(next,ceilings[i])
		# A low start/end speed interval still accelerates and brakes between its
		# endpoints; using a fixed crawl floor would grossly overestimate short moves.
		if speed+next<.01:
			var peak:=minf(ceilings[i],sqrt(2*lengths[i]/(1/accel+1/brake)))
			seconds+=peak/accel+peak/brake+maxf(0,lengths[i]-peak*peak*.5*(1/accel+1/brake))/maxf(.1,peak)
		else:seconds+=2*lengths[i]/maxf(.01,speed+next)
		speed=next
	return {ok=true,seconds=seconds,speed=speed,distance=total,tail_limits=prior.map(func(p):return {behind=total-p.end,limit=p.limit})}

## Calls contain absolute planned departures. Include intervening booked waits,
## passenger dwell and stationary departure horns, not just distance / top speed.
func arrival(train: Dictionary, road: String, at_s: float, stop: bool, cautious: bool=true) -> Dictionary:
	var edge: String=train.edge;var direction: int=train.direction;var from_s: float=train.head_s
	var speed: float=train.speed;var clock: float=train.clock;var distance:=0.0
	var leg_train:=train.duplicate(false)
	if train.get("at_stop",false):clock=maxf(clock,train.release)+train.get("departure_allowance",5.0)
	var target: Dictionary=topology.edges[road]
	var target_chainage: float=lerpf(target.start,target.end,at_s/target.length)
	# A passenger working terminates at its final call. Its eventual depot
	# movement is a separate working, not continued progress along the corridor.
	for call: Dictionary in train.calls:
		if call.get("final",false) and (target_chainage-call.chainage)*direction>1:
			if target.get("station","").is_empty() or call.get("code","")!=target.station:
				return {ok=false,reason="Target is beyond the final booked call"}
	var checkpoints:=[]
	for call: Dictionary in train.calls:
		if not target.get("station","").is_empty() and call.get("code","")==target.station:break
		# A call within one metre is still pending until the arrival controller
		# marks it berthed. Keep its dwell/booked departure, including a train
		# exactly at the marker; InputData already omits an acknowledged stop.
		# Calls in this input are unserved. A manual overshoot cannot certify
		# onward running by silently discarding that still-unacknowledged call.
		if (call.chainage-train.chainage)*direction<-.01:
			return {ok=false,reason="An unacknowledged call is behind the train"}
		if (target_chainage-call.chainage)*direction<=1:break
		checkpoints.append(call)
	checkpoints.append({road=road,s=at_s,final=true})
	for checkpoint: Dictionary in checkpoints:
		var sections:=pieces(edge,direction,from_s,checkpoint.road,checkpoint.s)
		var final: bool=checkpoint.get("final",false)
		var leg:=running(leg_train,sections,speed,stop if final else true,cautious)
		if not leg.ok:return {ok=false,reason="No compatible forward route"}
		clock+=leg.seconds;distance+=leg.distance;speed=leg.speed
		if not final:clock=maxf(clock+checkpoint.dwell,checkpoint.departure)+train.get("departure_allowance",5.0)
		if not sections.is_empty():direction=sections[-1].dir
		leg_train.tail_limits=leg.get("tail_limits",[])
		edge=checkpoint.road;from_s=checkpoint.s
	return {ok=true,arrival=clock,seconds=clock-train.clock,speed=speed,distance=distance}
