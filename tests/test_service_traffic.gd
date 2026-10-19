extends RefCounted
const Traffic:=preload("res://persistence/service_traffic.gd")

func fixture() -> Dictionary:
	return {version=1,complete=true,engine=Engine.get_version_info().string,start_sha256="current",services=["A","B","C"],audit={ok=true,safety_events=[]},events=[
		{time=86399.0,chainage_m=1000.0,a="A",b="B",kind="crossing",station="STA",location="Station"},
		{time=86410.0,chainage_m=1500.0,a="A",b="C",kind="overtake",overtaker="C",cleared=86430.0,station="",location="Station → Next"}]}

func test_preview_roles_are_reciprocal_and_do_not_mutate_shared_data():
	var data:=fixture();var before:=data.duplicate(true)
	var a:=Traffic.for_service(data,"A");var b:=Traffic.for_service(data,"B");var c:=Traffic.for_service(data,"C")
	if a.size()!=2 or b.size()!=1 or c.size()!=1:return false
	if a[0].other!="B" or b[0].other!="A" or a[0].time!=b[0].time:return "Crossing lost its reciprocal service/time"
	if a[1].role!="Overtakes you" or c[0].role!="You overtake" or a[1].time!=c[0].time:return "Overtake roles reversed"
	a[0].location="Changed"
	return data==before and Traffic.for_service(data,"missing").is_empty()

func test_preview_rejects_stale_incomplete_and_corrupt_catalogues():
	var data:=fixture()
	if not Traffic.validate(data,["A","B","C"],"current").ok:return "Valid fixture rejected"
	if Traffic.validate(data,["A","B","C"],"stale").ok:return "Stale baseline accepted"
	data.complete=false
	if Traffic.validate(data,["A","B","C"],"current").ok:return "Partial preview accepted"
	data=fixture();data.services=["A","A","C"]
	if Traffic.validate(data,["A","B","C"],"current").ok:return "Duplicate service accepted"
	data=fixture();data.events[1].overtaker="D"
	if Traffic.validate(data,["A","B","C"],"current").ok:return "Unknown overtaker accepted"
	data=fixture();data.events[1].cleared=86400
	if Traffic.validate(data,["A","B","C"],"current").ok:return "Overtake completed before passage"
	data=fixture();data.events[1].time=NAN
	return not Traffic.validate(data,["A","B","C"],"current").ok

func test_traffic_summary_and_midnight_use_selected_service_perspective():
	var rows:=Traffic.for_service(fixture(),"A")
	return Traffic.summary(rows)=="1 crossings · 0 you overtake · 1 overtake you" and Traffic.time_text(86399)=="~00:00 · day 2"

func test_shipped_preview_covers_all_departures_and_is_reciprocal():
	var starts:=preload("res://persistence/service_starts.gd").catalogue()
	if not starts.ok:return starts.reason
	var traffic:=Traffic.catalogue(starts.data.services)
	if not traffic.ok:return traffic.reason
	var count:=0
	for row in starts.data.services:count+=Traffic.for_service(traffic.data,row.id).size()
	return count==traffic.data.events.size()*2 and traffic.data.audit.sample_seconds==2
