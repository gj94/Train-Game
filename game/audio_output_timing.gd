extends RefCounted
## Predict audio submissions ahead of their audible time, preserving source PCM.
const Data := preload("res://game/body_v2_data.gd")
static var output_latency := 0.0
static var mix_period := 0.0
static var _realtime := false
static var _refresh_at := 0

static func refresh() -> void:
	var now := Time.get_ticks_usec()
	if now<_refresh_at: return
	_refresh_at=now+1000000
	# Offline movie capture and Dummy have no physical output device to offset.
	_realtime=AudioServer.get_driver_name()!="Dummy" and Engine.get_write_movie_path().is_empty()
	output_latency=clampf(AudioServer.get_output_latency(),0,.5) if _realtime else 0.0
	mix_period=clampf(AudioServer.get_time_since_last_mix()+AudioServer.get_time_to_next_mix(),0,.2) if _realtime else 0.0

static func delay_seconds() -> float:
	return output_latency+maxf(0.0,AudioServer.get_time_to_next_mix()) if _realtime else 0.0

static func prediction_seconds(frame_seconds: float, simulation_rate: float = 1.0) -> float:
	return Data.KERNEL_LEAD+(output_latency+mix_period)*simulation_rate+maxf(Data.LOOKAHEAD,frame_seconds)
