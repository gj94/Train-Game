extends SceneTree
## Geometry regressions for the permanent way: gauge, rail datum and chunk seams.
const Track := preload("res://game/track_view.gd")
const View := preload("res://game/world_view.gd")
var failures := 0

class RecordedTrack extends "res://game/track_view.gd":
	var plain_ties := []
	var plain_joints := []
	# The headless dummy renderer does not retain MultiMesh GPU transforms.
	# Record the actual upload, then exercise the normal rendering path too.
	func _instances(mesh: Mesh, transforms: Array, parent: Node3D, material: Material, label: String, distance: float) -> void:
		if label=="Sleepers" and parent.name.begins_with("plain_"):
			for transform in transforms: plain_ties.append(parent.to_global(transform.origin).x)
		if label=="Fishplates" and parent.name.begins_with("plain_"):
			for transform in transforms: plain_joints.append(parent.to_global(transform.origin).x)
		super._instances(mesh,transforms,parent,material,label,distance)

func _initialize() -> void:
	call_deferred("check_track")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func check_track() -> void:
	var w := RailWorld.new()
	w.graph.add_node("a",Vector3.ZERO)
	w.graph.add_node("b",Vector3(200,0,0))
	w.graph.add_node("c",Vector3(360,0,0))
	w.graph.add_node("d",Vector3(360,0,8))
	w.graph.add_edge("plain","a","b")
	w.graph.add_edge("normal","b","c")
	w.graph.add_edge("reverse","b","d",preload("res://sim/layouts/first_line.gd").ease_between(200,360,0,8))
	w.graph.add_switch("b","plain","normal","reverse",50)
	var parent := Node3D.new()
	root.add_child(parent)
	var view := View.new()
	view.world = w
	view.root = parent
	var track := RecordedTrack.new()
	track.build(view)
	var ties: Array = track.plain_ties
	var instance_count := 0
	var head_vertices := 0
	var joints := Track.AxleJoint.joints_on_edge(200,Track.JointLayout.SPACING,Track.JointLayout.OFFSET)
	for chunk in track.root.get_children():
		if not chunk.name.begins_with("plain_"): continue
		var rails: MeshInstance3D = chunk.get_node("Rails")
		var arrays := rails.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in vertices.size():
			var p: Vector3 = rails.to_global(vertices[i])
			check(p.y>=.3279 and p.y<=.5001,"rail stays on existing 0.5 m wheel-contact datum")
			if absf(p.y-.5)<.0001:
				check(absf(absf(p.z)-.874)<.0001,"1676 mm gauge plus 72 mm rail head")
				if colors[i].r>.9: check(normals[i].y>.9,"running surface faces upwards")
				head_vertices += 1
				for joint in joints:
					check(absf(p.x-joint)>=.0049,"running head leaves the 10 mm sound-aligned expansion gap")
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			var a: Vector3 = rails.to_global(vertices[indices[i]])
			var b: Vector3 = rails.to_global(vertices[indices[i+1]])
			var c: Vector3 = rails.to_global(vertices[indices[i+2]])
			if minf(a.y,minf(b.y,c.y))<.49: continue
			for joint in joints:
				check(not (minf(a.x,minf(b.x,c.x))<joint and maxf(a.x,maxf(b.x,c.x))>joint),"no top-surface triangle bridges a joint")
		var mm: MultiMeshInstance3D = chunk.get_node("Sleepers")
		instance_count += mm.multimesh.instance_count
	check(head_vertices>100,"both rail running surfaces generated")
	check(track.plain_joints.size()==joints.size(),"one fishplate assembly at every audible joint")
	track.plain_joints.sort()
	for i in joints.size(): check(absf(track.plain_joints[i]-joints[i])<.0001,"fishplate position equals sound joint position")
	for direction in [-1,1]:
		var scheduler := Track.AxleJoint.new()
		scheduler.setup([{x=0,cls=0,car=0}],Track.JointLayout.SPACING,Track.JointLayout.OFFSET)
		var s: float = joints[4]
		scheduler.advance([{edge="plain",s=s-direction*.1,dir=direction,length=200.0}],10)
		var hits: Array = scheduler.advance([{edge="plain",s=s+direction*.1,dir=direction,length=200.0}],10)
		check(hits.size()==1 and hits[0].joint==4,"both directions trigger the visible joint")
		check(absf(hits[0].late-.01)<.0001,"kernel lateness preserves crossing time")
	ties.sort()
	check(ties.size()==332 and instance_count==332,"1660 sleepers/km retained across 64 m chunk boundaries")
	for i in range(1,ties.size()):
		check(absf(ties[i]-ties[i-1]-Track.SLEEPER_PITCH)<.0001,"no missing or duplicated sleeper at chunk boundary")
	check(track.stats.crossings==2,"check rails on both crossing routes")
	var blades: Array = track.point_blades.b
	var normal_pose: Basis = blades[0].node.basis
	var reverse_pose: Basis = blades[1].node.basis
	w.graph.switches.b.reversed = true
	track.update_points(true)
	check(not blades[0].node.basis.is_equal_approx(normal_pose),"normal tongue opens for reverse route")
	check(not blades[1].node.basis.is_equal_approx(reverse_pose),"reverse tongue closes for reverse route")
	check(absf(track.point_rods.b.position.x-.12)<.001,"stretcher rod follows points")
	check(track._sample("reverse",1).shared and not track._sample("reverse",1).primary,"merged route suppresses overlapping sleeper bed")
	var top_count := 0
	var sa := track.sleeper.surface_get_arrays(0)
	for normal in sa[Mesh.ARRAY_NORMAL]:
		if normal.y>.99: top_count += 1
	check(top_count>0,"concrete top faces point outwards")
	check(track.sleeper.get_aabb().size.x>=2.749,"2.75 m sleepers")
	print("Permanent way geometry: %d failures; %d plain-line sleepers, %d crossing guards" % [failures,ties.size(),track.stats.crossings])
	parent.free()
	quit(1 if failures else 0)
