extends RefCounted
## Passenger navigation reads the formation and seat occupancy without reserving
## a seat or changing the simulated passenger manifest.
const CLASSES:={"1a":"AC first class","2a":"AC two tier","3a":"AC three tier","2s":"Second seating","cc":"AC chair car","sl":"Sleeper","gs":"General seating"}

static func name(model: String,index: int) -> String:
	if model=="wap7":return "WAP-7 locomotive"
	return ("Coach %d" % index) if model.begins_with("icf_") or model.begins_with("lhb_") else "Car %d" % (index+1)

static func description(model: String) -> String:
	if model.begins_with("vb_"):return "Vande Bharat · "+("Executive chair" if "_ec" in model else "Chair car")
	var family:=model.get_slice("_",0).to_upper()
	return family+" · "+str(CLASSES.get(model.get_slice("_",1),model.to_upper()))

static func available(view,train,index: int) -> Array:
	var result:=[]
	if view.get("specs")==null or index<0 or index>=view.specs.size():return result
	var cars: Array=train.passengers.get("cars",[])
	var occupied: Array=cars[index].get("seats",[]) if index<cars.size() else []
	for seat in view.specs[index].passengers.size():
		if seat>=occupied.size() or int(occupied[seat])<0:result.append(seat)
	return result

static func entries(view,train,current_car: int=-1,bookmark: Dictionary={}) -> Array:
	var result:=[]
	for index in view.passenger_coaches():
		if view.get("formation")==null:
			result.append({index=index,label="Coach %d" % (index+1)});continue
		var model: String=view.formation[index].model
		var label:=name(model,index)+" · "+description(model)
		var total: int=view.specs[index].passengers.size()
		label+="\n%d / %d seats free" % [available(view,train,index).size(),total]
		if index==current_car:label+=" · YOU ARE HERE"
		if index==bookmark.get("car",-1):label+=" · Saved seat %d" % (int(bookmark.get("seat",0))+1)
		result.append({index=index,label=label})
	return result

static func empty_seat(view,train,preferred_car: int=-1) -> Dictionary:
	var coaches: Array=view.passenger_coaches()
	if preferred_car in coaches:coaches.erase(preferred_car);coaches.push_front(preferred_car)
	for car in coaches:
		var seats:=available(view,train,car)
		if not seats.is_empty():return {car=car,seat=seats[0]}
	return {}
