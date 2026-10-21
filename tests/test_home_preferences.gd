extends RefCounted
const Controls:=preload("res://game/controller_preferences.gd")
const PATH:="res://.local/r45/home-unit.cfg"

func test_hardware_settings_sanitise_legacy_values_and_reach_runtime():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var config:=ConfigFile.new();config.set_value("controller","deadzone",4.0);config.set_value("controller","sensitivity","bad")
	config.set_value("controller","vibration",-2);config.set_value("controller","invert_y",true);config.set_value("controller","tsw_layout",false)
	if config.save(PATH)!=OK:return "Cannot create isolated settings"
	var pad:=preload("res://game/controller_input.gd").new();pad.settings_path=PATH;pad._load_settings()
	var ok:=is_equal_approx(pad.deadzone,.45) and pad.sensitivity==1 and pad.vibration==0 and pad.invert_y and pad.tsw_layout
	pad.free();DirAccess.remove_absolute(PATH);return ok

func test_home_controller_changes_persist_to_the_playing_controller():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var values:=Controls.DEFAULTS.duplicate()
	for key in ["deadzone","sensitivity","invert","vibration"]:Controls.cycle(values,key)
	if Controls.write_settings(values,PATH)!=OK:return "Cannot create isolated settings"
	var pad:=preload("res://game/controller_input.gd").new();pad.settings_path=PATH;pad._load_settings()
	var ok:=true
	for key in values:ok=ok and pad.get(key)==values[key]
	pad.free();DirAccess.remove_absolute(PATH);return ok

func test_audio_presets_respect_instance_file_and_report_failed_writes():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var sound:=preload("res://game/audio_preferences.gd").new(PATH)
	var ok: bool=sound.preset("quiet")==OK
	var restored:=preload("res://game/audio_preferences.gd").new(PATH)
	ok=ok and restored.quiet and restored.levels.impacts==-3.0 and restored.levels.wind==-4.0
	restored.levels.horn=-12.0;restored.muted.rolling=true;ok=ok and restored.save()==OK
	var verify:=preload("res://game/audio_preferences.gd").new(PATH)
	ok=ok and verify.levels.horn==-12.0 and verify.muted.rolling
	verify.settings_path="res://.local/r45/absent-settings-parent/file.cfg"
	ok=ok and verify.save()!=OK
	DirAccess.remove_absolute(PATH);return ok
