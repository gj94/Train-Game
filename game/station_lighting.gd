extends RefCounted
## Two instanced fixture draws and a bounded pool of nearby, default shadow-free lights.
## Absolute site datums follow platform/canopy geometry; no worker/scene searches.
const MAX_LIGHTS := 24
const MAX_FIXTURES := 96
const RADIUS := 280.0
var groups: Array=[]
var lights: Array[OmniLight3D]=[]
var housings: MultiMeshInstance3D
var lenses: MultiMeshInstance3D
var lens_material: StandardMaterial3D
var active_lights:=0
var visible_fixtures:=0
var _last_wall:=-1000000
var _origin:=Vector3(INF,0,0)
var _night:=-1.0
var _parent: Node3D

func _init(w: RailWorld,parent: Node3D) -> void:
	_parent=parent
	for station: Dictionary in w.stations:
		if not station.get("passenger_open",true):continue
		var sites:=[]
		if w.scenery.get("geographic",false):
			for face: Dictionary in preload("res://sim/platform_faces.gd").entries(station):
				var mid: float=w.graph.edges[face.edge].length*.5
				var half:=48.0 if station.get("through_halt",false) else 180.0
				if station.code=="VRLR":continue # Its authored shelters have other datums.
				var span:=preload("res://sim/berth_clearance.gd").platform_span(w,face.edge)
				for s in range(ceili(mid-half),floori(mid+half),24):
					if s<span.x or s>span.y:continue
					if preload("res://game/station_platform_civil.gd").has_bridge(station) and s-mid>50 and s-mid<82:continue
					var forward:=w.graph.tangent(face.edge,s,1)
					var right:=forward.cross(Vector3.UP)
					var at: Vector3=w.graph.position(face.edge,s)+right*face.platform_side*(2.02+face.platform_width*.5)
					# Under the existing roof, beside its column, inside the platform.
					at+=right*face.platform_side*minf(.65,face.platform_width*.2)+Vector3.UP*6.04
					_add_site(sites,at,Basis.looking_at(forward))
		else:
			for rect: Rect2 in station.get("platforms",[]):
				for x in range(ceili(rect.position.x+24),floori(rect.end.x-24),24):
					_add_site(sites,Vector3(x,station.origin.y+5.6,rect.get_center().y),Basis(Vector3.UP,PI*.5))
		groups.append({code=station.get("code",station.name),origin=station.origin,sites=sites})
	var metal:=StandardMaterial3D.new();metal.albedo_color=Color(.22,.25,.27);metal.metallic=.6;metal.roughness=.6
	lens_material=StandardMaterial3D.new();lens_material.albedo_color=Color(.82,.86,.84)
	lens_material.emission_enabled=true;lens_material.emission=Color(1.0,.89,.7)
	housings=_instances("StationLightHousings",Vector3(.28,.12,1.15),metal)
	lenses=_instances("StationLightLenses",Vector3(.21,.025,1.03),lens_material)
	for i in MAX_LIGHTS:
		var light:=OmniLight3D.new();light.name="StationLight%d" % i
		# Presentation-only rank in the existing nearest-first light pool.
		# Graphics options may add distance-faded shadows; selection, energy and
		# station availability remain owned by the unchanged update below.
		light.set_meta("station_shadow_rank",i)
		light.light_color=Color(1.0,.88,.68);light.omni_range=25;light.omni_attenuation=.75
		light.shadow_enabled=false;light.visible=false
		light.distance_fade_enabled=true;light.distance_fade_begin=90;light.distance_fade_length=40
		parent.add_child(light);lights.append(light)

static func _add_site(sites: Array,position: Vector3,basis: Basis) -> void:
	# Opposite faces of an island platform must not double the fixtures.
	for site in sites:
		if site.position.distance_squared_to(position)<4.0:return
	sites.append({position=position,basis=basis})

func add_forecourts(w: RailWorld,station_sites: Dictionary) -> void:
	for i in groups.size():
		var station: Dictionary={}
		for entry: Dictionary in w.stations:
			if entry.get("code",entry.name)==groups[i].code:station=entry;break
		if station.is_empty():continue
		for plan in preload("res://game/station_precinct_plan.gd").entries(station_sites,station):
			if plan.halt:continue
			for x in [-plan.half+2,plan.half-2]:
				for z in [plan.front-4,plan.outer+1]:
					var at: Vector3=plan.building+plan.basis*Vector3(x,4.91,z+.3)
					_add_site(groups[i].sites,at,plan.basis)

func _instances(label: String,size: Vector3,material: Material) -> MultiMeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size;mesh.material=material
	var node:=MultiMeshInstance3D.new();node.name=label
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh
	mm.instance_count=MAX_FIXTURES;mm.visible_instance_count=0;node.multimesh=mm
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_parent.add_child(node)
	return node

func update(observer: Vector3,origin: Vector3,night: float,available: Callable=Callable(),force: bool=false) -> void:
	var now:=Time.get_ticks_msec()
	if not force and now-_last_wall<250 and origin==_origin and is_equal_approx(night,_night):return
	_last_wall=now;_origin=origin;_night=night
	var candidates:=[]
	for group in groups:
		if group.origin.distance_squared_to(observer)>1100*1100:continue
		if available.is_valid() and not available.call(group.code):continue
		for site in group.sites:
			var distance: float=site.position.distance_squared_to(observer)
			if distance<RADIUS*RADIUS:candidates.append({site=site,distance=distance})
	candidates.sort_custom(func(a,b):return a.distance<b.distance)
	visible_fixtures=mini(MAX_FIXTURES,candidates.size());active_lights=0
	for i in visible_fixtures:
		var site: Dictionary=candidates[i].site
		var pose:=Transform3D(site.basis,site.position-origin)
		housings.multimesh.set_instance_transform(i,pose)
		pose.origin.y-=.07;lenses.multimesh.set_instance_transform(i,pose)
		if i<MAX_LIGHTS and night>.001 and candidates[i].distance<130*130:
			var light: OmniLight3D=lights[active_lights]
			light.position=pose.origin-Vector3.UP*.18;light.light_energy=2.8*night;light.visible=true
			active_lights+=1
	for i in range(active_lights,MAX_LIGHTS):lights[i].visible=false
	housings.multimesh.visible_instance_count=visible_fixtures;lenses.multimesh.visible_instance_count=visible_fixtures
	lens_material.emission_energy_multiplier=2.0*night
