extends RefCounted
## Rigid, metre-scale placement of the reviewed coastal station assemblies.
const CODES := ["KUMM","AROR","EZP","TUVR","VAY","SRTL","TRVZ","MAKM","KAVR","TMPY","ALLP","PUPR","AMPA","TZH","KVTA","HAD","CHPD","KYJ","OCR","KPY","STKT","MQO","PRND","QLN","IRP","MYY","PVU","KFI","EVA","VAK","AMY","KVU","CRY","PGZ","MQU","KXP","KZK","VELI","TVCN","TVP","NEM","BRAM","NYY","AMVA","DAVM","PASA","KZTW","KZT","PYD","ERL","VRLR","NJT"]
static func asset_code(code: String) -> String:
	return {"PUPR":"PNPR","NEM":"TVCS"}.get(code,code)

static func available(code: String) -> bool:
	return code in CODES

static func site(world: RailWorld, station: Dictionary, origin: Vector3) -> Dictionary:
	var faces: Array=preload("res://sim/platform_faces.gd").entries(station)
	var minimum:=INF
	var maximum:=-INF
	for road in station.operating_roads:
		minimum=minf(minimum,road.offset)
		maximum=maxf(maximum,road.offset)
	var selected: Dictionary={}
	for face in faces:
		if face.platform_side<0 and face.offset<=minimum+.01:
			selected=face;break
	if selected.is_empty():
		for face in faces:
			if face.platform_side>0 and face.offset>=maximum-.01:
				selected=face;break
	# An island-only station gets its entrance outside the complete yard.
	if selected.is_empty():
		selected=faces[0]
		var edge: String=selected.edge
		var s: float=world.graph.edges[edge].length*.5
		var f:=world.graph.tangent(edge,s,1)
		var r:=f.cross(Vector3.UP)
		return {position=world.graph.position_relative(edge,s,origin)+r*(minimum-selected.offset-8),forward=f,right=r}
	var edge: String=selected.edge
	var s: float=world.graph.edges[edge].length*.5
	var f:=world.graph.tangent(edge,s,1)
	var r:=f.cross(Vector3.UP)
	var side: float=selected.platform_side
	var lateral: float=2.02+selected.platform_width
	# Keep the intact 4.89 m shelter roof outside the loading gauge; its
	# foundation extends the outer apron without changing operating track data.
	if station.code=="VRLR":lateral=2.02+5.2*.5
	return {position=world.graph.position_relative(edge,s,origin)+r*side*lateral,forward=f*-side,right=r*-side}

static func layout(position: Vector3,forward: Vector3,right: Vector3,bounds: Array,placement: Dictionary) -> Dictionary:
	forward=Vector3(forward.x,0,forward.z).normalized()
	right=forward.cross(Vector3.UP)
	var signum: float=placement.outward_sign
	var along_y: bool=placement.axis=="y"
	var orientation:=Basis(-right*signum,Vector3.UP,forward*signum) if along_y else Basis(forward*signum,Vector3.UP,right*signum)
	var centre:=Vector3((bounds[0][0]+bounds[1][0])*.5,0,-(bounds[0][1]+bounds[1][1])*.5)
	var dx: float=bounds[1][0]-bounds[0][0]
	var dy: float=bounds[1][1]-bounds[0][1]
	var footprint:=Vector2(dy,dx) if along_y else Vector2(dx,dy)
	var centre_position:=position
	if not placement.get("open_shelters",false):
		centre_position-=right*(footprint.y*.5+.35)
	var lift: float=1.26-float(placement.floor_height)
	return {position=centre_position+Vector3.UP*(lift+bounds[0][2]),basis=Basis(forward,Vector3.UP,right),footprint=footprint+Vector2.ONE*.3,transform=Transform3D(orientation,centre_position-orientation*centre+Vector3.UP*lift)}

static func mount(parent: Node3D,model: Node3D,position: Vector3,forward: Vector3,right: Vector3,bounds: Array,placement: Dictionary) -> Dictionary:
	var result:=layout(position,forward,right,bounds,placement)
	model.transform=result.transform
	parent.add_child(model)
	model.set_meta("coastal_source_placement",placement)
	result.model=model
	return result
