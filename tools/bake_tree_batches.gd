extends SceneTree
## Offline material batching of unchanged source triangles and imported LODs.
const OUT:="res://assets/models/trackside/batched/"
func _initialize() -> void:call_deferred("bake")

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var library:=preload("res://game/scenery_library.gd").new()
	library.use_batches=false
	var manifest:={format=1,assets=[]}
	for name in preload("res://game/trackside_assets.gd").TREES:
		for level in ["","_LOD1","_LOD2"]:
			var source_name: String=name+level
			var parts: Array=library.asset("tf3_"+source_name)
			assert(parts.size()==1 and parts[0].transform==Transform3D.IDENTITY,"Source tree hierarchy changed; update the batch bake before exporting.")
			var source: ArrayMesh=parts[0].mesh
			if level=="_LOD2":
				var shadow: ArrayMesh=preload("res://game/scenery_shadow.gd").build(parts)[0].mesh
				assert(ResourceSaver.save(shadow,OUT+name+"_shadow.res",ResourceSaver.FLAG_COMPRESS)==OK)
			var merged:=preload("res://game/static_palette_mesh.gd").merge(source)
			assert(merged.get_surface_count()<source.get_surface_count(),"Source material eligibility changed")
			assert(ResourceSaver.save(merged,OUT+source_name+".res",ResourceSaver.FLAG_COMPRESS)==OK)
			manifest.assets.append({asset=source_name,source_surfaces=source.get_surface_count(),batched_surfaces=merged.get_surface_count(),
				gltf_sha256=FileAccess.get_sha256("res://assets/models/trackside/"+source_name+".gltf")})
			print("BATCHED ",source_name," ",source.get_surface_count()," -> ",merged.get_surface_count())
	FileAccess.open(OUT+"manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	quit()
