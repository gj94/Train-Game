extends RefCounted
## Verified source PBR meshes, authored tree LODs and baked distant silhouettes.
const ROOT:="res://assets/models/trackside/"
const Cells:=preload("res://game/spatial_batches.gd")
const ALIASES:={
	"coconut_palm":"KL_LS_Coconut_Tall_A","young_palm":"KL_LS_Coconut_Juvenile_C",
	"mango_tree":"KL_LS_Jackfruit_Tree","banana_clump":"KL_LS_Banana_Clump",
	"kerala_veranda":"BLD_Home_Verandah_01","laterite_cottage":"BLD_Cottage_Hipped_01",
	"coastal_shop":"BLD_TeaShop_Open_01","workshop":"BLD_Workshop_Corrugated_01",
	"courtyard_well":"BLD_Well_Roofed_01","country_canoe":"KL_LS_Country_Canoe",
	"rice_green":"KL_LS_Rice_Tuft_Green","rice_ripe":"KL_LS_Rice_Tuft_Ripe"}
const TREES:=["KL_LS_Coconut_Tall_A","KL_LS_Coconut_Leaning_B","KL_LS_Coconut_Juvenile_C","KL_LS_Jackfruit_Tree"]
static var catalog: Dictionary={}
static var atlases: Dictionary={}

static func resolve(kind: String) -> String:
	return "tf3_"+ALIASES[kind] if ALIASES.has(kind) else kind

static func prepare(library) -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json")).assets
	atlases=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"impostors/catalog.json"))
	for kind in catalog:
		library.asset(kind)
		library.catalog[kind]=catalog[kind]
	for alias in ALIASES:
		library.catalog[alias]=catalog["tf3_"+ALIASES[alias]]
	for kind in atlases:
		var entry: Dictionary=atlases[kind]
		var mesh:=QuadMesh.new();mesh.size=Vector2.ONE*float(entry.width)
		mesh.center_offset=Vector3(0,float(entry.centre[1]),0)
		var mat:=ShaderMaterial.new();mat.shader=load("res://game/shaders/scenery_impostor.gdshader")
		mat.set_shader_parameter("centre_y",0.0)
		var name: String=kind.trim_prefix("tf3_")
		mat.set_shader_parameter("colour_atlas",load(ROOT+"impostors/"+name+"_albedo.png"))
		mat.set_shader_parameter("normal_atlas",load(ROOT+"impostors/"+name+"_normal.png"))
		mesh.material=mat;library.impostors[kind]=mesh

static func levels(kind: String) -> Array:
	var name:=kind.trim_prefix("tf3_")
	if name in TREES:return [{kind=kind,begin=0.0,end=45.0},{kind=kind+"_LOD1",begin=45.0,end=95.0},{kind=kind+"_LOD2",begin=95.0,end=190.0}]
	if atlases.has(kind):return [{kind=kind,begin=0.0,end=180.0 if name.begins_with("BLD_") else 85.0}]
	var distance:=220.0
	if "Rice_Tuft" in name:distance=100.0
	elif name in ["KR_U01","KR_U02","KR_U03"]:distance=650.0
	elif name.begins_with("BLD_"):distance=380.0
	return [{kind=kind,begin=0.0,end=distance}]

static func flush(library,kind: String) -> void:
	var chain:=levels(kind)
	for level in chain:
		for part in library.asset(level.kind):
			var transforms:=[]
			for placement in library.placements[kind]:transforms.append(placement*part.transform)
			_batches(library,kind,part.mesh,transforms,level.begin,level.end,false)
	if not atlases.has(kind):return
	var transforms:=[]
	var centre: Array=atlases[kind].centre
	for placement in library.placements[kind]:
		transforms.append(placement*Transform3D(Basis.IDENTITY,Vector3(centre[0],0,centre[2])))
	var finish:=1800.0 if kind.contains("BLD_") else (2700.0 if kind.trim_prefix("tf3_") in TREES else 420.0)
	_batches(library,kind,library.impostors[kind],transforms,chain[-1].end,finish,true)

static func _batches(library,kind: String,mesh: Mesh,transforms: Array,start: float,finish: float,impostor: bool) -> void:
	# All levels use the same cell origins, so transitions cannot open a gap.
	for group in Cells.split(transforms,32.0 if "Rice_Tuft" in kind else 64.0).values():
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=mesh;mm.instance_count=group.transforms.size()
		for i in group.transforms.size():mm.set_instance_transform(i,group.transforms[i])
		var node:=MultiMeshInstance3D.new();node.multimesh=mm;node.position=group.origin
		node.name=("Impostor_" if impostor else "Trackside_")+kind
		node.set_meta("scenery_kind",kind);node.set_meta("impostor",impostor)
		node.visibility_range_begin=start;node.visibility_range_end=finish
		node.visibility_range_begin_margin=8;node.visibility_range_end_margin=8
		node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if impostor:
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.extra_cull_margin=float(atlases[kind].width)
		elif start>=95 or "Rice_Tuft" in kind:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		library.view.root.add_child(node)
