extends SceneTree
## Asset-pipeline setup. Run after import; then import again before launching a game.
func _initialize() -> void:
	var paths:=PackedStringArray()
	for folder in ["aerial_asphalt_01","red_brick_plaster_patch_02","pavement_06"]:
		for suffix in ["diff","nor_gl","rough"]:
			paths.append("res://assets/polyhaven/%s/%s_%s_2k.jpg"%[folder,folder,suffix])
	for tree in ["coconut_palm","young_palm","mango_tree","rain_tree","tree_small_02"]:
		for suffix in ["albedo","normal"]: paths.append("res://assets/models/scenery/impostors/%s_%s.png"%[tree,suffix])
	for file in DirAccess.get_files_at("res://assets/models/scenery"):
		if file.begins_with("tree_small_02_tree_small_02_") and file.get_extension() in ["png","jpg"]:
			paths.append("res://assets/models/scenery/"+file)
	for path in paths:
		var config:=ConfigFile.new()
		if config.load(path+".import")!=OK:
			printerr("Missing imported asset: ",path)
			quit(1)
			return
		config.set_value("params","mipmaps/generate",true)
		config.set_value("params","compress/mode",2)
		config.set_value("params","compress/high_quality",true)
		if path.ends_with("_normal.png"): config.set_value("params","compress/normal_map",2)
		if config.save(path+".import")!=OK:
			quit(1)
			return
	# Imported photographic twigs are subpixel geometry. Generic simplification
	# erases their crown; the explicit eight-view impostor handles distant LOD.
	var tree_config:=ConfigFile.new()
	var tree_path:="res://assets/models/scenery/tree_small_02.glb.import"
	if tree_config.load(tree_path)==OK:
		tree_config.set_value("params","meshes/generate_lods",false)
		tree_config.save(tree_path)
	print("Scenery imports: mipmaps and high-quality VRAM compression configured for ",paths.size()," textures")
	quit()
