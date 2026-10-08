extends RefCounted
## Bake pedestrian aisle routes against the same collision grids used by walking.
const Nav:=preload("res://game/interior_navigation.gd")

static func bake(profile: Dictionary, seats: Array, doors: Array) -> Dictionary:
	var nav=Nav.new(profile)
	var portals:={}
	var seen:={}
	for y in nav.height:
		for x in nav.width:
			var cell:=Vector2i(x,y)
			if seen.has(cell) or not nav.valid(cell):continue
			var component: Array=nav.component(nav.center(cell))
			for member in component:seen[member]=true
			if component.size()<8:continue
			for exit in nav.room_exits(nav.center(cell)):
				if exit.bridge.is_empty():continue
				var a: Vector2i=nav.cell(exit.point);var b: Vector2i=nav.cell(exit.bridge.point)
				if not nav.valid(a) or not nav.valid(b):continue
				if not portals.has(a):portals[a]=[]
				if not portals.has(b):portals[b]=[]
				portals[a].append(b);portals[b].append(a)
	var paths:=[]
	var failures:=0
	for door in doors:
		var target:=Vector2(door.point[0]*.58,door.point[1])
		var entry: Dictionary=nav.nearest(target,false,2.0,40)
		if entry.is_empty():paths.append([]);failures+=seats.size();continue
		var start: Vector2i=nav.cell(entry.point)
		var parents:={start:start};var queue:=[start];var cursor:=0
		while cursor<queue.size():
			var at: Vector2i=queue[cursor];cursor+=1
			var neighbours: Array=portals.get(at,[]).duplicate()
			for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:neighbours.append(at+delta)
			for next: Vector2i in neighbours:
				if parents.has(next) or not nav.valid(next):continue
				parents[next]=at;queue.append(next)
		var seat_paths:=[]
		for seat in seats:
			var position:=Vector2(seat.position[0],seat.position[2])
			var nearest:=Vector2i.ZERO;var distance:=INF
			for cell: Vector2i in parents:
				var d: float=nav.center(cell).distance_squared_to(position)
				if d<distance:distance=d;nearest=cell
			if distance>5.29:failures+=1;seat_paths.append([]);continue
			var route: Array[Vector2]=[];var at:=nearest
			while true:
				route.append(nav.center(at))
				if at==start:break
				at=parents[at]
			# Drop collinear grid points; preserve portal bends and seat-row access.
			var compact:=[]
			for i in route.size():
				if i>0 and i<route.size()-1 and (route[i]-route[i-1]).normalized().is_equal_approx((route[i+1]-route[i]).normalized()):continue
				compact.append([snappedf(route[i].x,.001),snappedf(nav.floor_height(route[i]),.001),snappedf(route[i].y,.001)])
			seat_paths.append(compact)
		paths.append(seat_paths)
	return {doors=doors,paths=paths,unreachable=failures}
