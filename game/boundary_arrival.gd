extends RefCounted
## Presentation handover after the simulation has proved full-tail clearance.
static func show(game) -> void:
	game.walker.stop();game.dispatcher.set_open(false)
	var head: Dictionary=game.train.path[0]
	var observer: Vector3=game.world.graph.position(head.edge,game.train.head_s)
	var spot: Dictionary=preload("res://game/platform_camera.gd").nearest(game.world,observer)
	var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
	game.cam.enter_free(spot.get("eye",observer+Vector3.UP*2)-origin,spot.get("forward",Vector3.FORWARD))
	game._set_cab_visuals(false);game.audio.set_interior(false)
	game.controller._free_train_controls=false;game.controller.neutralize()
	game._drive_keys_armed=false;game._set_paused(true)
	game.time_skip.show_page("JOURNEY CONTINUES BEYOND THE MAP",game.train.service_name+"\nThe whole train has cleared the boundary and continues to "+str(game.train.journey.get("destination",game.train.destination))+". This is the end of its simulated section.\nYou are now viewing the nearest station. Open Dispatch to choose another active service, or return to the journey menu.",[["Open Dispatch","skip:dispatch"],["Back to pause menu","skip:back"]])
