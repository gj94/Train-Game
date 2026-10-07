extends RefCounted
static func draw(batch,geo,position: Vector3,basis: Basis,size: Vector2,origin: Vector3) -> void:
	var ring:=PackedVector2Array()
	for corner in [Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(1,0,1),Vector3(-1,0,1)]:
		var p: Vector3=position+basis*(corner*Vector3(size.x*.5,0,size.y*.5))
		ring.append(Vector2(p.x,p.z))
	var foundations=preload("res://game/geographic_foundations.gd")
	var samples: Array=foundations.outline(ring,func(x,z):return geo.ground_at(x+origin.x,z+origin.z))
	foundations.skirt(batch,samples,position.y,"concrete")
