extends RefCounted
## Shared hardware preferences for Home and the in-game controller menu.
const FILE:="user://controller.cfg"
const DEFAULTS:={deadzone=.18,sensitivity=1.0,vibration=.35,invert_y=false,tsw_layout=true}
const LIMITS:={deadzone=Vector2(.05,.45),sensitivity=Vector2(.25,3),vibration=Vector2(0,1)}

static func read_settings(path: String=FILE) -> Dictionary:
	var config:=ConfigFile.new();config.load(path)
	var values:=DEFAULTS.duplicate()
	for key in LIMITS:
		var value=config.get_value("controller",key,DEFAULTS[key])
		if (value is float or value is int) and is_finite(float(value)):
			values[key]=clampf(float(value),LIMITS[key].x,LIMITS[key].y)
	values.invert_y=config.get_value("controller","invert_y",false)==true
	# Both historical layouts migrate to the current context controls.
	return values

static func write_settings(values: Dictionary,path: String=FILE) -> Error:
	var config:=ConfigFile.new()
	for key in DEFAULTS:config.set_value("controller",key,values.get(key,DEFAULTS[key]))
	return config.save(path)

static func cycle(values: Dictionary,key: String) -> void:
	match key:
		"deadzone":values.deadzone=.12 if values.deadzone>=.30 else snappedf(values.deadzone+.06,.01)
		"sensitivity":values.sensitivity=.5 if values.sensitivity>=2.0 else values.sensitivity+.25
		"invert":values.invert_y=not values.invert_y
		"vibration":values.vibration=0.0 if values.vibration>=.7 else (.35 if values.vibration==0 else .7)
		"defaults":values.merge(DEFAULTS,true)
