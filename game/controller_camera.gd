extends RefCounted
## Controller camera movement uses elapsed real time, independent of train speed.
static func apply(camera, look: Vector2, pan: Vector2, zoom: float, delta: float) -> void:
	if camera.mode == 0:
		camera.yaw -= look.x * 2.2 * delta
		camera.pitch = clampf(camera.pitch-look.y*1.6*delta,-1.5,-.05)
		camera.distance = clampf(camera.distance*exp(-zoom*1.2*delta),3,3000)
		if pan.length_squared() > 0:
			camera.follow = false
			var right: Vector3 = camera.global_basis.x
			var forward := Vector3(-camera.global_basis.z.x,0,-camera.global_basis.z.z).normalized()
			camera.pivot += (right*pan.x-forward*pan.y)*clampf(camera.distance*.65,2,1500)*delta
	else:
		camera._look.x = clampf(camera._look.x-look.x*2.2*delta,-camera.cab_yaw_limit,camera.cab_yaw_limit)
		camera._look.y = clampf(camera._look.y-look.y*1.6*delta,-.95,.85)
		camera.cab_fov = clampf(camera.cab_fov-zoom*32*delta,38,82)
