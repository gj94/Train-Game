extends SceneTree
## All adjacent geographic terrain edges, without stepping the railway. Outer
## mesh edges interpolate these shared 8 m samples, including fine shore tiles.
var cache:={}
var order:=[]
func _initialize():call_deferred("run")
func chunk(geo,key):
	if cache.has(key):return cache[key]
	var tile=geo.tile(key)
	var c=preload("res://game/geographic_scenery_chunk.gd").new(geo,{},null)
	c.origin=Vector3(key.x*512,0,key.y*512)
	for f in tile.get("features",[]):
		if f.kind=="water":c.water_levels.append({geometry=f.geometry,height=f.get("water_height",0)})
	c._index_shores();cache[key]=c;order.append(key)
	if order.size()>32:cache.erase(order.pop_front())
	return c
func run():
	var output:="res://.local/scenery-borders.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	var world=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world);geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world,geo)
	var samples:=0;var borders:=0;var maximum:=0.0;var worst:={};var failures:=[];var tiles:=0
	for key in geo.tile_keys:
		var own=chunk(geo,key)
		for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
			if not geo.tile_keys.has(key+direction):continue
			var other=chunk(geo,key+direction);borders+=1
			for i in 65:
				var a:=Vector2(512,i*8) if direction==Vector2i.RIGHT else Vector2(i*8,512)
				var b:=Vector2(0,i*8) if direction==Vector2i.RIGHT else Vector2(i*8,0)
				var heights:=[own._ground(a.x,a.y),other._ground(b.x,b.y)]
				var error:=absf(heights[0]-heights[1]);samples+=1
				if error>maximum or error>.001:
					var row:={tile=[key.x,key.y],neighbour=[key.x+direction.x,key.y+direction.y],point=[key.x*512+a.x,key.y*512+a.y],heights=heights,error=error}
					if error>maximum:maximum=error;worst=row
					if error>.001:failures.append(row)
		tiles+=1
		if tiles%250==0:print("SCENERY_BORDERS tiles=",tiles," samples=",samples," failures=",failures.size())
	var report:={tiles=tiles,borders=borders,samples=samples,maximum_error_m=maximum,worst=worst,failures=failures,tolerance_m=.001}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SCENERY_BORDERS_COMPLETE samples=",samples," maximum=",maximum," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
