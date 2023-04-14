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
	queue_free()


func _on_life_timer_timeout() -> void:
	queue_free()
