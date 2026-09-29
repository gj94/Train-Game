extends SceneTree
## Validate the actual imported GLBs: berth counts, articulation and clean export.

func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var failures: Array[String] = []
	for kind in ["3a", "2a"]:
		var packed: PackedScene = load("res://assets/models/lhb_%s.glb" % kind)
		if packed == null:
			failures.append("Missing imported " + kind)
			continue
		var coach: Node3D = packed.instantiate()
		root.add_child(coach)
		var berths := coach.find_children("Berth_*", "MeshInstance3D", true, false).filter(func(n): return str(n.name).trim_prefix("Berth_").is_valid_int())
		if berths.size() != (72 if kind == "3a" else 52):
			failures.append("Incorrect berth count: %s %d" % [kind, berths.size()])
		var axles := coach.find_children("Axle_*", "Node3D", true, false)
		if axles.size() != 4:
			failures.append("Missing four axle pivots")
		var expected: Array[float] = [-8.73, -6.17, 6.17, 8.73]
		var actual: Array[float] = []
		for axle in axles:
			actual.append(axle.global_position.z)
			if absf(axle.global_position.y - .4575) > .0001:
				failures.append("Incorrect wheel radius/height")
		actual.sort()
		for i in mini(expected.size(), actual.size()):
			if absf(expected[i] - actual[i]) > .0001:
				failures.append("Incorrect FIAT bogie spacing")
		var triangles := 0
		for node in coach.find_children("*", "Node", true, false):
			if node is Light3D or node is Camera3D or node.name.contains("Studio"):
				failures.append("Studio object leaked into GLB")
			if node is MeshInstance3D:
				for surface in node.mesh.get_surface_count():
					triangles += node.mesh.surface_get_array_index_len(surface) / 3
		print("LHB %s: %d berths, %d axle pivots, %d triangles" % [kind, berths.size(), axles.size(), triangles])
		coach.free()
	for failure in failures:
		printerr("LHB asset FAIL: ", failure)
	print("LHB assets: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
