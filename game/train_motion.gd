extends RefCounted
## Render-time railway position, one physics tick behind simulation.
## Samples distance along the occupied route: wheels stay on rails through curves
## and edge boundaries. Simulation and its reservations are never interpolated.
var train: Train
var graph: TrackGraph
var coordinate_origin := Vector3.ZERO
var _route: Train
var _current_path: Array = []
var _current_s := 0.0
var _current_odometer := 0.0
var _current_cab := 1
var _before_path: Array = []
var _before_s := 0.0
var _before_odometer := 0.0
var _before_cab := 1
var _distance := 0.0
var _lag := 0.0

func _init(t: Train, g: TrackGraph) -> void:
	train = t
	graph = g
	_route = Train.new(t.id, t.length)
	reset()

func reset() -> void:
	_current_path = train.path.duplicate(true)
	_current_s = train.head_s
	_current_odometer = train.odometer
	_current_cab = train.cab_end
	_route.path = _current_path.duplicate(true)
	_route.head_s = _current_s
	_route.length = train.length
	_distance = 0.0
	_lag = 0.0

func begin_tick() -> void:
	_before_path = train.path.duplicate(true)
	_before_s = train.head_s
	_before_odometer = train.odometer
	_before_cab = train.cab_end

func end_tick() -> void:
	reset()
	var travelled := train.odometer - _before_odometer
	if _before_path.is_empty() or train.cab_end != _before_cab or travelled < 0.0 or travelled > 40.0:
		return
	# Retain the old tail edge for the fraction of the tick before it cleared.
	# Never re-query current point settings for a route the train already took.
	for overlap in range(mini(_route.path.size(), _before_path.size()), 0, -1):
		if _route.path.slice(_route.path.size() - overlap) == _before_path.slice(0, overlap):
			_route.path.append_array(_before_path.slice(overlap))
			break
	var past := _route.locate_behind(graph, travelled)
	var before: Dictionary = _before_path[0]
	var anchor: Vector3 = graph.nodes[graph.edges[before.edge].a].pos
	if past.dir != before.dir or graph.position_relative(past.edge,past.s,anchor).distance_to(graph.position_relative(before.edge,_before_s,anchor)) > .01:
		reset()
		return # Teleport/reversal: snap instead of sweeping across unrelated track.
	_distance = travelled
	_lag = travelled

func _sync_external_change() -> void:
	if train.odometer != _current_odometer or train.head_s != _current_s or train.cab_end != _current_cab or train.path != _current_path:
		reset() # Direct test placement, scenario changes and cab reversal.

func sample(fraction: float) -> void:
	_sync_external_change()
	_lag = _distance * (1.0 - clampf(fraction, 0.0, 1.0))

func locate(back: float) -> Dictionary:
	_sync_external_change()
	return _route.locate_behind(graph, back + _lag)

func point(back: float) -> Vector3:
	var loc := locate(back)
	return graph.position_relative(loc.edge, loc.s, coordinate_origin)

func odometer() -> float:
	_sync_external_change()
	return _current_odometer - _lag
