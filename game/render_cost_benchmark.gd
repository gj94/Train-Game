extends RefCounted
## Optional leave-one-group-out GPU audit of an unchanged, paused camera.
## Marginal savings overlap (shadows/occlusion/post effects); never add them.
static func category(node: GeometryInstance3D, chunk_kind: String) -> String:
	var name:=str(node.name)
	var label:=str(node.get_meta("scenery_kind",name)).to_lower()
	if chunk_kind=="track":return "permanent_way"
	if chunk_kind=="station":return "stations_and_buildings"
	for word in ["coconut","palm","tree","jackfruit","banana","bamboo","fern","colocasia","pandanus","grass","shrub","reeds","rice_","canopy"]:
		if word in label:return "vegetation"
	for word in ["_ground","_water","_paddy"]:
		if word in name:return "terrain_and_water"
	if "architecture" in name or "house" in label or "bld_" in label or "cottage" in label or "veranda" in label or "villa" in label:
		return "stations_and_buildings"
	return "other_scenery"

static func run(bench) -> void:
	var game=bench.game
	var groups:={}
	for id in game.wv.loaded:
		var chunk: Node3D=game.wv.loaded[id].node
		if not chunk.visible:continue
		var kind: String=str(id).get_slice(":",0)
		for node in chunk.find_children("*","GeometryInstance3D",true,false):
			if not node.is_visible_in_tree():continue
			var group:=category(node,kind)
			if not groups.has(group):groups[group]=[]
			groups[group].append(node)
	groups.all_trains=[]
	for parent in game.traffic_presentation.roots.values():
		if parent.visible:groups.all_trains.append(parent)
	for i in 45:await game.get_tree().process_frame
	await bench._capture("cost_baseline_start",8)
	var audit:={note="Leave one category out at a fixed paused overview. GPU savings overlap and are not additive. Station-asset contents are grouped together.",groups={}}
	for key in ["vegetation","permanent_way","stations_and_buildings","terrain_and_water","other_scenery","all_trains"]:
		var nodes: Array=groups.get(key,[])
		audit.groups[key]=nodes.size()
		for node in nodes:node.hide()
		for i in 45:await game.get_tree().process_frame
		await bench._capture("cost_without_"+key,8)
		for node in nodes:node.show()
	var lights: Array=game.wv.root.find_children("*","DirectionalLight3D",true,false)
	var shadows:={}
	for light in lights:
		shadows[light]=light.shadow_enabled;light.shadow_enabled=false
	for i in 45:await game.get_tree().process_frame
	await bench._capture("cost_without_shadows",8)
	for light in lights:light.shadow_enabled=shadows[light]
	var environments: Array=game.wv.root.find_children("*","WorldEnvironment",true,false)
	if not environments.is_empty():
		var env: Environment=environments[0].environment
		var effects:={ssao_enabled=env.ssao_enabled,ssil_enabled=env.ssil_enabled,glow_enabled=env.glow_enabled}
		for property in effects:
			env.set(property,false)
			for i in 45:await game.get_tree().process_frame
			await bench._capture("cost_without_"+property,8)
			env.set(property,effects[property])
	for i in 45:await game.get_tree().process_frame
	await bench._capture("cost_baseline_end",8)
	bench.report.render_cost_audit=audit
	bench._write()
