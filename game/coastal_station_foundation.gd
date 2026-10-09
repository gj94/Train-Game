extends RefCounted
## Infill below source plinths, preserving every original visible surface.
static func draw(batch,geo,assembly: Dictionary,origin: Vector3) -> void:
	var model: Node3D=assembly.model
	if not model.has_meta("coastal_source_placement"):return
	var placement: Dictionary=model.get_meta("coastal_source_placement")
	for pad in placement.get("foundation_pads",[]):
		var lo: Array=pad.min;var hi: Array=pad.max
		var local:=Vector3((lo[0]+hi[0])*.5,lo[2]-.015,-(lo[1]+hi[1])*.5)
		var position: Vector3=model.transform*local
		var size:=Vector2(hi[0]-lo[0],hi[1]-lo[1])
		preload("res://game/geographic_station_foundation.gd").draw(batch,geo,position,model.basis,size,origin)
		batch.box("concrete",position-Vector3.UP*.04,Vector3(size.x,.08,size.y),Color.WHITE,model.basis)
