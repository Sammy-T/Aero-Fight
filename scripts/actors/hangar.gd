extends Area2D


const Tank: PackedScene = preload("res://scenes/actors/tank.tscn")
const PointDisplay: PackedScene = preload("res://scenes/gui/points.tscn")

var max_health: float = 20
var health: float = max_health
var points: int = 1000
var level: Node2D
var tile_map: TileMap
var spawn_limit: int = 2
var spawned: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level = get_tree().get_first_node_in_group("level")
	tile_map = get_tree().get_first_node_in_group("map")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _spawn_tank() -> void:
	if spawned == spawn_limit:
		return
	
	var tank: CharacterBody2D = Tank.instantiate()
	tank.position = position
	tank.set_hangar(self)
	tank.tree_exited.connect(_on_tank_destroyed)
	
	tile_map.add_child(tank)
	
	spawned += 1


func _on_tank_destroyed() -> void:
	spawned -= 1


func update_health(delta: float) -> void:
	if health == 0:
		return
	
	if delta < 0:
		%AnimationPlayer.play("impact")
	
	health = clamp(health + delta, 0, max_health)
	
	if health == 0:
		%AnimationPlayer.play("explode")
		
		if level:
			level.update_score(points)
		
		if tile_map:
			var point_display: Control = PointDisplay.instantiate()
			point_display.position = position
			point_display.set_points(points)
			
			tile_map.add_child(point_display)
