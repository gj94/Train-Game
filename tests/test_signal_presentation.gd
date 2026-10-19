extends RefCounted
const Readout:=preload("res://game/signal_readout.gd")
const Asset:=preload("res://game/signal_asset.gd")
func test_distance_only_is_identical_for_every_aspect():
	for aspect in 3:
		if Readout.text({id="HOME-R",distance=456.3},aspect,false)!="Next signal · 456 m":return "Aspect leaked"
	return Readout.text({},0,false)=="No signal ahead" and "GREEN" in Readout.text({id="H",distance=50},2)
func test_signal_has_exactly_one_correct_lit_lens_and_reuses_static_meshes():
	var a:=Node3D.new();var b:=Node3D.new();var lamps:=Asset.build(a);Asset.build(b)
	var ok: bool=a.get_child(0).mesh==b.get_child(0).mesh and a.get_child_count()==5
	for aspect in 3:
		Asset.apply(lamps,aspect)
		for i in 3:ok=ok and lamps[i].material_override.get_shader_parameter("lit")== (i==2-aspect)
	a.free();b.free();return ok
