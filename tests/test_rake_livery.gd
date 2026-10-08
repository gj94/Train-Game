extends RefCounted
const Livery := preload("res://game/coach_livery.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")

func test_all_coach_classes_keep_family_paint_and_authored_surface_detail():
	for family in ["icf","lhb"]:
		for kind in Stock.CLASSES:
			var key: String=family+"_"+kind
			var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/"+key+"_detail/materials.json"))
			var paints:=0
			for entry in data.materials:
				var before:=PackedFloat32Array(entry.source_values)
				var after:=Livery.values(key,entry)
				if before.size()!=after.size(): return "material layout changed"
				var paint: bool=family=="lhb" and entry.name==key+"_Class_livery"
				if paint:
					paints+=1
					if Vector3(after[18],after[19],after[20]).distance_to(Livery.LHB_PAINT)>.000001: return "mixed exterior livery in "+key
				for i in before.size():
					if paint and i>=18 and i<=20: continue
					if before[i]!=after[i]: return "authored roughness/bump/interior changed in "+key
				if PackedFloat32Array(entry.source_values)!=before: return "source material mutated"
			if family=="lhb" and paints!=1: return "missing exterior paint override"
	return true
