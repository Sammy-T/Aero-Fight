extends Node2D


var wave: int = 1
var player: Node2D

@onready var tile_map: TileMap = %TileMapGen
@onready var enemy_spawner: Node2D = %EnemySpawner
@onready var speed_display: Label = %Speed
@onready var health_display: Label = %Health
@onready var wave_display: Label = %Wave


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Place the player at the center of the map's load grid
	player = get_tree().get_first_node_in_group("player")
	player.position = tile_map.get_starting_pos()
	
	tile_map.tracking_target = player
	
	enemy_spawner.enemies_cleared.connect(_on_enemies_cleared)
	
	start_wave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	speed_display.text = "Speed: %s" % player.speed
	health_display.text = "Health: %3d%%" % (player.health / player.MAX_HEALTH * 100)


func start_wave() -> void:
	var difficulty: int = wave
	var spawn_limit: int = wave + 1
	var spawn_interval: float = maxf(5, 25 - wave * 2)
	print("Wave %s Difficulty %s Limit %s Interval %s" %\
			[wave, difficulty, spawn_limit, spawn_interval])
	
	enemy_spawner.start_spawner(difficulty, spawn_limit, spawn_interval)
	
	wave_display.text = "Wave %s" % wave


func _on_enemies_cleared() -> void:
	wave += 1
	start_wave()
