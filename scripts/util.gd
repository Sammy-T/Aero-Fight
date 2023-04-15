class_name Util
extends RefCounted


# A helper to get the difference between two rotations
static func get_rot_diff(rot_1: float, rot_2: float) -> float:
	var comp_rot: float = wrapf(rot_1, -PI + 0.01, PI)
	var comp_rot_2: float = wrapf(rot_2, -PI + 0.01, PI)
	
	return comp_rot - comp_rot_2


# A helper to determine if two rotations (in rads) are approximately equal
static func is_rot_equal_approx(rot_1: float, rot_2: float) -> bool:
	return absf(get_rot_diff(rot_1, rot_2)) <= 0.1
