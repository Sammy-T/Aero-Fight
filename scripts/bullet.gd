extends Area2D


const SPEED: float = 200
const DAMAGE: float = -1

var velocity: Vector2


func init_bullet(pos: Vector2, dir_angle: float, source_speed: float) -> void:
	position = pos
	rotation = dir_angle
	velocity = -transform.y * (SPEED + source_speed)


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta


func _on_life_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	body.update_health(DAMAGE)
	%AnimationPlayer.play("impact")


func _on_area_entered(area: Area2D) -> void:
	area.update_health(DAMAGE)
	%AnimationPlayer.play("impact")
