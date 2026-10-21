extends RefCounted
const Layout:=preload("res://game/dispatch_labels.gd")

func _request(id: String,head: Vector2,priority: int=0) -> Dictionary:
	return {id=id,head=head,priority=priority,dir=1,size=Vector2(112,49)}

func _clear(entries: Array,bounds: Rect2) -> bool:
	for i in entries.size():
		if not bounds.encloses(entries[i].rect):return false
		for j in i:
			if entries[i].rect.grow(3).intersects(entries[j].rect):return false
	return true

func test_crowded_boundary_tags_and_speed_lines_stay_separate():
	var requests:=[];var bounds:=Rect2(8,62,690,340)
	for i in 12:requests.append(_request("T%d"%i,Vector2(360,65)))
	var placed:=Layout.arrange(requests,bounds)
	return placed.size()==12 and _clear(placed,bounds)

func test_overflow_preserves_player_and_inspected_train():
	var requests:=[];var bounds:=Rect2(8,62,284,140)
	for i in 30:requests.append(_request("T%d"%i,Vector2(150,130)))
	requests.append(_request("YOU",Vector2(150,130),2));requests.append(_request("INSPECT",Vector2(150,130),1))
	var placed:=Layout.arrange(requests,bounds)
	return placed.size()<requests.size() and placed[0].id=="YOU" and placed[1].id=="INSPECT" and _clear(placed,bounds)

func test_label_layout_is_deterministic_without_mutating_requests():
	var requests:=[_request("B",Vector2(150,130)),_request("A",Vector2(150,130))]
	var before:=var_to_bytes(requests);var bounds:=Rect2(8,62,500,300)
	var a:=Layout.arrange(requests,bounds);requests.reverse();var b:=Layout.arrange(requests,bounds);requests.reverse()
	return var_to_bytes(a)==var_to_bytes(b) and before==var_to_bytes(requests)
