extends RefCounted
const Earthworks:=preload("res://game/geographic_earthworks.gd")

func test_formation_stays_level_then_reveals_both_banks_and_cuttings():
	for natural in [-2.0,12.0]:
		var rail:={height=5.15,distance=0.0,bridge=false}
		for distance in [0.0,7.0,14.0]:
			rail.distance=distance
			if absf(Earthworks.grade(natural,rail,14)-5)>.0001:return "Changed protected running formation"
		rail.distance=24.0
		var side:=Earthworks.grade(natural,rail,14)
		if natural<5 and not (side<4 and side>natural):return "Embankment remains artificially flat"
		if natural>5 and not (side>6 and side<natural):return "Cutting remains artificially flat"
		rail.distance=100.0
		if not is_equal_approx(Earthworks.grade(natural,rail,14),natural):return "Earthwork never rejoins natural landscape"
	return true

func test_station_transition_is_continuous_across_old_bin_boundaries():
	var bins:=Earthworks.index([{start=1000.0,end=3000.0,width=48.0}])
	for s in [500.0,720.0,1000.0,1500.0,3000.0,3280.0,3500.0]:
		if absf(Earthworks.half_width(bins,s-.01)-Earthworks.half_width(bins,s+.01))>.004:return "Step in station formation at "+str(s)
	if Earthworks.half_width(bins,2500)!=48:return "Station road footprint shrank"
	return Earthworks.half_width(bins,0)==14 and Earthworks.half_width(bins,4000)==14

func test_overlapping_station_tapers_do_not_create_a_notch():
	var regions:=[{start=-1500.0,end=-500.0,width=40.0},{start=-650.0,end=500.0,width=50.0}]
	var bins:=Earthworks.index(regions)
	for s in range(-650,-499):
		if Earthworks.half_width(bins,s)!=50:return "Overlap reduced the larger yard"
	return Earthworks.half_width(bins,-1781)==14

func test_bridge_clearance_does_not_fill_the_river_or_bury_deck():
	for natural in [-4.0,2.0,15.0]:
		for d in [0.0,14.0,28.0,55.0,90.0]:
			var result:=Earthworks.grade(natural,{height=8.0,distance=d,bridge=true},14)
			if result>natural+.0001:return "Bridge created a dam"
			if d<=14 and result>7.201:return "Terrain buried bridge deck"
	return true

func test_station_regions_retain_old_protected_widths():
	var regions:=Earthworks.regions({stations=[{s=2510.0}]},{stations=[{roads=[{offset=-32.0},{offset=10.0}]}]})
	var bins:=Earthworks.index(regions)
	for s in range(1500,4000,50):
		if Earthworks.half_width(bins,s)<60:return "Previously protected station envelope lost"
	return Earthworks.half_width(bins,0)==14

func test_distant_parallel_line_retains_formation_and_mesh_grid_margin():
	var regions:=[]
	var edges:={parallel={a="a",b="b",lateral=-16.3,chainage_start=2500.0,chainage_end=1500.0}}
	Earthworks.include_running_roads(regions,edges,{a={lateral=-16.3},b={lateral=-4.5}})
	var bins:=Earthworks.index(regions)
	if not is_equal_approx(Earthworks.half_width(bins,2000),28.3):return "Parallel main line omitted"
	Earthworks.include_running_roads(regions,edges,{a={lateral=-16.3},b={lateral=-4.5}})
	if regions.size()!=1:return "Installing the same formation duplicated work"
	return Earthworks.half_width(bins,1000)==14
