extends RefCounted
const Sound := preload("res://game/platform_audio.gd")
const Space := preload("res://game/listening_space.gd")
const Acoustics := preload("res://game/platform_acoustics.gd")

class Playback extends RefCounted:
	var offsets:=[]
	func play_stream(_wave,offset: float,_volume: float,_pitch: float) -> int:
		offsets.append(offset);return offsets.size()

class Probe extends Sound:
	var playback:=Playback.new()
	func _route_for(_contact: Dictionary,_priority: float,_bypass: bool) -> Dictionary:
		return {bus="probe",playback=playback,player=_track,until=0.0,priority=0.0}

func late_event(age: float) -> Dictionary:
	# Exercise the real event scheduler with a captured native-submission boundary.
	# The separate PCM probe verifies that the submitted tail is actually audible.
	var sound:=Probe.new();sound._track=AudioStreamPlayer.new()
	sound._routed=[[null,null]];sound._ear={position=Vector3.ZERO,forward=Vector3.FORWARD,up=Vector3.UP}
	var event:={arrival=-age,source=Vector3(0,0,-3),started=false,virtual=false,ids=[],contact={},priority=1.0,bypass=false,gain=1.0,variant=0,end=.32-age}
	sound._events=[event];sound._start_event(event)
	var result:={virtual=event.virtual,offsets=sound.playback.offsets.duplicate()}
	sound._events.clear();event.clear();sound._track.free();sound.free()
	return result

func test_late_impact_plays_remaining_decay_without_replaying_attack():
	var event:=late_event(.12)
	var ok: bool=not event.virtual and event.offsets.size()==2 and event.offsets[0]>2.1 and event.offsets[0]<2.2
	return true if ok else "A 120ms-old impact with audible decay remaining was discarded"

func test_expired_impact_is_not_resurrected_after_a_long_stall():
	var event:=late_event(.6)
	return event.virtual and event.offsets.is_empty()

func test_gangway_transmits_more_rail_sound_without_opening_to_wind():
	for model in ["icf_sl","lhb_3a","vb_tc_cc"]:
		var middle:=Space.compartment(model,Vector3(0,2,0),24,0)
		var end:=Space.compartment(model,Vector3(0,2,11.5),24,0)
		var a:=Space.response(middle,true,"track");var b:=Space.response(end,true,"track")
		if b.x<a.x*1.4 or b.y<a.y*1.8:return "Coach end lacks stronger local bogie transmission: "+model
		if end.exposure!=middle.exposure:return "Closed gangway became an open external door"
	return true

func test_closed_passenger_space_suppresses_air_more_than_clacks():
	for model in ["icf_sl","lhb_3a","vb_tc_cc"]:
		var space:=Space.compartment(model,Vector3(0,2,0),24,0)
		if Space.response(space,false,"wind").x>Space.response(space,false,"track").x*.5:return "Passing air masks transmitted rail sound: "+model
	return Space.response({inside=false},false,"wind")==Vector2(1,18000)

func test_head_turn_pan_preserves_energy_even_with_pitch():
	var source:=Vector3(3,.7,-8);var ear:=Vector3(0,2,0)
	var energy: float=Acoustics.stereo(source,ear,Vector3.FORWARD).length_squared()
	for yaw in range(0,361,15):
		for pitch in [-.9,0,.8]:
			var basis:=Basis.from_euler(Vector3(pitch,deg_to_rad(yaw),0))
			if absf(Acoustics.stereo(source,ear,-basis.z,basis.y).length_squared()-energy)>.00001:return "Head turn changes total rail energy"
	return true
