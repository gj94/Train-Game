extends SceneTree
## Verify the real imported asset and its articulated origins without running the game.

func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var packed: PackedScene = load("res://assets/models/wap7.glb")
	if packed == null:
		printerr("WAP7: could not load imported GLB")
		quit(1)
		return
	var loco := packed.instantiate()
	root.add_child(loco)
	var meshes: Array[MeshInstance3D] = []
	var wheels: Array[MeshInstance3D] = []
	var stack: Array[Node] = [loco]
	var failures: Array[String] = []
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is Camera3D or node is Light3D or str(node.name).contains("Studio"):
			failures.append("Studio object exported: %s" % node.name)
		if node is MeshInstance3D:
			meshes.append(node)
			if str(node.name).begins_with("Wheelset_"):
				wheels.append(node)
				if not is_equal_approx(node.global_position.y, 0.546):
					failures.append("Wheel origin is not at axle height: %s" % node.name)
			for surface in node.mesh.get_surface_count():
				var material: Material = node.mesh.surface_get_material(surface)
				if not material is BaseMaterial3D or material.cull_mode != BaseMaterial3D.CULL_BACK:
					failures.append("Invalid material or culling: %s" % node.name)
	if meshes.size() != 53:
		failures.append("Expected 53 mesh assemblies, got %d" % meshes.size())
	if wheels.size() != 6:
		failures.append("Expected six wheelsets, got %d" % wheels.size())
	var axle_z: Array[float] = []
	for wheel in wheels:
		axle_z.append(wheel.global_position.z)
	axle_z.sort()
	var expected: Array[float] = [-7.85, -6.0, -4.15, 4.15, 6.0, 7.85]
	if axle_z.size() == expected.size():
		for i in expected.size():
			if not is_equal_approx(axle_z[i], expected[i]):
				failures.append("Incorrect exported axle spacing: %s" % axle_z)
	for failure in failures:
		printerr("WAP7: " + failure)
	print("WAP7 asset check: %d meshes, %d wheelsets, %d failures" % [meshes.size(), wheels.size(), failures.size()])
	loco.free()
	quit(0 if failures.is_empty() else 1)
