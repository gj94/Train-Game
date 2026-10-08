extends SceneTree
const View:=preload("res://game/ported_train_view.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Motion:=preload("res://game/train_motion.gd")
const Contacts:=preload("res://game/track_contacts.gd")
var failures:=0
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: ",message)
func run() -> void:
	var scene:=Node3D.new();root.add_child(scene)
	var g:=TrackGraph.new()
	g.add_node("a",Vector3(-2000,0,0));g.add_node("b",Vector3(2000,0,0));g.add_edge("line","a","b")
	var layout:=Contacts.new(g)
	for configuration in [["lhb","express"],["lhb","passenger"],["icf","express"],["icf","passenger"],["vb8","fixed"],["vb16","fixed"]]:
		var family: String=configuration[0]
		var train:=Train.new("ride",1);Stock.configure(train,family,configuration[1])
		train.path=[{edge="line",dir=1}];train.head_s=1800;train.speed=20
		var parent:=Node3D.new();scene.add_child(parent)
		var view:=View.new();view.motion=Motion.new(train,g);view.build(train,g,parent,null)
		var maximum:=0.0;var rail_error:=0.0
		var render_us:=0
		for frame in 240:
			view.motion.begin_tick();train.advance(g,train.speed/60);view.motion.end_tick();view.motion.sample(1)
			var started:=Time.get_ticks_usec()
			view.ride.update(1.0/60,layout);view.update()
			render_us+=Time.get_ticks_usec()-started
			maximum=maxf(maximum,view.ride.bodies[0].displacement.length())
			for i in view.cars.size():
				for j in view.bogies[i].size():
					var pos:=view._v(view.specs[i].bogies[j].position)
					var expected: Vector3=view._point(view._center(i)+view._direction(i)*pos.z)+Vector3.UP*(View.RAIL_TOP+pos.y)
					rail_error=maxf(rail_error,view.bogies[i][j].global_position.distance_to(expected))
		check(maximum>.001 and maximum<.045,family+" moving sprung body within travel")
		check(view.ride.contact_count>30,family+" repeated real axle/joint contacts")
		check(rail_error<.001,family+" bogies remain on rails despite body motion")
		print("RAKE_PRESENTATION ",family,"/",configuration[1]," vehicles=",view.cars.size()," update_ms=",render_us/240000.0)
		check(view.cab_transform().basis.y.dot(view.cars[0].global_basis.y)>.995,family+" camera retains body roll")
		var before: Vector3=view.ride.bodies[0].displacement
		view.motion.coordinate_origin=Vector3(1024,0,0);view.ride.update(0,layout);view.update()
		check(view.ride.bodies[0].displacement==before,family+" pause/rebase does not disturb springs")
		train.cab_end=2;view.motion.reset();view.ride.update(.016,layout);view.update()
		check(view.ride.last_cab==2 and view.ride.sweep.previous.size()==view.sound_axles().size(),family+" cab reversal resets sweep")
		parent.free();view=null
		await process_frame
	scene.free()
	print("Ride integration: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
