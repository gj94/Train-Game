extends SceneTree
const Camera := preload("res://game/camera_rig.gd")
const Ported := preload("res://game/ported_train_view.gd")
var anchor := Transform3D()
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)

func run() -> void:
	var camera := Camera.new()
	camera.cab_transform = func(): return anchor * Transform3D(Basis.IDENTITY,Vector3(-.7,3,-8))
	camera.head_out_transform = func(side): return anchor * Transform3D(Basis.IDENTITY,Vector3(side*1.9,3,-8))
	root.add_child(camera)
	camera.set_process(false)
	camera.mode=Camera.Mode.CAB
	camera.global_transform=camera._target()
	camera.set_head_out(-1)
	var from: Transform3D=camera._from
	var before: Transform3D=camera._blend_reference
	anchor=Transform3D(Basis(Vector3.UP,.15),Vector3(30,0,8))
	camera._process(.09)
	var target: Transform3D=camera._target()
	var expected: Transform3D=(camera.head_out_transform.call(-1)*before.affine_inverse()*from).interpolate_with(target,.5)
	check(camera.global_transform.is_equal_approx(expected),"quick camera blend moves and rotates with travelling train")
	camera._process(.1)
	check(camera.global_transform.is_equal_approx(target),"head-out attaches exactly after transition")
	camera.set_head_out(1)
	camera._process(.2)
	check(camera.global_position.distance_to((camera.head_out_transform.call(1) as Transform3D).origin)<.0001,"switch side has no stale opposite-side offset")
	camera.set_mode(Camera.Mode.CAB)
	camera._process(.2)
	check(camera.global_transform.is_equal_approx(camera.cab_transform.call()),"return to pilot attaches exactly")
	var view := Ported.new()
	var car := Node3D.new()
	root.add_child(car)
	view.cars=[car]
	view.specs=[{eyes=[{position=[-.7,3,-8]},{position=[.7,3,8]}],detailed_materials=true}]
	view.train=Train.new("TEST",20.56)
	var first: Transform3D=view.head_out_transform(-1)
	view.train.cab_end=2
	var second: Transform3D=view.head_out_transform(-1)
	check(first.origin.x<0 and second.origin.x>0,"left side is relative to the active driving cab")
	check((-first.basis.z).dot(-second.basis.z)<-.99,"changing locomotive ends reverses head-out look")
	check(first.origin.z<0 and second.origin.z>0,"head-out moves to the opposite cab window")
	camera.queue_free(); car.queue_free()
	await process_frame
	print("Driving camera: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
