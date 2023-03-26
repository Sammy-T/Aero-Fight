extends Node2D


const MAP_SECTION_SIZE: int = 32
const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_ISLAND: Vector2i = Vector2i(4, 5)
const TILE_COORD_ISLAND2: Vector2i = Vector2i(10, 5)

@export var map_noise: Noise

var player: Node2D
var map_section: Vector2i = Vector2i.ZERO

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map_end_pos: Vector2 = tile_map.map_to_local(Vector2i.ONE * MAP_SECTION_SIZE)
	
	# Place the player at the center of the map's load area
	player = get_tree().get_first_node_in_group("player")
	player.position = map_end_pos * 0.5
	
	_load_map()


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
		_load_map(next_section)


func _load_map(offset: Vector2i = Vector2i.ZERO) -> void:
	var grass_cells: Array[Vector2i] = []
	var dirt_cells: Array[Vector2i] = []
	
	var noise_range: Vector2 = Vector2()
	
	# Use the noise to determine the terrain tiles
	for x in MAP_SECTION_SIZE:
		for y in MAP_SECTION_SIZE:
			var x_pos: int = x + offset.x * MAP_SECTION_SIZE
			var y_pos: int = y + offset.y * MAP_SECTION_SIZE
			
			var cell_coord: Vector2i = Vector2i(x_pos, y_pos)
			var noise_strength: float = map_noise.get_noise_2d(x_pos, y_pos)
			
			if noise_strength < noise_range.x:
				noise_range.x = noise_strength
			elif noise_strength > noise_range.y:
				noise_range.y = noise_strength
			
			if noise_strength >= 0.2:
				grass_cells.append(cell_coord)
			elif noise_strength <= -0.5:
				dirt_cells.append(cell_coord)
			else:
				tile_map.set_cell(0, cell_coord, 0, TILE_COORD_WATER)
	
	# Set and connect the terrain tiles
	tile_map.set_cells_terrain_connect(0, grass_cells, 0, 0)
	tile_map.set_cells_terrain_connect(0, dirt_cells, 0, 2)
	
	# The terrain tiles I'm using don't work well with single tiles
	# so remove any islands
	_remove_island_cells(grass_cells, TILE_COORD_ISLAND)
	_remove_island_cells(dirt_cells, TILE_COORD_ISLAND2)


func _remove_island_cells(cells: Array[Vector2i], island_tile: Vector2i) -> void:
	for cell in cells:
		var tile_coord: Vector2i = tile_map.get_cell_atlas_coords(0, cell)
		
		if tile_coord == island_tile:
			tile_map.set_cell(0, cell, 0, TILE_COORD_WATER)
