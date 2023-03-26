extends Node2D


const TILE_COORD_WATER: Vector2i = Vector2i(6, 3)
const TILE_COORD_ISLAND: Vector2i = Vector2i(4, 5)
const TILE_COORD_ISLAND2: Vector2i = Vector2i(10, 5)

@export var map_noise: Noise

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _init_map() -> void:
	var grass_cells: Array[Vector2i] = []
	var dirt_cells: Array[Vector2i] = []
	
	var noise_range: Vector2 = Vector2()
	
	for x in 64:
		for y in 64:
			var cell_coord: Vector2i = Vector2i(x, y)
			var noise_strength: float = map_noise.get_noise_2d(x, y)
			
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
	
	tile_map.set_cells_terrain_connect(0, grass_cells, 0, 0)
	tile_map.set_cells_terrain_connect(0, dirt_cells, 0, 2)
	
	_remove_island_cells(grass_cells, TILE_COORD_ISLAND)
	_remove_island_cells(dirt_cells, TILE_COORD_ISLAND2)


func _remove_island_cells(cells: Array[Vector2i], island_tile: Vector2i) -> void:
	for cell in cells:
		var tile_coord: Vector2i = tile_map.get_cell_atlas_coords(0, cell)
		
		if tile_coord == island_tile:
			tile_map.set_cell(0, cell, 0, TILE_COORD_WATER)
