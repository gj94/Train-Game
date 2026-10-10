extends RefCounted
const Policy:=preload("res://game/train_visibility.gd")
const Profile:=preload("res://game/performance_profile.gd")

func test_pilot_retains_own_cab_but_skips_hidden_coaches_and_ai_interiors():
	return Policy.interior_allowed(Policy.CAB,true,0,0,0) and not Policy.interior_allowed(Policy.CAB,true,1,0,22) and not Policy.interior_allowed(Policy.CAB,false,0,-100,4)

func test_pilot_has_no_seated_crowd_even_in_adjacent_ai_coach():
	return not Policy.seated_allowed(Policy.CAB,true,1,0,20) and not Policy.seated_allowed(Policy.CAB,false,0,-100,3)

func test_passenger_and_walking_restore_current_and_gangway_neighbours():
	for mode in [Policy.PASSENGER,Policy.WALKING]:
		if not Policy.interior_allowed(mode,true,8,8,0):return "Occupied coach vanished"
		if not Policy.seated_allowed(mode,true,9,8,24):return "Adjacent coach not restored"
		if Policy.seated_allowed(mode,true,2,8,140):return "Distant hidden passengers rendered"
	return true

func test_exterior_restores_near_ai_windows_but_not_distant_furnishings():
	return Policy.interior_allowed(0,false,0,-100,15) and Policy.seated_allowed(Policy.HEAD_OUT,false,0,-100,15) and not Policy.interior_allowed(0,false,0,-100,80)

func test_camera_transition_preserves_nearby_interiors_and_reverse_cab():
	return Policy.interior_allowed(Policy.CAB,false,0,-100,12,true) and Policy.interior_allowed(Policy.CAB,true,15,15,0) and not Policy.interior_allowed(Policy.CAB,true,0,15,380)

func test_4090_laptop_cache_budget_exceeds_active_allocation_with_headroom():
	var laptop:=Profile.for_adapter("NVIDIA GeForce RTX 4090 Laptop GPU",32)
	var laptop_4080:=Profile.for_adapter("NVIDIA GeForce RTX 4080 Laptop GPU",24)
	var desktop:=Profile.for_adapter("NVIDIA GeForce RTX 4080",32)
	var integrated:=Profile.for_adapter("AMD Radeon 780M Graphics",16)
	return laptop.warm_chunks==96 and laptop.gpu_cache_ceiling==8*Profile.GIB and laptop.workers==8 and laptop_4080.gpu_cache_ceiling==6*Profile.GIB and desktop.gpu_cache_ceiling==10*Profile.GIB and integrated.gpu_cache_ceiling==2*Profile.GIB

func test_shadow_hulls_preserve_nearby_and_occupied_car_detail():
	return Policy.detailed_shadows(Policy.CAB,true,0,0,0) and not Policy.detailed_shadows(Policy.CAB,true,4,0,80) and Policy.detailed_shadows(0,false,0,-100,20) and not Policy.detailed_shadows(0,false,0,-100,200)

func test_benchmark_override_is_reversible_and_not_a_gameplay_setting():
	Policy.benchmark_full_interiors=true
	var full:=Policy.interior_allowed(Policy.CAB,false,0,-100,10) and Policy.seated_allowed(Policy.CAB,true,1,0,24) and Policy.detailed_shadows(0,false,0,-100,250)
	Policy.benchmark_full_interiors=false
	return full and not Policy.interior_allowed(Policy.CAB,false,0,-100,10) and not Policy.detailed_shadows(0,false,0,-100,250)
