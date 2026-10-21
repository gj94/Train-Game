extends RefCounted
## Home uses the same preference files and labels as the in-journey menus.
const Controller:=preload("res://game/controller_preferences.gd")
const Audio:=preload("res://game/audio_menu.gd")
const Style:=preload("res://game/menu_theme.gd")
var controller_path:=Controller.FILE
var audio_path:="user://audio.cfg"
var sound
var controls: Dictionary={}

func build(home,page: String) -> void:
	if page=="controller":
		controls=Controller.read_settings(controller_path)
		home.settings_title.text="Controller preferences"
		_note(home,"These preferences also apply while driving, walking and looking around. Your control layout stays the same.")
		for entry in [["deadzone","Stick deadzone","%.0f%%" % (controls.deadzone*100),"Increase if the camera moves with your sticks centred."],
			["sensitivity","Look sensitivity","%.2f×" % controls.sensitivity,"How quickly the right stick turns your view."],
			["invert","Invert vertical look","On" if controls.invert_y else "Off","Reverse up and down when looking with the right stick."],
			["vibration","Vibration","Off" if controls.vibration==0 else "%.0f%%" % (controls.vibration*100),"Strength of controller vibration."]]:
			home._setting(entry[1]+" · "+entry[2],func():_controller_change(home,entry[0],entry[1])).tooltip_text=entry[3]
			_note(home,entry[3])
		home._setting("Restore controller defaults",func():_controller_change(home,"defaults","Restore"))
		return
	if sound==null or sound.settings_path!=audio_path:sound=preload("res://game/audio_preferences.gd").new(audio_path)
	var key:=page.trim_prefix("sound:")
	if page=="sound":
		home.settings_title.text="Sound mixer"
		_note(home,"Adjust each layer independently. 0 dB is the standard level. Your mix follows you into every journey.")
		_warning(home)
		home._setting(Audio.NAMES.master+" · "+Audio.level_text(sound,"master"),func():home.show_settings("sound:master"))
		for group in Audio.GROUPS:
			home._setting(Audio.GROUPS[group].title.capitalize(),func():home.show_settings("sound:"+group))
		home._setting("Listening preset · "+_preset_name(),func():home.show_settings("sound:presets"))
		home._setting("Headphone direction cues · "+("On" if sound.headphones else "Off"),func():_toggle(home,"headphones","Headphone"))
		home._setting("Reduced dynamic range · "+("On" if sound.quiet else "Off"),func():_toggle(home,"quiet","Reduced"))
	elif key=="presets":
		home.settings_title.text="Listening presets"
		_note(home,"Choosing a preset resets all layer volumes and mutes. Use the mixer to fine-tune afterwards.")
		for entry in [["speakers","Speakers","Standard full gameplay mix."],["headphones","Headphones","Full gameplay mix with headphone direction cues."],
			["quiet","Quiet / night","Reduced dynamic range, softer wind and joint impacts."],["reference","Approved track reference","Diagnostic track reference; bypasses the gameplay layer controls."]]:
			home._setting(entry[1]+(" · selected" if _preset_name()==entry[1] else ""),func():
				var result: int=sound.preset(entry[0]);home.show_settings(page);home.focus_setting(entry[1]);home.preference_result(result))
			_note(home,entry[2])
	elif key in Audio.GROUPS:
		home.settings_title.text=Audio.GROUPS[key].title.capitalize();_warning(home)
		for layer in Audio.GROUPS[key].keys:
			home._setting(Audio.NAMES[layer]+" · "+Audio.level_text(sound,layer),func():home.show_settings("sound:"+layer))
	elif key in Audio.NAMES:
		home.settings_title.text=Audio.NAMES[key]
		_note(home,Audio.DETAILS[key]);_warning(home)
		_note(home,"Current level: "+Audio.level_text(sound,key)+". Adjust in 2 dB steps; mute keeps this level for later.")
		home._setting("Quieter −2 dB",func():_level(home,key,-2,"Quieter"))
		home._setting("Louder +2 dB",func():_level(home,key,2,"Louder"))
		home._setting("Unmute this layer" if sound.muted.get(key,false) else "Mute this layer",func():
			sound.muted[key]=not sound.muted.get(key,false);_save_sound(home,page,"Unmute" if sound.muted[key] else "Mute"))
		home._setting("Restore standard level",func():sound.levels[key]=0.0;sound.muted[key]=false;_save_sound(home,page,"Restore"))

func _controller_change(home,key: String,focus: String) -> void:
	Controller.cycle(controls,key)
	var result:=Controller.write_settings(controls,controller_path)
	# Failed writes must not be presented as saved or silently discarded.
	if result==OK:home.show_settings("controller");home.focus_setting(focus)
	home.preference_result(result)

func _toggle(home,key: String,focus: String) -> void:
	sound.set(key,not sound.get(key));_save_sound(home,"sound",focus)

func _level(home,key: String,change: float,focus: String) -> void:
	sound.levels[key]=clampf(sound.levels[key]+change,-60,6);_save_sound(home,"sound:"+key,focus)

func _save_sound(home,page: String,focus: String) -> void:
	sound.apply();var result: int=sound.save()
	home.show_settings(page);home.focus_setting(focus);home.preference_result(result)

func _preset_name() -> String:
	return "Approved track reference" if sound.reference else "Quiet / night" if sound.quiet else "Headphones" if sound.headphones else "Speakers"

func _warning(home) -> void:
	if sound.reference:_note(home,"Approved track reference is active: gameplay layer controls are bypassed. Choose Speakers or Headphones under Listening preset to tune the full mix.")

func _note(home,text: String) -> void:
	var label:=Style.label(home.option_list,text,15,Style.MUTED);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

static func parent(page: String) -> Dictionary:
	if page=="controller":return {page="",focus="Controller preferences"}
	if page=="sound":return {page="",focus="Sound mixer"}
	var key:=page.trim_prefix("sound:")
	if key in Audio.NAMES:
		var group:=Audio.parent(key)
		return {page="sound" if group=="open" else "sound:"+group,focus=Audio.NAMES[key]}
	return {page="sound",focus="Listening preset" if key=="presets" else Audio.GROUPS.get(key,{}).get("title","").capitalize()}
