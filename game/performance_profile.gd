extends RefCounted
## Resource budgets, not quality presets. No geometry, texture or AA reductions.
const GIB:=1024*1024*1024

static func worker_count(logical_cpus: int) -> int:
	# Leave capacity for rendering, simulation, audio and engine task workers.
	return clampi(logical_cpus/4,2,8)

static func settings() -> Dictionary:
	var target:=RenderingServer.get_video_adapter_name().to_lower().contains("rtx 4080")
	return {workers=worker_count(OS.get_processor_count()),warm_chunks=96 if target else 32,
		warm_seconds=120.0,gpu_cache_ceiling=(10.0 if target else 2.0)*GIB,
		activation_usec=2000,activation_children=24}
