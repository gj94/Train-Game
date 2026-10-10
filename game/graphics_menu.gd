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
		for label in ["Performance","Balanced","High"]:
			entries.append(["Use "+label+" preset"+("  ·  current" if label==settings.preset_name() else ""),"graphics:preset:"+label])
		for group in settings.GROUPS:entries.append([settings.GROUPS[group].capitalize()+"…","graphics:"+group])
		entries.append(["Resume and compare  ·  F10 shows performance","graphics:resume"])
	entries.append(["Back","graphics:back"])
	for entry in entries:hud._button(hud._buttons,entry[0],entry[1])
