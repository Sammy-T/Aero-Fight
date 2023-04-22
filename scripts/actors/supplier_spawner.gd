extends Node2D


const Supplier: PackedScene = preload("res://scenes/actors/supplier.tscn")
const Health: PackedScene = preload("res://scenes/health.tscn")

const SPAWN_DELAY_MIN: float = 20
const SPAWN_DELAY_MAX: float = 45
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
	supplier.supplier_destroyed.connect(_on_supplier_destroyed)
	
	supplier_holder.add_child(supplier)
	
	if radar:
		radar.add_marker(supplier) # Mark the supplier on the radar


func _on_supplier_destroyed(health: float, last_pos: Vector2) -> void:
	if is_instance_valid(spawn_timer): # Reloading the level errors here without checking
		var delay: float = randf_range(SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)
		spawn_timer.start(delay)
	
	# If it was destroyed by the player, spawn a health pickup
	if health == 0:
		var health_pickup: Area2D = Health.instantiate()
		health_pickup.position = last_pos
		
		supplier_holder.add_child(health_pickup)
		
		if radar:
			radar.add_marker(health_pickup)
