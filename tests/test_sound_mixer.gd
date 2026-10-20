extends RefCounted
const Prefs:=preload("res://game/audio_preferences.gd")
const Menu:=preload("res://game/audio_menu.gd")

func test_existing_shared_settings_migrate_without_resetting_user_mix():
	var path:="user://test-audio-migration.cfg"
	var config:=ConfigFile.new()
	config.set_value("levels","traction",-8.0);config.set_value("levels","wind",-4.0)
	config.set_value("levels","body",2.0);config.set_value("levels","ambience",-10.0)
	config.save(path)
	var prefs:=Prefs.new(path)
	var ok: bool=prefs.levels.fans==-8 and prefs.levels.horn==-8 and prefs.levels.compressor==-8 and prefs.levels.passing_air==-4 and prefs.levels.rattles==2 and prefs.levels.doors==-10
	prefs.levels.fans=4;prefs.muted.horn=true;prefs.save(path)
	var loaded:=Prefs.new(path)
	ok=ok and loaded.levels.fans==4 and loaded.levels.traction==-8 and loaded.muted.horn and not loaded.muted.fans
	DirAccess.remove_absolute(path);Prefs.new()
	return ok

func test_muting_joint_clacks_leaves_rolling_wind_and_squeal_independent():
	var prefs:=Prefs.new("user://test-nonexistent-audio.cfg")
	prefs.muted.impacts=true;prefs.levels.wind=-6;prefs.levels.rolling=4;prefs.apply()
	var ok:=AudioServer.is_bus_mute(AudioServer.get_bus_index("RailImpacts"))
	for bus in ["RailRolling","RailSqueal","TrainWind","PassingAir","CoachBody"]:
		ok=ok and not AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))
	ok=ok and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("TrainWind"))==-6 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("PassingAir"))==0
	Prefs.new();return ok

func test_every_layer_has_an_explanation_and_one_controller_group():
	var grouped:=["master"]
	for group in Menu.GROUPS:
		for key in Menu.GROUPS[group].keys:
			if grouped.has(key):return "Duplicate sound category "+key
			grouped.append(key)
			if Menu.parent(key)!=group:return "Incorrect Back destination"
	for key in Prefs.LAYERS:
		if not grouped.has(key) or not Menu.NAMES.has(key) or not Menu.DETAILS.has(key):return "Hidden sound channel "+key
	return grouped.size()==Prefs.LAYERS.size()

func test_invalid_levels_cannot_poison_the_native_mixer():
	var path:="user://test-audio-invalid.cfg";var config:=ConfigFile.new()
	config.set_value("levels","wind",NAN);config.set_value("levels","horn","loud");config.set_value("levels","rolling",999)
	config.save(path)
	var prefs:=Prefs.new(path)
	var ok: bool=prefs.levels.wind==0 and prefs.levels.horn==0 and prefs.levels.rolling==6
	DirAccess.remove_absolute(path);Prefs.new();return ok
