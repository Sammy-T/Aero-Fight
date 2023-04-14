extends Node2D


const Supplier: PackedScene = preload("res://scenes/actors/supplier.tscn")

const SPAWN_RADIUS: float = 900

var player: Node2D
var radar: Control

@onready var supplier_holder = %SupplierHolder
@onready var spawn_timer = %SpawnTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	radar = get_tree().get_first_node_in_group("radar")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func spawn_supplier() -> void:
	# Find a random direction to spawn in
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) * SPAWN_RADIUS
	var spawn_position: Vector2 = player.position + offset
	
	# Spawn the supplier
	var supplier: CharacterBody2D = Supplier.instantiate()
	supplier.position = spawn_position
	supplier.tree_exited.connect(_on_supplier_destroyed)
	
	supplier_holder.add_child(supplier)
	
	if radar:
		radar.add_marker(supplier) # Mark the supplier on the radar


func _on_supplier_destroyed() -> void:
	var delay: float = randf_range(15, 30)
	spawn_timer.start(delay)
