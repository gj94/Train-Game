extends SceneTree
## Audit the same absolute roof envelopes used by geographic scenery generation.
func _init():
 var w=preload("res://sim/layouts/kerala_coast.gd").build()
 var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
 geo.install_railway(w)
 geo.station_sites=preload("res://game/coastal_station_sites.gd").build(w)
 geo.vegetation_clearance=preload("res://game/vegetation_clearance.gd").build(w)
 var report:={}
 for code in ["QLN","TVC"]:
  var station: Dictionary=w.stations.filter(func(s):return s.code==code)[0]
  var origin: Vector3=station.origin
  var rejected:={};var retained:={}
  for x in range(floori((origin.x-1800)/512),ceili((origin.x+1800)/512)):
   for z in range(floori((origin.z-1800)/512),ceili((origin.z+1800)/512)):
    var tile: Dictionary=geo.tile(Vector2i(x,z));var tile_origin:=Vector3(x*512,0,z*512)
    for feature in tile.get("features",[]):
     if feature.kind!="building" or feature.tags.get("building","") in ["train_station","station"]:continue
     var polygons: Array=feature.geometry.coordinates if feature.geometry.type=="MultiPolygon" else [feature.geometry.coordinates]
     for poly in polygons:
      if poly.is_empty() or poly[0].size()<4:continue
      var ring:=PackedVector2Array()
      for p in poly[0]:ring.append(Vector2(p[0],p[1]))
      if ring[0].is_equal_approx(ring[-1]):ring.remove_at(ring.size()-1)
      if preload("res://game/coastal_station_sites.gd").intersect(geo.station_sites,ring,tile_origin):continue
      var centre:=Vector2.ZERO
      for p in ring:centre+=p
      centre/=ring.size()
      var rail: Dictionary=geo.nearest_rail(centre.x+tile_origin.x,centre.y+tile_origin.z)
      if rail.distance<(60 if rail.get("depot",false) else 22):continue
      var width: float=preload("res://game/railway_render_budget.gd").CORRIDOR_WIDTH
      if rail.distance>width and not Array(ring).any(func(p):return geo.nearest_rail(p.x+tile_origin.x,p.y+tile_origin.z).distance<=width):continue
      var envelope:=PackedVector2Array()
      for p in ring:envelope.append(centre+(p-centre)*1.06+Vector2(tile_origin.x,tile_origin.z))
      if geo.vegetation_clearance.clear_polygon(envelope,.8):retained[feature.id]=true
      else:rejected[feature.id]=true
  report[code]={additional_conflicting_footprints_removed=rejected.size(),retained_clear_footprints=retained.size(),removed_ids=rejected.keys()}
 FileAccess.open("res://.local/map-building-clearance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print(JSON.stringify(report));quit()
