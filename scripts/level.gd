extends Node2D


const MAP_SECTION_SIZE: int = 8
const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_ISLAND: Vector2i = Vector2i(4, 5)
const TILE_COORD_ISLAND2: Vector2i = Vector2i(10, 5)

@export var map_noise: Noise

var player: Node2D
var current_section: Vector2i = Vector2i.ONE
var pending_sections: Array[Vector2i] = []
var loaded_sections: Array[Vector2i] = []
var section_offset: Vector2i = Vector2i.ZERO
var thread: Thread
var semaphore: Semaphore

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var section_end_pos: Vector2 = tile_map.map_to_local(Vector2i.ONE * MAP_SECTION_SIZE)
	
	# Place the player at the center of the map's load area
	player = get_tree().get_first_node_in_group("player")
	player.position = section_end_pos * 0.5 + section_end_pos
	
	semaphore = Semaphore.new()
	thread = Thread.new()
	var _err: Error = thread.start(_threaded_load_section, Thread.PRIORITY_NORMAL)
	
	for x in 3:
		for y in 3:
			pending_sections.append(Vector2i(x, y))
	
	semaphore.post()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var section: Vector2i = tile_map.local_to_map(player.position) / MAP_SECTION_SIZE
	
	if current_section != section:
		current_section = section
		print("curr section ", current_section)


func _threaded_load_section() -> void:
	while true:
		semaphore.wait()
		
		while pending_sections.size() > 0:
			_load_section()


func _load_section() -> void:
	var section: Vector2i = pending_sections.pop_front()
	print("loading section ", section)
	
	var grass_cells: PackedVector2Array = []
	var dirt_cells: PackedVector2Array = []
	
	var half_section: int = int(MAP_SECTION_SIZE / 2.0)
	
	# Use the noise to determine the terrain tiles
	for x in half_section:
		for y in half_section:
			var x_pos: int = x + section.x * MAP_SECTION_SIZE
			var y_pos: int = y + section.y * MAP_SECTION_SIZE
				
			var x2_pos: int = (section.x + 1) * MAP_SECTION_SIZE - x - 1
			var y2_pos: int = (section.y + 1) * MAP_SECTION_SIZE - y - 1
				
			_append_or_set_cell(x_pos, y_pos, grass_cells, dirt_cells)
			_append_or_set_cell(x2_pos, y_pos, grass_cells, dirt_cells)
			_append_or_set_cell(x_pos, y2_pos, grass_cells, dirt_cells)
			_append_or_set_cell(x2_pos, y2_pos, grass_cells, dirt_cells)
	
	# Set and connect the terrain tiles
	tile_map.call_deferred("set_cells_terrain_connect", 0, grass_cells, 0, 0)
	tile_map.call_deferred("set_cells_terrain_connect", 0, dirt_cells, 0, 2)
	
	print("loaded section ", section)
	loaded_sections.append(section)


func _append_or_set_cell(x_pos: int, y_pos: int,\
			grass_cells: PackedVector2Array, dirt_cells: PackedVector2Array) -> void:
	# Create 2x2 clusters of the same noise position sample based on the cell position
	var noise_pos: Vector2 = (Vector2(x_pos, y_pos) / 2).floor()
	var noise_strength: float = map_noise.get_noise_2d(noise_pos.x, noise_pos.y)
	
	var cell_coord: Vector2i = Vector2i(x_pos, y_pos)
	
	if noise_strength >= 0.2:
		grass_cells.append(cell_coord)
	elif noise_strength <= -0.5:
		dirt_cells.append(cell_coord)
	else:
		tile_map.call_deferred("set_cell", 0, cell_coord, 0, TILE_COORD_WATER)
