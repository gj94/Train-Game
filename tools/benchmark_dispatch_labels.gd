extends SceneTree
func _initialize() -> void:
	var layout:=preload("res://game/dispatch_labels.gd")
	var results:=[]
	for count in [5,30,100]:
		var requests:=[]
		for i in count:requests.append({id="T%03d"%i,head=Vector2(30+posmod(i*117,650),200+posmod(i*19,100)),priority=2 if i==0 else 0,dir=1 if i%2==0 else -1,size=Vector2(100,49)})
		var times:=[];var placed:=0
		for iteration in 30:
			var began:=Time.get_ticks_usec()
			placed=layout.arrange(requests,Rect2(8,62,690,340)).size()
			times.append((Time.get_ticks_usec()-began)/1000.0)
		times.sort();results.append({trains=count,visible_tags=placed,mean_ms=times.reduce(func(a,b):return a+b,0.0)/times.size(),p95_ms=times[28],max_ms=times[-1]})
	print(JSON.stringify(results,"  "))
	quit()
