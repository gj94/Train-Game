extends RefCounted
## Presentation-independent sprung-body response, metres and radians.
## Tuned for restrained ride cues; not measured WAP/LHB suspension parameters.
## Track excitation is spatial: the same defect is encountered by each car.
var displacement := Vector3.ZERO
var velocity := Vector3.ZERO
var angles := Vector3.ZERO
var angular_velocity := Vector3.ZERO
var distance := 0.0

func reset(at: float=0.0) -> void:
	displacement=Vector3.ZERO; velocity=Vector3.ZERO
	angles=Vector3.ZERO; angular_velocity=Vector3.ZERO; distance=at

func contact(speed: float,strength: float,along: float,side: float) -> void:
	# along: +1 at the leading bogie, -1 at the trailing bogie.
	var impulse := clampf(speed/16.667,0,2.2)*clampf(strength,0,1.2)
	velocity.y+=.026*impulse
	angular_velocity.x+=.006*impulse*clampf(along,-1,1)
	angular_velocity.z-=.009*impulse*clampf(side,-1,1)
	velocity.x+=.008*impulse*clampf(side,-1,1)

func advance(delta: float,to_distance: float,speed: float,acceleration: float,lateral: float) -> void:
	if delta<=0: return
	var count := clampi(ceili(delta*120),1,64)
	var dt := delta/count
	var start := distance
	for i in count:
		distance=lerpf(start,to_distance,float(i+1)/count)
		var rough := clampf(speed/22.222,0,1.6)
		var heave := rough*(.0035*sin(distance*TAU/8.3)+.0016*sin(distance*TAU/2.7+.8))
		var sway := rough*(.004*sin(distance*TAU/17.7)+.0014*sin(distance*TAU/5.1))
		var lateral_force := clampf(lateral,-1.8,1.8)
		var accel := clampf(acceleration,-1.5,1.5)
		var target := Vector3(sway-lateral_force*.014,heave,accel*.012)
		var tilt := Vector3(accel*.006+rough*.0006*sin(distance*TAU/12.3),0,lateral_force*.008+sway*.18)
		for axis in 3:
			var body := spring(displacement[axis],velocity[axis],target[axis],[1.15,1.65,1.7][axis],.38,dt)
			displacement[axis]=body.x; velocity[axis]=body.y
			var rotation := spring(angles[axis],angular_velocity[axis],tilt[axis],[1.25,1.0,.95][axis],.42,dt)
			angles[axis]=rotation.x; angular_velocity[axis]=rotation.y
	# Hard travel stops only protect pathological contact clusters / imported track.
	for axis in 3:
		if absf(displacement[axis])>.045: displacement[axis]=clampf(displacement[axis],-.045,.045); velocity[axis]=0
		if absf(angles[axis])>.024: angles[axis]=clampf(angles[axis],-.024,.024); angular_velocity[axis]=0

static func spring(x: float,v: float,target: float,hz: float,damping: float,dt: float) -> Vector2:
	# Exact underdamped solution for a constant forcing interval. Stable at 32x.
	var omega := TAU*hz
	var decay := damping*omega
	var frequency := omega*sqrt(1-damping*damping)
	var offset := x-target
	var b := (v+decay*offset)/frequency
	var sine := sin(frequency*dt)
	var cosine := cos(frequency*dt)
	var envelope := exp(-decay*dt)
	return Vector2(target+envelope*(offset*cosine+b*sine),envelope*(v*cosine-(decay*b+frequency*offset)*sine))
