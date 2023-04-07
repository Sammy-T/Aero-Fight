extends Node2D


var player: Node2D

@onready var tile_map: TileMap = %TileMapGen
@onready var speed_display: Label = %Speed
@onready var health_display: Label = %Health


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Place the player at the center of the map's load grid
	player = get_tree().get_first_node_in_group("player")
	player.position = tile_map.get_starting_pos()
	
	tile_map.tracking_target = player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	speed_display.text = "Speed: %s" % player.speed
	health_display.text = "Health: %3d%%" % (player.health / player.MAX_HEALTH * 100)
