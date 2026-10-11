extends RefCounted
## Presentation-only clock follower. Owns no world and never advances simulation.
const Daylight := preload("res://sim/daylight.gd")
var environment: Environment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var sky_material: ShaderMaterial
var state: Dictionary={}
var updates:=0
var _clock:=-INF
var _wall:=-1000000

func _init(env: Environment, daylight: DirectionalLight3D, parent: Node3D) -> void:
	environment=env;sun=daylight
	sky_material=env.sky.sky_material
	moon=DirectionalLight3D.new();moon.name="Moonlight"
	moon.light_color=Color(.64,.73,.91)
	moon.shadow_enabled=false
	moon.set_meta("no_night_shadow",true)
	parent.add_child(moon)

func update(clock: float,force: bool=false) -> bool:
	var now:=Time.get_ticks_msec()
	if not force:
		if absf(clock-_clock)<5.0:return false
		if now-_wall<500 and absf(clock-_clock)<300.0:return false
	_clock=clock;_wall=now;updates+=1
	state=Daylight.sample(clock)
	sun.basis=Basis.looking_at(-state.sun,Vector3.UP)
	sun.light_energy=state.sun_energy;sun.visible=state.sun_energy>.0001
	sun.light_color=Color(1.0,.96,.89).lerp(Color(1.0,.43,.16),state.warmth*.8)
	moon.basis=Basis.looking_at(-state.moon,Vector3.UP)
	moon.light_energy=state.moon_energy;moon.visible=state.moon_energy>.0001
	sky_material.set_shader_parameter("sun_direction",state.sun)
	sky_material.set_shader_parameter("daylight",state.daylight)
	sky_material.set_shader_parameter("twilight",state.twilight)
	sky_material.set_shader_parameter("night",state.night)
	environment.ambient_light_energy=lerpf(.65,.42,state.daylight)
	environment.fog_light_color=Color(.055,.075,.115).lerp(Color(.78,.84,.85),state.daylight)
	environment.fog_light_color=environment.fog_light_color.lerp(Color(.55,.27,.14),state.twilight*.22)
	return true
