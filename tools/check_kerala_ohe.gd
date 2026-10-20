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
	var wire_chunks:=0
	var wire_joins:=0
	var attachments:=0
	for eid in world.graph.edges:
		var edge: Dictionary=world.graph.edges[eid]
		var previous: Dictionary={}
		for start in range(0,ceili(edge.length),256):
			var end:=minf(start+256,edge.length)
			# Use local coordinates just as the renderer does, preserving precision.
			var origin: Vector3=world.graph.position(eid,0)
			var spans: Array=layout.wire_spans(eid,start,end,origin)
			if spans.is_empty():failures.append(eid+" missing wire span");continue
			wire_chunks+=1
			if not previous.is_empty():
				wire_joins+=1
				if previous.contacts[-1].distance_to(spans[0].contacts[0])>.001 or previous.messengers[-1].distance_to(spans[0].messengers[0])>.001:failures.append(eid+" wire chunk seam")
			previous=spans[-1]
			for plan in layout.plans(eid,start,end,Vector3.ZERO):
				if used.has(plan.chainage):failures.append("Duplicate support at "+str(plan.chainage))
				used[plan.chainage]=true
				rows+=1
				if plan.portal:portals+=1
				else:
					for i in plan.posts.size():
						var delta: Vector3=plan.anchors[0 if i==0 else -1].contact-plan.posts[i];delta.y=0
						if delta.length()>layout.MAX_CANTILEVER_REACH+.01:failures.append(eid+" oversized cantilever")
				for p in plan.posts:
					posts+=1
					if not layout.clearance.clear_point(p,3.0):failures.append(eid+" pillar inside 3 m clearance")
				for anchor in plan.anchors:
					attachments+=1
					var road: Dictionary=world.graph.edges[anchor.road]
					var along: float=(plan.chainage-road.chainage_start)/(road.chainage_end-road.chainage_start)*road.length
					var wires: Array=layout.wire_spans(anchor.road,maxf(0,along-.1),minf(road.length,along+.1),Vector3.ZERO)
					if not wires.any(func(span):return span.contacts.any(func(p):return p.distance_to(anchor.contact)<.04)):failures.append(anchor.road+" floating registration")
			for s in range(ceili(start/55),ceili(minf(start+256,edge.length)/55)):
				var old: Vector3=world.graph.position(eid,s*55.0)+world.graph.tangent(eid,s*55.0,1).cross(Vector3.UP)*3.6
				if not layout.clearance.clear_point(old,3.0):old_bad+=1
	print("OHE_AUDIT rows=",rows," posts=",posts," yard_gantries=",portals," old_unsafe_sites=",old_bad," failures=",failures.size())
	print("OHE_WIRES chunks=",wire_chunks," seamless_boundaries=",wire_joins," connected_registrations=",attachments)
	for failure in failures:printerr(failure)
	quit(0 if failures.is_empty() and rows>4900 and portals>0 and old_bad>100 else 1)
