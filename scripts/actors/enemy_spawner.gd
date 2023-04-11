extends Node2D


signal enemies_cleared

const Enemy: PackedScene = preload("res://scenes/actors/enemy.tscn")

const SPAWN_RADIUS: float = 450
const INITIAL_DELAY: float = 1

var spawn_limit: int
var spawned: int
var player: Node2D
var radar: Control

@onready var enemy_holder = %EnemyHolder
@onready var spawn_timer = %SpawnTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	radar = get_tree().get_first_node_in_group("radar")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func start_spawner(limit: int) -> void:
	spawn_limit = limit
	spawned = 0
	
	# Wait the initial delay before spawning the first enemy
	# and starting the spawn timer
	await get_tree().create_timer(INITIAL_DELAY).timeout
	
	_spawn_enemy()
	spawn_timer.start()


func _spawn_enemy() -> void:
	# Find a random direction to spawn in
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) * SPAWN_RADIUS
	var spawn_position: Vector2 = player.position + offset
	
	# Spawn the enemy
	var enemy: CharacterBody2D = Enemy.instantiate()
	enemy.position = spawn_position
	enemy.tree_exited.connect(_on_enemy_destroyed)
	
	enemy_holder.add_child(enemy)
	
	if radar:
		radar.add_marker(enemy)
	
	spawned += 1 # Increment the spawn count
	
	# Stop spawning when the limit is reached
	if spawned == spawn_limit:
		print("Spawn limit reached (%s/%s)" % [spawned, spawn_limit])
		spawn_timer.stop()


func _on_enemy_destroyed() -> void:
	if spawned == spawn_limit && enemy_holder.get_child_count() == 0:
		print("enemies cleared")
		enemies_cleared.emit()
