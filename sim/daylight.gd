extends RefCounted
## A repeatable tropical day, in the timetable's local clock (never wall time).
## Representative equinox at 9.6 N, solar noon 12:20. No calendar/weather claim.
const DAY := 86400.0
const NOON := 12.0 + 20.0 / 60.0

static func sample(clock: float) -> Dictionary:
	var hour:=fposmod(clock,DAY)/3600.0
	var angle: float=(hour-NOON)*PI/12.0
	var latitude:=deg_to_rad(9.6)
	# Geographic coordinates: +X east, -Z north; vector points toward the sun.
	var sun:=Vector3(-sin(angle),cos(latitude)*cos(angle),sin(latitude)*cos(angle)).normalized()
	var elevation:=rad_to_deg(asin(clampf(sun.y,-1,1)))
	var daylight:=smoothstep(-8.0,10.0,elevation)
	var direct:=smoothstep(-.8,9.0,elevation)
	var night:=1.0-smoothstep(-5.0,3.0,elevation)
	var twilight: float=smoothstep(-10.0,-1.0,elevation)*(1.0-smoothstep(1.0,16.0,elevation))
	return {hour=hour,sun=sun,moon=-sun,elevation=elevation,daylight=daylight,
		sun_energy=1.55*direct,moon_energy=.055*night,night=night,twilight=twilight,
		warmth=1.0-smoothstep(0.0,25.0,elevation)}
