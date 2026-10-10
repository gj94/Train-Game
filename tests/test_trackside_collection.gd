extends RefCounted
const Collection:=preload("res://game/trackside_assets.gd")
const Chunk:=preload("res://game/geographic_scenery_chunk.gd")

func test_impostor_atlases_use_mipmaps_and_preserve_rgb_normals():
	for root in ["res://assets/models/scenery/impostors/", "res://assets/models/trackside/impostors/"]:
		var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root+("buildings_catalog.json" if "scenery" in root else "catalog.json")))
		for key in catalog:
			for channel in ["albedo","normal"]:
				var config:=ConfigFile.new()
				if config.load(root+str(key).trim_prefix("tf3_")+"_"+channel+".png.import")!=OK:return "Missing atlas import"
				if config.get_value("params","compress/mode")!=2 or not config.get_value("params","mipmaps/generate"):return "Atlas lacks GPU compression or mipmaps"
				if config.get_value("params","compress/normal_map")!=2:return "Object-space normal RGB must be preserved"
	return true

func test_native_building_atlases_cover_six_palettes_and_eight_views():
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/impostors/buildings_catalog.json"))
	if catalog.size()!=9:return "Missing distant building families"
	for kind in catalog:
		if catalog[kind].palettes!=6 or catalog[kind].views!=8:return "Facade palette/view coverage lost"
		for channel in ["albedo","normal"]:
			var image:=Image.new()
			var error:=image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/models/scenery/impostors/"+kind+"_"+channel+".png"))
			if error!=OK or image.get_size()!=Vector2i(1024,3072):return "Incorrect atlas dimensions"
	return true

func test_grass_density_lods_keep_real_height_and_reduce_geometry():
	var Grass:=preload("res://game/coastal_groundcover.gd")
	var full:=Grass.mesh(null)
	var mid:=Grass.mesh(null,96,2)
	var far:=Grass.mesh(null,24,4)
	return full.get_faces().size()==384*9 and mid.get_faces().size()==96*9 and far.get_faces().size()==24*9 and far.get_aabb().size.y>.2 and mid.get_aabb().size.y>.2

func test_all_52_source_entries_have_runtime_geometry_and_provenance():
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Collection.ROOT+"manifest.json"))
	if manifest.revision!="16c06aee07c70eea5ed74e8420116998c27a4895" or manifest.assets.size()!=52:return "Incomplete scenery handoff"
	for asset in manifest.assets.values():
		if not FileAccess.file_exists(asset.path) or asset.source_sha256.length()!=64:return "Missing source provenance or geometry"
		if asset.triangles<=0 or asset.surfaces<=0:return "Empty scenery model"
		for axis in 3:
			if asset.godot_size[axis]<=0:return "Invalid metric bounds"
	return true

func test_authored_tree_lods_reduce_geometry_and_have_continuous_ranges():
	var assets: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Collection.ROOT+"manifest.json")).assets
	for name in Collection.TREES:
		var key: String="tf3_"+name
		if assets[key+"_LOD1"].triangles>=assets[key].triangles or assets[key+"_LOD2"].triangles>=assets[key+"_LOD1"].triangles:return "LOD does not reduce triangle work"
		var levels:=Collection.levels(key)
		if levels[0].begin!=0 or levels[0].end!=levels[1].begin or levels[1].end!=levels[2].begin:return "Gap between LOD ranges"
	return true

func test_baked_impostors_exist_for_each_catalog_entry():
	var atlases: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Collection.ROOT+"impostors/catalog.json"))
	if atlases.size()!=14:return "Incomplete bake"
	for key in atlases:
		var name: String=key.trim_prefix("tf3_")
		for channel in ["albedo","normal"]:
			if not FileAccess.file_exists(Collection.ROOT+"impostors/"+name+"_"+channel+".png"):return "Missing atlas"
		if atlases[key].width<=0 or atlases[key].views!=8:return "Invalid atlas projection"
	return true

func test_cached_polygon_query_preserves_islands_and_multiple_water_bodies():
	var c:=Chunk.new(null,{},null)
	var shape:={type="MultiPolygon",coordinates=[[[[0,0],[20,0],[20,20],[0,20],[0,0]],[[5,5],[10,5],[10,10],[5,10],[5,5]]],[[[30,30],[40,30],[40,40],[30,40],[30,30]]]]}
	var original: Array=shape.coordinates.duplicate(true)
	for i in 3:
		if not c._inside(Vector2(2,2),shape) or c._inside(Vector2(7,7),shape) or not c._inside(Vector2(35,35),shape) or c._inside(Vector2(25,25),shape):return "Water/hole classification changed"
	return shape.has("prepared_rings") and shape.coordinates==original
