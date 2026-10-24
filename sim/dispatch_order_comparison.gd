extends RefCounted
## Compare arrival order at the same downstream timing point. Booked slack can
## absorb following delay: a faster/higher-priority train alone is not a reason
## to detain another service when both orders preserve its punctuality.
static func compare(follow_eta: float,pass_eta: float,booked_arrival: float,slow_extra: float,slow_priority: int,fast_priority: int) -> Dictionary:
	var follow_delay:=maxf(0,follow_eta-booked_arrival)
	var pass_delay:=maxf(0,pass_eta-booked_arrival)
	var saved:=maxf(0,follow_delay-pass_delay)
	var weight: float=(10.0+fast_priority)/(10.0+slow_priority)
	var gain:=saved*weight-maxf(0,slow_extra)
	return {follow_eta=follow_eta,pass_eta=pass_eta,booked_arrival=booked_arrival,
		follow_delay=follow_delay,pass_delay=pass_delay,saved=saved,slow_extra=slow_extra,priority_weight=weight,
		gain=gain,worthwhile=fast_priority>slow_priority and saved>=15.0 and gain>15.0}
