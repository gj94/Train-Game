extends RefCounted
## Verified source PBR meshes, authored tree LODs and baked distant silhouettes.
const ROOT:="res://assets/models/trackside/"
const Cells:=preload("res://game/spatial_batches.gd")
const Lod:=preload("res://game/scenery_lod.gd")
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
	for name in TREES:
		var kind: String="tf3_"+name
		var shadow_path: String=ROOT+"batched/"+name+"_shadow.res"
		library.meshes["shadow:"+kind]=[{mesh=load(shadow_path),transform=Transform3D.IDENTITY}] if library.use_batches and ResourceLoader.exists(shadow_path) else preload("res://game/scenery_shadow.gd").build(library.asset(kind+"_LOD2"))
	for alias in ALIASES:
		library.catalog[alias]=catalog["tf3_"+ALIASES[alias]]
	for kind in atlases:
		var entry: Dictionary=atlases[kind]
		var mesh:=QuadMesh.new();mesh.size=Vector2.ONE*float(entry.width)
		mesh.center_offset=Vector3(0,float(entry.centre[1]),0)
		var mat:=ShaderMaterial.new();mat.shader=load("res://game/shaders/scenery_impostor.gdshader")
		mat.set_shader_parameter("centre_y",0.0)
		mat.set_shader_parameter("view_count",float(entry.get("views",8)))
		mat.set_shader_parameter("atlas_columns",float(entry.get("columns",4)))
		mat.set_shader_parameter("blend_views",int(entry.get("views",8))>=64)
		var name: String=kind.trim_prefix("tf3_")
		mat.set_shader_parameter("colour_atlas",load(ROOT+"impostors/"+name+"_albedo.png"))
		mat.set_shader_parameter("normal_atlas",load(ROOT+"impostors/"+name+"_normal.png"))
		if ResourceLoader.exists(ROOT+"impostors/"+name+"_windows.png"):
			mat.set_shader_parameter("window_mask",load(ROOT+"impostors/"+name+"_windows.png"))
			mat.set_shader_parameter("has_window_mask",true)
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
	var parts:=[]
	var tree: bool=kind.trim_prefix("tf3_") in TREES
	for level in chain:
		for part in library.asset(level.kind):
			var entry: Dictionary=part.duplicate()
			entry.begin=level.begin;entry.end=level.end;entry.impostor=false
			parts.append(entry)
	if atlases.has(kind):
		var centre: Array=atlases[kind].centre
		parts.append({mesh=library.impostors[kind],transform=Transform3D(Basis.IDENTITY,Vector3(centre[0],0,centre[2])),
			begin=chain[-1].end,end=1800.0 if kind.contains("BLD_") else (2700.0 if tree else 420.0),impostor=true})
	if tree:
		# One inexpensive, stable caster survives the visual LOD transitions.
		# This replaces the expensive near-tree shadows rather than adding them.
		for part in library.meshes.get("shadow:"+kind,library.asset(chain[-1].kind)):
			var entry: Dictionary=part.duplicate()
			entry.begin=0.0;entry.end=300.0;entry.impostor=false;entry.shadow=true
			parts.append(entry)
	for group in Lod.groups(library.placements[kind],parts,32.0 if "Rice_Tuft" in kind else 64.0):
		for part in parts:
			var node:=Lod.instance(group,part)
			node.name=("Impostor_" if part.impostor else "Trackside_")+kind
			node.set_meta("scenery_kind",kind);node.set_meta("impostor",part.impostor)
			node.visibility_range_begin=part.begin;node.visibility_range_end=part.end
			node.visibility_range_begin_margin=12;node.visibility_range_end_margin=12
			node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			if part.get("shadow",false):
				node.name="TreeShadow_"+kind;node.set_meta("scenery_shadow",true)
				node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				node.visibility_range_end_margin=40
			elif tree or part.impostor or "Rice_Tuft" in kind:
				node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			library.view.root.add_child(node)
