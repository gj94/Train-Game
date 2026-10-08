extends RefCounted
## Pure-simulation geometry for the user's imported fleet. Metres, kg, watts.
## Full-size v02 VB datums and detailed WAP-7 with the two coach families.

const CHOICES := ["lhb", "icf", "vb8", "vb16"]
const LABELS := {
	"wap7": "WAP-7 · imported light engine",
	"wag9": "WAG-9 · light engine",
	"wag12": "WAG-12B · twin section",
	"icf": "WAP-7 + ICF · blue rake",
	"lhb": "WAP-7 + LHB · red / grey rake",
	"vb8": "Vande Bharat · detailed 8 cars · 192 m",
	"vb16": "Vande Bharat · detailed 16 cars · 384 m",
}
const CLASSES := ["1a", "2a", "3a", "2s", "cc", "sl", "gs"]
const RAKE_LABELS := {"express": "22-coach express", "passenger": "20-coach seated passenger", "fixed": "Fixed Vande Bharat formation"}
# Representative fictional workings, not an exact real train's diagram.
# Utility/guard/power cars are not present in the source asset collection.
const RAKES := {
	"express": [["gs",2], ["sl",10], ["3a",6], ["2a",2], ["1a",1], ["gs",1]],
	"passenger": [["gs",5], ["2s",10], ["gs",5]],
}

static func profiles(choice: String) -> Array:
	return ["express", "passenger"] if choice in ["icf", "lhb"] else ["fixed"]

static func resolve_profile(choice: String, profile: String = "") -> String:
	return str(profiles(choice)[0]) if profile.is_empty() else profile


static func geometry(model: String) -> Dictionary:
	if model.begins_with("icf_"):
		return {pitch = 22.297, bogie = 7.3915, axle_offsets = [-1.448, 1.448], radius = .4575, front = .08, rear = .08}
	if model.begins_with("lhb_"):
		return {pitch = 24.0, bogie = 7.45, axle_offsets = [-1.28, 1.28], radius = .4575, front = .08, rear = .08}
	if model.begins_with("vb_"):
		return {pitch = 24.0, bogie = 7.45, axle_offsets = [-1.35, 1.35], radius = .476, front = 0.0, rear = 0.0}
	if model.begins_with("wag12"):
		return {pitch = 19.2, bogie = 5.1, axle_offsets = [-1.3, 1.3], radius = .625, front = .09, rear = 0.0}
	return {pitch = 20.4 if model == "wap7" else 20.562, bogie = 6.0, axle_offsets = [-1.85, 0.0, 1.85], radius = .546, front = .08 if model == "wap7" else .04, rear = .08 if model == "wap7" else .04}


static func formation(choice: String, profile: String = "") -> Array:
	assert(choice in CHOICES)
	profile = resolve_profile(choice, profile)
	assert(profile in profiles(choice), "Incompatible rake profile")
	var ids: Array = []
	var flips: Array = []
	match choice:
		"wap7", "wag9": ids = [choice]
		"wag12":
			ids = ["wag12b_a", "wag12b_b"]
			flips = [false, true]
		"icf", "lhb":
			ids = ["wap7"]
			for group in RAKES[profile]:
				for _i in int(group[1]): ids.append(choice + "_" + str(group[0]))
		"vb8":
			ids = ["vb_dtc", "vb_mc", "vb_tc_ec", "vb_mc2", "vb_mc2", "vb_tc_cc", "vb_mc", "vb_dtc"]
		"vb16":
			ids = ["vb_dtc", "vb_mc", "vb_tc_cc", "vb_mc2", "vb_mc", "vb_tc_cc", "vb_mc2", "vb_ndtc_ec", "vb_ndtc_ec2", "vb_mc2", "vb_tc_cc", "vb_mc", "vb_mc2", "vb_tc_cc", "vb_mc", "vb_dtc"]
	if flips.is_empty():
		for i in ids.size(): flips.append(choice.begins_with("vb") and i >= ids.size() / 2)
	var result := []
	var distance: float = geometry(ids[0]).front
	for i in ids.size():
		var spec := geometry(ids[i])
		result.append({model = ids[i], reverse = flips[i], center = distance + spec.pitch * .5, pitch = spec.pitch})
		distance += spec.pitch
	return result


static func length_of(choice: String, profile: String = "") -> float:
	var items := formation(choice, profile)
	var last: Dictionary = items.back()
	var spec := geometry(last.model)
	return last.center + last.pitch * .5 + (spec.front if last.reverse else spec.rear)


static func configure(train: Train, choice: String, profile: String = "") -> void:
	train.stock_kind = "ported:" + choice
	train.rake_profile = resolve_profile(choice, profile)
	train.length = length_of(choice, train.rake_profile)
	train.service_name = LABELS[choice]
	train.can_change_ends = choice not in ["icf", "lhb"]
	train.max_speed = (110.0 if choice == "icf" else (120.0 if choice in ["wag9", "wag12"] else 180.0)) / 3.6
	train.mass = 108000.0
	train.max_power = 4500000.0
	train.max_accel = 1.0
	train.service_decel = .85
	match choice:
		"wag9": train.mass = 123000.0
		"wag12":
			train.mass = 180000.0
			train.max_power = 9000000.0
		"icf", "lhb":
			var count := formation(choice, train.rake_profile).size()-1
			train.mass = 123000.0 + count * (45000.0 if choice == "icf" else 54000.0)
			# WAP-7 adhesion/tractive-effort ceiling: a longer rake must accelerate slower.
			train.max_accel = minf(.6, 322600.0/train.mass)
			train.max_speed = (110.0 if choice == "icf" else 140.0)/3.6
		"vb8", "vb16":
			var count := 8 if choice == "vb8" else 16
			train.mass = count * 48000.0
			train.max_power = count * 750000.0
			train.max_accel = .65
	train.status = "Imported fleet test drive"


static func sound_axles(choice: String, reversed: bool = false, profile: String = "") -> Array:
	var result := []
	var total := length_of(choice, profile)
	var cars := formation(choice, profile)
	for i in cars.size():
		var car: Dictionary = cars[i]
		var spec := geometry(car.model)
		for bogie in 2:
			for axle in spec.axle_offsets.size():
				var back: float = car.center + (bogie * 2 - 1) * spec.bogie + spec.axle_offsets[axle]
				var order: int = spec.axle_offsets.size() - 1 - axle if reversed else axle
				result.append({x = total - back if reversed else back, cls = bogie * 2 + order % 2, car = i})
	return result
