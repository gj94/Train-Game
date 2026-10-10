extends SceneTree
## Equal-distance curve metrics and graph export for the independent crossing audit.
func _init() -> void:
 var path:="res://sim/layouts/kerala_coast.gd"
 var output:=".local/map-geometry"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--layout="):path=arg.trim_prefix("--layout=")
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 var layout=load(path).new()
 var began:=Time.get_ticks_msec()
 var w: RailWorld=layout._build()
 var build_ms:=Time.get_ticks_msec()-began
 var worst:=[];var exported:=[];var failures:=[];var jumps:=0
 for id in w.graph.edges:
  var e: Dictionary=w.graph.edges[id]
  var angle:=0.0
  for s in range(5,int(e.length)-5,5):
   var a:=w.graph.position_relative(id,s-5,e.points[0])
   var b:=w.graph.position_relative(id,s,e.points[0])
   var c:=w.graph.position_relative(id,s+5,e.points[0])
   var incoming:=b-a;incoming.y=0
   var outgoing:=c-b;outgoing.y=0
   angle=maxf(angle,rad_to_deg(incoming.angle_to(outgoing)))
  worst.append({id=id,angle_degrees=angle})
  var points:=[]
  for p in e.points:points.append([p.x,p.z])
  exported.append({id=id,a=e.a,b=e.b,points=points,sa=e.chainage_start,sb=e.chainage_end})
  if e.chainage_start>=e.chainage_end:failures.append("Nonpositive edge "+id)
 for i in range(5,layout.distance.size()-5,19):
  var s: float=layout.distance[i]
  var a: Array=layout.point(s-.001,80);var b: Array=layout.point(s+.001,80)
  if Vector2(a[0]-b[0],a[2]-b[2]).length()>.03:jumps+=1
 worst.sort_custom(func(a,b):return a.angle_degrees>b.angle_degrees)
 var result:={layout=path,build_ms=build_ms,edge_count=w.graph.edges.size(),sample_metres=5,maximum_bend_degrees=worst[0].angle_degrees,worst=worst.slice(0,15),outer_offset_discontinuities=jumps,failures=failures}
 FileAccess.open(output+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
 FileAccess.open(output+"-graph.json",FileAccess.WRITE).store_string(JSON.stringify(exported))
 print(JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
