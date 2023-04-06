extends Node2D


const SPEED: int = 250

var desired_rot: float = 0


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(delta: float) -> void:
	var rotation_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")\
			.rotated(PI / 2)
	
	if rotation_dir.length() > 0:
		rotation = lerp_angle(rotation, rotation_dir.angle(), delta * 5)
	
	position += -transform.y * SPEED * delta
