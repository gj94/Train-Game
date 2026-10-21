extends RefCounted
const Summary:=preload("res://game/save_summary.gd")

func test_old_summary_and_backup_are_explained_without_invented_viewpoint():
	var old:={service="K1",clock="09:30",day=1,title="Passenger",saved_at="2026-10-22 03:00:00",stops=2,total=43}
	var text:=Summary.describe(old,true)
	return text.contains("2 / 43") and text.contains("Previous version") and not text.contains("Pilot seat") and not text.contains("AI driving")

func test_summary_presents_role_recovery_and_progress_without_changing_source():
	var info:={service="K1",clock="09:30",day=1,title="Passenger",saved_at="2026-10-22 03:00:00",stops=2,total=43,viewpoint="Passenger seat · carriage 5",control="AI driving",reason="Before time skip"}
	var before:=info.duplicate(true);var text:=Summary.describe(info)
	return info==before and text.contains(info.viewpoint) and text.contains(info.reason) and text.contains("AI driving") and text.contains("2 / 43")
