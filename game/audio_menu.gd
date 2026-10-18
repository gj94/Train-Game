extends RefCounted
const NAMES:={"master":"Master volume","traction":"Motors, fans & horn","rolling":"Rolling wheels","impacts":"Rail joints","squeal":"Curve squeal","wind":"Passing air & wind","body":"Coach body & rattles","ambience":"Interior & movement"}
static func show(game,page: String="open",focus: int=0) -> void:
	game._set_paused(true);game.dispatcher.set_open(false)
	var prefs=game.audio_options
	var options:=[["Back","save:back"]]
	var title:="AUDIO";var body:="Tune the mix for your speakers or headphones. Settings are saved for this PC.\nReference keeps the approved track mix for comparison."
	if page=="levels":
		title="AUDIO LAYERS";body="Choose a layer to adjust its volume. Changes take effect when you resume."
		options=[["Back to audio settings","audio:open"]]
		for key in prefs.LAYERS:options.append(["%s · %+.0f dB" % [NAMES[key],prefs.levels[key]],"audio:layer:"+key])
	elif page in NAMES:
		title=NAMES[page].to_upper();body="Current level: %+.0f dB\nAdjust in 2 dB steps. Zero uses the standard mix; −60 is effectively silent." % prefs.levels[page]
		options=[["Back to layers","audio:levels"],["Quieter −2 dB","audio:level:"+page+":-2"],["Louder +2 dB","audio:level:"+page+":2"],["Restore standard level","audio:reset:"+page]]
	else:
		options.append_array([["Layer volumes…","audio:levels"],["Preset · Speakers","audio:preset:speakers"],["Preset · Headphones","audio:preset:headphones"],["Preset · Quiet / night listening","audio:preset:quiet"],["Preset · Approved track reference","audio:preset:reference"],["Headphone direction cues: "+("ON" if prefs.headphones else "OFF"),"audio:toggle:headphones"],["Reduced dynamic range: "+("ON" if prefs.quiet else "OFF"),"audio:toggle:quiet"]])
	game.save_load.show(title,body,options)
	game.hud.save_menu.back_action=options[0][1]
	if focus<game.hud._buttons.get_child_count():game.hud._buttons.get_child(focus).grab_focus()
static func action(game,command: String) -> void:
	var parts:=command.split(":");var prefs=game.audio_options
	var focus:=0;var page:="open"
	var control=game.get_viewport().gui_get_focus_owner()
	if control!=null and control.get_parent()==game.hud._buttons:focus=control.get_index()
	match parts[1]:
		"open":show(game);return
		"levels":show(game,"levels");return
		"layer":show(game,parts[2]);return
		"preset":prefs.preset(parts[2])
		"level":prefs.levels[parts[2]]=clampf(prefs.levels[parts[2]]+float(parts[3]),-60,6);page=parts[2]
		"reset":prefs.levels[parts[2]]=0.0;page=parts[2]
		"toggle":prefs.set(parts[2],not prefs.get(parts[2]))
	prefs.apply();prefs.save()
	for sound in game.train_audio.values():sound.refresh_mix()
	show(game,page,focus)
