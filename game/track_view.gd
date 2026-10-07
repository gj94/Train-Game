extends RefCounted
## Metre-scale permanent way. Rendering only; the simulation owns alignment/points.
const RAIL_TOP := .5
const HEAD_WIDTH := .072
const RAIL_CENTRE := (1.676 + HEAD_WIDTH) * .5
const SLEEPER_PITCH := 1000.0 / 1660.0
const CHUNK := 64.0
const JointLayout := preload("res://game/rail_joint_layout.gd")
const AxleJoint := preload("res://game/axle_joint.gd")
const PROFILE := [Vector2(-.075,.328),Vector2(-.075,.340),Vector2(-.016,.356),
	Vector2(-.00825,.365),Vector2(-.00825,.447),Vector2(-.032,.456),
	Vector2(-.036,.467),Vector2(-.036,.491),Vector2(-.025,.499),
	Vector2(0,.5),Vector2(.025,.499),Vector2(.036,.491),Vector2(.036,.467),
	Vector2(.032,.456),Vector2(.00825,.447),Vector2(.00825,.365),
	Vector2(.016,.356),Vector2(.075,.340),Vector2(.075,.328)]
var wv
var graph: TrackGraph
var root: Node3D
var junctions := {}
var contact_layout
var single_fishplate: ArrayMesh
var point_blades := {}
var point_rods := {}
var _point_tick := 0
var materials := {}
var sleeper: ArrayMesh
var bearer: ArrayMesh
var fastening: ArrayMesh
var stone: ArrayMesh
var fishplate: ArrayMesh
var stats := {chunks=0, sleepers=0, stones=0, crossings=0, joints=0}

func build(view) -> void:
	wv = view
	graph = view.world.graph
	root = Node3D.new()
	root.name = "PermanentWay"
	view.root.add_child(root)
	_materials()
	sleeper = _sleeper_mesh()
	bearer = _sleeper_mesh(true)
	fastening = _fastening_mesh()
	stone = _stone_mesh()
	fishplate = _fishplate_mesh()
	single_fishplate = _fishplate_mesh(true)
	_find_junctions()
	for eid in graph.edges:
		var length: float = graph.edges[eid].length
		for chunk in ceili(length / CHUNK):
			_build_chunk(eid, chunk * CHUNK, minf(length, (chunk+1)*CHUNK))
	_build_check_rails()
	_build_points()
	update_points(true)
	root.set_meta("track_stats", stats)
	wv = null # WorldView retains this adapter; do not create a RefCounted cycle.

func _materials() -> void:
	for kind in ["ballast", "concrete", "rail"]:
		var m := ShaderMaterial.new()
		m.shader = load("res://game/shaders/track_" + kind + ".gdshader")
		var asset := "brushed_concrete" if kind == "concrete" else "gravel_floor_02"
		m.set_shader_parameter("albedo_tex", wv.ph_tex(asset,"diff"))
		m.set_shader_parameter("normal_tex", wv.ph_tex(asset,"nor_gl"))
		m.set_shader_parameter("rough_tex", wv.ph_tex(asset,"rough"))
		materials[kind] = m
	var hardware := StandardMaterial3D.new()
	hardware.albedo_color = Color("403a32")
	hardware.metallic = .5
	hardware.roughness = .78
	materials.hardware = hardware
	var stones := StandardMaterial3D.new()
	stones.vertex_color_use_as_albedo = true
	stones.albedo_color = Color("88857e")
	stones.roughness = .96
	materials.stone = stones
	var shoulder := ShaderMaterial.new()
	shoulder.shader = load("res://game/shaders/track_shoulder.gdshader")
	shoulder.set_shader_parameter("soil_albedo", wv.ph_tex("red_laterite_soil_stones","diff"))
	shoulder.set_shader_parameter("soil_normal", wv.ph_tex("red_laterite_soil_stones","nor_gl"))
	shoulder.set_shader_parameter("gravel_albedo", wv.ph_tex("gravel_floor_02","diff"))
	shoulder.set_shader_parameter("noise_tex", wv._noise_tex)
	materials.shoulder = shoulder

func _find_junctions() -> void:
	contact_layout = preload("res://game/track_contacts.gd").new(graph)
	junctions = contact_layout.junctions




func _from_node(eid: String, nid: String, d: float) -> Dictionary:
	var direction := 1 if graph.edges[eid].a == nid else -1
	var s := graph.entry_s(eid,direction) + direction*d
	var f := graph.tangent(eid,s,direction)
	return {pos=graph.position(eid,s), fwd=f, right=f.cross(Vector3.UP), s=s, direction=direction}

func _sample(eid: String, s: float) -> Dictionary:
	var f := graph.tangent(eid,s,1)
	var p := {pos=graph.position(eid,s), fwd=f, right=f.cross(Vector3.UP), s=s,
		gap=0.0, shared=false, primary=true, frog=-1000.0, node_distance=0.0, toe=0.0, heel=0.0}
	for j in junctions.get(eid,[]):
		var d: float = s if graph.edges[eid].a==j.node else graph.edges[eid].length-s
		if d > j.extent: continue
		var other := _from_node(j.other,j.node,d)
		p.gap = (other.pos-p.pos).dot(p.right)
		p.shared = true
		p.primary = j.primary
		p.frog = j.frog
		p.node_distance = d
		p.toe = j.toe
		p.heel = j.heel
		break
	return p

func _build_chunk(eid: String, start: float, end: float) -> void:
	var node := Node3D.new()
	node.name = eid + "_" + str(int(start))
	root.add_child(node)
	# Local coordinates keep bounds tight and retain precision over the 22 km route.
	node.position = graph.position(eid,(start+end)*.5)
	var steps := ceili((end-start)/(.5 if junctions.has(eid) and (start<280 or end>graph.edges[eid].length-280) else 2.0))
	var distances := []
	for i in steps+1: distances.append(lerpf(start,end,i/float(steps)))
	var joints := []
	var joint_contacts: Array = contact_layout.gaps(eid,start-JointLayout.GAP,end+JointLayout.GAP)
	for contact in joint_contacts:
		var s: float = contact.s
		for edge in [s-JointLayout.GAP*.5,s+JointLayout.GAP*.5]:
			if edge>start and edge<end: distances.append(edge)
		if s>=start and s<end and not s in joints: joints.append(s)
	distances.sort()
	var pts := []
	for s in distances:
		if not pts.is_empty() and absf(pts[-1].s-s)<.00001: continue
		pts.append(_sample(eid,s))
	var count := pts.size()-1
	var bed := SurfaceTool.new()
	var soil := SurfaceTool.new()
	var rails := SurfaceTool.new()
	for st in [bed,soil,rails]: st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bed_faces := 0
	var rail_faces := 0
	for i in count:
		var a: Dictionary = pts[i]
		var b: Dictionary = pts[i+1]
		var mid := _sample(eid,(a.s+b.s)*.5)
		if not mid.shared or mid.primary or absf(mid.gap)>=4.95:
			_bed_segment(bed,a,b,node.position,false)
			_bed_segment(soil,a,b,node.position,true)
			bed_faces += 1
		for side in [-1.0,1.0]:
			if contact_layout.at_gap(eid,mid.s,side): continue
			# Stock rails follow the two OUTSIDE routes. The two inside tongues
			# are separate hinged meshes, controlled by the interlocking state.
			if mid.shared and mid.node_distance<mid.heel and side==signf(mid.gap): continue
			# A flange passage through the crossing, rather than solid intersecting heads.
			if mid.shared and signf(mid.gap)==side and absf(absf(mid.gap)-2*RAIL_CENTRE)<.045:
				continue
			var taper := 1.0
			for k in PROFILE.size()-1:
				var v0: Vector2 = PROFILE[k]
				var v1: Vector2 = PROFILE[k+1]
				var color := Color.WHITE if k>=7 and k<=10 else Color.BLACK
				_quad(rails, [a.pos+a.right*(side*RAIL_CENTRE+v0.x*taper)+Vector3.UP*v0.y-node.position,
					b.pos+b.right*(side*RAIL_CENTRE+v0.x*taper)+Vector3.UP*v0.y-node.position,
					a.pos+a.right*(side*RAIL_CENTRE+v1.x*taper)+Vector3.UP*v1.y-node.position,
					b.pos+b.right*(side*RAIL_CENTRE+v1.x*taper)+Vector3.UP*v1.y-node.position],
					[Vector2(v0.x,a.s),Vector2(v0.x,b.s),Vector2(v1.x,a.s),Vector2(v1.x,b.s)],color)
			rail_faces += 1
	if bed_faces:
		_finish(bed,node,materials.ballast,"Ballast")
		_finish(soil,node,materials.shoulder,"Formation")
	for s in joints:
		for direction in [-1.0,1.0]:
			var p := _sample(eid,s+direction*JointLayout.GAP*.5)
			if p.s<start or p.s>end: continue
			for side in [-1.0,1.0]:
				if not contact_layout.at_gap(eid,s,side): continue
				if p.shared and p.node_distance<p.heel and side==signf(p.gap): continue
				_cap_rail(rails,p,side,node.position,-direction)
	if rail_faces: _finish(rails,node,materials.rail,"Rails")
	var plates := []
	var single_plates := []
	for contact in joint_contacts:
		if contact.s<start or contact.s>=end: continue
		var p := _sample(eid,contact.s)
		# Shared stock rails receive one plate assembly, not coincident duplicates.
		if p.shared and not p.primary and absf(p.gap)<.095: continue
		if contact.side==0:
			plates.append(Transform3D(Basis.looking_at(p.fwd,Vector3.UP),p.pos-node.position))
		else:
			single_plates.append(Transform3D(Basis.looking_at(p.fwd,Vector3.UP),p.pos+p.right*contact.side*RAIL_CENTRE-node.position))
	_instances(fishplate,plates,node,materials.hardware,"Fishplates",160)
	_instances(single_fishplate,single_plates,node,materials.hardware,"PointFishplates",160)
	stats.joints += plates.size()+single_plates.size()
	var ties := []
	var bearers := []
	var clips := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(eid+str(start))
	for i in range(maxi(0,ceili(start/SLEEPER_PITCH-.5)),ceili(end/SLEEPER_PITCH-.5)):
		var s := (i+.5)*SLEEPER_PITCH
		if s >= end: continue
		var p := _sample(eid,s)
		var basis := Basis.looking_at(p.fwd,Vector3.UP)
		var gap: float = p.gap if p.shared and absf(p.gap)<3.0 else 0.0
		if gap==0 or p.primary:
			var width := 2.75+absf(gap)
			var transform := Transform3D(basis.scaled_local(Vector3(width/2.75,1,1)),p.pos+p.right*gap*.5-node.position)
			if gap!=0: bearers.append(transform)
			else: ties.append(transform)
		if not p.shared or p.primary or absf(p.gap)>.30:
			clips.append(Transform3D(basis,p.pos-node.position))
	_instances(sleeper,ties,node,materials.concrete,"Sleepers",650)
	_instances(bearer,bearers,node,materials.concrete,"TurnoutBearers",650)
	_instances(fastening,clips,node,materials.hardware,"Fastenings",110)
	stats.sleepers += ties.size()+bearers.size()
	var stones := []
	for i in int((end-start)*7):
		var s := rng.randf_range(start,end)
		var p := _sample(eid,s)
		if p.shared: continue # keep points/slide chairs and overlapping beds free
		var offset := rng.randf_range(-2.45,2.45)
		# Granite in cribs and shoulders, never floating on sleeper crowns.
		if absf(offset)<1.40 and absf(fposmod(s,SLEEPER_PITCH)-SLEEPER_PITCH*.5)<.17: continue
		var y := lerpf(.238,.012,clampf((absf(offset)-1.875)/.6,0,1))
		var size := rng.randf_range(.035,.072)
		var basis := Basis.from_euler(Vector3(rng.randf()*2,rng.randf()*TAU,rng.randf()*2)).scaled(Vector3(size,size*.62,size*.85))
		stones.append(Transform3D(basis,p.pos+p.right*offset+Vector3.UP*(y+.009)-node.position))
	_instances(stone,stones,node,materials.stone,"LooseGranite",75)
	stats.stones += stones.size()
	stats.chunks += 1

func _bed_segment(st: SurfaceTool, a: Dictionary, b: Dictionary, origin: Vector3, soil: bool) -> void:
	var rows := []
	for p in [a,b]:
		var gap: float = p.gap if p.shared and p.primary and absf(p.gap)<4.95 else 0.0
		var left := minf(0,gap)
		var right := maxf(0,gap)
		var profile := [Vector2(left-2.475,.012),Vector2(left-1.875,.238),Vector2(left-1.40,.238),
			Vector2(0,.235),Vector2(right+1.40,.238),Vector2(right+1.875,.238),Vector2(right+2.475,.012)]
		if absf(gap)>3.75:
			var valley := .238-(absf(gap)*.5-1.875)*(.226/.6)
			profile = [Vector2(left-2.475,.012),Vector2(left-1.875,.238),Vector2(left+1.875,.238),
				Vector2((left+right)*.5,valley),Vector2(right-1.875,.238),Vector2(right+1.875,.238),Vector2(right+2.475,.012)]
		if soil: profile = [Vector2(left-3.35,.006),Vector2(right+3.35,.006)]
		var row := []
		for k in profile.size():
			var v: Vector2 = profile[k]
			var edge := k==0 or k==profile.size()-1
			if not soil:
				v.x += (sin(p.s*1.7)+sin(p.s*.31)*.7)*(.055 if edge else .016)
				v.y += sin(p.s*2.15+k*1.8)*(.003 if edge else .006)
			row.append([p.pos+p.right*v.x+Vector3.UP*v.y-origin,
				Vector2(k/float(profile.size()-1) if soil else v.x,p.s)])
		rows.append(row)
	for k in rows[0].size()-1:
		_quad(st,[rows[0][k][0],rows[1][k][0],rows[0][k+1][0],rows[1][k+1][0]],
			[rows[0][k][1],rows[1][k][1],rows[0][k+1][1],rows[1][k+1][1]])

func _build_check_rails() -> void:
	for eid in junctions:
		for j in junctions[eid]:
			if j.frog<0: continue
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in 24:
				var d0: float = j.frog-3+i*.25
				var d1 := d0+.25
				var a := _from_node(eid,j.node,d0)
				var b := _from_node(eid,j.node,d1)
				var other := _from_node(j.other,j.node,d0)
				var side := -signf((other.pos-a.pos).dot(a.right))
				var off0 := side*(RAIL_CENTRE-.12-.045*clampf((absf(d0-j.frog)-2)/1,0,1))
				var off1 := side*(RAIL_CENTRE-.12-.045*clampf((absf(d1-j.frog)-2)/1,0,1))
				var profile := [Vector2(-.025,.34),Vector2(-.025,.475),Vector2(.025,.475),Vector2(.025,.34)]
				for k in 3:
					var v: Vector2 = profile[k]
					var u: Vector2 = profile[k+1]
					_quad(st,[a.pos+a.right*(off0+v.x)+Vector3.UP*v.y,b.pos+b.right*(off1+v.x)+Vector3.UP*v.y,
						a.pos+a.right*(off0+u.x)+Vector3.UP*u.y,b.pos+b.right*(off1+u.x)+Vector3.UP*u.y],
						[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],Color(.4,.4,.4))
			_finish(st,root,materials.rail,"CrossingCheckRail")
			stats.crossings += 1
			if j.primary: _crossing_hardware(eid,j)

func _crossing_hardware(eid: String, j: Dictionary) -> void:
	var casting := SurfaceTool.new()
	casting.begin(Mesh.PRIMITIVE_TRIANGLES)
	casting.set_smooth_group(-1)
	var ends := []
	for d in [j.frog+.45,j.frog+2.8]:
		var a := _from_node(eid,j.node,d)
		var b := _from_node(j.other,j.node,d)
		var side := signf((b.pos-a.pos).dot(a.right))
		ends.append([a.pos+a.right*(side*RAIL_CENTRE),b.pos-b.right*(side*RAIL_CENTRE)])
	var nose: Vector3 = (ends[0][0]+ends[0][1])*.5
	var triangle := [nose,ends[1][0],ends[1][1]]
	for i in 3:
		var a: Vector3 = triangle[i]
		var b: Vector3 = triangle[(i+1)%3]
		_quad(casting,[a+Vector3.UP*.35,b+Vector3.UP*.35,a+Vector3.UP*.494,b+Vector3.UP*.494],
			[Vector2.ZERO,Vector2.RIGHT,Vector2.UP,Vector2.ONE],Color.BLACK)
	var order := [0,1,2] if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).y<0 else [0,2,1]
	for k in order:
		casting.set_color(Color(.8,.8,.8))
		casting.set_uv(Vector2(triangle[k].x,triangle[k].z))
		casting.add_vertex(triangle[k]+Vector3.UP*.494)
	_finish(casting,root,materials.rail,"CastCrossingNose")
	# Short wing rails bend clear of the V; a visible flange channel remains.
	for route in [eid,j.other]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in 24:
			var rows := []
			for d in [j.frog-3+k*.15,j.frog-3+(k+1)*.15]:
				var a := _from_node(route,j.node,d)
				var b := _from_node(j.other if route==eid else eid,j.node,d)
				var side := signf((b.pos-a.pos).dot(a.right))
				var offset := side*(RAIL_CENTRE-.125-.07*clampf((d-j.frog+.3)/.8,0,1))
				rows.append([a.pos+a.right*(offset-.022)+Vector3.UP*.34,a.pos+a.right*(offset-.022)+Vector3.UP*.488,
					a.pos+a.right*(offset+.022)+Vector3.UP*.488,a.pos+a.right*(offset+.022)+Vector3.UP*.34])
			for n in 3:
				_quad(st,[rows[0][n],rows[1][n],rows[0][n+1],rows[1][n+1]],
					[Vector2.ZERO,Vector2.UP,Vector2.RIGHT,Vector2.ONE],Color(.75,.75,.75) if n==1 else Color.BLACK)
		_finish(st,root,materials.rail,"CrossingWingRail")

func _cap_rail(st: SurfaceTool, p: Dictionary, side: float, origin: Vector3, facing: float) -> void:
	var indices := Geometry2D.triangulate_polygon(PackedVector2Array(PROFILE))
	for i in range(0,indices.size(),3):
		var q := []
		for n in 3:
			var v: Vector2 = PROFILE[indices[i+n]]
			q.append(p.pos+p.right*(side*RAIL_CENTRE+v.x)+Vector3.UP*v.y-origin)
		if (q[1]-q[0]).cross(q[2]-q[0]).dot(p.fwd*facing)>0: q.reverse()
		for v in q:
			st.set_color(Color(.35,.35,.35))
			st.set_uv(Vector2(v.x,v.y))
			st.add_vertex(v)

func _quad(st: SurfaceTool, q: Array, uv: Array, color: Color = Color.WHITE) -> void:
	for k in [0,1,2,2,1,3]:
		st.set_uv(uv[k])
		st.set_color(color)
		st.add_vertex(q[k])

func _build_points() -> void:
	for nid in graph.switches:
		var sw: Dictionary = graph.switches[nid]
		var blades := []
		for eid in [sw.normal,sw.reverse]:
			var j: Dictionary = junctions[eid].filter(func(v): return v.node==nid)[0]
			var toe := _from_node(eid,nid,j.toe)
			var heel := _from_node(eid,nid,j.heel)
			var other := _from_node(j.other,nid,j.toe)
			var side := signf((other.pos-toe.pos).dot(toe.right))
			var pivot := Node3D.new()
			pivot.name = "Blade_"+nid+"_"+eid
			pivot.transform = Transform3D(Basis.looking_at(heel.fwd,Vector3.UP),heel.pos+heel.right*side*RAIL_CENTRE)
			root.add_child(pivot)
			# Permanent-way assemblies are authored relative to their local root.
			# This also allows a geographic chunk to be built outside the scene tree.
			var inverse := pivot.transform.affine_inverse()
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var ds := []
			for k in 37: ds.append(lerpf(j.toe,j.heel,k/36.0))
			# Visible gaps stay centred on the scheduler even on a moving tongue.
			for contact in contact_layout.gaps(eid,0,graph.edges[eid].length):
				if contact.side!=0 and contact.side!=side*heel.direction: continue
				var s: float = contact.s
				var d: float = s if graph.edges[eid].a==nid else graph.edges[eid].length-s
				for v in [d-JointLayout.GAP*.5,d+JointLayout.GAP*.5]:
					if v>j.toe and v<j.heel: ds.append(v)
			ds.sort()
			for k in ds.size()-1:
				var mid := _from_node(eid,nid,(ds[k]+ds[k+1])*.5)
				if contact_layout.at_gap(eid,mid.s,side*mid.direction): continue
				var rows := []
				for d in [ds[k],ds[k+1]]:
					var p := _from_node(eid,nid,d)
					var t := clampf((d-j.toe)/(j.heel-j.toe),0,1)
					var taper := lerpf(.08,1,t)
					# Feathered nose nearly meets the stock rail's inside gauge face.
					var nose := side*.028*pow(1-t,2)
					var row := []
					for v in PROFILE:
						row.append(inverse*(p.pos+p.right*(side*RAIL_CENTRE+nose+v.x*taper)+Vector3.UP*v.y))
					rows.append(row)
				for v in PROFILE.size()-1:
					_quad(st,[rows[0][v],rows[1][v],rows[0][v+1],rows[1][v+1]],
						[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],Color.WHITE if v>=7 and v<=10 else Color.BLACK)
			_finish(st,pivot,materials.rail,"MachinedTongue")
			blades.append({node=pivot, closed=pivot.transform.basis, angle=-side*.12/(j.heel-j.toe), normal=eid==sw.normal})
		point_blades[nid] = blades
		var first: Dictionary = junctions[sw.normal].filter(func(v): return v.node==nid)[0]
		var p := _from_node(sw.normal,nid,first.toe+1.2)
		var assembly := Node3D.new()
		assembly.name = "SwitchMechanism_"+nid
		assembly.transform = Transform3D(Basis.looking_at(p.fwd,Vector3.UP),p.pos)
		root.add_child(assembly)
		var kit := SurfaceTool.new()
		kit.begin(Mesh.PRIMITIVE_TRIANGLES)
		_box(kit,Vector3(.62,.27,.95),Vector3(-2.05,.34,0))
		_box(kit,Vector3(.72,.10,1.2),Vector3(-2.05,.13,0))
		for x in [-.874,.874]:
			for z in [-.45,.45]: _box(kit,Vector3(.34,.02,.30),Vector3(x,.321,z))
		_finish(kit,assembly,materials.hardware,"PointMotorAndSlideChairs")
		var rods := Node3D.new()
		rods.name = "StretcherRods"
		assembly.add_child(rods)
		var rod_mesh := SurfaceTool.new()
		rod_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		_box(rod_mesh,Vector3(2.75,.035,.045),Vector3(-.65,.298,0))
		_box(rod_mesh,Vector3(1.75,.025,.045),Vector3(0,.292,.38))
		for x in [-.79,.79]: _box(rod_mesh,Vector3(.06,.055,.075),Vector3(x,.312,0))
		_finish(rod_mesh,rods,materials.hardware,"DriveAndDetectionRods")
		point_rods[nid] = rods

func update_points(immediate: bool = false) -> void:
	var now := Time.get_ticks_msec()
	var blend := 1.0 if immediate else 1.0-exp(-12.0*minf((now-_point_tick)*.001,.1))
	_point_tick = now
	for nid in point_blades:
		var reverse: bool = graph.switches[nid].reversed
		for blade in point_blades[nid]:
			var open: bool = reverse if blade.normal else not reverse
			var target: Basis = blade.closed*Basis(Vector3.UP,blade.angle if open else 0.0)
			blade.node.basis = blade.node.basis.slerp(target,blend)
		point_rods[nid].position.x = lerpf(point_rods[nid].position.x,.12 if reverse else 0.0,blend)

func _finish(st: SurfaceTool, parent: Node3D, material: Material, label: String) -> void:
	st.generate_normals()
	st.generate_tangents()
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.material_override = material
	parent.add_child(mi)

func _instances(mesh: Mesh, transforms: Array, parent: Node3D, material: Material, label: String, distance: float) -> void:
	if transforms.is_empty(): return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i,transforms[i])
		var tone := .84+.16*fposmod(i*0.618034,1)
		mm.set_instance_color(i,Color(tone,tone,tone))
	var mi := MultiMeshInstance3D.new()
	mi.name = label
	mi.multimesh = mm
	mi.material_override = material
	mi.visibility_range_end = distance
	mi.visibility_range_end_margin = 18
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if label=="LooseGranite": mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

func _sleeper_mesh(flat_bearer: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1) # crisp cast faces with explicit narrow chamfers
	var rings := []
	for x in [-1.375,-1.29,-1.08,-.67,-.42,0,.42,.67,1.08,1.29,1.375]:
		var top := .321 if absf(x)>=.67 and absf(x)<=1.08 else (.289 if absf(x)<.67 else .297)
		if flat_bearer: top = .321
		var width := .12 if absf(x)<1.29 else .105
		rings.append([Vector3(x,.12,-.145),Vector3(x,top-.012,-width),Vector3(x,top,-width+.012),
			Vector3(x,top,width-.012),Vector3(x,top-.012,width),Vector3(x,.12,.145)])
	for i in rings.size()-1:
		for j in 5:
			var q := [rings[i][j],rings[i+1][j],rings[i][j+1],rings[i+1][j+1]]
			_quad(st,q,[Vector2(q[0].x,q[0].z),Vector2(q[1].x,q[1].z),Vector2(q[2].x,q[2].z),Vector2(q[3].x,q[3].z)])
	# Close the two end faces; their base is embedded in the ballast.
	for end in [0,rings.size()-1]:
		var ring: Array = rings[end]
		for j in range(1,ring.size()-1):
			for k in ([0,j,j+1] if end==0 else [0,j+1,j]):
				st.set_uv(Vector2(ring[k].x,ring[k].z))
				st.add_vertex(ring[k])
	st.generate_normals()
	st.generate_tangents()
	st.index()
	return st.commit()

func _box(st: SurfaceTool, size: Vector3, pos: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	st.append_from(box,0,Transform3D(Basis.IDENTITY,pos))

func _fastening_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0,1.0]:
		var x: float = side*RAIL_CENTRE
		_box(st,Vector3(.18,.007,.205),Vector3(x,.3245,0)) # resilient rail pad
		for outer in [-1.0,1.0]:
			_box(st,Vector3(.045,.052,.065),Vector3(x+outer*.11,.343,0)) # cast-in shoulder
			# Bent spring clip, with the toe seated against the foot of the rail.
			var points := [Vector3(x+outer*.055,.351,-.054),Vector3(x+outer*.12,.385,-.054),
				Vector3(x+outer*.15,.38,0),Vector3(x+outer*.12,.362,.054),Vector3(x+outer*.095,.35,.02)]
			for i in points.size()-1:
				var cyl := CylinderMesh.new()
				cyl.top_radius = .009
				cyl.bottom_radius = .009
				cyl.height = points[i].distance_to(points[i+1])
				cyl.radial_segments = 6
				cyl.rings = 0
				var axis: Vector3 = (points[i+1]-points[i]).normalized()
				var basis := Basis(Quaternion(Vector3.UP,axis))
				st.append_from(cyl,0,Transform3D(basis,(points[i]+points[i+1])*.5))
	return st.commit()

func _stone_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := [Vector3(-.52,0,-.3),Vector3(.15,-.16,-.51),Vector3(.55,0,.02),Vector3(.18,.04,.51),Vector3(-.46,.05,.32)]
	for i in 5:
		for tip in [Vector3(.12,.44,.03),Vector3(-.1,-.33,-.02)]:
			var q := [tip,ring[i],ring[(i+1)%5]] if tip.y>0 else [tip,ring[(i+1)%5],ring[i]]
			for p in q: st.add_vertex(p)
	st.generate_normals()
	return st.commit()

func _fishplate_mesh(single: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in ([0.0] if single else [-1.0,1.0]):
		var x: float = side*RAIL_CENTRE
		for face in [-1.0,1.0]:
			_box(st,Vector3(.023,.070,.64),Vector3(x+face*.026,.403,0))
			for z in [-.245,-.145,-.055,.055,.145,.245]:
				var bolt := CylinderMesh.new()
				bolt.top_radius = .014
				bolt.bottom_radius = .014
				bolt.height = .012
				bolt.radial_segments = 6
				bolt.rings = 0
				st.append_from(bolt,0,Transform3D(Basis(Vector3.FORWARD,PI*.5),Vector3(x+face*.044,.403,z)))
	return st.commit()
