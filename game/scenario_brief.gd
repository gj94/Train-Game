extends RefCounted
## Player-facing explanation of the currently selected working.
const Clock := preload("res://sim/world_clock.gd")

static func describe(world: RailWorld, train: Train, traffic: bool, auto_dispatch: bool, hold: bool) -> String:
	var text := "[b]YOUR SCENARIO · " + train.id + "[/b]\n" + train.service_name + "\n\n"
	if traffic:
		text += "You are driving one of %d scheduled services. The other %d run under AI control.\n" % [world.trains.size(),world.trains.size()-1]
		var ahead := []
		for other in world.trains.values():
			if other == train or other.timetable == null: continue
			if other.timetable.departure < train.timetable.departure and other.timetable.stops[0].block.get_slice("_",0) == train.timetable.stops[0].block.get_slice("_",0):
				ahead.append(other.id)
		if ahead.is_empty():
			text += "Other services can depart at the same time and share your station throat. Wait for a proceed signal; the dispatcher clears conflicting routes only after trains have passed.\n"
		else:
			text += "Earlier booked departures from your starting station: " + ", ".join(ahead) + ". You may wait at red until their trains clear a shared route; there may be more than one train to wait for.\n"
		text += "Trains follow their booked stops and share routes and platform roads. Signals can hold you behind another train or an occupied platform. F5 opens the service designer; D lets you select another working during this run.\n\n"
	if train.timetable != null:
		text += "[b]YOUR BOOKED STOPS[/b]\n"
		for i in train.timetable.stops.size():
			var stop: Dictionary = train.timetable.stops[i]
			text += stop.name + " · " + Clock.format_time(train.timetable.planned_arrival(i))
			if i > 0 and i < train.timetable.stops.size()-1:
				text += " · dwell %.0f min" % stop.dwell_minutes
			text += "\n"
		text += "\nStop at each booked platform marker; wait for departure time, station dwell and a proceed signal. A delay does not permit passing red. The run finishes when you stop at the final booked platform.\n"
	else:
		text += "Drive along the Southern corridor via Maruthur to the opposite terminus. The initial outward route is set to Maruthur P1; use C to set onward routes when you reach it. Stop before the terminal buffer.\n"
	if auto_dispatch:
		text += "\n[b]ROUTES[/b] Auto dispatch is ON. " + ("Your routes and the AI trains' routes are requested automatically; you do not need to clear your own signals.\n" if traffic else "AI services request their booked routes. Set your manually driven service's routes with C.\n")
	else:
		text += "\n[b]ROUTES[/b] Auto dispatch is OFF. Use C / D to set routes, or enable AUTO DISPATCH on the desk. Trains wait at red until a safe route is available.\n"
	if hold:
		text += "HOLD MRT is ON: Maruthur departures are deliberately held. Turn it off on the dispatch desk to let those trains continue.\n"
	text += "\n[b]HOW TO PLAY[/b] W adds power / releases brake; S reduces power / brakes. Watch the next signal and speed limit. A lets AI drive the selected service; Alt+1/2/3 lets you ride its first/middle/last passenger coach. D shows the other trains; M shows the timetable. Help pauses the simulation.\n"
	if traffic:
		text += "Restart keeps this assignment. F9 → New random traffic service starts a fresh assignment.\n"
	return text
