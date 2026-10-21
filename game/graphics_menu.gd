extends RefCounted
## Button-based choices use the existing mouse, keyboard and Xbox focus navigation.
static func build(hud,kind: String) -> void:
	var settings=hud.graphics_options
	var parts:=kind.split(":")
	var entries:=[]
	hud._heading.text="GRAPHICS"
	hud._body.text="Preset: [b]"+settings.preset_name()+"[/b] · Changes apply immediately and save on this PC.\nD-pad / LS move · A select · B / Esc back · Resume to compare.\n"+settings.notice
	if parts.size()>2 and parts[1]=="option" and settings.OPTIONS.has(parts[2]):
		var key: String=parts[2]
		var option: Dictionary=settings.OPTIONS[key]
		hud._heading.text=option.label.to_upper()
		hud._body.text=option.help+"\n\nCurrent: [b]"+settings.label_for(key)+"[/b]\nChoose a value to apply it and return."
		for i in option.values.size():
			entries.append([("✓  " if settings.values[key]==option.values[i] else "")+option.labels[i],"graphics:set:"+key+":"+str(i)])
	elif parts.size()==2 and settings.GROUPS.has(parts[1]):
		hud._heading.text=settings.GROUPS[parts[1]]
		for key in settings.OPTIONS:
			if settings.OPTIONS[key].group==parts[1]:
				entries.append([settings.OPTIONS[key].label+"  ·  "+settings.label_for(key),"graphics:option:"+key])
	else:
		for label in ["Performance","Balanced","High","Epic"]:
			entries.append(["Use "+label+" preset"+("  ·  current" if label==settings.preset_name() else ""),"graphics:preset:"+label])
		for group in settings.GROUPS:entries.append([settings.GROUPS[group].capitalize()+"…","graphics:"+group])
		entries.append(["Resume and compare  ·  F10 shows performance","graphics:resume"])
	entries.append(["Back","graphics:back"])
	var overview: String=hud._body.text
	for entry in entries:
		var button: Button=hud._button(hud._buttons,entry[0],entry[1])
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		var explanation:=overview
		if str(entry[1]).begins_with("graphics:option:"):
			var key: String=str(entry[1]).get_slice(":",2)
			explanation="[b]"+settings.OPTIONS[key].label+"[/b]\n\n"+settings.OPTIONS[key].help+"\n\nCurrent: [b]"+settings.label_for(key)+"[/b]\n\nSelect to see the available values."
		elif str(entry[1]).begins_with("graphics:preset:"):
			var preset: String=str(entry[1]).get_slice(":",2)
			var descriptions:={"Performance":"Reduces render resolution, shadows and distant detail to favour frame rate.","Balanced":"Keeps native resolution with lighter shadows, anti-aliasing and mesh detail.","High":"The default presentation: full scenery, detailed trains and high-quality shadows.","Epic":"Longer detail ranges, close surface detail and nearby station-light shadows. Dense stations need more GPU time."}
			explanation="[b]"+preset+" preset[/b]\n\n"+descriptions[preset]+"\n\nYou can adjust individual settings after applying a preset.\n\nCurrent preset: [b]"+settings.preset_name()+"[/b]"
		button.focus_entered.connect(func():hud._body.text=explanation)
		button.mouse_entered.connect(func():hud._body.text=explanation)
