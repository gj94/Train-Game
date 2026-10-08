extends RefCounted
const Rattle:=preload("res://sim/coach_rattle.gd")

func test_rattle_events_are_repeatable_and_silent_stopped_or_paused():
	var a:=Rattle.new(82);var b:=Rattle.new(82)
	var count:=0
	for tick in 1800:
		var x:=tick/60.0*16.667
		var first:=a.advance(x,16.667,0,1.0/60)
		if first!=b.advance(x,16.667,0,1.0/60):return "not repeatable"
		if not first.is_empty():count+=1
	var next:=a.next_distance
	if not a.advance(500,16.667,.2,0).is_empty() or a.next_distance!=next:return "pause advanced rattle"
	for tick in 100:
		if not a.advance(500,0,.2,.016).is_empty():return "stationary body rattles"
	return count>=3 and count<15

func test_icf_is_more_active_than_lhb_and_speed_changes_cadence_not_pitch():
	var counts:={}
	var gain:={}
	for family in ["icf","lhb"]:
		for speed in [10.0,30.0]:
			var sound:=Rattle.new(17,family)
			var count:=0;var level:=0.0
			for tick in 12000:
				var event:=sound.advance(tick*.01*speed,speed,0,.01)
				if event.is_empty():continue
				count+=1;level+=event.gain
				if event.has("pitch") or event.variant<0 or event.variant>=8:return "pitch tied to speed / invalid bank"
			counts[family+str(int(speed))]=count;gain[family+str(int(speed))]=level/maxi(1,count)
	return counts.icf30>counts.icf10 and counts.icf30>counts.lhb30 and gain.icf30>gain.lhb30*2

func test_rattle_seeks_and_long_frames_do_not_emit_a_backlog():
	var sound:=Rattle.new(1)
	sound.advance(0,20,0,.01)
	if not sound.advance(10000,20,.1,.01).is_empty():return "seek emitted burst"
	if not sound.advance(0,20,.1,.01).is_empty():return "reverse seek emitted burst"
	var one:=sound.advance(640,20,0,32)
	return one.size()<=4 and sound.next_distance>640
