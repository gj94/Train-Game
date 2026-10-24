extends RefCounted
const Order:=preload("res://sim/dispatch_order_comparison.gd")

func test_priority_train_still_on_time_does_not_warrant_detention():
	var r:=Order.compare(1000,900,1100,30,20,90)
	return not r.worthwhile and r.saved==0 and r.follow_delay==0

func test_useful_priority_punctuality_improvement_can_outweigh_slow_delay():
	var r:=Order.compare(1200,1000,1050,250,20,90)
	return r.worthwhile and r.saved==150 and r.pass_delay==0 and r.slow_extra==250

func test_token_benefit_or_reversed_priority_cannot_justify_long_hold():
	return not Order.compare(1200,1195,1100,180,20,90).worthwhile and not Order.compare(1500,1000,1000,30,90,20).worthwhile

func test_loop_penalty_that_erases_priority_benefit_rejects_pass():
	return not Order.compare(1200,1220,1100,10,20,90).worthwhile

func test_reducing_existing_lateness_counts_even_without_full_recovery():
	var r:=Order.compare(1500,1300,1000,90,20,75)
	return r.worthwhile and r.saved==200 and r.pass_delay==300
