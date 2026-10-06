extends RefCounted
const Model := preload("res://game/platform_acoustics.gd")
const Contacts := preload("res://game/track_contacts.gd")
const Sweep := preload("res://game/contact_sweep.gd")
const History := preload("res://game/acoustic_history.gd")
const Data := preload("res://game/platform_enhanced_data.gd")

func fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/platform_enhanced.json"))

func axles() -> Array:
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/body_v2_website.json"))
	var result := []
	for a in source.consist.axles: result.append({x=a.offset,car=int(a.vehicle),cls=int(a.bogie)*2+int(a.index)%2})
	return result

func test_website_onboard_balance_and_wavefront():
	var described := Model.describe(axles())
	for item in fixture().cases:
		var receiver := Vector3(item.receiver[0],item.receiver[1],item.receiver[2])
		var velocity := Vector3(item.direction*item.speed/3.6,0,0)
		var source := Vector3(0,.3,0)
		var listener := func(time: float): return receiver+velocity*time
		var arrival := Model.curved_arrival(source,0,listener)
		if absf(arrival-item.arrival)>.000001: return "moving wavefront differs from website"
		if absf(Model.arrival_delay(source,receiver,velocity)-arrival)>.000001: return "analytic receiver solution differs"
		var own: Dictionary=described.axles[int(item.axle)]
		var leading: Dictionary=described.axles[int(item.leading)]
		var own_body := Model.body_level(own,0,source,0,listener)
		var leading_body := Model.body_level(leading,0,source,(leading.x-own.x)/(item.speed/3.6),listener)
		var gain := Model.cab_gain(own_body,leading_body) if item.position=="pilot" else Model.passenger_gain(own_body,leading_body)
		if absf(gain-item.gain)>.000002: return "onboard body balance differs: %s vs %s"%[gain,item.gain]
	return true

func test_low_speed_rolling_and_squeal_match_javascript():
	for item in fixture().rolling:
		var mix := Model.rolling_mix(item.speed)
		if absf(mix.x-item.gain)>.000001 or absf(mix.y-item.hissDb)>.000002: return "rolling law differs"
	for item in fixture().squeal:
		if absf(Model.squeal_demand(item.v,item.k,item.wb)-item.expected)>.000001: return "squeal demand differs"
	return true

func test_stable_axle_identity_after_reversing():
	var original := axles()
	var reversed := original.duplicate(true)
	for a in reversed: a.x=500.56-a.x
	var forward := Model.describe(original)
	var backward := Model.describe(reversed)
	for i in original.size():
		if forward.axles[i].id!=backward.axles[i].id: return "axle ID swapped when reversing"
		if forward.axles[i].variant!=backward.axles[i].variant: return "timbre changed when reversing"
	if forward.bogies[0].indices[0]==backward.bogies[-1].indices[0]: return "leading axle did not reverse"
	var pair := Model.passenger_pair(forward.bogies,1,21.5)
	if pair!=Vector2i(5,6): return "first coach should balance against locomotive rear axle"
	return true

func point_graph() -> TrackGraph:
	var g := TrackGraph.new()
	g.add_node("a",Vector3(-100,0,0)); g.add_node("b",Vector3.ZERO)
	g.add_node("c",Vector3(160,0,0)); g.add_node("d",Vector3(160,0,8))
	g.add_edge("trunk","a","b"); g.add_edge("normal","b","c")
	g.add_edge("reverse","b","d",preload("res://sim/layouts/first_line.gd").ease_between(0,160,0,8))
	g.add_switch("b","trunk","normal","reverse")
	return g

func test_actual_turnout_has_eleven_contacts_without_periodic_duplicates():
	var g := point_graph()
	var layout := Contacts.new(g)
	for edge in ["normal","reverse"]:
		var assembly: Array=layout.contacts[edge].filter(func(c): return c.id>=100000)
		if assembly.size()!=11: return "point should contain eleven rail contacts"
		var gaps := 0
		for c in assembly:
			if c.kind=="joint":
				gaps+=1
				if not layout.at_gap(edge,c.s,c.side) or layout.at_gap(edge,c.s,-c.side) and c.label.find("SRJ")<0: return "gap exists on wrong rail"
			if absf(c.source.distance_to(g.position(edge,c.s)+Vector3.UP*.3)-.838)>.00001: return "source is not on affected wheel rail"
		if gaps!=7: return "incorrect assembly-interface count"
		for c in layout.contacts[edge]:
			if c.id<100000 and layout.in_assembly(edge,c.s): return "ordinary joint duplicates assembly contact"
	return true

func test_swept_contact_times_both_directions_and_frame_rates():
	var g := point_graph()
	var layout := Contacts.new(g)
	for direction in [-1,1]:
		for fps in [30,60,120]:
			for speed in [10.0,30.0,71.6,130.0]:
				var sweep := Sweep.new()
				var s: float = 0.0 if direction==1 else g.edges.reverse.length
				var start: float = s
				var time := 0.0
				var observed := {}
				sweep.advance([{edge="reverse",s=s,dir=direction}],layout,1.0/fps)
				while s>=0 and s<=g.edges.reverse.length:
					s+=direction*speed/3.6/fps; time+=1.0/fps
					for hit in sweep.advance([{edge="reverse",s=s,dir=direction}],layout,1.0/fps):
						if observed.has(hit.contact.key): return "contact duplicated"
						observed[hit.contact.key]=true
						var expected: float=absf(hit.contact.s-start)/(speed/3.6)
						if absf(time+hit.relative-expected)>.0001: return "render frame quantized physical crossing"
				if observed.size()!=layout.contacts.reverse.size(): return "missed a physical rail contact: direction %d fps %d speed %.1f, got %d expected %d"%[direction,fps,speed,observed.size(),layout.contacts.reverse.size()]
	return true

func test_sweep_acceleration_pause_and_teleport():
	var g := point_graph()
	var layout := Contacts.new(g)
	var sweep := Sweep.new()
	sweep.advance([{edge="trunk",s=6.0,dir=1}],layout,.1)
	var hits := sweep.advance([{edge="trunk",s=7.0,dir=1}],layout,.1)
	if hits.size()!=1 or absf(hits[0].relative+.05)>.000001: return "fractional crossing wrong"
	if not sweep.advance([{edge="trunk",s=7.0,dir=1}],layout,.1).is_empty(): return "stationary contact repeated"
	if not sweep.advance([{edge="trunk",s=90.0,dir=1}],layout,.1).is_empty() or not sweep.discontinuity: return "teleport generated contacts"
	return true

func test_curve_squeal_rear_axle_and_both_rails():
	var b := {id="C1B1",car=1,index=0,indices=[0,1],wb=2.56}
	var p := PackedVector3Array([Vector3(1.28,0,0),Vector3(-1.28,0,0)])
	var t := PackedVector3Array([Vector3.RIGHT,Vector3.RIGHT])
	for sign in [-1,1]:
		var state := Model.squeal_state(1,20,b,p,t,PackedFloat32Array([0,sign/441.36]))
		if state.level<=0 or state.axle!=1 or state.side!=sign: return "rear axle failed to sustain squeal"
		if absf(state.source.z-sign*.838)>.000001: return "wrong inner rail"
		if Model.squeal_state(1,0,b,p,t,PackedFloat32Array([0,sign/441.36])).level!=0: return "squeal at rest"
	if Model.squeal_state(1,20,b,p,t,PackedFloat32Array([0,0])).level!=0: return "straight track squeals"
	return true

func test_benchmark_squeal_state_matches_new_javascript():
	for item in fixture().states:
		var positions := PackedVector3Array()
		var tangents := PackedVector3Array()
		for p in item.poses:
			positions.append(Vector3(p.x,0,p.z)); tangents.append(Vector3(p.tx,0,p.tz))
		var b := {id="C1B1",car=1,index=0,indices=[0,1],wb=2.56}
		var state := Model.squeal_state(item.time,item.speed/3.6,b,positions,tangents,PackedFloat32Array(item.curves))
		if absf(state.level-item.expected.level)>.000002 or absf(state.edge_db-item.expected.edgeDb)>.00001: return "benchmark envelope/curve-color differs"
		if state.source.distance_to(Vector3(item.expected.x,item.expected.y,item.expected.z))>.00001: return "benchmark source wheel differs"
	return true

func test_history_interpolation_and_reset():
	var history := History.new()
	var t := PackedVector3Array([Vector3.RIGHT])
	var k := PackedFloat32Array([0])
	history.append(0,10,PackedVector3Array([Vector3.ZERO]),t,k)
	history.append(1,10,PackedVector3Array([Vector3(10,0,0)]),t,k)
	if history.sample(.4).positions[0].distance_to(Vector3(4,0,0))>.000001: return "retarded pose interpolation differs"
	if not history.sample(-1).is_empty(): return "invented history before seek"
	history.clear()
	if not history.sample(1).is_empty(): return "seek retained old source"
	return true

func test_sparse_history_matches_complete_history():
	var history := History.new()
	var p := PackedVector3Array([Vector3(1,2,3),Vector3(4,5,6),Vector3(7,8,9)])
	var t := PackedVector3Array([Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK])
	var k := PackedFloat32Array([.1,.2,.3])
	history.append(0,10,p,t,k)
	history.append(1,20,PackedVector3Array([p[0]+Vector3.RIGHT,p[1]+Vector3.RIGHT,p[2]+Vector3.RIGHT]),t,k)
	for time in [.0,.3,.99,1.0,1.2]:
		var all := history.sample(time)
		var sparse := history.sample(time,[2,0])
		if sparse.positions.size()!=2: return "sparse query expands entire train"
		for i in 2:
			var index := 2 if i==0 else 0
			if not sparse.positions[i].is_equal_approx(all.positions[index]) or sparse.curvatures[i]!=all.curvatures[index] or not sparse.tangents[i].is_equal_approx(all.tangents[index]): return "sparse history changes acoustics"
	return true

func test_generated_squeal_bank_lossless_and_bounded():
	for file in Data.HASHES:
		if FileAccess.get_sha256(Data.ROOT+file)!=Data.HASHES[file]: return "squeal source changed"
	for i in 4:
		var mono: AudioStreamWAV=load(Data.ROOT+"squeal-%d.wav"%i)
		if mono.format!=AudioStreamWAV.FORMAT_16_BITS or mono.mix_rate!=48000 or absf(mono.get_length()-Data.SQUEAL_SECONDS)>.000001: return "squeal import is lossy or wrong duration"
		for side in 2:
			var routed: AudioStreamWAV=load(Data.ROOT+"squeal-%d-%s.wav"%[i,"left" if side==0 else "right"])
			var raw := mono.data
			var stereo := routed.data
			for frame in raw.size()/2:
				if raw.decode_s16(frame*2)!=stereo.decode_s16(frame*4+side*2): return "routed squeal PCM changed"
				if stereo.decode_s16(frame*4+(1-side)*2)!=0: return "squeal leaked into wrong channel"
	return true
