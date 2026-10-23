extends RefCounted
const Finishes:=preload("res://game/geographic_road_finishes.gd")
const Road:=preload("res://game/geographic_road_surface.gd")
const Reservations:=preload("res://game/geographic_road_reservations.gd")

func test_mapped_surfaces_override_road_class_without_changing_source_tags():
	var finish:=Finishes.new({ways={a={surface="concrete"},b={surface="dirt"},c={surface="paving_stones"}}})
	var tags:={highway="residential"}
	return finish.material("a",tags)=="road_concrete" and finish.material("b",tags)=="road_earth" and finish.material("c",tags)=="road_pavers" and tags=={highway="residential"}

func test_direct_surface_beats_cached_tag_and_handles_mixed_source_values():
	return Finishes.classify({surface=" Concrete;asphalt "},{surface="gravel"})=="road_concrete" and Finishes.classify({surface="unknown;fine_gravel"})=="road_gravel"

func test_untagged_streets_stay_paved_but_country_tracks_are_not_all_asphalt():
	return Finishes.classify({highway="residential"})=="road" and Finishes.classify({highway="path"})=="road_earth" and Finishes.classify({highway="track",tracktype="grade2"})=="road_gravel" and Finishes.classify({highway="footway",bridge="yes"})=="road_concrete"

func test_unpaved_roads_do_not_get_painted_centre_lines():
	return not Finishes.marked("road_earth") and not Finishes.marked("road_gravel") and not Finishes.marked("road_pavers") and Finishes.marked("road") and Finishes.marked("road_concrete")

func test_every_finish_keeps_clipped_geometry_and_absolute_uv_scale():
	var reserved:=Reservations.new()
	reserved.add(PackedVector2Array([Vector2(1032,2046),Vector2(1034,2046),Vector2(1034,2050),Vector2(1032,2050)]),5)
	var reference:=PackedVector3Array()
	for kind in Finishes.KINDS:
		var batch=preload("res://game/geographic_mesh.gd").new()
		var c:={batch=batch,origin=Vector3(1024,0,2048),geo={road_reservations=reserved},road_water=null}
		var corners: Array[Vector3]=[Vector3(0,0,-2),Vector3(20,0,-2),Vector3(20,0,2),Vector3(0,0,2)]
		var area:=Road._surface(c,kind,corners,Vector3.ZERO,Vector3(20,0,0),Color.WHITE)
		if absf(area-72)>.001:return "Finish paints over the reserved station footprint: "+kind
		var arrays: Array=batch.surfaces[kind].commit().surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		if kind=="road":reference=vertices
		elif reference!=vertices:return "Material switch changed surface geometry: "+kind
		for i in vertices.size():
			var p:=vertices[i]
			if arrays[Mesh.ARRAY_TEX_UV][i].distance_to(Vector2(p.x+1024,p.z+2048))>.001:return "Texture not in absolute metres: "+kind
			if absf(arrays[Mesh.ARRAY_TEX_UV2][i].x-(p.z/4+.5))>.001:return "Edge mask changes with finish: "+kind
	return true

func test_committed_overlay_has_provenance_and_only_appearance_tags():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Finishes.PATH))
	if data.get("schema")!=1 or data.get("source_sha256","").length()!=64:return "Missing provenance"
	if data.get("requested_ways")!=50365 or data.get("found_ways")!=50365:return "Missing source ways"
	if data.ways.size()!=6717:return "Incomplete appearance overlay"
	for row: Dictionary in data.ways.values():
		for key in row:
			if key not in ["surface","tracktype","smoothness"]:return "Geometry tag in appearance overlay: "+key
	return true
