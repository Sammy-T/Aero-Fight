extends "res://scripts/actors/enemy.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = randf_range(-PI, PI)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(_delta: float) -> void:
	velocity = -transform.y * max_speed # Apply forward movement
	move_and_slide()
	
	shadow_holder.rotation = -rotation
	shadow.rotation = rotation


func _on_life_timer_timeout() -> void:
	queue_free()
