extends RefCounted
const Cache:=preload("res://game/immutable_asset_cache.gd")

func test_old_station_resources_expire_while_live_consumers_remain_valid():
	var cache:=Cache.new(2,"station_")
	var resource:=RefCounted.new();var weak: WeakRef=weakref(resource)
	var consumer: Dictionary=cache.publish("station_a",{resource=resource})
	resource=null
	cache.publish("station_b",{name="B"});cache.publish("station_c",{name="C"})
	if cache.contains("station_a") or not _alive(weak):return "Eviction invalidated a live consumer"
	consumer.clear()
	return weak.get_ref()==null and cache.counts().bounded==2

func _alive(weak: WeakRef) -> bool:
	# Keep get_ref's temporary strong reference out of the collection test's scope.
	return weak.get_ref()!=null

func test_cache_revisits_keep_recent_stations_and_do_not_evict_rolling_stock():
	var cache:=Cache.new(2,"station_")
	cache.publish("wap7",{name="loco"});cache.publish("station_a",{name="A"})
	cache.publish("station_b",{name="B"});cache.fetch("station_a")
	cache.publish("station_c",{name="C"})
	return cache.contains("station_a") and not cache.contains("station_b") and cache.fetch("wap7").name=="loco" and cache.counts().bounded==2

func test_concurrent_publication_returns_one_immutable_bundle_and_stays_bounded():
	var cache:=Cache.new(8)
	var workers:=[]
	for i in 4:
		var worker:=Thread.new()
		worker.start(func():
			for entry in 500:
				var key:="asset%d"%(entry%12)
				cache.publish(key,{key=key});cache.fetch(key)
			return true)
		workers.append(worker)
	for worker in workers:worker.wait_to_finish()
	var first: Dictionary=cache.publish("one",{version=1})
	var duplicate: Dictionary=cache.publish("one",{version=2})
	return first.version==1 and duplicate.version==1 and cache.counts().bounded<=8
