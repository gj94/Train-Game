extends RefCounted
## Player-facing explanation of the currently selected working.
const Clock := preload("res://sim/world_clock.gd")

static func describe(world: RailWorld, train: Train, traffic: bool, auto_dispatch: bool, hold: bool) -> String:
	var text := "[b]YOUR SCENARIO · " + train.id + "[/b]\n" + train.service_name + "\n\n"
	if traffic:
		text += "You are one of six passenger services: three leave each end of the corridor. The other five run under AI control.\n"
		var ahead := []
		for other in world.trains.values():
			if other == train: break
			if other.timetable.stops[0].direction == train.timetable.stops[0].direction:
				ahead.append(other.id)
		if ahead.is_empty():
			text += "Your service normally gets the first departure route from its terminus. Traffic can still delay you farther along the line.\n"
		else:
			text += "At the start, " + ", ".join(ahead) + " normally leave ahead of you. Expect to wait at red until their trains clear the shared route; there may be more than one train to wait for.\n"
		text += "Trains meet at Maruthur, share platform roads and then continue to the opposite terminus. Signals can hold you again behind a train or an occupied platform.\n\n"
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
