extends CharacterBody2D


const Bullet: PackedScene = preload("res://scenes/projectiles/enemy_bullet.tscn")

const MAX_SPEED: float = 50
const MAX_ROT_SPEED: float = 5
const MAX_AIM_SPEED: float = 1
const ACCELERATION: float = 0.5
const MIN_TARGET_DIST: int = 50
const MAX_TARGET_DIST: int = 200
const MAX_HEALTH: float = 8
const POINTS: int = 300

var health: float = MAX_HEALTH
var speed: float = 0
var player: Node2D
var level: Node2D
var tile_map: TileMap
var hangar: Area2D

@onready var body: Sprite2D = %Body
@onready var gun: Sprite2D = %Gun
@onready var projectile_spawn: Node2D = %ProjectileSpawn
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D
@onready var move_timer: Timer = %MoveTimer
@onready var react_timer: Timer = %ReactTimer
@onready var fire_timer: Timer = %FireTimer


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	level = get_tree().get_first_node_in_group("level")
	tile_map = get_tree().get_first_node_in_group("map")
	
	_set_random_target()


func _physics_process(delta: float) -> void:
	if player:
		# Aim the gun towards the player
		var aim_angle: float = position.angle_to_point(player.position) - PI / 2
		gun.rotation = lerp_angle(gun.rotation, aim_angle, MAX_AIM_SPEED * delta)
		
		var rot_diff: float = absf(Util.get_rot_diff(gun.rotation, aim_angle))
		
		var player_in_sight: bool = rot_diff <= PI / 8 && \
					position.distance_to(player.position) <= 300
		
		# Start/Stop attacking depending on whether the player is in sight
		if player_in_sight && react_timer.is_stopped() && fire_timer.is_stopped():
			var reaction_time: float = randf_range(0.4, 0.75)
			react_timer.start(reaction_time)
		elif !player_in_sight && (!react_timer.is_stopped() || !fire_timer.is_stopped()):
			react_timer.stop()
			fire_timer.stop()
	
	if nav_agent.is_navigation_finished():
		speed = 0
		return
	
	# Move in the direction of the target position
	var direction: Vector2 = nav_agent.get_next_path_position() - position
	speed = move_toward(speed, MAX_SPEED, ACCELERATION)
	
	velocity = direction.normalized() * speed
	move_and_slide()
	
	# Rotate the body in the direction of movement
	body.rotation = lerp_angle(body.rotation, direction.angle(), MAX_ROT_SPEED * delta)


func set_hangar(parent_hangar: Area2D) -> void:
	hangar = parent_hangar
	hangar.tree_exited.connect(_on_hangar_destroyed)


func _set_path_target(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos


func _set_random_target() -> void:
	# Find a target position in a random direction from the current position
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2.from_angle(angle) \
			* randi_range(MIN_TARGET_DIST, MAX_TARGET_DIST)
	var target_pos: Vector2 = hangar.position + offset if is_instance_valid(hangar) \
			else position + offset
	
	_set_path_target(target_pos)


# Triggered via timer to start firing after simulating the initial delay of a reaction time
func _start_firing_with_reaction() -> void:
	if fire_timer.is_stopped():
		_fire_bullet()
		fire_timer.start()


func _fire_bullet() -> void:
	if health == 0:
		react_timer.stop()
		fire_timer.stop()
		return
	
	if player.health == 0:
		fire_timer.stop()
	
	var bullet: Area2D = Bullet.instantiate()
	
	# I don't know why I have to shift the gun rotation 180deg but I do.
	bullet.init_bullet(projectile_spawn.global_position, gun.rotation - PI, 0)
	
	tile_map.add_child(bullet)


func _on_move_timer_timeout() -> void:
	_set_random_target()


func _on_navigation_finished() -> void:
	move_timer.start()


func _on_hangar_destroyed() -> void:
	var destruct_delay: float = randf_range(5, 10)
	%DestructTimer.start(destruct_delay)


func _on_destruct_timer_timeout() -> void:
	%AnimationPlayer.play("explode")


func update_health(delta: float) -> void:
	if health == 0:
		return
	
	if delta < 0:
		%AnimationPlayer.play("impact") # Play impact animation when taking damage
	
	health = clamp(health + delta, 0, MAX_HEALTH)
	
	if health == 0:
		%AnimationPlayer.play("explode")
	
		if level:
			level.update_score(POINTS)
