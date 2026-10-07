extends RefCounted
## All game actions are reachable with focus navigation, including diagnostics.
static func build(hud, kind: String) -> void:
	var entries := []
	match kind:
		"controllers":
			var options: Dictionary = hud.controller_options
			hud._heading.text = "CONTROLLER"
			hud._body.text = options.get("name","No controller connected") + "\n\n" + hud.controller_help
			entries = [
				["Stick deadzone: %d%%" % roundi(options.get("deadzone",.18)*100),"pad_setting:deadzone"],
				["Look sensitivity: %.2f×" % options.get("sensitivity",1.0),"pad_setting:sensitivity"],
				["Invert vertical look: " + ("ON" if options.get("invert",false) else "OFF"),"pad_setting:invert"],
				["Vibration: %d%%" % roundi(options.get("vibration",.35)*100),"pad_setting:vibration"],
				["Restore controller defaults","pad_setting:defaults"],
				["Back","fleet_back"]]
		"controller_actions":
			hud._heading.text = "TRAIN & VIEW ACTIONS"
			hud._body.text = "Choose a group. Selecting an action resumes the simulation.\nD-pad / left stick move · A select · B back."
			entries = [["Driving & signals","train_controls"],["Camera & passengers","view_controls"],["Sound & joint diagnostics","sound_controls"],["Back","fleet_back"]]
		"train_controls":
			hud._heading.text = "DRIVING & SIGNALS"
			hud._body.text = "Obey signals and speed limits. Emergency release and changing ends still require a stand."
			entries = [["AI / manual driver","padcmd:ai"],["Coast","padcmd:coast"],["Emergency brake / release","padcmd:emergency"],["Change driving ends","padcmd:reverse"],["Horn","padcmd:horn"],["Next signal route desk","padcmd:route"],["Manual point control…","points"],["Dispatch desk","padcmd:dispatch"],["Timetable","padcmd:timetable"],["Simulation speed ×1 / ×2 / ×4","padcmd:time"],["Train protection ON / OFF","padcmd:protection"],["Event history","padcmd:history"],["Back","controller_actions"]]
		"view_controls":
			hud._heading.text = "CAMERA & PASSENGERS"
			hud._body.text = "Passenger controls apply to trains with passenger interiors.\nRight stick looks; LB/RB zoom; left stick pans outside or changes position inside."
			entries = [["Pilot seat","padcmd:pilot"],["Left head-out / return","padcmd:head_left"],["Right head-out / return","padcmd:head_right"],["Cab / exterior","padcmd:view"],["Passenger / cab","padcmd:passenger"],["First / middle / last passenger coach…","passengers"],["Cab position / passenger aisle or seat","padcmd:seat"],["Fold / lower berths (original LHB)","padcmd:berths"],["Follow train","padcmd:follow"],["Chennapuram view","padcmd:station1"],["Maruthur view","padcmd:station2"],["Kadalur view","padcmd:station3"],["Back","controller_actions"]]
		"points":
			hud._heading.text = "MANUAL POINT CONTROL"
			hud._body.text = "A toggles a point. Occupied and route-locked points refuse movement.\nUse the dispatch desk to set complete routes and clear signals."
			for id in hud.controller_options.get("points",{}):
				var point: Dictionary = hud.controller_options.points[id]
				entries.append([id + "  ·  " + ("REVERSE" if point.reversed else "NORMAL"),"padpoint:"+id])
			entries.append(["Back","train_controls"])
		"sound_controls":
			hud._heading.text = "SOUND & JOINT DIAGNOSTICS"
			hud._body.text = "Adjust track sound and second-axle balance, or show the physical contact markers."
			entries = [["Track sound quieter","padcmd:track_down"],["Track sound louder","padcmd:track_up"],["Second axle quieter","padcmd:clang_down"],["Second axle louder","padcmd:clang_up"],["Rail-joint markers ON / OFF","padcmd:joints"],["Performance overlay ON / OFF","padcmd:performance"],["Back","controller_actions"]]
	for entry in entries: hud._button(hud._buttons,entry[0],entry[1])
