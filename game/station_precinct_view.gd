extends RefCounted
## Material-batched civil works, in the station chunk's local frame.
const Plans:=preload("res://game/station_precinct_plan.gd")
const Foundation:=preload("res://game/geographic_station_foundation.gd")
static func draw(batch,geo,world: RailWorld,station: Dictionary,origin: Vector3,props) -> void:
	for plan: Dictionary in Plans.entries(geo.station_sites,station):
		if plan.halt:continue
		var p: Vector3=plan.building-origin
		var basis: Basis=plan.basis
		var half: float=plan.half;var front: float=plan.front;var outer: float=plan.outer
		var depth: float=front-outer
		# One connected ground plane from the entrance steps to the public road.
		var centre: Vector3=p+basis.z*(front+outer)*.5
		Foundation.draw(batch,geo,centre-Vector3.UP*.035,basis,Vector2(half*2,depth),origin)
		batch.box("forecourt",centre-Vector3.UP*.015,Vector3(half*2,.10,depth),Color.WHITE,basis)
		# Entrance promenade, accessible kerb crossing and a separate vehicle lane.
		_slab(batch,p,basis,0,front-2.6,half*2,5.2,.16,"forecourt")
		_slab(batch,p,basis,0,front-8.8,half*2-1,7.0,.05,"station_asphalt")
		_slab(batch,p,basis,0,front-16.0,half*2-1,7.1,.06,"station_asphalt")
		# Protected station-side pavement with a central ramp/crossing.
		for side in [-1,1]:
			_slab(batch,p,basis,side*(half*.5+2),front-5.2,half-4,.22,.22,"concrete")
			for x in range(6,floori(half)-3,4):
				var at: Vector3=p+basis*Vector3(x*side,.65,front-4.95)
				batch.box("station_fence",at,Vector3(.10,1.0,.10),Color.WHITE,basis)
				batch.box("station_white",at+Vector3.UP*.26,Vector3(.115,.10,.115),Color.WHITE,basis)
		var a: Vector3=p+basis*Vector3(-2,0,front-4.0)+Vector3.UP*.22
		var b: Vector3=p+basis*Vector3(2,0,front-4.0)+Vector3.UP*.22
		var c: Vector3=p+basis*Vector3(2,0,front-6.0)+Vector3.UP*.09
		var d: Vector3=p+basis*Vector3(-2,0,front-6.0)+Vector3.UP*.09
		batch.quad("forecourt",a,b,c,d,Vector3.UP)
		for z in range(7):
			_slab(batch,p,basis,0,front-5.9-z*.84,3.9,.38,.065,"station_white")
		# Formal bays leave the entrance/crosswalk and the circulation lane open.
		for side in [-1,1]:
			for x in range(7,floori(half)-2,3):
				_slab(batch,p,basis,float(x)*side,front-16.2,.065,5.0,.071,"station_white")
		for side in [-1,1]:
			for i in (5 if plan.major else 3):
				var x: float=side*(8.5+i*6.0)
				if absf(x)>half-5:continue
				var at: Vector3=p+basis*Vector3(x,.11,front-16.0)
				props.place("auto_rickshaw" if i==0 else "hatchback",at,atan2(basis.z.x,basis.z.z)+(PI if side<0 else 0))
		for i in (10 if plan.major else 5):
			var x: float=-half+7+i*1.05
			if x>-6:break
			props.place("motorcycle",p+basis*Vector3(x,.08,outer+2.1),atan2(basis.z.x,basis.z.z)+PI*.25)
		# Landscaped pockets outside movement lanes; trees don't occupy pavement.
		for side in [-1,1]:
			var x: float=side*(half-3.2)
			var z: float=outer+2.2
			_slab(batch,p,basis,x,z,4.7,2.8,.30,"concrete")
			_slab(batch,p,basis,x,z,4.3,2.4,.32,"road_shoulder")
			for offset in [-1.3,0,1.3]:
				props.place("shrub",p+basis*Vector3(x+offset,.33,z),0,Vector3(.75,.65,.75))
		# Open railing keeps the facade visible; gates align with accepted roads.
		var gates:=[0.0];var left_gates:=[];var right_gates:=[]
		for connection in plan.access:
			var local: Vector3=basis.inverse()*(connection[0]-plan.building)
			if absf(local.x+half)<.1:left_gates.append(local.z)
			elif absf(local.x-half)<.1:right_gates.append(local.z)
			else:gates.append(local.x)
		_fence(batch,p,basis,Vector2(-half,outer),Vector2(half,outer),gates)
		for side in [-1,1]:
			_fence(batch,p,basis,Vector2(side*half,outer),Vector2(side*half,plan.back),left_gates if side<0 else right_gates)
		for x in [-half+2,half-2]:
			for z in [front-4,outer+1]:
				var at: Vector3=p+basis*Vector3(x,0,z)
				batch.box("concrete",at+Vector3.UP*.14,Vector3(.5,.28,.5))
				batch.box("station_fence",at+Vector3.UP*2.5,Vector3(.10,5,.10))
				batch.box("metal",at+Vector3.UP*5+basis.z*.3,Vector3(.35,.12,.8),Color.WHITE,basis)
		# Covered surface drains along the kerb, clear of pedestrian entrances.
		for side in [-1,1]:
			var x: float=side*(half*.5+2.5)
			_slab(batch,p,basis,x,front-5.45,half-5,.25,.056,"station_drain")
			for k in range(6,floori(half)-2,2):
				_slab(batch,p,basis,k*side,front-5.45,.045,.29,.065,"metal")
		for connection in plan.access:_road_link(batch,geo,connection,origin)

static func halt_boundary(batch,geo,station: Dictionary,origin: Vector3) -> void:
	for plan: Dictionary in Plans.entries(geo.station_sites,station):
		var p: Vector3=plan.building-origin
		_fence(batch,p,plan.basis,Vector2(-plan.half,plan.front-.25),Vector2(plan.half,plan.front-.25),[0.0])

static func _slab(batch,p: Vector3,basis: Basis,x: float,z: float,width: float,depth: float,top: float,kind: String) -> void:
	batch.box(kind,p+basis*Vector3(x,top-.035,z),Vector3(width,.07,depth),Color.WHITE,basis)

static func _fence(batch,p: Vector3,basis: Basis,a: Vector2,b: Vector2,gates: Array) -> void:
	var span:=a.distance_to(b)
	var count:=maxi(1,ceili(span/2.6))
	for i in count:
		var start:=a.lerp(b,float(i)/count);var end:=a.lerp(b,float(i+1)/count)
		var centre: Vector2=(start+end)*.5
		var gap:=false
		for gate: float in gates:
			if absf((centre.x if absf(b.x-a.x)>absf(b.y-a.y) else centre.y)-gate)<4.5:gap=true
		if gap:continue
		var pa: Vector3=p+basis*Vector3(start.x,0,start.y)
		var pb: Vector3=p+basis*Vector3(end.x,0,end.y)
		preload("res://game/station_boundary_mesh.gd").section(batch,pa,pb)

static func _road_link(batch,geo,connection: Array,origin: Vector3) -> void:
	var a: Vector3=connection[0]-origin;var b: Vector3=connection[1]-origin
	var count:=maxi(1,ceili(a.distance_to(b)/3))
	var side: Vector3=(b-a).normalized().cross(Vector3.UP).normalized()*3.0
	for i in count:
		var p:=a.lerp(b,float(i)/count);var q:=a.lerp(b,float(i+1)/count)
		p.y=maxf(p.y,geo.ground_at(p.x+origin.x,p.z+origin.z)+.06)
		q.y=maxf(q.y,geo.ground_at(q.x+origin.x,q.z+origin.z)+.06)
		batch.quad("station_asphalt",p-side,q-side,q+side,p+side,Vector3.UP)
		for signum in [-1,1]:
			var edge_p: Vector3=p+side*signum;var edge_q: Vector3=q+side*signum
			var ground_p: float=geo.ground_at(edge_p.x+origin.x,edge_p.z+origin.z)
			var ground_q: float=geo.ground_at(edge_q.x+origin.x,edge_q.z+origin.z)
			batch.quad("concrete",edge_p,edge_q,Vector3(edge_q.x,minf(ground_q-.1,edge_q.y-.08),edge_q.z),Vector3(edge_p.x,minf(ground_p-.1,edge_p.y-.08),edge_p.z),side.normalized()*signum)
