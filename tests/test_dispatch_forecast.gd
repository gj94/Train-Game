extends RefCounted
const Forecast:=preload("res://sim/dispatch_forecast.gd")

func train() -> Dictionary:
	return {edge="A",direction=1,head_s=0.0,chainage=0.0,clock=0.0,speed=0.0,length=400.0,max_speed=30.0,accel=.5,power=4000000.0,mass=600000.0,decel=.8,calls=[],at_stop=false}

func network() -> Dictionary:
	return {edges={
		A={length=1000.0,limit=30.0,start=0.0,end=1000.0,next={"1":[{edge="B",dir=1}],"-1":[]}},
		B={length=1000.0,limit=30.0,start=1000.0,end=2000.0,next={"1":[{edge="C",dir=1}],"-1":[{edge="A",dir=-1}]}},
		C={length=1000.0,limit=30.0,start=2000.0,end=3000.0,next={"1":[],"-1":[{edge="B",dir=-1}]}}}}

func test_directional_path_and_unreachable_reverse():
	var f:=Forecast.new(network())
	return f.route("A",1,"C").size()==3 and f.route("C",-1,"A").size()==3 and f.route("C",1,"A").is_empty()

func test_line_limit_and_acceleration_change_arrival():
	var n:=network();var t:=train();var f:=Forecast.new(n)
	var fast:=f.arrival(t,"C",900,true)
	n.edges.B.limit=10.0
	var slow:=Forecast.new(n).arrival(t,"C",900,true)
	t.power=500000.0
	var heavy:=Forecast.new(n).arrival(t,"C",900,true)
	return fast.ok and slow.arrival>fast.arrival+25 and heavy.arrival>slow.arrival+10

func test_station_call_braking_dwell_and_booked_departure_are_counted():
	var t:=train();var f:=Forecast.new(network())
	var nonstop:=f.arrival(t,"C",900,false)
	t.calls=[{road="B",s=500.0,chainage=1500.0,dwell=120.0,departure=500.0}]
	var stopping:=f.arrival(t,"C",900,false)
	return stopping.ok and stopping.arrival>505 and stopping.arrival>nonstop.arrival+120

func test_full_train_remains_restricted_after_head_clears():
	var f:=Forecast.new(network());var t:=train()
	var sections:=[{length=50.0,limit=8.0},{length=1000.0,limit=30.0}]
	var long_train:=f.running(t,sections,8,false)
	t.length=20.0
	var short_train:=f.running(t,sections,8,false)
	return long_train.seconds>short_train.seconds+20

func test_stop_and_cautious_forecast_are_slower_than_through():
	var f:=Forecast.new(network());var t:=train();t.speed=20.0
	var through:=f.arrival(t,"C",900,false,false)
	var stopped:=f.arrival(t,"C",900,true,true)
	return stopped.arrival>through.arrival and stopped.speed==0

func test_dwell_release_and_departure_allowance():
	var f:=Forecast.new(network());var t:=train()
	var moving:=f.arrival(t,"C",900,true)
	t.at_stop=true;t.release=120.0;t.departure_allowance=5.0
	var waiting:=f.arrival(t,"C",900,true)
	return is_equal_approx(waiting.arrival-moving.arrival,125.0)

func test_short_stop_has_finite_travel_time_and_target_behind_is_rejected():
	var f:=Forecast.new(network());var t:=train()
	var short_move:=f.arrival(t,"A",10,true)
	t.head_s=900.0;t.chainage=900.0
	return short_move.ok and short_move.seconds>1 and short_move.seconds<30 and not f.arrival(t,"A",100,true).ok

func test_forecast_cannot_run_beyond_the_final_booked_call():
	var f:=Forecast.new(network());var t:=train()
	t.calls=[{road="B",s=500.0,chainage=1500.0,dwell=90.0,departure=500.0,final=true}]
	return not f.arrival(t,"C",900,false).ok and f.arrival(t,"B",500,true).ok
