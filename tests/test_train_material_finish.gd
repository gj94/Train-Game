extends RefCounted
const Finish:=preload("res://game/train_material_finish.gd")

func test_lhb_shared_sign_material_only_emits_at_ceiling_height():
	var fixture:=Finish.fixture("lhb_cc","lhb_cc_Signs_and_diffusers")
	return fixture.minimum_height>3.37438 and fixture.minimum_height<3.598

func test_known_interior_diffusers_retain_family_colour():
	for item in [["wap7","wap7_CABV02_Frosted lamp diffuser"],["wap7","wap7_MACHV02_Fluorescent opal diffuser"],["icf_gs","icf_gs_Warm light diffuser"],["vb_dtc","vb_dtc_VB02_INT_Diffused_daylight_LED"]]:
		if Finish.fixture(item[0],item[1]).is_empty():return "Missing interior fixture "+item[1]
	return true

func test_glazing_exterior_markings_and_other_assets_never_emit():
	for item in [["wap7","wap7_SURFV02_Clear_laminated_cab_glass"],["lhb_cc","lhb_cc_Class_livery"],["icf_gs","icf_gs_GLASS sealed passenger glazing alpha fallback"],["station_ers","station_ers_Signs_and_diffusers"]]:
		if not Finish.fixture(item[0],item[1]).is_empty():return "Unrelated surface emits: "+item[1]
	return true

func test_four_ceiling_lights_follow_car_not_camera_and_hide_outside():
	var holder:=Node3D.new()
	Engine.get_main_loop().root.add_child(holder)
	var view=preload("res://game/ported_train_view.gd").new()
	view.train=Train.new("LIGHT",100)
	for key in ["wap7","lhb_cc"]:
		var car:=Node3D.new();holder.add_child(car)
		view.cars.append(car);view.formation.append({model=key})
	view._interior_setup(holder)
	view.set_cab_view(true)
	var ok: bool=view._interior_light.get_parent()==view.cars[0] and view._interior_fixtures.size()==4
	view.set_cab_view(false);view.passenger_coach=1;view.set_passenger_view(true)
	ok=ok and view._interior_light.get_parent()==view.cars[1]
	var local: Transform3D=view._interior_light.transform
	view.walk_car=1;view.walk_eye=Vector3(1,2.65,-8)
	view.update_interior_lighting()
	ok=ok and view._interior_light.transform==local
	view.cars[1].position=Vector3(30,2,40)
	ok=ok and view._interior_light.global_position==view.cars[1].global_position
	for light in view._interior_fixtures:
		ok=ok and not light.shadow_enabled and light.light_cull_mask==2 and light.position.y<3.598
	view.walk_car=-1;view.set_passenger_view(false)
	ok=ok and not view._interior_light.visible
	holder.free()
	return ok
