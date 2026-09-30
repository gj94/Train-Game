extends SceneTree
## Verify imported station kit dimensions against independent layout metadata.

func _initialize() -> void:
	var w := preload("res://sim/layouts/southern_corridor.gd").build()
	for station in w.stations:
		var model := load("res://assets/models/stations/%s%s.glb" % [station.kit,station.get("asset_variant", "")]).instantiate() as Node3D
		root.add_child(model)
		var platforms := model.find_children("Platform_*", "MeshInstance3D", true, false)
		if platforms.size() != station.platforms.size():
			_fail("Platform count differs from simulation: " + station.code)
			return
		for i in platforms.size():
			var bounds: AABB = platforms[i].get_aabb()
			var r: Rect2 = station.platforms[i]
			if absf(bounds.size.x - (r.size.x + 16.0)) > .05 or absf(bounds.size.z - r.size.y) > .1:
				_fail("Imported platform length/width differs from simulation: " + station.code)
				return
			if absf(bounds.end.y - 1.34) > .03:
				_fail("Platform must be 0.8 m above 0.5 m rail top, plus coping")
				return
		if model.find_children("Covered_FOB*", "MeshInstance3D", true, false).size() != 1:
			_fail("Missing connected footbridge: " + station.code)
			return
		for mesh: MeshInstance3D in model.find_children("Canopy*", "MeshInstance3D", true, false):
			if mesh.get_aabb().end.y < 6.0:
				_fail("Missing roof sheet: " + station.code)
				return
		model.free()
	print("Stations: PASS (three four-platform yard kits, 600 m usable platforms + ramps, widths, 800 mm rail-relative height, canopies, footbridges)")
	quit(0)

func _fail(message: String) -> void:
	printerr("Station asset FAIL: ", message)
	quit(1)
