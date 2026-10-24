extends SceneTree
## Export actual emitted bridge top triangles and independent rail probes.
## No railway is advanced; Python audits union coverage/duplicate area.
const Deck=preload("res://game/geographic_bridge_deck.gd")
class Capture:
	var tops:=[]
	var guards:=[]
	var piers:=[]
	func triangle(kind,a,b,c,normal,_color=Color.WHITE,_uv=[],_uv2=[]):
		if kind=="concrete" and normal.y>.5:tops.append([a,b,c])
	func quad(_kind,_a,_b,_c,_d,_normal,_color=Color.WHITE,_uv=[]):pass
	func beam(kind,a,b,width,_color=Color.WHITE,depth=-1):
		if kind=="metal" and is_equal_approx(width,.065) and depth<0:guards.append([a,b])
		if kind=="concrete" and is_equal_approx(depth,.9):
			var basis:=Basis.looking_at((b-a).normalized())
			var p: Vector3=a+basis.x*width*.5+basis.y*depth*.5
			var q: Vector3=b+basis.x*width*.5+basis.y*depth*.5
			var r: Vector3=b-basis.x*width*.5+basis.y*depth*.5
			var s: Vector3=a-basis.x*width*.5+basis.y*depth*.5
			tops.append([p,q,r]);tops.append([p,r,s])
	func box(_kind,p,size,_color=Color.WHITE,basis=Basis.IDENTITY):piers.append({p=p,size=size,basis=basis})
func vec(p: Vector3):return [p.x,p.y,p.z]
func _initialize():call_deferred("run")
func run():
	var output:="res://.local/map-2026-10-24/bridge-decks.jsonl"
	var baseline
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--baseline="):baseline=load(arg.trim_prefix("--baseline="))
	var w=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
	geo.road_profiles=preload("res://game/geographic_road_profiles.gd").new()
	geo.install_railway(w)
	var layout=preload("res://game/geographic_ohe_layout.gd").new(w)
	var file=FileAccess.open(output,FileAccess.WRITE);var total:=0;var triangles:=0;var started:=Time.get_ticks_msec()
	for span in geo.bridges:
		var ids:=[]
		for eid: String in w.graph.edges:
			var e: Dictionary=w.graph.edges[eid]
			if e.chainage_start<span.end and e.chainage_end>span.start:ids.append(eid)
		if ids.is_empty():continue
		var anchor: Vector3=layout.at_chainage(ids[0],clampf(span.start,w.graph.edges[ids[0]].chainage_start,w.graph.edges[ids[0]].chainage_end),Vector3.ZERO)
		var origin:=Vector3(floorf(anchor.x/256)*256,0,floorf(anchor.z/256)*256)
		var c:=Capture.new();var probes:=[]
		for eid: String in ids:
			var e: Dictionary=w.graph.edges[eid]
			for interval in preload("res://game/geographic_bridges.gd").intervals(e,0,e.length,[span]):
				if baseline!=null:baseline.draw(c,w.graph,geo,layout,eid,interval.start,interval.end,origin)
				else:Deck.draw(c,w.graph,geo,layout,eid,interval,origin)
				var count:=maxi(2,ceili((interval.end-interval.start)/2))
				for i in range(count+1):
					var s:=lerpf(interval.start+.02,interval.end-.02,float(i)/count)
					var p: Vector3=w.graph.position_relative(eid,s,origin)
					var right:=Deck.side(w.graph,eid,s)
					for offset in [-3.8,0.0,3.8]:probes.append({edge=eid,s=s,offset=offset,p=vec(p+right*offset)})
		var tops:=[];var guards:=[];var piers:=[]
		for tri in c.tops:tops.append([vec(tri[0]),vec(tri[1]),vec(tri[2])])
		for guard in c.guards:guards.append([vec(guard[0]),vec(guard[1])])
		for pier in c.piers:
			var ring:=[]
			for corner in [Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(1,0,1),Vector3(-1,0,1)]:ring.append(vec(pier.p+pier.basis*corner))
			piers.append({ring=ring,bottom=pier.p.y-pier.size.y*.5,top=pier.p.y+pier.size.y*.5})
		file.store_line(JSON.stringify({span=span,origin=vec(origin),tops=tops,guards=guards,piers=piers,probes=probes}))
		total+=probes.size();triangles+=tops.size()
	print("BRIDGE_DECK_EXPORT probes=",total," triangles=",triangles," elapsed_ms=",Time.get_ticks_msec()-started)
	quit()
