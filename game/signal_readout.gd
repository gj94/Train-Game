extends RefCounted
## Distance-only mode deliberately has no colour, aspect or proceed vocabulary.
static func text(next: Dictionary, aspect: int, show_aspect: bool=true) -> String:
	if next.is_empty():return "No signal ahead"
	var distance:="Next signal · %d m" % roundi(next.distance)
	if not show_aspect:return distance
	var aspects:=["[color=#ff7868]RED[/color]","[color=#ffca72]YELLOW[/color]","[color=#72e6be]GREEN[/color]"]
	return "%s  %s · %d m" % [next.id,aspects[clampi(aspect,0,2)],roundi(next.distance)]
