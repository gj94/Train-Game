extends RefCounted
## All game actions are reachable with focus navigation, including diagnostics.
static func build(hud, kind: String) -> void:
	var entries := []
	match kind:
		"controllers":
			var options: Dictionary = hud.controller_options
			hud._heading.text = "CONTROLLER"
			hud._body.text = options.get("name","No controller connected") + "\nAdjust your hardware preferences. Open Controller layout for the separate driving, walking and camera pages."
			entries = [
				["View controller layout…","controller_guide"],
				["Stick deadzone: %d%%" % roundi(options.get("deadzone",.18)*100),"pad_setting:deadzone"],
				["Look sensitivity: %.2f×" % options.get("sensitivity",1.0),"pad_setting:sensitivity"],
				["Invert vertical look: " + ("ON" if options.get("invert",false) else "OFF"),"pad_setting:invert"],
				["Vibration: %d%%" % roundi(options.get("vibration",.35)*100),"pad_setting:vibration"],
				["Restore controller defaults","pad_setting:defaults"],
				["Back","pad_back"]]
		"controller_actions":
			var state: Dictionary=hud.controller_options
			var locked: bool=state.get("passenger_seated",false)
			hud._heading.text = "TRAIN & VIEW ACTIONS"
			hud._body.text = ("[b]AI is driving · passenger seat[/b]\nStand before using driving commands." if locked else ("[b]AI is driving[/b]" if state.get("automatic",false) else "[b]You are driving[/b]"))+"\nA select · B return"+" · X hands over to AI; hold X takes control."
			entries = [["Resume journey" if state.get("quick_from_game",false) else "Back","pad_back"]]
			if locked:entries.append(["Stand up from passenger seat","padcmd:stand"])
			entries.append_array([["Take over driving" if state.get("automatic",false) else "Let AI drive","padcmd:ai"],["Sound horn","padcmd:horn"],["Coast","padcmd:coast"],["Release emergency brake" if state.get("emergency",false) else "Emergency brake","padcmd:emergency"],["Journey progress","padcmd:progress"],["Dispatch desk","padcmd:dispatch"],["Camera & passengers…","view_controls"],["Driving & signals…","train_controls"],["Sound & audio settings…","sound_controls"],["Controller settings…","controllers"]])
		"train_controls":
			hud._heading.text = "DRIVING & SIGNALS"
			hud._body.text = "Obey signals and speed limits. Emergency release and changing ends still require a stand."
			entries = [["AI / manual driver","padcmd:ai"],["Coast","padcmd:coast"],["Emergency brake / release","padcmd:emergency"],["Change driving ends","padcmd:reverse"],["Horn","padcmd:horn"],["Next signal route desk","padcmd:route"],["Manual point control…","points"],["Dispatch desk","padcmd:dispatch"],["Timetable","padcmd:timetable"],["Simulation speed ×1 / ×2 / ×4","padcmd:time"],["Train protection ON / OFF","padcmd:protection"],["Event history","padcmd:history"],["Back","controller_actions"]]
		"view_controls":
			hud._heading.text = "CAMERA & PASSENGERS"
			hud._body.text = "Y stands; AI takes over. A interacts or sits. D-pad up/down moves between carriages standing; hold either to return to the loco. Hold left/right to return to pilot, then hold X to take control. See Controller layout for all contexts."
			entries = [["Controller layout…","controller_guide"],["Free camera at nearest platform","padcmd:free"],["View bookmarks & journey tools…","journey:open"],["Stand up / sit down","padcmd:stand"],["Crouch / stand on foot","padcmd:crouch"],["Pilot seat","padcmd:pilot"],["Left head-out / return","padcmd:head_left"],["Right head-out / return","padcmd:head_right"],["Cab / exterior","padcmd:view"],["Passenger / cab","padcmd:passenger"],["Go to passenger coach (also while moving)…","passengers"],["Cab position / passenger aisle or seat","padcmd:seat"],["Fold / lower berths (original LHB)","padcmd:berths"],["Follow train","padcmd:follow"],["Chennapuram view","padcmd:station1"],["Maruthur view","padcmd:station2"],["Kadalur view","padcmd:station3"],["Back","controller_actions"]]
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
			entries = [["Detailed sound mixer…","audio:open"],["Rail hiss, joints & squeal…","audio:group:rail"],["Wind & passing trains…","audio:group:air"],["Recovery & local diagnostics…","journey:open"],["Rail-joint markers ON / OFF","padcmd:joints"],["Performance overlay ON / OFF","padcmd:performance"],["Back","controller_actions"]]
	for entry in entries:
		var action: String="pad_back" if entry[0]=="Back" else entry[1]
		var button: Button=hud._button(hud._buttons,entry[0],action)
		if hud.controller_options.get("passenger_seated",false) and action in ["padcmd:ai","padcmd:horn","padcmd:coast","padcmd:emergency","padcmd:reverse","padcmd:protection"]:
			button.disabled=true;button.tooltip_text="AI drives while you occupy a passenger seat. Stand first."
		elif action=="padcmd:reverse" and not hud.controller_options.get("stopped",true):
			button.disabled=true;button.tooltip_text="Stop the train before changing ends."
