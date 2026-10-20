extends RefCounted
const NAMES:={"master":"Master volume","traction":"Traction motors","fans":"Engine cooling fans","horn":"Train horns","compressor":"Air compressor",
	"rolling":"Rolling rumble & hiss","impacts":"Rail-joint clacks","squeal":"Wheel / flange squeal","wind":"Own-train wind / head-out",
	"passing_air":"Passing-train air & wake","body":"Joint thumps through the floor","rattles":"Coach metallic rattles",
	"ambience":"Interior ventilation","footsteps":"Walking footsteps","doors":"Doors & latches","brake_air":"Brake-release air"}
const GROUPS := {
	"rail":{title="RAIL & WHEELS",keys=["rolling","impacts","squeal","body","rattles"]},
	"air":{title="WIND & PASSING TRAINS",keys=["wind","passing_air"]},
	"machinery":{title="MOTORS & EQUIPMENT",keys=["traction","fans","horn","compressor"]},
	"inside":{title="INTERIOR & MOVEMENT",keys=["ambience","footsteps","doors","brake_air"]}}
const DETAILS := {
	"master":"Overall output. The other controls adjust independent sound layers.",
	"rolling":"Continuous wheel-on-rail rumble and hiss. Does not raise the wind, joint clacks or curve squeal.",
	"impacts":"Airborne cling-clang when each axle crosses a real joint or point contact. Volume only; timing and pitch remain physical.",
	"squeal":"Tonal wheel / flange sound on curves. Does not affect rolling hiss or joint clacks.",
	"body":"Low-frequency joint thumps transmitted through your occupied carriage. Separate from airborne clacks and metallic rattles.",
	"rattles":"Intermittent coach-body metallic noises, particularly in ICF stock.",
	"wind":"Air around your assigned train, strongest in head-out and exposed views. Speed and your position still affect it.",
	"passing_air":"Nose, body and wake air from other trains. Their wheels, horns and motors use their own controls.",
	"traction":"Electric motor whine under power or braking. Cooling fans and the horn are separate.",
	"fans":"WAP / Vande Bharat cooling fans and auxiliary hum.",
	"horn":"Both your horn and nearby AI horns. Does not change when departure horns are triggered.",
	"compressor":"Periodic compressor operation aboard and beside locomotives.",
	"ambience":"Ventilation inside air-conditioned coaches.",
	"footsteps":"Your footsteps on carriage floors and platforms.",
	"doors":"Door movement, latches and carriage transitions.",
	"brake_air":"The local air-release cue when releasing the brakes."}

static func parent(key: String) -> String:
	for group in GROUPS:
		if key in GROUPS[group].keys:return group
	return "open"

static func level_text(prefs,key: String) -> String:
	return "MUTED · %+.0f dB" % prefs.levels[key] if prefs.muted.get(key,false) else "%+.0f dB" % prefs.levels[key]
static func show(game,page: String="open",focus: int=0) -> void:
	game.controller.remember_overlay_entry("audio")
	game._set_paused(true);game.dispatcher.set_open(false)
	var prefs=game.audio_options
	var options:=[["Back","pad_return:audio"]]
	var title:="SOUND MIXER"
	var body:="Adjust each sound independently. Saved for this PC; resume to hear the mix.\n0 dB is the approved standard level. Mute keeps your chosen level for later."
	if prefs.reference:body+="\nAPPROVED REFERENCE is active: gameplay layer controls are bypassed. Select Speakers or Headphones to tune the full mix."
	if page in GROUPS or page=="levels":
		title=GROUPS[page].title if page in GROUPS else "ALL SOUND LAYERS"
		options=[["Back to sound mixer","audio:open"]]
		var keys: Array=GROUPS[page].keys if page in GROUPS else prefs.LAYERS.keys()
		for key in keys:options.append([NAMES[key]+" · "+level_text(prefs,key),"audio:layer:"+key])
		if page=="rail":
			body+="\nThe [ / ] track-group boost also affects rolling, clacks and squeal on your current train: %+.0f dB." % linear_to_db(game.audio.track_level)
			options.append(["Reset current train's track-group boost","audio:track_reset"])
			options.append(["Second axle / clang balance…","audio:balance"])
	elif page in NAMES:
		title=NAMES[page].to_upper()
		body=DETAILS[page]+"\n\nCurrent level: "+level_text(prefs,page)+"\nAdjust in 2 dB steps; use Mute for complete silence. Resume to listen."
		if prefs.reference:body+="\nReference mode bypasses gameplay layers. Return to the mixer and select a gameplay preset first."
		options=[["Back","audio:group:"+parent(page)],
			["Quieter −2 dB","audio:level:"+page+":-2"],["Louder +2 dB","audio:level:"+page+":2"],
			["Unmute" if prefs.muted.get(page,false) else "Mute this layer","audio:mute:"+page],
			["Restore standard level","audio:reset:"+page]]
	elif page=="balance":
		title="SECOND AXLE / CLANG BALANCE"
		body="Current train: %+.0f dB relative to the first axle.\nChanges the second strike's prominence without changing axle spacing or pitch." % game.audio.clang_balance_db
		options=[["Back to rail & wheels","audio:group:rail"],["Second axle quieter −1 dB","audio:balance_level:-1"],["Second axle louder +1 dB","audio:balance_level:1"],["Restore approved balance","audio:balance_reset"]]
	else:
		options.append(["Master volume · "+level_text(prefs,"master"),"audio:layer:master"])
		for group in GROUPS:options.append([GROUPS[group].title.capitalize()+"…","audio:group:"+group])
		options.append_array([["All sound layers…","audio:levels"],
			["Preset · Speakers (reset mix)","audio:preset:speakers"],["Preset · Headphones (reset mix)","audio:preset:headphones"],
			["Preset · Quiet / night (reset mix)","audio:preset:quiet"],["Preset · Approved track reference","audio:preset:reference"],
			["Headphone direction cues: "+("ON" if prefs.headphones else "OFF"),"audio:toggle:headphones"],
			["Reduced dynamic range: "+("ON" if prefs.quiet else "OFF"),"audio:toggle:quiet"]])
	game.save_load.show(title,body,options)
	game.hud.save_menu.back_action=options[0][1]
	if focus<game.hud._buttons.get_child_count():game.hud._buttons.get_child(focus).grab_focus()
static func action(game,command: String) -> void:
	var parts:=command.split(":");var prefs=game.audio_options
	var focus:=0;var page:="open"
	var control=game.get_viewport().gui_get_focus_owner()
	if control!=null and control.get_parent()==game.hud._buttons:focus=control.get_index()
	match parts[1]:
		"open","levels","balance":show(game,parts[1]);return
		"group","layer":show(game,parts[2]);return
		"preset":prefs.preset(parts[2])
		"level":prefs.levels[parts[2]]=clampf(prefs.levels[parts[2]]+float(parts[3]),-60,6);page=parts[2]
		"mute":prefs.muted[parts[2]]=not prefs.muted.get(parts[2],false);page=parts[2]
		"reset":prefs.levels[parts[2]]=0.0;prefs.muted[parts[2]]=false;page=parts[2]
		"toggle":prefs.set(parts[2],not prefs.get(parts[2]))
		"track_reset":game.audio.track_level=1.0;page="rail"
		"balance_level":game.audio.adjust_clang_balance(float(parts[2]));page="balance"
		"balance_reset":game.audio.clang_balance_db=0.0;page="balance"
	prefs.apply();prefs.save()
	for sound in game.train_audio.values():sound.refresh_mix()
	show(game,page,focus)
