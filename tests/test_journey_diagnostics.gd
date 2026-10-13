extends RefCounted
const Journal:=preload("res://game/journey_diagnostics.gd")

class BusySkip:
	func running() -> bool:return true
class WorkerOwnedGame:
	var time_skip:=BusySkip.new()
	var world_reads:=0
	var world:
		get:world_reads+=1;return null

func cleanup(logfile) -> void:
	for path in [logfile.path,logfile.previous]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(logfile.path.get_base_dir())

func test_diagnostics_never_read_worker_owned_world_and_are_rate_limited():
	var journal:=Journal.new("res://.local/test-journal-"+str(Time.get_ticks_usec()))
	if not journal.start({build="fixture"}):return "Could not create diagnostic fixture"
	var game:=WorkerOwnedGame.new()
	journal.sample(game,journal.next_sample-1)
	var valid: bool=journal.records==0 and game.world_reads==0
	journal.sample(game,journal.next_sample)
	valid=valid and journal.records==1 and game.world_reads==0
	journal.close()
	var lines:=FileAccess.get_file_as_string(journal.path).strip_edges().split("\n")
	valid=valid and JSON.parse_string(lines[1]).event=="time_skip" and JSON.parse_string(lines[-1]).event=="clean_scene_exit"
	cleanup(journal);return valid

func test_diagnostics_keep_two_bounded_files_and_flush_the_latest_record():
	var journal:=Journal.new("res://.local/test-journal-"+str(Time.get_ticks_usec()))
	journal.limit=1024
	var preferences:={quality="High",nested={scale=1.0}}
	if not journal.start({build="fixture",graphics=preferences}):return "Could not create diagnostic fixture"
	preferences.quality="Low";preferences.nested.scale=.5
	for i in 100:
		journal.write({event="fixture",sequence=i,edge="NCJ_NJT_M0",clock=33000+i});journal.flush()
	# Read while the writer is open: a native process crash must leave this line.
	var lines:=FileAccess.get_file_as_string(journal.path).strip_edges().split("\n")
	var valid: bool=JSON.parse_string(lines[-1]).sequence==99 and FileAccess.file_exists(journal.previous)
	var header: Dictionary=JSON.parse_string(lines[0])
	valid=valid and header.graphics.quality=="High" and header.graphics.nested.scale==1.0
	for path in [journal.path,journal.previous]:
		valid=valid and FileAccess.get_file_as_bytes(path).size()<=journal.limit
	journal.close();cleanup(journal);return valid

func test_slow_diagnostic_disk_keeps_only_one_pending_write():
	var journal:=Journal.new("res://.local/test-journal-"+str(Time.get_ticks_usec()))
	if not journal.start({build="fixture"}):return "Could not create diagnostic fixture"
	journal.writer.close()
	journal.writer=preload("res://game/stream_worker.gd").new()
	var gate:=Semaphore.new()
	journal.writer.start(func(_job):gate.wait();return {ok=true})
	journal.write({sequence=0})
	for i in 100:journal.write({sequence=i+1})
	var valid: bool=journal.records==1 and JSON.parse_string(journal.writer.job.line).sequence==0
	gate.post();journal.flush();journal.writer.close();journal.writer=null
	journal.close();cleanup(journal);return valid
