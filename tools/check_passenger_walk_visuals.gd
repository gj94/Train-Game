extends "res://tools/check_walking_playable.gd"
## The controller harness deliberately stops automatic presentation processing.
## Advance its normal render path before capture, including visibility selection.
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for frame in 3:
		game.cam._process(.016)
		game._process(.016)
		await process_frame
	# The scripted walk can cross a car before the seat-to-walk camera blend
	# has elapsed. Let the normal blend finish, rather than capture inside a wall.
	for frame in 90:
		if game.cam._blend>=1.0:break
		game.cam._process(.016)
		game._process(.016)
		await process_frame
	check(game.cam._blend>=1.0,"camera transition finished before "+name)
	if walk.active and not walk.platform.outside:
		check(game.cam.global_position.distance_to(walk.camera_transform().origin)<.001,"camera is at the walked position before "+name)
	var occupied: int=preload("res://game/train_visibility.gd").occupied_car(game)
	check(game.tv.interior_visible[occupied],"occupied interior visible before "+name+" screenshot")
	check(game.tv.interior_meshes[occupied].all(func(mesh):return mesh.visible),"all occupied interior meshes enabled before "+name)
	await super.shot(name)
	if name=="gangway":
		var saved_look: Vector2=game.cam._look
		game.cam._look.x=wrapf(saved_look.x+PI,-PI,PI)
		game.cam._process(.016);game._process(.016)
		await super.shot("gangway-look-back")
		game.cam._look=saved_look
		game.cam._process(.016)
