extends Node2D


@export var noise: Noise

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _init_map() -> void:
	var grass_tiles: Array[Vector2i] = []
	var dirt_tiles: Array[Vector2i] = []
	
	var noise_range: Vector2 = Vector2()
	
	for x in 64:
		for y in 32:
			var noise_strength: float = noise.get_noise_2d(x, y)
			
			if noise_strength < noise_range.x:
				noise_range.x = noise_strength
			elif noise_strength > noise_range.y:
				noise_range.y = noise_strength
			
			if noise_strength >= 0.2:
				grass_tiles.append(Vector2i(x, y))
			elif noise_strength <= -0.5:
				dirt_tiles.append(Vector2i(x, y))
			else:
				tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(6, 3))
	
	tile_map.set_cells_terrain_connect(0, grass_tiles, 0, 0)
	tile_map.set_cells_terrain_connect(0, dirt_tiles, 0, 2)
