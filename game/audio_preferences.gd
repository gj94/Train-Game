extends RefCounted
const FILE := "user://audio.cfg"
const LAYERS := {"master":"Master","traction":"Traction","fans":"TrainFans","horn":"TrainHorn","compressor":"TrainCompressor",
	"rolling":"RailRolling","impacts":"RailImpacts","squeal":"RailSqueal","wind":"TrainWind","passing_air":"PassingAir",
	"body":"CoachBody","rattles":"CoachRattles","ambience":"TrainAmbience","footsteps":"TrainFootsteps","doors":"TrainDoors","brake_air":"TrainBrakeAir"}
# New channels inherit their former shared setting once, preserving existing mixes.
const LEGACY := {"fans":"traction","horn":"traction","compressor":"traction","passing_air":"wind","rattles":"body","footsteps":"ambience","doors":"ambience","brake_air":"ambience"}
var levels: Dictionary = {}
var muted: Dictionary = {}
var headphones := false
var quiet := false
var reference := false

func _init(path: String=FILE) -> void:
	var config:=ConfigFile.new();config.load(path)
	for key in LAYERS:
		var value=config.get_value("levels",key,config.get_value("levels",LEGACY.get(key,key),0.0))
		levels[key]=clampf(float(value),-60,6) if (value is float or value is int) and is_finite(float(value)) else 0.0
		muted[key]=config.get_value("muted",key,false)==true
	headphones=config.get_value("mix","headphones",false)==true
	quiet=config.get_value("mix","quiet",false)==true
	reference=config.get_value("mix","reference",false)==true
	apply()

static func bus(name: String, send: String="Master") -> int:
	var index:=AudioServer.get_bus_index(name)
	if index<0:
		AudioServer.add_bus();index=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,name);AudioServer.set_bus_send(index,send)
	return index

func apply() -> void:
	# Godot mixes right to left: the shared output must precede its child buses.
	var output:=bus("TrainOutput")
	if output!=1:AudioServer.move_bus(output,1)
	output=AudioServer.get_bus_index("TrainOutput")
	for key in LAYERS:
		var name: String=LAYERS[key]
		var index:=bus(name)
		AudioServer.set_bus_volume_db(index,levels[key])
		AudioServer.set_bus_mute(index,muted.get(key,false))
	if AudioServer.get_bus_effect_count(output)==0:
		var limiter:=AudioEffectLimiter.new();limiter.ceiling_db=-.8;limiter.threshold_db=-.8
		AudioServer.add_bus_effect(output,limiter)
		var compressor:=AudioEffectCompressor.new();compressor.threshold=-18;compressor.ratio=3;compressor.attack_us=10000;compressor.release_ms=220;compressor.gain=3
		AudioServer.add_bus_effect(output,compressor,0)
	AudioServer.set_bus_effect_enabled(output,0,quiet)
	for key in LAYERS:
		if key!="master":AudioServer.set_bus_send(bus(LAYERS[key]),"TrainOutput")

func save(path: String=FILE) -> void:
	var config:=ConfigFile.new()
	for key in levels:config.set_value("levels",key,levels[key])
	for key in muted:config.set_value("muted",key,muted[key])
	for key in ["headphones","quiet","reference"]:config.set_value("mix",key,get(key))
	config.save(path)

func preset(name: String) -> void:
	for key in levels:levels[key]=0.0;muted[key]=false
	quiet=name=="quiet";headphones=name=="headphones";reference=name=="reference"
	if quiet:levels.impacts=-3.0;levels.wind=-4.0;levels.passing_air=-4.0
	apply();save()
