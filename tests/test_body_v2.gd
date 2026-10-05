extends RefCounted
const Data := preload("res://game/body_v2_data.gd")
const Model := preload("res://game/body_v2_model.gd")
const Audio := preload("res://game/body_v2_audio.gd")
const Scheduler := preload("res://game/axle_joint.gd")
const Layout := preload("res://game/rail_joint_layout.gd")

func test_approved_source_files_are_byte_identical():
	for file in Data.SOURCE_HASHES:
		if FileAccess.get_sha256(Data.ROOT+file)!=Data.SOURCE_HASHES[file]:
			return "approved PCM changed: "+file
	return true

func test_channel_routing_preserves_full_pcm_and_decay():
	for index in Data.KERNELS:
		var original: AudioStreamWAV=load(Data.ROOT+"impact-%d.wav"%index)
		if original.stereo or original.mix_rate!=48000 or absf(original.get_length()-Data.KERNEL_SECONDS)>.00001:
			return "approved mono bank was converted or truncated"
		for side in 2:
			var routed: AudioStreamWAV=load(Data.ROOT+"impact-%d-%s.wav"%[index,"left" if side==0 else "right"])
			if routed.loop_mode!=AudioStreamWAV.LOOP_DISABLED: return "impact loops"
			if absf(routed.get_length()-Data.PAD-Data.KERNEL_SECONDS)>.00001: return "padding truncated the original"
			var data:=routed.data
			var raw:=original.data
			for frame in raw.size()/2:
				var start:=int(Data.PAD*Data.RATE+frame)*4
				if data[start+side*2]!=raw[frame*2] or data[start+side*2+1]!=raw[frame*2+1]: return "routed PCM differs"
				if data[start+(1-side)*2]!=0 or data[start+(1-side)*2+1]!=0: return "wrong channel is audible"
	return true

func test_website_axle_identity_and_load_mapping():
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/body_v2_website.json"))
	var axles: Array=[]
	for a in fixture.consist.axles: axles.append({x=a.offset,cls=int(a.bogie)*2+int(a.index)%2,car=int(a.vehicle)})
	var actual:=Model.describe(axles)
	if actual.bogies.size()!=42: return "wrong rolling source count"
	for i in axles.size():
		var a: Dictionary=fixture.consist.axles[i]
		if actual.axles[i].variant!=posmod(int(a.vehicle)*3+int(a.bogie)*2+int(a.index),8): return "variant identity differs from website"
		if absf(actual.axles[i].load-a.load)>.000001: return "axle weighting differs from website"
	return true

func test_rolling_power_normalization_prevents_long_rake_boost():
	for distances in [[5.8],[5.8,5.8],[5.8,10.0,24.0,100.0]]:
		var energy:=0.0
		var loudest:=0.0
		for d in distances:
			var w:=Model.falloff(d,false)
			energy+=w*w
			loudest=maxf(loudest,w)
		if absf(energy*pow(Model.normalizer(distances),2)-loudest*loudest)>.000001: return "rolling power scales with rake length"
	return true

func test_equal_power_pan_and_approved_distance_law():
	for position in [Vector3(0,0,-5.8),Vector3(5.8,0,0),Vector3(-5.8,0,0),Vector3(0,0,5.8)]:
		var stereo:=Model.stereo(position,Vector3.ZERO,Vector3.FORWARD)
		if absf(stereo.length()-4.0/(4.0+1.2*1.8))>.00001: return "panning changes total power"
	var left:=Model.stereo(Vector3.LEFT*4,Vector3.ZERO,Vector3.FORWARD)
	if left.x<.999 or left.y>.001: return "left and right are reversed"
	return true

func test_joint_selection_uses_one_visible_gap():
	var graph:=TrackGraph.new()
	graph.add_node("a",Vector3.ZERO); graph.add_node("b",Vector3(500,0,0))
	graph.add_edge("line","a","b")
	for focus in [10.0,50.0,110.0]:
		var choice:=Model.listening_joint(graph,Vector3(focus,2,5.8))
		if choice.edge!="line" or absf(choice.point.x-(Layout.OFFSET+choice.joint*Layout.SPACING))>.00001: return "audible gap differs from visible gap"
	return true

func test_body_v2_timing_at_all_speeds_and_directions():
	for speed in [25.0,30.0,60.0,71.6,100.0,120.0,130.0,160.0]:
		for direction in [1,-1]:
			for fps in [30.0,60.0,120.0]:
				var v: float=speed/3.6
				var scheduler:=Scheduler.new()
				scheduler.setup([{x=3.0,cls=0,car=1},{x=5.56,cls=1,car=1}],13,6.5)
				var times: Dictionary={}
				for frame in int(60/v*fps):
					var now: float=frame/fps
					var head: float=100.0+direction*v*now
					var positions:=[]
					for a in scheduler.axles: positions.append({edge="line",dir=direction,length=500,s=head-direction*(a.x-v*(Data.KERNEL_LEAD+Data.LOOKAHEAD))})
					for h in scheduler.advance(positions,v):
						var arrival: float=now-h.late+Data.KERNEL_LEAD+Data.LOOKAHEAD
						if h.axle==0: times[h.joint]=arrival
						elif times.has(h.joint) and absf(arrival-times[h.joint]-2.56/v)>.0001: return "speed-dependent pair timing differs"
	return true
