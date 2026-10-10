extends RefCounted
## Resource budgets, not quality presets. No geometry, texture or AA reductions.
const GIB:=1024*1024*1024

static func worker_count(logical_cpus: int) -> int:
	# Leave capacity for rendering, simulation, audio and engine task workers.
	return clampi(logical_cpus/4,2,8)

static func settings() -> Dictionary:
	return for_adapter(RenderingServer.get_video_adapter_name(),OS.get_processor_count())

static func for_adapter(adapter: String,cpus: int) -> Dictionary:
	var name:=adapter.to_lower()
	var large: bool="rtx 4090" in name or "rtx 4080" in name or "rx 7900" in name
	var budget:=8.0 if "laptop" in name and "4090" in name else (6.0 if "laptop" in name else 10.0)
	return {workers=worker_count(cpus),warm_chunks=96 if large else 32,
		warm_seconds=120.0,gpu_cache_ceiling=(budget if large else 2.0)*GIB,
		activation_usec=2000,activation_children=24}
