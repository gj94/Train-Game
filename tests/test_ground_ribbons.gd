extends RefCounted
const Ribbon:=preload("res://game/geographic_ground_ribbon.gd")
const Foundations:=preload("res://game/geographic_foundations.gd")
class Landscape:
	extends RefCounted
	var wet_samples:={}
	var origin:=Vector3.ZERO
	var geo:={road_reservations=null}
	var road_water=null
	var batch=preload("res://game/geographic_mesh.gd").new()
	func _ground(x: float,z: float) -> float:
		return sin(x*.18)*2.0+cos(z*.23)*3.0
class Shore:
	extends RefCounted
	var wet_samples:={Vector2.ZERO:true}
	func _ground(x: float,z: float) -> float:return -2.0 if x<3 and z<3 else 2.0

func test_ground_road_matches_the_rendered_landscape_between_vertices():
	var landscape:=Landscape.new()
	var polygon:=PackedVector2Array([Vector2(-10,-3),Vector2(25,-3),Vector2(25,3),Vector2(-10,3)])
	var triangles:=Ribbon.project(landscape,polygon,.07)
	var area:=0.0
	for triangle: PackedVector3Array in triangles:
		var centre: Vector3=(triangle[0]+triangle[1]+triangle[2])/3.0
		var ground:=Foundations.surface_height(landscape._ground,centre.x,centre.z)
		if absf(centre.y-ground-.07)>.00002:return "Road cuts or floats between terrain vertices"
		var a:=Vector2(triangle[0].x,triangle[0].z);var b:=Vector2(triangle[1].x,triangle[1].z);var c:=Vector2(triangle[2].x,triangle[2].z)
		area+=absf((b-a).cross(c-a))*.5
	return triangles.size()>6 and absf(area-210)<.001

func test_joined_road_segments_have_no_height_discontinuity():
	var landscape:=Landscape.new()
	var heights:=[]
	for ends in [Vector2(-7,3),Vector2(3,13)]:
		var polygon:=PackedVector2Array([Vector2(ends.x,1),Vector2(ends.y,1),Vector2(ends.y,5),Vector2(ends.x,5)])
		var found:={}
		for triangle in Ribbon.project(landscape,polygon,.07):
			for p in triangle:
				if absf(p.x-3)<.001:found[snappedf(p.z,.0001)]=p.y
		heights.append(found)
	if heights[0].size()<2 or heights[1].size()<2:return "Incomplete road join"
	# A coplanar neighbour can omit a collinear vertex without opening a crack.
	for z in heights[0].keys()+heights[1].keys():
		if absf(_edge_height(heights[0],z)-_edge_height(heights[1],z))>.00002:return "Height step at joined road edge"
	return true

func _edge_height(samples: Dictionary,z: float) -> float:
	var keys:=samples.keys();keys.sort()
	for i in range(1,keys.size()):
		if z<=keys[i]:return lerpf(samples[keys[i-1]],samples[keys[i]],(z-keys[i-1])/(keys[i]-keys[i-1]))
	return samples[keys[-1]]

func test_shore_road_follows_refined_cell_but_keeps_outer_edge_joined():
	var shore:=Shore.new()
	var polygon:=PackedVector2Array([Vector2(0,0),Vector2(8,0),Vector2(8,8),Vector2(0,8)])
	var triangles:=Ribbon.project(shore,polygon,.07)
	if triangles.size()!=32:return "Road ignored finer bank triangles"
	for triangle in triangles:
		for p in triangle:
			if p.z==0 and absf(p.y-lerpf(-2,2,p.x/8)-.07)>.00001:return "Refined road has a crack at shoreline cell border"
	return true

func test_ground_ribbon_joins_planar_approach_without_an_edge_height_step():
	var landscape:=Landscape.new()
	var corners: Array[Vector3]=[Vector3(0,5,-3),Vector3(16,4,-3),Vector3(16,4,3),Vector3(0,5,3)]
	preload("res://game/geographic_road_surface.gd")._surface(landscape,"road",corners,Vector3(0,5,0),Vector3(16,4,0),Color.WHITE,false,true,Vector2(0,1))
	var mesh: ArrayMesh=landscape.batch.surfaces.road.commit()
	var vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var start:=0;var end:=0
	for p in vertices:
		if absf(p.x)<.001:
			start+=1
			if absf(p.y-5)>.00001:return "Ground edge misses engineered road"
		if absf(p.x-16)<.001:
			end+=1
			if absf(p.y-Foundations.surface_height(landscape._ground,p.x,p.z)-.07)>.00002:return "Ground edge does not return to landscape"
	return start>1 and end>1
