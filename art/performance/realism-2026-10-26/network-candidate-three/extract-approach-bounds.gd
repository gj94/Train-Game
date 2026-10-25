extends SceneTree
func _initialize():
 var w:=preload("res://sim/layouts/kerala_coast.gd").build()
 var rows:={}
 for id in w.single_line_sections:
  var section: String=w.single_line_sections[id]
  if section not in ["TVC_single","KZT_single"]:continue
  if not rows.has(section):rows[section]=[]
  var e: Dictionary=w.graph.edges[id]
  rows[section].append({edge=id,from=e.chainage_start,to=e.chainage_end})
 FileAccess.open("res://.local/realism-2026-10-26/escape-approach-bounds.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
 quit()
