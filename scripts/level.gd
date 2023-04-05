extends Node2D


const MAP_SECTION_SIZE: int = 10
const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_ISLAND: Vector2i = Vector2i(4, 5)
const TILE_COORD_ISLAND2: Vector2i = Vector2i(10, 5)

@export var map_noise: Noise

var player: Node2D
var current_section: Vector2i = Vector2i.ONE
var pending_sections: Array[Vector2i] = []
var pending_unload_sections: Array[Vector2i] = []
var loaded_sections: Array[Vector2i] = []
var section_offset: Vector2i = Vector2i.ZERO

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var section_end_pos: Vector2 = tile_map.map_to_local(Vector2i.ONE * MAP_SECTION_SIZE)
	
	# Place the player at the center of the map's load area
	player = get_tree().get_first_node_in_group("player")
	player.position = section_end_pos * 0.5 + section_end_pos
	
	# Create the initial 3x3 grid
	for x in 3:
		for y in 3:
			pending_sections.append(Vector2i(x, y))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var player_map_pos: Vector2i = tile_map.local_to_map(player.position)
	var section: Vector2i = player_map_pos / MAP_SECTION_SIZE
	
	# Offset the loading deadzone and shifted loading area when the player transitions
	# to a negative x or y position.
	if player_map_pos.x < 0:
		section.x -= 1
	
	if player_map_pos.y < 0:
		section.y -= 1
	
	if current_section != section:
		current_section = section
		print("curr section ", current_section)
		
		_update_sections()
	
	_load_from_map_queue()
	
	## TODO: TEMP
	%CurrSection.text = "Section: %s\nraw: %s" % [current_section, \
			tile_map.local_to_map(player.position)]
	##


# Updates which sections we want to load/unload
func _update_sections() -> void:
	var process_map_update: bool = false
	var wanted_sections: Array[Vector2i] = []
	
	## TODO: TEMP
	var debug_str: String = ""
	loaded_sections.sort()
	for i in loaded_sections.size():
		if i % 3 == 0:
			debug_str += "\n"
		
		var s: Vector2i = loaded_sections[i]
		if s == current_section:
			debug_str += "[%s] " % s
		else:
			debug_str += "%s " % s
	%LoadedSections.text = debug_str
	##
	
	# Determine which sections are wanted based on the current section position
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var wanted_section: Vector2i = current_section + Vector2i(x_offset, y_offset)
			wanted_sections.append(wanted_section)
			
			if !loaded_sections.has(wanted_section):
				process_map_update = true
	
	if !process_map_update:
		return
	
	pending_sections.clear()
	
	# Check which sections to add
	for wanted_section in wanted_sections:
		if !loaded_sections.has(wanted_section):
			pending_sections.append(wanted_section)
	
	# Check which sections to remove
	for loaded_section in loaded_sections:
		if !wanted_sections.has(loaded_section):
			pending_unload_sections.append(loaded_section)


func _load_from_map_queue() -> void:
	if pending_sections.size() > 0:
		_load_section()
	
	if pending_unload_sections.size() > 0:
		_remove_section()


func _load_section() -> void:
	var section: Vector2i = pending_sections.pop_back()
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


func _remove_section() -> void:
	var section: Vector2i = pending_unload_sections.pop_back()
	
	var half_section: int = int(MAP_SECTION_SIZE / 2.0)
	
	for x in half_section:
		for y in half_section:
			var x_pos: int = x + section.x * MAP_SECTION_SIZE
			var y_pos: int = y + section.y * MAP_SECTION_SIZE
			
			var x2_pos: int = (section.x + 1) * MAP_SECTION_SIZE - x - 1
			var y2_pos: int = (section.y + 1) * MAP_SECTION_SIZE - y - 1
			
			tile_map.call_deferred("erase_cell", 0, Vector2i(x_pos, y_pos))
			tile_map.call_deferred("erase_cell", 0, Vector2i(x2_pos, y_pos))
			tile_map.call_deferred("erase_cell", 0, Vector2i(x_pos, y2_pos))
			tile_map.call_deferred("erase_cell", 0, Vector2i(x2_pos, y2_pos))
	
	loaded_sections.erase(section)
