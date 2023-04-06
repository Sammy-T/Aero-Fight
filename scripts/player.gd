extends CharacterBody2D


const MAX_SPEED: float = 250
const MAX_ROT_SPEED: float = 5
const ACCELERATION: float = 5
const DECELERATION: float = 1

var speed: float = MAX_SPEED / 2


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(delta: float) -> void:
	var desired_rot_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")\
			.rotated(PI / 2)
	
	if desired_rot_dir.length() > 0:
		rotation = lerp_angle(rotation, desired_rot_dir.angle(), MAX_ROT_SPEED * delta)
		
		# If there's input while the player is already rotated
		# in the desired direction, apply acceleration.
		if _is_rot_equal_approx(rotation, desired_rot_dir.angle()):
			speed = move_toward(speed, MAX_SPEED, ACCELERATION)
	else:
		speed = move_toward(speed, MAX_SPEED / 2, DECELERATION)
	
	velocity = -transform.y * speed # Apply forward movement
	
	move_and_slide()


# A helper to determine if two rotations (in rads) are approximately equal
func _is_rot_equal_approx(rot_1: float, rot_2: float) -> bool:
	var comp_rot: float = wrapf(rot_1, -PI + 0.01, PI)
	var comp_rot_2: float = wrapf(rot_2, -PI + 0.01, PI)
	
	return absf(comp_rot - comp_rot_2) <= 0.1
