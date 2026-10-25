extends RefCounted
## Flexible visible floor and bellows connect the actual moving coach ends.
const Connection:=preload("res://game/gangway_connection.gd")
var owner: WeakRef
var bridges:=[]
static var steel: StandardMaterial3D
static var rubber: StandardMaterial3D
static var gate: StandardMaterial3D
static var cube: BoxMesh

func _init(train_view, parent: Node3D) -> void:
	owner=weakref(train_view)
	var view=train_view
	if cube==null:
		cube=BoxMesh.new();cube.size=Vector3.ONE
		steel=StandardMaterial3D.new();steel.albedo_color=Color("555c61");steel.metallic=.7;steel.roughness=.6
		rubber=StandardMaterial3D.new();rubber.albedo_color=Color("202225");rubber.roughness=.94
		gate=StandardMaterial3D.new();gate.albedo_color=Color("cdb45e");gate.metallic=.4;gate.roughness=.65
	for i in view.formation.size():
		for end in Connection.load_profiles()[view.formation[i].model].gangway_ends:
			var other:=Connection.neighbour(view.formation,i,end)
			if other<0:
				# A visible end barrier accompanies the closed navigation boundary.
				var bar:=box(view.cars[i],gate)
				bar.position=Connection.local_end(view.formation[i].model,end)+Vector3(0,.85,-end*.1)
				bar.scale=Vector3(.9,.12,.05)
			elif other>i:
				var body:=Node3D.new();parent.add_child(body)
				var floor:=box(body,steel);var left:=box(body,rubber);var right:=box(body,rubber);var roof:=box(body,rubber)
				bridges.append({a=i,b=other,from=Connection.local_end(view.formation[i].model,end),to=Connection.local_end(view.formation[other].model,Connection.end_for(view.formation,other,i)),node=body,floor=floor,left=left,right=right,roof=roof})
	update()

func box(parent: Node3D, material: Material) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.mesh=cube;mesh.material_override=material
	mesh.visibility_range_end=150;mesh.visibility_range_end_margin=20;mesh.layers|=2
	parent.add_child(mesh)
	return mesh

func update() -> void:
	var view=owner.get_ref()
	if view==null:return
	for bridge in bridges:
		var a: Vector3=view.cars[bridge.a].global_transform*bridge.from
		var b: Vector3=view.cars[bridge.b].global_transform*bridge.to
		var length:=a.distance_to(b)
		bridge.node.visible=length>.02 and length<3.0
		if not bridge.node.visible:continue
		var up: Vector3=(view.cars[bridge.a].global_basis.y+view.cars[bridge.b].global_basis.y).normalized()
		bridge.node.global_transform=Transform3D(Basis.looking_at(a-b,up),(a+b)*.5)
		bridge.floor.scale=Vector3(.96,.035,length+.04);bridge.floor.position.y=-.0175
		bridge.left.scale=Vector3(.045,1.98,length+.04);bridge.left.position=Vector3(-.51,.99,0)
		bridge.right.scale=Vector3(.045,1.98,length+.04);bridge.right.position=Vector3(.51,.99,0)
		bridge.roof.scale=Vector3(1.065,.04,length+.04);bridge.roof.position.y=2.0
