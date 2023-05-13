extends CharacterBody2D


#const Bullet: PackedScene = preload("res://scenes/projectiles/enemy_bullet.tscn")

const MAX_SPEED: float = 50
const MAX_ROT_SPEED: float = 1
const ACCELERATION: float = 0.5
const MIN_TARGET_DIST: int = 50
const MAX_TARGET_DIST: int = 500
const MAX_HEALTH: float = 8
const POINTS: int = 300

var speed: float = 0
var player: Node2D

@onready var body: Sprite2D = %Body
@onready var gun: Sprite2D = %Gun
@onready var projectile_spawn: Node2D = %ProjectileSpawn
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D
@onready var move_timer: Timer = %MoveTimer


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	_set_random_target()


func _physics_process(delta: float) -> void:
	var aim_angle: float = position.angle_to_point(player.position) - PI / 2
	gun.rotation = lerp_angle(gun.rotation, aim_angle, MAX_ROT_SPEED * delta)
	
	if nav_agent.is_navigation_finished():
		speed = 0
		return
	
	var direction: Vector2 = nav_agent.get_next_path_position() - position
	speed = move_toward(speed, MAX_SPEED, ACCELERATION)
	
	velocity = direction.normalized() * speed
	move_and_slide()
	
	body.rotation = direction.angle()


func set_path_target(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos


func _set_random_target() -> void:
	# Find a target position in a random direction from the current position
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) \
			* randi_range(MIN_TARGET_DIST, MAX_TARGET_DIST)
	var target_pos: Vector2 = position + offset
	
	set_path_target(target_pos)


func _on_move_timer_timeout() -> void:
	_set_random_target()


func _on_navigation_finished() -> void:
	move_timer.start()
