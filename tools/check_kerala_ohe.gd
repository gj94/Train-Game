extends SceneTree
func _init() -> void:
	var world=preload("res://sim/layouts/kerala_coast.gd").build()
	var layout=preload("res://game/geographic_ohe_layout.gd").new(world)
	var rows:=0
	var posts:=0
	var portals:=0
	var old_bad:=0
	var failures:=[]
	var used:={}
	for eid in world.graph.edges:
		var edge: Dictionary=world.graph.edges[eid]
		for start in range(0,ceili(edge.length),256):
			for plan in layout.plans(eid,start,minf(start+256,edge.length),Vector3.ZERO):
				if used.has(plan.chainage):failures.append("Duplicate support at "+str(plan.chainage))
				used[plan.chainage]=true
				rows+=1
				if plan.portal:portals+=1
				for p in plan.posts:
					posts+=1
					if not layout.clearance.clear_point(p,3.0):failures.append(eid+" pillar inside 3 m clearance")
			for s in range(ceili(start/55),ceili(minf(start+256,edge.length)/55)):
				var old: Vector3=world.graph.position(eid,s*55.0)+world.graph.tangent(eid,s*55.0,1).cross(Vector3.UP)*3.6
				if not layout.clearance.clear_point(old,3.0):old_bad+=1
	print("OHE_AUDIT rows=",rows," posts=",posts," yard_gantries=",portals," old_unsafe_sites=",old_bad," failures=",failures.size())
	for failure in failures:printerr(failure)
	quit(0 if failures.is_empty() and rows>4900 and portals>0 and old_bad>100 else 1)
