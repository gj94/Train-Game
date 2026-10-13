extends "res://tools/soak_coastal_streaming.gd"
## Camera-only 140 km/h sweep and reversal on real track geometry. The railway
## is paused: this measures scenery coverage, not overspeed train physics.
var route:=[]
var route_length:=0.0
var coverage_samples:=0
var loading_samples:=0
var origin_changes:=0

func route_between(start: String,target: String) -> Array:
	var graph: TrackGraph=game.world.graph
	var queue:=[start];var parents:={start:{}};var cursor:=0
	while cursor<queue.size():
		var node: String=queue[cursor];cursor+=1
		if node==target:break
		for edge: String in graph.nodes[node].edges:
			var other: String=graph.edges[edge].b if graph.edges[edge].a==node else graph.edges[edge].a
			if parents.has(other):continue
			parents[other]={previous=node,edge=edge,dir=1 if graph.edges[edge].a==node else -1};queue.append(other)
	if not parents.has(target):return []
	var result:=[];var node:=target
	while node!=start:
		result.push_front(parents[node]);node=parents[node].previous
	return result

func move_camera(distance: float,backward: bool) -> void:
	var graph: TrackGraph=game.world.graph
	for step in route:
		var length: float=graph.edges[step.edge].length
		if distance>length:distance-=length;continue
		var s: float=distance if step.dir>0 else length-distance
		var point:=graph.position_relative(step.edge,s,game.wv.coordinate_origin)+Vector3.UP*3.5
		var forward:=graph.tangent(step.edge,s,step.dir)*(-1 if backward else 1)
		game.cam.enter_free(point,forward);return

func run() -> void:
	root.size=Vector2i(1280,720);started=Time.get_ticks_msec()
	if not await load_service("B012"):printerr("REVERSAL loading timeout");quit(2);return
	game._set_paused(true)
	var graph: TrackGraph=game.world.graph
	var start: String=graph.entry_node(game.train.path[0].edge,game.train.path[0].dir)
	var target_station: Dictionary=game.world.stations.filter(func(s):return s.code=="KZT")[0]
	var target: String=graph.edges[target_station.platform_tracks[0]].a
	route=route_between(start,target)
	for step in route:route_length+=float(graph.edges[step.edge].length)
	if route_length<5000:printerr("REVERSAL invalid route");quit(2);return
	game._set_cab_visuals(false);game.dispatcher.set_open(false)
	move_camera(0,false)
	while game.wv.loading:await process_frame
	var length:=minf(6000,route_length);var distance:=0.0
	var last:=Time.get_ticks_msec();var until:=last+600000
	var origin: Vector3=game.wv.coordinate_origin
	for backward in [false,true]:
		while distance>=0 and distance<=length:
			await process_frame
			var now:=Time.get_ticks_msec();var elapsed: float=(now-last)*.001;last=now
			distance+=elapsed*140.0/3.6*(-1 if backward else 1)
			move_camera(clampf(distance,0,length),backward)
			if game.wv.coordinate_origin!=origin:origin_changes+=1;origin=game.wv.coordinate_origin
			if now>=next_sample:
				record("reverse_140" if backward else "forward_140");coverage_samples+=1
				if game.wv.loading:loading_samples+=1
				next_sample=now+2000
			if now>until:printerr("REVERSAL timed out");quit(2);return
		distance=length if not backward else 0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+("/returned.png" if backward else "/turnaround.png"))
	if origin_changes<4:errors+=1
	await close_service()
	var result:={complete=true,errors=errors,coverage_samples=coverage_samples,loading_samples=loading_samples,
		origin_changes=origin_changes,metres=length*2,wall_seconds=(Time.get_ticks_msec()-started)*.001,
		journeys=summaries,note="Paused railway, camera-only 140 km/h source sweep/reversal; not an overspeed physics test."}
	FileAccess.open(output+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	log_file.close();print("REVERSAL_COMPLETE ",JSON.stringify(result));quit(1 if errors else 0)
