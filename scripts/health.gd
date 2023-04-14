extends Area2D


const HEALING: float = 1


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_body_entered(body: Node2D) -> void:
	body.update_health(HEALING)
	%AnimationPlayer.play("pop")


func _on_life_timer_timeout() -> void:
	# Flash the sprite opacity before freeing
	var tween_loops: int = 4
	var tween: Tween = create_tween().set_loops(tween_loops)
	tween.tween_property(%Sprite2D, "self_modulate", Color(1, 1, 1, 0.9), 1)
	tween.tween_property(%Sprite2D, "self_modulate", Color(1, 1, 1, 0.2), 1)
	
	await get_tree().create_timer(tween_loops * 2).timeout
	queue_free()
