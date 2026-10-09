extends RefCounted
## Detailed source building assemblies. Track/signalling remain simulation-owned.
static var _prepared := {}
static var _mutex := Mutex.new()

static func available(code: String) -> bool:
	return code in ["ERS","TVC","NCJ"] or preload("res://game/coastal_station_placement.gd").available(code)

static func prepare(code: String) -> Dictionary:
	var key: String="station_"+preload("res://game/coastal_station_placement.gd").asset_code(code).to_lower()
	_mutex.lock()
	var cached: Dictionary=_prepared.get(key,{})
	_mutex.unlock()
	if not cached.is_empty():return cached
	var scene: PackedScene=load("res://assets/models/ported/"+key+".glb")
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/"+key+"_detail/provenance.json"))
	var placement: Dictionary=source.get("placement",{})
	if not placement.is_empty():placement["foundation_pads"]=source.get("foundation_pads",[])
	var warm: Node3D=scene.instantiate()
	preload("res://game/authored_vehicle_materials.gd").apply(warm,key)
	warm.free()
	_mutex.lock()
	_prepared[key]={scene=scene,bounds=source.source_bounds,placement=placement}
	cached=_prepared[key]
	_mutex.unlock()
	return cached

static func add_building(parent: Node3D, code: String, position: Vector3, forward: Vector3, right: Vector3, centered: bool=false) -> Dictionary:
	var prepared:=prepare(code)
	var key: String="station_"+preload("res://game/coastal_station_placement.gd").asset_code(code).to_lower()
	var model: Node3D=(prepared.scene as PackedScene).instantiate()
	model.name=code+"_AuthoredStation"
	preload("res://game/authored_vehicle_materials.gd").apply(model,key)
	if not prepared.placement.is_empty():
		return preload("res://game/coastal_station_placement.gd").mount(parent,model,position,forward,right,prepared.bounds,prepared.placement)
	# glTF: author X -> X, Y -> -Z, Z -> Y. Orient source yard side inward.
	var basis:=Basis(-forward,Vector3.UP,-right)
	var bounds: Array=prepared.bounds
	var centre:=Vector3((bounds[0][0]+bounds[1][0])*.5,0,-(bounds[0][1]+bounds[1][1])*.5)
	if centered:position-=basis*centre
	model.transform=Transform3D(basis,position)
	parent.add_child(model)
	return {position=position+basis*centre,basis=basis,footprint=Vector2(bounds[1][0]-bounds[0][0]+2,bounds[1][1]-bounds[0][1]+2),model=model}
