extends RefCounted
## Small local crash breadcrumbs. No GPU queries, uploads or scene-tree scans.
## Called by the owning main loop; never inspect a worker-owned railway.
const INTERVAL_MS:=5000
const MAX_BYTES:=256*1024
var path: String
var previous: String
var file: FileAccess
var header:={}
var next_sample:=0
var last_frame:=0
var peak_frame_ms:=0
var records:=0
var limit:=MAX_BYTES
var writer
var enabled:=false

func _init(directory: String="user://logs") -> void:
	path=directory.path_join("journey-current.jsonl")
	previous=directory.path_join("journey-previous.jsonl")

func start(metadata: Dictionary) -> bool:
	# Rotation serializes this on the writer. Nested preferences must not remain
	# shared with settings edited by the presentation thread during a journey.
	header=metadata.duplicate(true);header.event="session";header.format=1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if not _rotate():return false
	writer=preload("res://game/stream_worker.gd").new();writer.start(_append_line)
	enabled=true
	next_sample=Time.get_ticks_msec()+INTERVAL_MS;last_frame=Time.get_ticks_msec()
	return true

func _rotate() -> bool:
	if file!=null:file.close();file=null
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(previous) and DirAccess.remove_absolute(previous)!=OK:return false
		if DirAccess.rename_absolute(path,previous)!=OK:return false
	file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_line(JSON.stringify(header));file.flush();return true

func write(row: Dictionary) -> void:
	if not enabled:return
	var completed: Dictionary=writer.take()
	if not completed.is_empty() and not completed.result.ok:enabled=false;return
	# At most one pending write. A stalled disk never stalls play or grows a queue.
	if not writer.job.is_empty():return
	writer.submit({line=JSON.stringify(row)});records+=1

func _append_line(job: Dictionary) -> Dictionary:
	if file==null:return {ok=false}
	var line: String=job.line
	if file.get_length()+line.to_utf8_buffer().size()+1>limit and not _rotate():return {ok=false}
	file.store_line(line);file.flush();return {ok=file.get_error()==OK}

func flush() -> void:
	# Only explicit tests and scene shutdown wait; the normal frame loop never does.
	if writer==null:return
	while writer.busy():OS.delay_msec(1)
	var completed: Dictionary=writer.take()
	if not completed.is_empty() and not completed.result.ok:enabled=false

func sample(game,now: int) -> void:
	if not enabled:return
	peak_frame_ms=maxi(peak_frame_ms,now-last_frame);last_frame=now
	if now<next_sample:return
	next_sample=now+INTERVAL_MS
	if game.time_skip!=null and game.time_skip.running():
		# Ownership may already be transferred before main processing is disabled.
		write({event="time_skip",wall_ms=now});peak_frame_ms=0;return
	var train: Train=game.train
	var row:={event="journey",wall_ms=now,clock=game.world.clock_seconds(),service=train.id,
		edge=train.path[0].edge,s=train.head_s,speed_kmh=train.speed*3.6,odometer=train.odometer,
		automatic=train.automatic,paused=game.paused,time_scale=game.time_scale,
		camera=game.cam.mode,peak_loop_gap_ms=peak_frame_ms,
		heap_bytes=OS.get_static_memory_usage() if OS.is_debug_build() else null}
	if game.geographic_drive:
		var view=game.wv
		row.merge({origin=str(view.coordinate_origin),camera_local=str(game.cam.global_position),loading=view.loading,
			loaded=view.loaded.size(),warm=view._warm.size(),pending=view.queue.size(),activating=view._activating.size(),
			completed=view.completed_jobs,jobs=view.workers.map(func(worker):return worker.runner.job.get("id",""))})
	write(row);peak_frame_ms=0

func close() -> void:
	if writer!=null:
		flush();write({event="clean_scene_exit",wall_ms=Time.get_ticks_msec()});flush()
		writer.close();writer=null
	if file!=null:file.close();file=null
	enabled=false
