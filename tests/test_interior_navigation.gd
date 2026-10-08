extends RefCounted
const Nav := preload("res://game/interior_navigation.gd")
const Profiles := "res://data/interiors/walkways.json"

func fixture(rows: Array, crouching: Array=[]):
	var floors:=[]
	for row in rows:
		var line:=[]
		for x in row.length(): line.append(1300)
		floors.append(line)
	return Nav.new({origin=[0,0],step=.1,width=rows[0].length(),standing=rows,crouching=rows if crouching.is_empty() else crouching,floor_mm=floors})

func test_sweep_stops_at_wall_even_after_long_frame():
	var nav=fixture(["11011","11011","11011"])
	var p: Vector2=nav.move(Vector2(.05,.15),Vector2(12,0))
	return p.x<.2 and p.x>.17 and nav.allowed(p)

func test_wall_sliding_and_diagonal_corner():
	var nav=fixture(["1110","1000","1011","1111"])
	var p: Vector2=nav.move(Vector2(.05,.15),Vector2(.2,.1))
	if p.x>=.1 or p.y<.23: return "wall slide crossed a seat or failed to slide"
	return not nav.reachable_step(Vector2(.05,.05),Vector2(.15,.15),false)

func test_floor_steps_and_holes_block_movement():
	var nav=fixture(["111"])
	nav.data.floor_mm[0][1]=1800
	return nav.move(Vector2(.05,.05),Vector2(.2,0)).x<.1 and not nav.allowed(Vector2(-.01,.05))

func test_crouch_only_clearance_and_nearest_limit():
	var nav=fixture(["101"],["111"])
	return nav.move(Vector2(.05,.05),Vector2(.2,0),true).x>.2 and not nav.allowed(Vector2(.15,.05)) and nav.nearest(Vector2(4,4),false,.5).is_empty()

func test_real_fleet_profiles_have_supported_floors_and_crouch_superset():
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profiles))
	if profiles.size()!=22: return "Missing a detailed fleet model"
	for id in profiles:
		var d: Dictionary=profiles[id]
		if d.source_sha256.length()!=64 or d.source_revision.length()!=40: return id+" unpinned"
		for y in d.standing.size():
			if d.standing[y].length()!=d.width or d.crouching[y].length()!=d.width: return id+" malformed grid"
			for x in d.width:
				if d.standing[y][x]=="1" and d.crouching[y][x]!="1": return id+" standing space lost when crouching"
				if d.crouching[y][x]=="1" and (d.floor_mm[y][x]<1200 or d.floor_mm[y][x]>1950): return id+" unsupported floor"
	return true

func test_seat_and_cab_standing_clearance_in_every_detailed_model():
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profiles))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	for id in profiles:
		var nav=Nav.new(profiles[id])
		var seats: Array=catalog[id].passengers
		if id=="wap7": seats=[{position=[-.78,3.05,-7.98]}]
		elif id=="vb_dtc": seats=seats.duplicate()+catalog[id].eyes
		for i in range(0,seats.size(),maxi(1,seats.size()/9)):
			var s: Array=seats[i].position
			var found: Dictionary=nav.nearest(Vector2(s[0],s[2]),false,2.5,40)
			if found.is_empty(): return "%s seat %d has no standing space" % [id,i]
			var rooms:=nav.room_exits(found.point)
			if rooms.is_empty(): return id+" has no room navigation"
	return true

func test_wap_machinery_door_is_bidirectional_and_external_walls_are_not_doors():
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profiles))
	var nav=Nav.new(profiles.wap7)
	var cab: Dictionary=nav.nearest(Vector2(-.78,-7.98),false,2.5,40)
	for e in nav.room_exits(cab.point):
		if e.bridge.is_empty(): continue
		if e.bridge.point.y< -7.3: return "door doesn't reach machinery aisle"
		for back in nav.room_exits(e.bridge.point):
			if not back.bridge.is_empty() and back.bridge.point.y< -7.3: return true
	return "Cab and machinery aisle are not connected both ways"

func test_compartment_side_doors_come_from_source_headers():
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profiles))
	var nav=Nav.new(profiles.lhb_1a)
	if nav.data.side_doors.size()!=8: return "LHB 1A source door headers missing"
	var aisle: Dictionary=nav.nearest(Vector2(-1,0),false,2.5,40)
	for e in nav.room_exits(aisle.point):
		if e.direction==0 and not e.bridge.is_empty(): return true
	return "Side compartment prompts missing"
