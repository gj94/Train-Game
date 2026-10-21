extends RefCounted
## Shared data-only defaults; the UI owns persistence.
const DEFAULTS := {"stops":true,"crossing":true,"overtaking":true,"overtaken":true,"signal":true}
const LABELS := {"stops":"Approaching a scheduled stop","crossing":"An oncoming train passes","overtaking":"Your train overtakes another","overtaken":"Another train overtakes yours","signal":"Your blocking signal permits movement"}
static func normalized(raw: Dictionary) -> Dictionary:
	var result:=DEFAULTS.duplicate()
	for key in result:
		if raw.get(key) is bool:result[key]=raw[key]
	return result

static func encounters(options: Dictionary) -> bool:
	return options.crossing or options.overtaking or options.overtaken
