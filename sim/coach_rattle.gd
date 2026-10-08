extends RefCounted
## Repeatable per-coach loose-fitting events, driven by travel and body jolts.
## Presentation cue scheduler; no changes to railway physics or approved clacks.
var rng:=RandomNumberGenerator.new()
var family:="icf"
var next_distance:=0.0
var last_distance:=0.0
var cooldown:=0.0
var last_jolt:=0.0
var ready:=false

func _init(seed_value: int=1,coach_family: String="icf") -> void:
	rng.seed=seed_value;family=coach_family

func reset(distance: float) -> void:
	last_distance=distance;next_distance=distance+_spacing();cooldown=0;last_jolt=0;ready=true

func _spacing() -> float:
	return rng.randf_range(38,130) if family=="icf" else rng.randf_range(95,260)

func advance(distance: float,speed: float,jolt: float,delta: float) -> Dictionary:
	if delta<=0:return {}
	if not ready or distance<last_distance or distance-last_distance>maxf(40,speed*delta*2+5):
		reset(distance);return {}
	last_distance=distance;cooldown=maxf(0,cooldown-delta)
	var knock: bool=jolt>.055 and last_jolt<=.055
	last_jolt=jolt
	if speed<.25:return {}
	var due:=distance>=next_distance
	if not due and not (knock and cooldown<=0 and rng.randf()<(.4 if family=="icf" else .14)):return {}
	# Missed events during fast-forward are not replayed as a crowded burst.
	next_distance=distance+_spacing()
	if cooldown>0:return {}
	cooldown=rng.randf_range(.8,1.7)
	var movement:=smoothstep(.25,12,speed)
	return {variant=rng.randi_range(0,7),gain=(.16 if family=="icf" else .055)*rng.randf_range(.65,1.15)*movement*(1+clampf(jolt*8,0,.65)),position=rng.randf_range(-7,7)}
