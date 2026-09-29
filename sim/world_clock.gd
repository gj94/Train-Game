extends RefCounted
## Monotonic simulation timestamps; only their display wraps every 24 hours.
const DAY := 86400.0

static func parse_time(value: String) -> float:
	var parts := value.split(":")
	if parts.size() not in [2, 3]:
		return -1.0
	for part in parts:
		if part.length() != 2:
			return -1.0
		for character in part:
			if character.unicode_at(0) < 48 or character.unicode_at(0) > 57:
				return -1.0
	var hour := int(parts[0])
	var minute := int(parts[1])
	var second := int(parts[2]) if parts.size() == 3 else 0
	if hour < 0 or hour > 23 or minute < 0 or minute > 59 or second < 0 or second > 59:
		return -1.0
	return hour * 3600.0 + minute * 60.0 + second

static func format_time(seconds: float) -> String:
	var whole := posmod(floori(seconds + 0.000001), 86400)
	return "%02d:%02d:%02d" % [int(whole / 3600.0), int(whole / 60.0) % 60, whole % 60]

static func day(seconds: float) -> int:
	return floori((seconds + 0.000001) / DAY) + 1

static func stamp(seconds: float) -> String:
	return "D%d %s" % [day(seconds), format_time(seconds)]
