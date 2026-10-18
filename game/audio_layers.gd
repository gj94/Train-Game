extends RefCounted
const ROOT := "res://assets/sounds/journey/"
static var waves := {}
static func wave(name: String, loop: bool=false) -> AudioStreamWAV:
	var key:=name+str(loop)
	if not waves.has(key):
		var sound: AudioStreamWAV=load(ROOT+name+".wav").duplicate()
		if loop:
			sound.loop_mode=AudioStreamWAV.LOOP_FORWARD;sound.loop_begin=0;sound.loop_end=sound.data.size()/2
		waves[key]=sound
	return waves[key]
static func filtered_bus(owner: Object, suffix: String, destination: String) -> Dictionary:
	var name:="Journey%s-%s" % [owner.get_instance_id(),suffix]
	var index:=preload("res://game/audio_preferences.gd").bus(name,destination)
	var filter:=AudioEffectLowPassFilter.new();filter.cutoff_hz=18000;filter.db=AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(index,filter)
	return {name=name,filter=filter}
static func remove_bus(bus: Dictionary) -> void:
	if bus.is_empty():return
	var index:=AudioServer.get_bus_index(bus.name)
	if index>=0:AudioServer.remove_bus(index)
