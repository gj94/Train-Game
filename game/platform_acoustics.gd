extends RefCounted
## Pure port of Acoustics.md; positions/times come from the game's occupied route.
const Base := preload("res://game/body_v2_model.gd")
const Data := preload("res://game/platform_enhanced_data.gd")
const C := 343.0

static func rolling_mix(kmh: float) -> Vector2:
	var ratio := maxf(0,kmh)/71.6
	return Vector2(minf(1.4,pow(ratio,1.25)),clampf(15*log(maxf(.001,ratio))/log(10),-24,0))

static func variant(identity: Dictionary, joint: int) -> int:
	return posmod(identity.vehicle*3+identity.bogie*2+identity.order+absi(joint)*3,8)

static func arrival_delay(source: Vector3, receiver: Vector3, velocity: Vector3) -> float:
	var r := receiver-source
	var a := C*C-velocity.length_squared()
	var dot := r.dot(velocity)
	var h := sqrt(dot*dot+a*r.length_squared())
	return r.length_squared()/maxf(.000001,h-dot) if dot<0 else (dot+h)/a

static func impact_can_arrive(source: Vector3,receiver: Vector3,age: float,lookahead: float,receiver_travel: float) -> bool:
	# A sound wave cannot cover more than C*(age+lookahead). Even if the
	# receiver moves straight toward it by its full travel bound, a more
	# distant event cannot need native playback yet. Exact timing stays below.
	if age+lookahead<0: return false
	var reach:=C*(age+lookahead)+maxf(0,receiver_travel)
	return source.distance_squared_to(receiver)<=reach*reach

static func curved_arrival(source: Vector3, contact_time: float, listener_at: Callable) -> float:
	var delay := 0.0
	for i in 12:
		var next := (listener_at.call(contact_time+delay) as Vector3).distance_to(source)/C
		if absf(next-delay)<1e-10:
			delay=next
			break
		delay=next
	return contact_time+delay

static func stereo(source: Vector3, receiver: Vector3, forward: Vector3, up: Vector3=Vector3.UP, cap: float=1600.0) -> Vector2:
	var d := source-receiver
	var azimuth := rad_to_deg(atan2(d.dot(forward.normalized().cross(up).normalized()),d.dot(forward.normalized())))
	if azimuth>90: azimuth=180-azimuth
	if azimuth< -90: azimuth=-180-azimuth
	var angle := (azimuth+90)/180*PI/2
	return Vector2(cos(angle),sin(angle))*Base.falloff(minf(cap,d.length()),false)

static func impact_cutoff(source: Vector3, ear: Vector3, onboard: bool, cab: bool, local_side: float=.4) -> float:
	var distance := source.distance_to(ear) if onboard else Vector2(source.x-ear.x,source.z-ear.z).length()
	var near := Vector2(local_side,ear.y-source.y).length() if onboard else Vector2(3.8,5.8).length()
	return (6500.0 if cab else 18000.0)/(1+maxf(0,distance-near)/22)

static func body_level(identity: Dictionary, joint_id: int, source: Vector3, contact_time: float, listener_at: Callable) -> float:
	var arrival := curved_arrival(source,contact_time,listener_at)
	var energy := 0.0
	for bin in Data.ENVELOPES[variant(identity,joint_id)]:
		var receiver: Vector3=listener_at.call(arrival+bin[0])
		energy+=bin[1]*pow(Base.falloff(receiver.distance_to(source),false),2)
	return identity.load*sqrt(energy)

static func passenger_gain(preceding: float, leading: float) -> float:
	return minf(pow(10,.1),.95*leading/preceding) if preceding>0 else 1.0

static func cab_gain(own: float, leading: float) -> float:
	return clampf(pow(leading/own,.6),1,pow(10,.4)) if own>0 else 1.0

static func squeal_demand(speed: float, curvature: float, wheelbase: float, friction: float=1.0) -> float:
	var v := absf(speed)
	return smoothstep(.0004,.006,absf(curvature)*wheelbase*.5)*smoothstep(.35,2.5,v)*(.55+.45*(1-exp(-v/5)))*clampf(friction,0,1)

static func squeal_curve_color(curvature: float,wheelbase: float) -> float:
	return clampf(6*log(maxf(.001,absf(curvature)*wheelbase/(2.56/441.36)))/log(2),-9,3)

static func describe(axles: Array) -> Dictionary:
	var identities := []
	identities.resize(axles.size())
	var groups := {}
	for i in axles.size():
		var a: Dictionary=axles[i]
		var key := "%d:%d"%[a.car,int(a.cls/2)]
		if not groups.has(key): groups[key]=[]
		groups[key].append(i)
	var bogies := []
	for key in groups:
		var indices: Array=groups[key]
		var center := 0.0
		for order in indices.size():
			var index: int=indices[order]
			var a: Dictionary=axles[index]
			identities[index]={id=key+":"+str(order),vehicle=a.car,bogie=int(a.cls/2),order=order,x=a.x,
				load=Base.axle_load(a.car,int(a.cls/2),order,indices.size()==3),locomotive=indices.size()==3}
			identities[index].variant=variant(identities[index],0)
			center+=a.x
		indices.sort_custom(func(a,b): return axles[a].x<axles[b].x)
		bogies.append({id=key,x=center/indices.size(),car=axles[indices[0]].car,index=int(axles[indices[0]].cls/2),
			indices=indices,wb=absf(axles[indices[-1]].x-axles[indices[0]].x)})
	bogies.sort_custom(func(a,b): return a.x<b.x)
	return {axles=identities,bogies=bogies}

static func passenger_pair(bogies: Array, car: int, back: float) -> Vector2i:
	var own := -1
	var nearest := INF
	for i in bogies.size():
		if bogies[i].car!=car: continue
		var distance: float=absf(bogies[i].x-back)
		if distance<nearest: nearest=distance; own=i
	if own<=0: return Vector2i(-1,-1)
	return Vector2i(bogies[own-1].indices[-1],bogies[own].indices[0])

static func squeal_state(time: float, speed: float, bogie: Dictionary, positions: PackedVector3Array, tangents: PackedVector3Array, curvatures: PackedFloat32Array) -> Dictionary:
	var weighted_curvature := 0.0
	var dominant: int=bogie.indices[0]
	var score := -1.0
	for i in bogie.indices.size():
		var a: int=bogie.indices[i]
		var weight: float = .7 if i==0 else .3/(bogie.indices.size()-1)
		weighted_curvature+=weight*curvatures[a]
		if absf(curvatures[a])*weight>score: score=absf(curvatures[a])*weight; dominant=a
	var phase := posmod(bogie.car*37+bogie.index*17,97)/97.0*TAU
	var instability := .7+.3*smoothstep(-.45,.6,.65*sin(time*TAU*.73+phase)+.35*sin(time*TAU*1.19-phase*.7))
	var tangent := tangents[dominant]
	var side := signf(curvatures[dominant])
	var normal := Vector3(-tangent.z,0,tangent.x)
	return {id=bogie.id,axle=dominant,source=positions[dominant]+normal*.838*side+Vector3.UP*.35,
		level=squeal_demand(speed,weighted_curvature,bogie.wb)*instability,tangent=tangent,side=side,
		curvature=weighted_curvature,edge_db=squeal_curve_color(weighted_curvature,bogie.wb),emission=time}
