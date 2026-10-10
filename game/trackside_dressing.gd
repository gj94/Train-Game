extends RefCounted
## Sparse original scenic details on verified dry, unoccupied land.
## Operational boards, crossings, culverts and drainage stay route-owned.
const Kerala:=preload("res://game/kerala_scenery.gd")
static func add(c) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=hash(str(c.origin)+"trackside")
	var count:=0
	for i in 40:
		var p:=Vector2(rng.randf_range(12,500),rng.randf_range(12,500))
		var absolute:=p+Vector2(c.origin.x,c.origin.z)
		var rail: Dictionary=c.geo.nearest_rail(absolute.x,absolute.y)
		if rail.distance<25 or rail.distance>95 or not Kerala.dry_clear(c,p,4):continue
		var kind: String=["KR_R01","KR_R02","KR_R11","KR_R12","KR_R13"][i%5]
		var front:=Kerala.frontage(c,p,c.tile_features)
		if front.length()>7 and front.length()<20:kind=["KR_U01","KR_U02","KR_U03"][i%3]
		var height: float=c._ground(p.x,p.y)
		var low:=height;var high:=height
		for offset in [Vector2(2,2),Vector2(-2,2),Vector2(2,-2),Vector2(-2,-2)]:
			var h: float=c._ground(p.x+offset.x,p.y+offset.y);low=minf(low,h);high=maxf(high,h)
		if high-low>.20:continue
		# Seat the base in the terrain, with a small maintenance hardstanding.
		c.batch.box("forecourt",Vector3(p.x,high-.08,p.y),Vector3(4.8,.18,4.8),Color.WHITE)
		c.library.place("tf3_"+kind,Vector3(p.x,high,p.y),atan2(front.x,front.y))
		c.occupancy.add_road(p,p,3.5)
		count+=1
		if count>=3:break
	c.root.set_meta("trackside_details",count)
