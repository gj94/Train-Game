extends RefCounted
const Ride := preload("res://sim/ride_dynamics.gd")

func test_stationary_train_settles_without_random_shake():
	var r:=Ride.new()
	r.contact(20,1,1,1)
	for i in 600: r.advance(1.0/60,0,0,0,0)
	return true if r.displacement.length()<.000001 and r.angles.length()<.000001 else "suspension did not settle at rest"

func test_joint_impulse_changes_with_speed_and_bogie_end():
	var front:=Ride.new(); var rear:=Ride.new(); var slow:=Ride.new()
	front.contact(25,1,1,0); rear.contact(25,1,-1,0); slow.contact(5,1,1,0)
	for r in [front,rear,slow]: r.advance(.04,0,0,0,0)
	if front.displacement.y<=slow.displacement.y: return "speed has no effect on impact"
	if front.angles.x<=0 or rear.angles.x>=0: return "bogie pitching lever arm lost"
	return true

func test_one_rail_point_contact_rolls_body_to_correct_side():
	var left:=Ride.new(); var right:=Ride.new()
	left.contact(15,1,0,-1); right.contact(15,1,0,1)
	left.advance(.03,0,0,0,0); right.advance(.03,0,0,0,0)
	return true if left.angles.z>0 and right.angles.z<0 else "point impacts have no signed roll"

func test_braking_and_acceleration_pitch_in_opposite_directions():
	var r:=Ride.new()
	for i in 120: r.advance(1.0/60,0,0,.8,0)
	if r.angles.x<.003: return "traction has no body pitch"
	for i in 120: r.advance(1.0/60,0,0,-.8,0)
	return true if r.angles.x<-.003 else "braking does not pitch nose down"

func test_spatial_roughness_is_repeatable_across_frame_rates():
	var poses:=[]
	for fps in [30,60,120,240]:
		var r:=Ride.new()
		for i in fps*3: r.advance(1.0/fps,(i+1)*20.0/fps,20,0,0)
		poses.append(r.displacement)
	for pose in poses:
		if pose.distance_to(poses[-1])>.0003: return "roughness depends on rendering FPS"
	return true

func test_fast_forward_stays_finite_and_within_suspension_travel():
	var r:=Ride.new()
	for i in 100:
		r.contact(90,10,1,1)
		r.advance(32.0/30,(i+1)*90*32.0/30,90,12,90)
		if not r.displacement.is_finite() or not r.angles.is_finite(): return "unstable at 32x"
		if r.displacement.length()>.079 or r.angles.length()>.042: return "suspension travel exceeded"
	return true

func test_pause_does_not_integrate_and_reset_clears_impulses():
	var r:=Ride.new(); r.contact(20,1,1,1); r.advance(.04,1,20,0,0)
	var before:=r.displacement
	r.advance(0,100,40,1,1)
	if r.displacement!=before: return "pause moved body"
	r.reset(100)
	return true if r.displacement==Vector3.ZERO and r.angular_velocity==Vector3.ZERO and r.distance==100 else "reset retains old jolts"

func test_curve_loading_rolls_opposite_directions():
	var a:=Ride.new(); var b:=Ride.new()
	for i in 240:
		a.advance(1.0/120,0,0,0,1); b.advance(1.0/120,0,0,0,-1)
	return true if a.angles.z>.006 and b.angles.z<-.006 else "curve loading lost"
