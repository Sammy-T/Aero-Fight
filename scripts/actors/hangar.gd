extends Area2D


var max_health: float = 20
var health: float = max_health
var points: int = 1000
var level: Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level = get_tree().get_first_node_in_group("level")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func update_health(delta: float) -> void:
	if health == 0:
		return
	
	if delta < 0:
		%AnimationPlayer.play("impact")
	
	health = clamp(health + delta, 0, max_health)
	print("hangar hit %s/%s" % [health, max_health])
	
	if health == 0:
		%AnimationPlayer.play("explode")
		
		if level:
			level.update_score(points)
