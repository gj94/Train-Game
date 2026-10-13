extends RefCounted
## Instanced porch fixtures and eight persistent, shadow-free local light slots.
## Remote homes use emissive windows, with no thousands-of-lights overhead.
const MAX_LIGHTS:=8
const MAX_FIXTURES:=96
const Windows:=preload("res://game/night_windows.gd")
var fixtures: MultiMeshInstance3D
var housings: MultiMeshInstance3D
var slots:=[]
var active_lights:=0
var visible_fixtures:=0
var _last_wall:=-1000000
var _origin:=Vector3(INF,0,0)
var _eye:=Vector3(INF,0,0)
var _night:=-1.0

func _init(parent: Node3D) -> void:
	var bulb:=SphereMesh.new();bulb.radius=.065;bulb.height=.10;bulb.radial_segments=8;bulb.rings=4
	var material:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded; void fragment(){ALBEDO=COLOR.rgb*.18;EMISSION=COLOR.rgb*COLOR.a*3.0;}"
	material.shader=shader;bulb.material=material
	fixtures=_batch(parent,"PorchLightLenses",bulb)
	var body:=BoxMesh.new();body.size=Vector3(.18,.08,.20)
	var metal:=StandardMaterial3D.new();metal.albedo_color=Color(.18,.20,.19);metal.roughness=.65;metal.metallic=.45;body.material=metal
	housings=_batch(parent,"PorchLightHousings",body)
	for i in MAX_LIGHTS:
		var light:=OmniLight3D.new();light.name="ResidentialLight%d" % i
		light.omni_range=9;light.omni_attenuation=1.4;light.shadow_enabled=false;light.visible=false
		light.distance_fade_enabled=true;light.distance_fade_begin=55;light.distance_fade_length=40
		parent.add_child(light);slots.append({light=light,id=""})

func _batch(parent: Node3D,label: String,mesh: Mesh) -> MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new();node.name=label
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
	mm.mesh=mesh;mm.instance_count=MAX_FIXTURES;mm.visible_instance_count=0;node.multimesh=mm
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);return node

static func amount(seed: float,night: float,hour: float) -> float:
	return night*smoothstep(seed-.055,seed+.055,Windows.occupied_fraction(hour))

static func warmth(seed: float) -> Color:
	return Color(.68,.83,1) if fposmod(seed*5.71,1)>.83 else Color(1,.64,.30)

func update(chunks: Dictionary,eye: Vector3,origin: Vector3,night: float,hour: float,force: bool=false) -> void:
	var now:=Time.get_ticks_msec()
	if not force and now-_last_wall<300 and origin==_origin and is_equal_approx(night,_night):return
	_last_wall=now;_origin=origin;_eye=eye;_night=night
	var candidates:=[];var by_id:={}
	for id: String in chunks:
		var chunk: Dictionary=chunks[id]
		if not chunk.has("night_sites") or not chunk.node.visible:continue
		for i in chunk.night_sites.size():
			var site: Dictionary=chunk.night_sites[i]
			var point: Vector3=chunk.origin+site.position
			var distance:=point.distance_squared_to(eye)
			if distance>200*200:continue
			var entry:={id=id+"#"+str(i),position=point,distance=distance,seed=site.seed,energy=amount(site.seed,night,hour)}
			candidates.append(entry);by_id[entry.id]=entry
	candidates.sort_custom(func(a,b):return a.distance<b.distance)
	visible_fixtures=mini(MAX_FIXTURES,candidates.size())
	for i in visible_fixtures:
		var entry: Dictionary=candidates[i]
		var pose:=Transform3D(Basis.IDENTITY,entry.position-origin)
		fixtures.multimesh.set_instance_transform(i,pose)
		var color:=warmth(entry.seed);color.a=entry.energy
		fixtures.multimesh.set_instance_color(i,color)
		pose.origin.y+=.065;housings.multimesh.set_instance_transform(i,pose)
	fixtures.multimesh.visible_instance_count=visible_fixtures;housings.multimesh.visible_instance_count=visible_fixtures
	var claimed:={}
	# Keep a slot until it has faded out by distance, instead of resorting and
	# teleporting every light whenever two houses exchange nearest rank.
	for slot in slots:
		if by_id.has(slot.id) and by_id[slot.id].distance<100*100 and by_id[slot.id].energy>.001:claimed[slot.id]=true
		else:slot.id=""
	for slot in slots:
		if not slot.id.is_empty():continue
		for entry in candidates:
			if entry.distance<80*80 and entry.energy>.001 and not claimed.has(entry.id):
				slot.id=entry.id;claimed[entry.id]=true;break
	active_lights=0
	for slot in slots:
		var light: OmniLight3D=slot.light
		light.visible=not slot.id.is_empty()
		if not light.visible:continue
		var entry: Dictionary=by_id[slot.id]
		light.position=entry.position-origin-Vector3.UP*.1
		light.light_color=warmth(entry.seed);light.light_energy=1.4*entry.energy
		active_lights+=1
