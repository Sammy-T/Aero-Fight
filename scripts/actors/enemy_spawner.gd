extends Node2D


const Enemy: PackedScene = preload("res://scenes/actors/enemy.tscn")

const SPAWN_RADIUS: float = 450

var spawn_limit: int
var spawned: int
var player: Node2D

@onready var enemy_holder = %EnemyHolder
@onready var spawn_timer = %SpawnTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func start_spawner(limit: int) -> void:
	spawn_limit = limit
	spawned = 0
	spawn_timer.start()


func _spawn_enemy() -> void:
	# Find a random direction to spawn in
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) * SPAWN_RADIUS
	var spawn_position: Vector2 = player.position + offset
	
	# Spawn the enemy
	var enemy: CharacterBody2D = Enemy.instantiate()
	enemy.position = spawn_position
	enemy_holder.add_child(enemy)
	
	spawned += 1 # Increment the spawn count
	
	# Stop spawning when the limit is reached
	if spawned == spawn_limit:
		print("Spawn limit reached (%s/%s)" % [spawned, spawn_limit])
		spawn_timer.stop()
