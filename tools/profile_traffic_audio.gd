extends SceneTree
## Deterministic six-service CPU/queue profile; no rendering cost in the result.
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const Plan := preload("res://sim/dispatch_plan.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Sound := preload("res://game/platform_audio.gd")
class Listener extends Node3D:
	var mode := 1
	var pivot := Vector3.ZERO
var elapsed := 0.0
func _initialize() -> void: call_deferred("run_profile")
func run_profile() -> void:
	var world := Traffic.build()
	var listener := Listener.new()
	if "--exterior" in OS.get_cmdline_user_args(): listener.mode = 0
	root.add_child(listener)
	var sounds := {}
	for train in world.trains.values():
		train.automatic = true
		var sound := Sound.new()
		root.add_child(sound)
		sound.setup(train,world,listener,Stock.sound_axles(train.stock_kind.trim_prefix("ported:")))
		sound.set_process(false)
		sounds[train.id] = sound
	for sound in sounds.values(): sound.listener_owner = sounds.T1
	var durations := []
	var results := []
	var seconds := 120
	var output := "res://.local/traffic-audio-profile.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="): seconds = maxi(10,int(arg.trim_prefix("--seconds=")))
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	for frame in seconds*10:
		if frame%5 == 0: Plan.update(world,false)
		world.step(.1)
		elapsed += .1
		var loc: Dictionary = world.trains.T1.locate_behind(world.graph,2.0)
		listener.global_position = world.graph.position(loc.edge,loc.s)+Vector3(0,3.0,.4)
		listener.pivot = listener.global_position
		var started := Time.get_ticks_usec()
		for sound in sounds.values(): sound._process(.1)
		durations.append((Time.get_ticks_usec()-started)*.001)
		if frame%100 == 99:
			var queues := {}
			var events := 0
			for id in sounds:
				queues[id] = sounds[id]._events.size()
				events += sounds[id]._events.size()
			durations.sort()
			var mean := 0.0
			for value in durations: mean += value/durations.size()
			var sample := {seconds=snappedf(elapsed,.1),cpu_ms=mean,p95_ms=durations[int(durations.size()*.95)],events=events,queues=queues,buses=AudioServer.bus_count}
			results.append(sample)
			print(JSON.stringify(sample))
			var report := FileAccess.open(output,FileAccess.WRITE)
			report.store_string(JSON.stringify(results,"\t"))
			durations.clear()
		await process_frame
	for sound in sounds.values(): sound.free()
	sounds.clear()
	listener.free()
	await create_timer(.2).timeout
	call_deferred("quit")
