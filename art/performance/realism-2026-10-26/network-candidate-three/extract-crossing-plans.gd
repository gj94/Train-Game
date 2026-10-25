extends SceneTree
func _initialize():
 var rows:=[]
 for mode in ["classic","predictive"]:
  var folder: String="res://.local/realism-2026-10-26/rehearsals-v3/"+mode+"-network/times"
  for name in DirAccess.get_files_at(folder):
   if not name.ends_with(".bin") or int(name.trim_prefix("T").trim_suffix(".bin"))<18000:continue
   var f:=FileAccess.open_compressed(folder+"/"+name,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
   var size:=f.get_32()
   if f.get_length()<size+4:
    print("Skipping preserved incomplete snapshot: ",folder+"/"+name);f.close();continue
   f.seek(0)
   var data: Dictionary=f.get_var();f.close()
   var plans: Array=data.future.plans.filter(func(p):return p.escape_station in ["NEM","KZT"])
   if plans.is_empty() and not ((mode=="classic" and name=="T024300.bin") or (mode=="predictive" and name=="T023100.bin")):continue
   var actors:={}
   for t in data.trains:
    if t.id in ["L002","L021","L022","L033","M061","M078","V005","S045"]:
     actors[t.id]={path=t.path,speed=t.speed}
   rows.append({mode=mode,file=folder+"/"+name,sha256=FileAccess.get_sha256(folder+"/"+name),clock=data.world.clock_start+data.world.time,plans=plans,trains=actors})
 FileAccess.open("res://.local/realism-2026-10-26/escape-plan-snapshots.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
 print("Matching original snapshots: ",rows.size());quit()
