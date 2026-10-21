extends RefCounted
## Screen-space packing only. A crowded map may omit secondary tags; the
## actual occupied train footprints remain visible and selectable underneath.
static func arrange(requests: Array, bounds: Rect2) -> Array:
	var ordered:=requests.duplicate(true)
	ordered.sort_custom(func(a,b):
		if a.priority!=b.priority:return a.priority>b.priority
		var da: float=a.head.distance_squared_to(bounds.get_center())
		var db: float=b.head.distance_squared_to(bounds.get_center())
		return str(a.id)<str(b.id) if is_equal_approx(da,db) else da<db)
	var placed: Array=[]
	var cells:={}
	for entry in ordered:
		var extent: Vector2=entry.size.min(bounds.size)
		var preferred: Vector2=entry.head+Vector2(-extent.x*.5,-extent.y-16 if entry.dir>0 else 24)
		var best:=Rect2();var score:=INF;var tried:={}
		# Clamp candidates before testing. Include the detail line in their size.
		# A small bounded search avoids unbounded per-frame work on busy days.
		for row in [0,-1,1,-2,2,-3,3,-4,4]:
			for column in [0,-1,1,-2,2,-3,3]:
				var at:=preferred+Vector2(column*(extent.x+8),row*(extent.y+8))
				at=at.clamp(bounds.position,bounds.end-extent)
				var cost:=at.distance_squared_to(preferred)
				if cost>=score or tried.has(at):continue
				tried[at]=true
				var rect:=Rect2(at,extent)
				if _free(rect,cells):best=rect;score=cost
				if score==0:break
			if score==0:break
		if score==INF:continue
		entry.rect=best;placed.append(entry)
		var padded:=best.grow(4)
		for y in range(floori(padded.position.y/64),floori(padded.end.y/64)+1):
			for x in range(floori(padded.position.x/128),floori(padded.end.x/128)+1):
				var key:=Vector2i(x,y)
				if not cells.has(key):cells[key]=[]
				cells[key].append(padded)
	return placed

static func _free(rect: Rect2,cells: Dictionary) -> bool:
	for y in range(floori(rect.position.y/64),floori(rect.end.y/64)+1):
		for x in range(floori(rect.position.x/128),floori(rect.end.x/128)+1):
			for other: Rect2 in cells.get(Vector2i(x,y),[]):
				if other.intersects(rect):return false
	return true
