extends RefCounted
## Keep authored finish/roughness/bump; standardise only the exterior body colour.
## The source LHB CC/2S blue Class_livery is replaced by the source AC/sleeper red.
const LHB_PAINT := Vector3(.58, .025, .045)

static func values(key: String, entry: Dictionary) -> PackedFloat32Array:
	var result := PackedFloat32Array(entry.source_values)
	if key.begins_with("lhb_") and entry.name == key + "_Class_livery":
		# Pinned exporter graph: base-colour RGB inputs, not arbitrary colour slots.
		# The later exporter adds an unused brick helper to its shared header.
		# Both audited graphs keep RGB at 18..20 and all 33 source values.
		var shader: String=entry.shader
		assert((shader.ends_with("_2a9558f6486c.gdshader") or shader.ends_with("_03c1186df8ca.gdshader")) and result.size()==33,
			"LHB paint graph changed: revalidate the livery parameter mapping")
		result[18] = LHB_PAINT.x
		result[19] = LHB_PAINT.y
		result[20] = LHB_PAINT.z
	return result
