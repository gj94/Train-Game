extends RefCounted
## Small baked grids in vehicle space. No render or railway simulation dependency.
var data: Dictionary
var origin: Vector2
var step: float
var width: int
var height: int
var _components := [{},{}]
var _exit_cache := {}

func _init(profile: Dictionary = {}) -> void:
	if profile.is_empty(): return
	data = profile
	origin = Vector2(data.origin[0],data.origin[1])
	step = data.step
	width = data.width
	height = data.standing.size()

func cell(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x-origin.x)/step),floori((point.y-origin.y)/step))

func center(index: Vector2i) -> Vector2:
	return origin+(Vector2(index)+Vector2(.5,.5))*step

func valid(index: Vector2i, crouched: bool = false) -> bool:
	if index.x<0 or index.y<0 or index.x>=width or index.y>=height: return false
	return str(data.crouching[index.y] if crouched else data.standing[index.y])[index.x]=="1"

func allowed(point: Vector2, crouched: bool = false) -> bool:
	return valid(cell(point),crouched)

func floor_height(point: Vector2) -> float:
	var index := cell(point)
	if index.x<0 or index.y<0 or index.x>=width or index.y>=height: return 0
	return float(data.floor_mm[index.y][index.x])*.001

func nearest(point: Vector2, crouched: bool = false, maximum: float = INF, minimum_cells: int = 0) -> Dictionary:
	var best := maximum*maximum
	var found := {}
	for y in height:
		for x in width:
			var index := Vector2i(x,y)
			if not valid(index,crouched): continue
			var p := center(index)
			var distance := p.distance_squared_to(point)
			if distance<best:
				if minimum_cells>0 and component(p,true).size()<minimum_cells: continue
				best=distance
				found={point=p,distance=sqrt(distance)}
	return found

func move(point: Vector2, displacement: Vector2, crouched: bool = false) -> Vector2:
	# Sweep in sub-cell steps, including after a long frame. Slide along obstacles.
	if not allowed(point,crouched): return point
	var count := maxi(1,ceili(displacement.length()/(step*.35)))
	var increment := displacement/float(count)
	var p := point
	for i in count:
		var candidate := p+increment
		if reachable_step(p,candidate,crouched):
			p=candidate
		else:
			candidate=p+Vector2(increment.x,0)
			if reachable_step(p,candidate,crouched): p=candidate
			candidate=p+Vector2(0,increment.y)
			if reachable_step(p,candidate,crouched): p=candidate
	return p

func reachable_step(a: Vector2, b: Vector2, crouched: bool) -> bool:
	if not allowed(b,crouched) or absf(floor_height(b)-floor_height(a))>.21: return false
	# A diagonal may not cut the blocked corner of a partition or chair.
	return allowed(Vector2(a.x,b.y),crouched) and allowed(Vector2(b.x,a.y),crouched)

func component(point: Vector2, crouched: bool = false) -> Array[Vector2i]:
	var start := cell(point)
	var result: Array[Vector2i] = []
	if not valid(start,crouched): return result
	var cache: Dictionary = _components[1 if crouched else 0]
	if cache.has(start): return cache[start]
	var visited := {start:true}
	result.append(start)
	var cursor := 0
	while cursor<result.size():
		var at := result[cursor]
		cursor+=1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = at+direction
			if visited.has(next) or not valid(next,crouched): continue
			if absf(floor_height(center(next))-floor_height(center(at)))>.21: continue
			visited[next]=true
			result.append(next)
	for index in result: cache[index]=result
	return result

func room_exits(point: Vector2) -> Array:
	var cells := component(point,true)
	if cells.is_empty(): return []
	if _exit_cache.has(cells[0]): return _exit_cache[cells[0]]
	var member := {}
	for index in cells: member[index]=true
	var exits := []
	for direction in [-1,1]:
		var best := -INF
		var edge := point
		for index in cells:
			var p := center(index)
			var score: float = p.y*direction-absf(p.x)*.03
			if score>best: best=score;edge=p
		var bridge := {}
		var distance := 1.1
		for y in height:
			for x in width:
				var index := Vector2i(x,y)
				if member.has(index) or not valid(index,true): continue
				var p := center(index)
				if (p.y-edge.y)*direction<.12 or absf(p.x-edge.x)>.55: continue
				var d := p.distance_to(edge)
				if d<distance and component(p,true).size()>40:
					distance=d;bridge={point=p}
		exits.append({point=edge,direction=direction,bridge=bridge})
	# Side compartment door headers come from the source model, not arbitrary walls.
	for hint in data.get("side_doors",[]):
		var door := Vector2(hint[0],hint[1])
		var sides := []
		for sign_dir in [-1,1]:
			var found := {}
			var best := .85
			for y in height:
				for x in width:
					var index := Vector2i(x,y)
					if not valid(index,true): continue
					var p := center(index)
					if (p.x-door.x)*sign_dir<.18: continue
					if p.distance_to(door)<best and component(p,true).size()>40:
						best=p.distance_to(door);found={point=p}
			sides.append(found)
		if sides[0].is_empty() or sides[1].is_empty(): continue
		for i in 2:
			if member.has(cell(sides[i].point)) and not member.has(cell(sides[1-i].point)):
				exits.append({point=sides[i].point,direction=0,bridge=sides[1-i]})
	_exit_cache[cells[0]]=exits
	return exits

func end_point(point: Vector2, direction: int) -> Dictionary:
	var cells := component(point,true)
	var best := -INF
	var result := {}
	for index in cells:
		var p := center(index)
		var score := p.y*direction-absf(p.x)*.06
		if score>best:
			best=score
			result={point=p}
	return result
