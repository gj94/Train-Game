extends RefCounted
## Physical Indian-style permanent speed indicators. Numbers are track km/h.
## Static shared geometry/materials; bounded by the geographic streamer.
const Plan := preload("res://sim/track_speed_boards.gd")
const Clearance := preload("res://game/scenery_clearance.gd")
const Batch := preload("res://game/geographic_mesh.gd")
var jobs := []
var materials := {}

func _init(world: RailWorld, exclusion=null) -> void:
	var clearance := Clearance.new(world.graph)
	var groups := {}
	for board: Dictionary in Plan.build(world):
		var key := "%s:%d:%d" % [board.edge,board.dir,roundi(board.s)]
		if not groups.has(key):groups[key]=[]
		groups[key].append(board)
	for key: String in groups:
		var plates: Array=groups[key]
		var board: Dictionary=plates[0]
		var p := world.graph.position(board.edge,board.s)
		var f := world.graph.tangent(board.edge,board.s,board.dir)
		var left := Vector3.UP.cross(f).normalized()
		var offset := 3.4
		while offset<100:
			var candidate: Vector3=p+left*offset
			if clearance.clear_point(candidate,3.05) and (exclusion==null or exclusion.clear(Vector2(candidate.x,candidate.z),.8)):break
			offset+=.5
		var point := p+left*offset
		var route := Plan.label(board.edge) if offset>4.0 else ""
		jobs.append({id="speed-board:"+key,kind="speed_board",point=point,forward=f,plates=plates,road=route,rail_y=p.y})
	for pair in [["yellow",Color("eac327")],["black",Color("171b18")],["white",Color("d5d3c6")],["steel",Color("4e544e")]]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color=pair[1];mat.roughness=.68
		mat.vertex_color_use_as_albedo=true
		if pair[0]=="steel":mat.metallic=.65
		materials[pair[0]]=mat

func build(job: Dictionary, geo=null) -> Dictionary:
	var origin := Vector3(floorf(job.point.x/256)*256,0,floorf(job.point.z/256)*256)
	var node := Node3D.new();node.name="SpeedIndicators"
	var assembly := Node3D.new();node.add_child(assembly)
	var ground: float=job.rail_y
	if geo!=null:ground=geo.ground_at(job.point.x,job.point.z)
	var base_height: float=maxf(ground,job.rail_y-.15)
	assembly.position=job.point-origin;assembly.position.y=base_height
	# Local +Z faces the approaching driver; labels and front faces agree.
	assembly.basis=Basis.looking_at(job.forward,Vector3.UP)
	var batch := Batch.new()
	var plates: Array=job.plates
	var height := 2.7+maxi(0,plates.size()-1)*1.22
	batch.box("white",Vector3(0,-(base_height-ground)*.5+.09,0),Vector3(.52,base_height-ground+.34,.52))
	for i in ceili(height/.3):
		var h := minf(.3,height-i*.3)
		batch.box("black" if i%2 else "white",Vector3(0,i*.3+h*.5,0),Vector3(.085,h,.085))
	for i in plates.size():
		var plate: Dictionary=plates[i]
		var y := height-i*1.22
		_face(batch,plate.kind,y)
		if plate.kind=="speed":_text(assembly,str(roundi(plate.limit*3.6)),Vector3(0,y-.055,.067),.0046,72)
		elif plate.kind=="termination":
			_text(assembly,"T/P",Vector3(0,y,.067),.0043,72)
			_plaque(batch,assembly,str(roundi(plate.limit*3.6))+" km/h",y-.62)
		var route: String=plate.route if not plate.route.is_empty() else job.road
		if not route.is_empty():_plaque(batch,assembly,route,y-(.91 if plate.kind=="termination" else .63))
	batch.finish(assembly,materials,"Indicator")
	return {node=node,origin=origin}

func _face(batch,kind: String,y: float) -> void:
	var polygon := PackedVector2Array()
	if kind=="speed":polygon=PackedVector2Array([Vector2(-.5,-.289),Vector2(.5,-.289),Vector2(0,.577)])
	elif kind=="caution":polygon=PackedVector2Array([Vector2(-.7,-.2),Vector2(.5,-.2),Vector2(.7,0),Vector2(.5,.2),Vector2(-.7,.2),Vector2(-.5,0)])
	else:
		for i in 48:
			var a:=TAU*i/48.0
			polygon.append(Vector2(cos(a),sin(a))*.5)
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for j in range(0,triangles.size(),3):
		var v := []
		for k in 3:v.append(Vector3(polygon[triangles[j+k]].x,y+polygon[triangles[j+k]].y,.052))
		batch.triangle("yellow",v[0],v[1],v[2],Vector3.BACK)
		batch.triangle("steel",v[0]-Vector3.BACK*.025,v[1]-Vector3.BACK*.025,v[2]-Vector3.BACK*.025,Vector3.FORWARD)
	for j in polygon.size():
		var a := Vector3(polygon[j].x,y+polygon[j].y,.052)
		var b := Vector3(polygon[(j+1)%polygon.size()].x,y+polygon[(j+1)%polygon.size()].y,.052)
		batch.beam("black",a,b,.012)
	for x in [-.17,.17]:batch.box("steel",Vector3(x,y,.060),Vector3(.013,.013,.007))

func _plaque(batch,root: Node3D,text: String,y: float) -> void:
	batch.box("yellow",Vector3(0,y,.045),Vector3(1.3,.24,.028))
	_text(root,text,Vector3(0,y,.066),minf(.0028,1.15/maxf(text.length()*36.0,1.0)),64)

func _text(root: Node3D,value: String,p: Vector3,pixel: float,size: int) -> void:
	var label := Label3D.new()
	label.text=value;label.position=p;label.font_size=size;label.pixel_size=pixel
	label.modulate=Color("101512");label.outline_size=0;label.double_sided=false
	label.no_depth_test=false;label.shaded=true
	label.visibility_range_end=450
	root.add_child(label)
