extends Node2D


const MAP_SECTION_SIZE: int = 32
const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_ISLAND: Vector2i = Vector2i(4, 5)
const TILE_COORD_ISLAND2: Vector2i = Vector2i(10, 5)

@export var map_noise: Noise

var player: Node2D
var map_section: Vector2i = Vector2i.ZERO
var map_offset: Vector2i = Vector2i.ZERO
var thread: Thread
var semaphore: Semaphore

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map_end_pos: Vector2 = tile_map.map_to_local(Vector2i.ONE * MAP_SECTION_SIZE)
	
	# Place the player at the center of the map's load area
	player = get_tree().get_first_node_in_group("player")
	player.position = map_end_pos * 0.5
	
	semaphore = Semaphore.new()
	thread = Thread.new()
	var err: Error = thread.start(_process_load_map, Thread.PRIORITY_NORMAL)
	print(err)
	
	_threaded_load_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var section_start_pos: Vector2 = tile_map.map_to_local(map_section * MAP_SECTION_SIZE)
	var section_end_pos: Vector2 = tile_map.map_to_local(\
			(map_section + Vector2i.ONE) * MAP_SECTION_SIZE)
	
	var load_buffer: int = 50 #500
	
	# Check whether the player has entered the load buffer
	if player.position.x >= section_end_pos.x - load_buffer:
		_check_section_load(Vector2i.RIGHT)
	elif player.position.x <= section_start_pos.x + load_buffer:
		_check_section_load(Vector2i.LEFT)
	
	# Update the currently occupied map section
	if player.position.x >= section_end_pos.x:
		map_section.x += 1
		print("section %s" % map_section)
	elif player.position.x <= section_start_pos.x:
		map_section.x -= 1
		print("section %s" % map_section)


func _check_section_load(next_direction: Vector2i) -> void:
	var next_section: Vector2i = map_section + next_direction
	var next_load_end: Vector2i = next_section * MAP_SECTION_SIZE
	
	var next_load_source: int = tile_map.get_cell_source_id(0, next_load_end)
	
	# If the source of the checked tile doesn't exist load the next section
	if next_load_source == -1:
		print("load next")
		_threaded_load_map(next_section)


func _threaded_load_map(offset: Vector2i = Vector2i.ZERO) -> void:
	map_offset = offset
	semaphore.post()


func _process_load_map() -> void:
	while true:
		semaphore.wait()
		
		var grass_cells: PackedVector2Array = []
		var dirt_cells: PackedVector2Array = []
		
		var half_section: int = int(MAP_SECTION_SIZE / 2.0)
		
		# Use the noise to determine the terrain tiles
		for x in half_section:
			for y in half_section:
				var x_pos: int = x + map_offset.x * MAP_SECTION_SIZE
				var y_pos: int = y + map_offset.y * MAP_SECTION_SIZE
				
				var x2_pos: int = (map_offset.x + 1) * MAP_SECTION_SIZE - x - 1
				var y2_pos: int = (map_offset.y + 1) * MAP_SECTION_SIZE - y - 1
				
				_proc_append_or_set_cell(x_pos, y_pos, grass_cells, dirt_cells)
				_proc_append_or_set_cell(x2_pos, y_pos, grass_cells, dirt_cells)
				_proc_append_or_set_cell(x_pos, y2_pos, grass_cells, dirt_cells)
				_proc_append_or_set_cell(x2_pos, y2_pos, grass_cells, dirt_cells)
		
		# Set and connect the terrain tiles
		tile_map.call_deferred("set_cells_terrain_connect", 0, grass_cells, 0, 0)
		tile_map.call_deferred("set_cells_terrain_connect", 0, dirt_cells, 0, 2)
		
		# The terrain tiles I'm using don't work well with single tiles
		# so remove any islands
		_proc_remove_island_cells(grass_cells, TILE_COORD_ISLAND)
		_proc_remove_island_cells(dirt_cells, TILE_COORD_ISLAND2)


func _proc_append_or_set_cell(x_pos: int, y_pos: int,\
			grass_cells: PackedVector2Array, dirt_cells: PackedVector2Array) -> void:
	var cell_coord: Vector2i = Vector2i(x_pos, y_pos)
	var noise_strength: float = map_noise.get_noise_2d(x_pos, y_pos)
	
	if noise_strength >= 0.2:
		grass_cells.append(cell_coord)
	elif noise_strength <= -0.5:
		dirt_cells.append(cell_coord)
	else:
		tile_map.call_deferred("set_cell", 0, cell_coord, 0, TILE_COORD_WATER)


func _proc_remove_island_cells(cells: Array[Vector2i], island_tile: Vector2i) -> void:
	for cell in cells:
		var tile_coord: Vector2i = tile_map.get_cell_atlas_coords(0, cell)
		
		if tile_coord == island_tile:
			tile_map.call_deferred("set_cell", 0, cell, 0, TILE_COORD_WATER)
