extends RefCounted
## Sweeps the rendered axles over the same contacts used by sound and track gaps.
const Body := preload("res://sim/ride_dynamics.gd")
const Sweep := preload("res://game/contact_sweep.gd")
var bodies := []
var sweep := Sweep.new()
var _view: WeakRef
var view:
	get: return _view.get_ref()
var axles := []
var last_speed := 0.0
var last_cab := 0
var last_distance := 0.0
var ready := false
var contact_count := 0

func _init(vehicle) -> void:
	_view=weakref(vehicle)
	for car in view.cars: bodies.append(Body.new())

func reset(at: float) -> void:
	axles=view.sound_axles()
	sweep.reset()
	for i in bodies.size(): bodies[i].reset(at-view._center(i))
	last_speed=view.train.speed; last_cab=view.train.cab_end
	last_distance=at; ready=true

func update(delta: float,layout) -> void:
	if delta<=0 or layout==null: return
	var at: float=view.motion.odometer() if view.motion!=null else view.train.odometer
	if not ready or last_cab!=view.train.cab_end or absf(at-last_distance)>40: reset(at)
	var locations := []
	for axle in axles:
		locations.append(view.motion.locate(axle.x) if view.motion!=null else view.train.locate_behind(view.graph,axle.x))
	var hits := sweep.advance(locations,layout,delta)
	if sweep.discontinuity: reset(at); return
	hits.sort_custom(func(a,b): return a.relative<b.relative)
	var acceleration := clampf((view.train.speed-last_speed)/delta,-1.5,1.5)
	var elapsed := 0.0
	for hit in hits:
		var next: float=clampf(delta+hit.relative,elapsed,delta)
		_advance(next-elapsed,lerpf(last_distance,at,next/delta),acceleration,layout)
		var axle: Dictionary=axles[hit.axle]
		var car: int=axle.car
		var along: float=(view._center(car)-axle.x)/maxf(1,view.Stock.geometry(view.formation[car].model).bogie)
		bodies[car].contact(view.train.speed,hit.contact.strength,along*view._direction(car),hit.contact.side*locations[hit.axle].dir*view._direction(car))
		contact_count+=1; elapsed=next
	_advance(delta-elapsed,at,acceleration,layout)
	last_distance=at; last_speed=view.train.speed

func _advance(delta: float,at: float,acceleration: float,layout) -> void:
	if delta<=0: return
	for i in bodies.size():
		var back: float=view._center(i)
		var loc: Dictionary=view.motion.locate(back) if view.motion!=null else view.train.locate_behind(view.graph,back)
		var curve: float=layout.curvature(loc.edge,loc.s)*loc.dir*view._direction(i)
		bodies[i].advance(delta,at-back,view.train.speed,acceleration*view._direction(i),view.train.speed*view.train.speed*curve)

func offset(index: int) -> Transform3D:
	return Transform3D(Basis.from_euler(bodies[index].angles),bodies[index].displacement)
