extends RefCounted
## Detailed source building assemblies. Track/signalling remain simulation-owned.
static var _scenes := {}
static var _bounds := {}

static func available(code: String) -> bool:
	return code in ["ERS","TVC","NCJ"]

static func prepare(code: String) -> void:
	var key: String="station_"+code.to_lower()
	if _scenes.has(key):return
	if not _scenes.has(key):
		_scenes[key]=load("res://assets/models/ported/"+key+".glb")
		var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/"+key+"_detail/provenance.json"))
		_bounds[key]=source.source_bounds
	var warm: Node3D=(_scenes[key] as PackedScene).instantiate()
	preload("res://game/authored_vehicle_materials.gd").apply(warm,key)
	warm.free()

static func add_building(parent: Node3D, code: String, position: Vector3, forward: Vector3, right: Vector3, centered: bool=false) -> Dictionary:
	prepare(code)
	var key: String="station_"+code.to_lower()
	var model: Node3D=(_scenes[key] as PackedScene).instantiate()
	model.name=code+"_AuthoredStation"
	preload("res://game/authored_vehicle_materials.gd").apply(model,key)
	# glTF: author X -> X, Y -> -Z, Z -> Y. Orient source yard side inward.
	var basis:=Basis(-forward,Vector3.UP,-right)
	var bounds: Array=_bounds[key]
	var centre:=Vector3((bounds[0][0]+bounds[1][0])*.5,0,-(bounds[0][1]+bounds[1][1])*.5)
	if centered:position-=basis*centre
	model.transform=Transform3D(basis,position)
	parent.add_child(model)
	return {position=position+basis*centre,basis=basis,footprint=Vector2(bounds[1][0]-bounds[0][0]+2,bounds[1][1]-bounds[0][1]+2),model=model}
