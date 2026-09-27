extends RefCounted
## Timing logic of the train sound (the audio itself is checked by ear).

const TrainAudio := preload("res://game/train_audio.gd")


func test_joint_crossings_follow_distance():
	var j: float = TrainAudio.JOINT_SPACING
	if TrainAudio._joints_crossed(0.0, j * 0.5) != 0:
		return "no joint within the first half rail"
	if TrainAudio._joints_crossed(j * 0.9, j * 1.1) != 1:
		return "one joint when passing a rail end"
	if TrainAudio._joints_crossed(-1.0, j * 3.0 + 1.0) != 4:
		return "four joints over three rails starting just before a joint"
	return TrainAudio._joints_crossed(5.0, 4.0) == 0   # never negative
