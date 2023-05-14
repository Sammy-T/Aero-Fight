extends TileMap


const MAP_SECTION_SIZE: int = 6
const MAP_LOAD_GRID_SIZE: Vector2i = Vector2i(9, 9)

enum Layer {ENV, SURFACE}
enum Terrain {GRASS, DIRT = 2}

var current_section: Vector2i = Vector2i.ONE
var pending_sections: Array[Vector2i] = []
var loaded_sections: Array[Vector2i] = []
var level_map: TileMap
var map_noise: Noise


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_map = get_tree().get_first_node_in_group("map")
	map_noise = level_map.map_noise


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_load_from_map_queue()


func set_target(target: Node2D) -> void:
	clear()
	
	var target_map_pos: Vector2i = local_to_map(target.position)
	var section: Vector2i = target_map_pos / MAP_SECTION_SIZE
	
	# Offset the loading deadzone and shifted loading area when the tracking_target transitions
	# to a negative x or y position.
	if target_map_pos.x < 0:
		section.x -= 1
	
	if target_map_pos.y < 0:
		section.y -= 1
	
	current_section = section
	
	_update_queues()


# Updates which sections we want to load/unload
func _update_queues() -> void:
	var process_map_update: bool = false
	var wanted_sections: Array[Vector2i] = []
	
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


func _load_from_map_queue() -> void:
	if pending_sections.size() > 0:
		_load_section()


func _load_section() -> void:
	var section: Vector2i = pending_sections.pop_back()
	var half_section: int = int(MAP_SECTION_SIZE / 2.0)
	
	var grass_cells: PackedVector2Array = []
	
	# Use the noise to determine the terrain tiles
	for x in half_section:
		for y in half_section:
			var x_pos: int = x + section.x * MAP_SECTION_SIZE
			var y_pos: int = y + section.y * MAP_SECTION_SIZE
				
			var x2_pos: int = (section.x + 1) * MAP_SECTION_SIZE - x - 1
			var y2_pos: int = (section.y + 1) * MAP_SECTION_SIZE - y - 1
				
			_append_cell(x_pos, y_pos, grass_cells)
			_append_cell(x2_pos, y_pos, grass_cells)
			_append_cell(x_pos, y2_pos, grass_cells)
			_append_cell(x2_pos, y2_pos, grass_cells)
	
	# Set and connect the terrain tiles
	call_deferred("set_cells_terrain_connect", Layer.ENV, grass_cells, 0, Terrain.GRASS)
	
	loaded_sections.append(section)


func _append_cell(x_pos: int, y_pos: int, grass_cells: PackedVector2Array) -> void:
	# Create 2x2 clusters of the same noise position sample based on the cell position
	var noise_pos: Vector2 = (Vector2(x_pos, y_pos) / 2).floor()
	var noise_strength: float = map_noise.get_noise_2d(noise_pos.x, noise_pos.y)
	
	var cell_coord: Vector2i = Vector2i(x_pos, y_pos)
	
	if noise_strength >= 0.1:
		grass_cells.append(cell_coord)
