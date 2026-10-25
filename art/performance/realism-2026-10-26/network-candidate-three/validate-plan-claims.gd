extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rows:=[]
 for item in [{mode="classic",file="T024600.bin"},{mode="predictive",file="T023400.bin"}]:
  var path: String="res://.local/realism-2026-10-26/rehearsals-v3/"+item.mode+"-network/times/"+item.file
  var f:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
  var snapshot: Dictionary=f.get_var();f.close()
  var result: Dictionary=preload("res://sim/world_snapshot.gd").restore(snapshot)
  if not result.ok:printerr(result.reason);quit(1);return
  var w: RailWorld=result.world
  var before:=var_to_bytes(preload("res://sim/world_snapshot.gd").capture(w))
  for p in w.dispatcher().future_clearances.plans:
   if p.escape_station not in ["NEM","KZT"]:continue
   var station: Dictionary=w.stations.filter(func(st):return st.code==p.escape_station)[0]
   var claims:=preload("res://sim/dispatch_planner.gd").new()._station_claims(w,station)
   rows.append({mode=item.mode,path=path,sha256=FileAccess.get_sha256(path),clock=w.clock_seconds(),plan=p,claims=claims,all_claims_fit=preload("res://sim/dispatch_planner.gd")._can_berth(claims),snapshot_unchanged=before==var_to_bytes(preload("res://sim/world_snapshot.gd").capture(w))})
 FileAccess.open("res://.local/realism-2026-10-26/escape-plan-claims.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
 print(JSON.stringify(rows));quit()
