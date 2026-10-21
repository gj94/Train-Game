extends RefCounted
const Directory:=preload("res://game/coach_directory.gd")
class View extends RefCounted:
	var formation:=[{model="wap7"},{model="icf_gs"},{model="icf_2s"}]
	var specs:=[{passengers=[]},{passengers=[{},{}]},{passengers=[{},{},{}]}]
	func passenger_coaches() -> Array:return [1,2]

func test_directory_reports_actual_occupancy_and_location_without_mutation():
	var view:=View.new();var train:=Train.new("TEST",100)
	train.passengers={cars=[{seats=[]},{seats=[2,-1]},{seats=[-1,-1,2]}]}
	var before:=var_to_bytes(train.passengers)
	var rows:=Directory.entries(view,train,2,{car=1,seat=1})
	return rows.size()==2 and rows[0].label.contains("Coach 1 · ICF · General seating") and rows[0].label.contains("1 / 2 seats free") and rows[0].label.contains("Saved seat 2") and rows[1].label.contains("YOU ARE HERE") and before==var_to_bytes(train.passengers)

func test_empty_seat_prefers_current_car_then_other_car_and_refuses_full_train():
	var view:=View.new();var train:=Train.new("TEST",100)
	train.passengers={cars=[{seats=[]},{seats=[2,-1]},{seats=[-1,-1,2]}]}
	if Directory.empty_seat(view,train,2)!={car=2,seat=0}:return false
	train.passengers.cars[2].seats=[2,2,2]
	if Directory.empty_seat(view,train,2)!={car=1,seat=1}:return false
	train.passengers.cars[1].seats=[2,2]
	return Directory.empty_seat(view,train,2).is_empty()

func test_coach_numbering_matches_bookmarks_and_vande_bharat():
	return preload("res://game/passenger_bookmark.gd").label({model="icf_gs",car=1,seat=3})=="Coach 1 · seat 4" and Directory.name("vb_dtc",0)=="Car 1" and Directory.name("vb_dtc",15)=="Car 16" and Directory.description("vb_ndtc_ec2")=="Vande Bharat · Executive chair"
