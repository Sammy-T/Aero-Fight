extends Node2D


@export var noise_texture: NoiseTexture2D

@onready var tile_map: TileMap = %TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _init_map() -> void:
	var noise: Noise = noise_texture.noise
	
	for x in 32:
		for y in 32:
			print(noise.get_noise_2d(x, y))
