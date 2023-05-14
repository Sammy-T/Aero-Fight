extends Node2D


const Hangar: PackedScene = preload("res://scenes/actors/hangar.tscn")

const INITIAL_DELAY: float = 5

var player: Node2D
var radar: Control
var tile_map: TileMap
var queued: bool = false

@onready var hangar_holder: Node2D = %HangarHolder
@onready var spawn_timer: Timer = %SpawnTimer
@onready var nav_map: TileMap = %NavMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	radar = get_tree().get_first_node_in_group("radar")
	tile_map = get_tree().get_first_node_in_group("map")
	
	await get_tree().create_timer(INITIAL_DELAY).timeout
	queued = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if queued:
		_spawn_hangar()


func _spawn_hangar() -> void:
	var spawn_pos: Vector2 = _find_spawn_pos()
	
	# Determine if the task should be re-queued 
	# depending on whether a valid position is returned
	queued = spawn_pos == player.position
	
	# Return early if the task is re-queued
	if queued:
		return
	
	# Spawn the hangar
	var hangar: Node2D = Hangar.instantiate()
	hangar.position = spawn_pos
	hangar.tree_exited.connect(_on_hangar_destroyed)
	
	hangar_holder.add_child(hangar)
	
	if radar:
		radar.add_marker(hangar) # Mark the hangar on radar
	
	nav_map.set_target(hangar)


func _find_spawn_pos() -> Vector2:
	var player_map_pos: Vector2i = tile_map.local_to_map(player.position)
	var offset: int = 50
	
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x == 0 && y == 0:
				continue
			
			var offset_pos: Vector2i = player_map_pos
			offset_pos.x += x * offset
			offset_pos.y += y * offset
			
			if _can_place_hangar(offset_pos):
				return tile_map.map_to_local(offset_pos)
	
	return player.position


func _can_place_hangar(cell_coord: Vector2i) -> bool:
	var map_noise: Noise = tile_map.map_noise
	
	# Check if each neighboring cell is valid
	for x in range(-1, 2):
		for y in range(-1, 2):
			var check_cell: Vector2 = Vector2(cell_coord.x + x, cell_coord.y + y)
			var noise_pos: Vector2 = (check_cell / 2).floor()
			var noise_strength: float = map_noise.get_noise_2d(noise_pos.x, noise_pos.y)
			
			if noise_strength < 0.1:
				return false
	
	return true


func _on_spawn_timer_timeout() -> void:
	queued = true


func _on_hangar_destroyed() -> void:
	spawn_timer.start()
