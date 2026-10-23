extends RefCounted
## Immutable OSM appearance overlay. This never changes road width/elevation.
const PATH:="res://assets/models/scenery/road-finishes.json"
const KINDS:=["road","road_concrete","road_pavers","road_gravel","road_earth"]
var ways: Dictionary={}

func _init(data: Dictionary={}) -> void:
	if data.is_empty() and FileAccess.file_exists(PATH):
		data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	ways=data.get("ways",{})

func material(way: String,tags: Dictionary) -> String:
	var recovered: Dictionary=ways.get(way,{})
	return classify(tags,recovered)

static func classify(tags: Dictionary,recovered: Dictionary={}) -> String:
	# Direct tags win, allowing future imports without changing the overlay.
	var surface: String=str(tags.get("surface",recovered.get("surface",""))).strip_edges().to_lower()
	for value in surface.split(";",false):
		match value.strip_edges():
			"asphalt","paved","chipseal","tar_road":return "road"
			"concrete","concrete:plates","concrete:lanes":return "road_concrete"
			"paving_stones","sett","bricks","cobblestone","grass_paver":return "road_pavers"
			"gravel","fine_gravel","compacted","pebblestone":return "road_gravel"
			"dirt","earth","ground","sand","mud","grass","unpaved":return "road_earth"
	# No claim of surveyed surfacing for untagged country paths. Keep ordinary
	# streets paved; track grades 1/2 indicate a firm surface, not necessarily tar.
	if tags.get("highway","") in ["track","path","footway","bridleway"]:
		var grade: String=str(tags.get("tracktype",recovered.get("tracktype","")))
		if grade in ["grade1","grade2"]:return "road_gravel"
		if tags.get("bridge","no")!="no":return "road_concrete"
		return "road_earth"
	return "road"

static func marked(kind: String) -> bool:
	return kind in ["road","road_concrete"]
