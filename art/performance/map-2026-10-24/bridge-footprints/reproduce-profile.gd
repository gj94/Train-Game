extends SceneTree
func _initialize():call_deferred("run")
func run():
 var w=preload("res://sim/layouts/kerala_coast.gd").build()
 var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
 geo.road_profiles=preload("res://game/geographic_road_profiles.gd").new();geo.install_railway(w)
 var layout=preload("res://game/geographic_ohe_layout.gd").new(w)
 var before=load("res://.local/map-2026-10-24/deck-baseline.gd")
 var after=preload("res://game/geographic_bridges.gd")
 var jobs=[];var cases=[]
 for eid in w.graph.edges:
  var e=w.graph.edges[eid]
  if not after.intervals(e,0,e.length,geo.bridges).is_empty():jobs.append(eid)
 for km in [4.25,6.6,129.1,140.73]:
  var span=geo.bridge_at(km*1000)
  if span.is_empty():
   for candidate in geo.bridges:
    if span.is_empty() or absf((candidate.start+candidate.end)*.5-km*1000)<absf((span.start+span.end)*.5-km*1000):span=candidate
  var chain=(span.start+span.end)*.5;var selected=""
  for eid in jobs:
   var e=w.graph.edges[eid]
   if chain>=e.chainage_start and chain<e.chainage_end:
    if selected=="" or absf(e.get("lateral",0))<absf(w.graph.edges[selected].get("lateral",0)):selected=eid
  var e=w.graph.edges[selected];var s=(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length
  var a=w.graph.position(selected,s);var b=a+w.graph.tangent(selected,s,1)*10
  cases.append({a=[a.x,a.y,a.z],b=[b.x,b.y,b.z],building=selected,km=km,kind="actual-bridge-footprints",distance=12,height=5,side=18,target_height=-.4,look_back=4})
 FileAccess.open("res://.local/map-2026-10-24/deck-cases.json",FileAccess.WRITE).store_string(JSON.stringify(cases,"\t"))
 var results=[]
 for trial in 3:
  for mode in (["before","after"] if trial%2==0 else ["after","before"]):
   var script=before if mode=="before" else after;var total_usec=0;var total_vertices=0;var worst=0
   for eid in jobs:
    var e=w.graph.edges[eid];var p=w.graph.position(eid,e.length*.5);var origin=Vector3(floorf(p.x/256)*256,0,floorf(p.z/256)*256)
    var batch=preload("res://game/geographic_mesh.gd").new()
    var started=Time.get_ticks_usec()
    script.draw(batch,w.graph,geo,layout,eid,0,e.length,origin)
    for surface in batch.surfaces.values():
     var mesh=surface.commit();total_vertices+=mesh.surface_get_array_len(0)
    var elapsed=Time.get_ticks_usec()-started;total_usec+=elapsed;worst=maxi(worst,elapsed)
   results.append({mode=mode,trial=trial,total_ms=total_usec/1000.0,worst_edge_ms=worst/1000.0,vertices=total_vertices,jobs=jobs.size()})
   print("DECK_PROFILE ",JSON.stringify(results[-1]))
 FileAccess.open("res://.local/map-2026-10-24/deck-generation.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 quit()
