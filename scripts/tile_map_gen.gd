extends TileMap


const MAP_SECTION_SIZE: int = 6
const MAP_LOAD_GRID_SIZE: Vector2i = Vector2i(9, 9)

enum Layer {ENV, SURFACE}
enum Terrain {GRASS, DIRT = 2}

const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_GRASS_BLADE: Vector2i = Vector2i(0, 3)
const TILE_COORD_TREE: Vector2i = Vector2i(0, 4)
const TILE_COORD_TREES: Vector2i = Vector2i(0, 5)
const TILE_COORD_BUILDING: Vector2i = Vector2i(0, 6)
const TILE_COORD_BUILDING_2: Vector2i = Vector2i(0, 7)

@export var map_noise: Noise

var tracking_target: Node2D
var current_section: Vector2i = Vector2i.ONE
var pending_sections: Array[Vector2i] = []
var pending_unload_sections: Array[Vector2i] = []
var loaded_sections: Array[Vector2i] = []
var surface_cells: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create the initial grid
	for x in MAP_LOAD_GRID_SIZE.x:
		for y in MAP_LOAD_GRID_SIZE.y:
			pending_sections.append(Vector2i(x, y))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var target_map_pos: Vector2i = local_to_map(tracking_target.position)\
			if tracking_target else Vector2i.ZERO
	var section: Vector2i = target_map_pos / MAP_SECTION_SIZE
	
	# Offset the loading deadzone and shifted loading area when the tracking_target transitions
	# to a negative x or y position.
	if target_map_pos.x < 0:
		section.x -= 1
	
	if target_map_pos.y < 0:
		section.y -= 1
	
	if current_section != section:
		current_section = section
		_update_queues()
	
	_load_from_map_queue()
	_update_debug_curr_section()


# A helper to get the center position of the initial grid
func get_starting_pos() -> Vector2:
	var start_pos_map: Vector2i = MAP_SECTION_SIZE * MAP_LOAD_GRID_SIZE / 2
	return map_to_local(start_pos_map)


# Updates which sections we want to load/unload
func _update_queues() -> void:
	var process_map_update: bool = false
	var wanted_sections: Array[Vector2i] = []
	
	_update_debug_loaded_sections()
	
	var offset_range: Vector2i = MAP_LOAD_GRID_SIZE / 2
	
	# Determine which sections are wanted based on the current section position
	for x_offset in range(-offset_range.x, offset_range.x + 1):
		for y_offset in range(-offset_range.y, offset_range.y + 1):
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
				
			_append_or_set_cell(section, x_pos, y_pos, grass_cells, dirt_cells)
			_append_or_set_cell(section, x2_pos, y_pos, grass_cells, dirt_cells)
			_append_or_set_cell(section, x_pos, y2_pos, grass_cells, dirt_cells)
			_append_or_set_cell(section, x2_pos, y2_pos, grass_cells, dirt_cells)
	
	# Set and connect the terrain tiles
	call_deferred("set_cells_terrain_connect", Layer.ENV, grass_cells, 0, Terrain.GRASS)
	call_deferred("set_cells_terrain_connect", Layer.ENV, dirt_cells, 0, Terrain.DIRT)
	
	loaded_sections.append(section)


func _append_or_set_cell(section: Vector2i, x_pos: int, y_pos: int,\
			grass_cells: PackedVector2Array, dirt_cells: PackedVector2Array) -> void:
	# Create 2x2 clusters of the same noise position sample based on the cell position
	var noise_pos: Vector2 = (Vector2(x_pos, y_pos) / 2).floor()
	var noise_strength: float = map_noise.get_noise_2d(noise_pos.x, noise_pos.y)
	
	var cell_coord: Vector2i = Vector2i(x_pos, y_pos)
	
	_set_surface_cell(section, cell_coord)
	
	if noise_strength >= 0.3:
		grass_cells.append(cell_coord)
	elif noise_strength <= -0.5:
		dirt_cells.append(cell_coord)
	else:
		call_deferred("set_cell", Layer.ENV, cell_coord, 0, TILE_COORD_WATER)


# Places cells on the map's 'surface' layer
func _set_surface_cell(section: Vector2i, cell_coord: Vector2i) -> void:
	# Scale the noise sample position so it matches up with the rest of the map
	var noise_pos: Vector2 = cell_coord / 2.0
	var noise_strength: float = map_noise.get_noise_2d(noise_pos.x, noise_pos.y)
	
	var surface_tile: Vector2i
	
	# Round the noise strength and determine which tile we want to place
	match snappedf(noise_strength, 0.001):
		0.46:
			surface_tile = TILE_COORD_GRASS_BLADE
		0.41, 0.42, 0.43:
			surface_tile = TILE_COORD_TREE
		0.44, 0.45, 0.55:
			surface_tile = TILE_COORD_TREES
		0.6:
			surface_tile = TILE_COORD_BUILDING
		0.7:
			surface_tile = TILE_COORD_BUILDING_2
		_:
			return
	
	call_deferred("set_cell", Layer.SURFACE, cell_coord, 0, surface_tile)
	
	# Store the surface cell's coordinates so it can be more easily deleted later
	if !surface_cells.has(section):
		surface_cells[section] = PackedVector2Array([cell_coord])
	else:
		surface_cells[section].append(cell_coord)


func _remove_section() -> void:
	var section: Vector2i = pending_unload_sections.pop_back()
	
	var half_section: int = int(MAP_SECTION_SIZE / 2.0)
	
	for x in half_section:
		for y in half_section:
			var x_pos: int = x + section.x * MAP_SECTION_SIZE
			var y_pos: int = y + section.y * MAP_SECTION_SIZE
			
			var x2_pos: int = (section.x + 1) * MAP_SECTION_SIZE - x - 1
			var y2_pos: int = (section.y + 1) * MAP_SECTION_SIZE - y - 1
			
			call_deferred("erase_cell", Layer.ENV, Vector2i(x_pos, y_pos))
			call_deferred("erase_cell", Layer.ENV, Vector2i(x2_pos, y_pos))
			call_deferred("erase_cell", Layer.ENV, Vector2i(x_pos, y2_pos))
			call_deferred("erase_cell", Layer.ENV, Vector2i(x2_pos, y2_pos))
	
	if surface_cells.has(section):
		for cell in surface_cells[section]:
			call_deferred("erase_cell", Layer.SURFACE, cell)
		
		surface_cells.erase(section)
	
	loaded_sections.erase(section)


func _update_debug_curr_section() -> void:
	if !%DebugUI.visible || !%CurrSection.visible:
		return
	
	%CurrSection.text = "Section: %s\nraw: %s" % [current_section, \
			local_to_map(tracking_target.position) if tracking_target else Vector2i.ZERO]


func _update_debug_loaded_sections() -> void:
	if !%DebugUI.visible || !%LoadedSections.visible:
		return
	
	var debug_str: String = ""
	loaded_sections.sort()
	
	for i in loaded_sections.size():
		if i % MAP_LOAD_GRID_SIZE.x == 0:
			debug_str += "\n"
		
		var s: Vector2i = loaded_sections[i]
		if s == current_section:
			debug_str += "[%s] " % s
		else:
			debug_str += "%s " % s
	
	%LoadedSections.text = debug_str
