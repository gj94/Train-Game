extends RefCounted
const Quality:=preload("res://tools/wait_quality.gd")

func test_requested_wait_distribution_passes():
	var rows:=[]
	for i in 100:rows.append({seconds=500 if i<70 else 1100 if i<90 else 1700 if i<98 else 2600})
	var report:=Quality.summarize(rows)
	return report.ok and report.bins==[70,20,8,2,0]

func test_better_distribution_passes_without_manufacturing_long_waits():
	return Quality.summarize([{seconds=100},{seconds=40}]).ok

func test_trivial_startup_pauses_do_not_hide_long_waits():
	var rows:=[{seconds=2600}]
	for i in 100:rows.append({seconds=2})
	var report:=Quality.summarize(rows)
	return not report.ok and report.count==1 and report.brief_count==100

func test_each_percentile_and_absolute_limit_is_enforced():
	for failing in [0,1,2,3]:
		var rows:=[]
		for i in 100:rows.append({seconds=500 if i<70 else 1100 if i<90 else 1700 if i<98 else 2600})
		rows[[69,89,97,99][failing]].seconds=Quality.LIMITS[failing]
		if Quality.summarize(rows).ok:return "Accepted over-budget band "+str(failing)
	return true
