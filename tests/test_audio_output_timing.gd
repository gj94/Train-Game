extends RefCounted
const Timing := preload("res://game/audio_output_timing.gd")
const Data := preload("res://game/body_v2_data.gd")
const Layout := preload("res://game/rail_joint_layout.gd")
const Contacts := preload("res://game/track_contacts.gd")
const Sweep := preload("res://game/contact_sweep.gd")

func test_buffered_prediction_keeps_full_attack_at_multiple_speeds():
	var old_latency: float=Timing.output_latency
	var old_period: float=Timing.mix_period
	var result=true
	for latency in [0.0,.02,.08,.25]:
		for fps in [30.0,60.0,144.0]:
			Timing.output_latency=latency
			Timing.mix_period=.021333333
			var horizon: float=Timing.prediction_seconds(1/fps)
			# A contact can first enter the horizon just after this display frame.
			# Even the next frame and worst mixer phase must leave the entire
			# pre-contact waveform, for both the cling and following clang.
			var remaining: float=horizon-1/fps-latency-Timing.mix_period
			if remaining<Data.KERNEL_LEAD-.000001: result="Prediction cuts the approved attack after device buffering"
			for kmh in [30.0,60.0,120.0]:
				var metres: float=horizon*kmh/3.6
				var earliest_heard: float=metres/(kmh/3.6)-Data.KERNEL_LEAD-latency-Timing.mix_period
				if earliest_heard<1/fps-.000001: result="Predictor cannot submit before the mixer deadline"
	Timing.output_latency=old_latency; Timing.mix_period=old_period
	return result

func test_website_39m_contacts_keep_speed_dependent_axle_pairs():
	if Layout.SPACING!=39: return "Game does not use approved website SWR spacing"
	var graph:=TrackGraph.new()
	graph.add_node("a",Vector3.ZERO); graph.add_node("b",Vector3(1000,0,0))
	graph.add_edge("line","a","b")
	var layout:=Contacts.new(graph)
	for direction in [-1,1]:
		for kmh in [30.0,60.0,120.0]:
			var v: float=kmh/3.6
			var sweep:=Sweep.new()
			var impacts: Array=[]
			var start:=5.0 if direction==1 else 395.0
			for frame in range(3001):
				var elapsed: float=frame/120.0
				var positions: Array=[]
				for back in [0.0,2.56]:
					positions.append({edge="line",s=start+direction*(elapsed*v-back),dir=direction})
				for event in sweep.advance(positions,layout,1.0/120):
					impacts.append({axle=event.axle,id=event.contact.id,time=elapsed+event.relative})
			var seen: Dictionary={}
			var last: Dictionary={}
			for hit in impacts:
				if last.has(hit.axle):
					if absf((hit.time-last[hit.axle])*v-39)>.0001: return "Same axle repeats at the wrong physical spacing"
				last[hit.axle]=hit.time
				var key=str(hit.id)
				if seen.has(key):
					if absf(absf(hit.time-seen[key])*v-2.56)>.0001: return "Cling/clang axle separation changed"
				else: seen[key]=hit.time
	return true
