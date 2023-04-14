extends "res://scripts/actors/enemy.gd"


signal supplier_destroyed(health: float, last_position: Vector2)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = randf_range(-PI, PI)
	tree_exited.connect(_on_tree_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(_delta: float) -> void:
	velocity = -transform.y * max_speed # Apply forward movement
	move_and_slide()
	
	shadow_holder.rotation = -rotation
	shadow.rotation = rotation


func _on_life_timer_timeout() -> void:
	# Flash the sprite opacity before freeing
	var tween_loops: int = 4
	var tween: Tween = create_tween().set_loops(tween_loops)
	tween.tween_property(%Sprite, "self_modulate", Color(1, 1, 1, 0.9), 1)
	tween.tween_property(%Sprite, "self_modulate", Color(1, 1, 1, 0.2), 1)
	
	await get_tree().create_timer(tween_loops * 2).timeout
	queue_free()


func _on_tree_exited() -> void:
	supplier_destroyed.emit(health, position)
