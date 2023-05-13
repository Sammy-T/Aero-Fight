extends CharacterBody2D


#const Bullet: PackedScene = preload("res://scenes/projectiles/enemy_bullet.tscn")

@export var max_speed: float = 50
@export var max_rot_speed: float = 1
@export var acceleration: float = 0.5
@export var max_health: float = 8
@export var points: int = 300

var speed: float = 0

@onready var body: Sprite2D = %Body
@onready var gun: Sprite2D = %Gun
@onready var projectile_spawn: Node2D = %ProjectileSpawn
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D


func _ready() -> void:
	_set_random_target()


func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		speed = 0
		return
	
	var direction: Vector2 = nav_agent.get_next_path_position() - position
	speed = move_toward(speed, max_speed, acceleration)
	
	velocity = direction.normalized() * speed
	move_and_slide()
	
	body.rotation = direction.angle()
	gun.rotation = direction.angle() - PI / 2 ## TODO: TEMP


func set_path_target(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos


func _set_random_target() -> void:
	# Find a target position in a random direction from the current position
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) * 150
	var target_pos: Vector2 = position + offset
	
	set_path_target(target_pos)


func _on_move_timer_timeout() -> void:
	_set_random_target()
