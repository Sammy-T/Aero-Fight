extends CharacterBody2D


const Bullet: PackedScene = preload("res://scenes/projectiles/enemy_bullet.tscn")

@export var max_speed: float = 150
@export var max_rot_speed: float = 1
@export var acceleration: float = 0.75
@export var deceleration: float = 0.5
@export var max_health: float = 4
@export var points: int = 100

var gun: Node2D
var gun_2: Node2D
var react_timer: Timer
var fire_timer: Timer
var player: Node2D
var tile_map: TileMap
var level: Node2D

@onready var speed: float = max_speed / 2
@onready var health: float = max_health

@onready var shadow_holder: Node2D = %ShadowHolder
@onready var shadow: Sprite2D = %Shadow
@onready var particles_smoke: GPUParticles2D = %Smoke


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gun = %Gun
	gun_2 = %Gun2
	react_timer = %ReactTimer
	fire_timer = %FireTimer
	
	player = get_tree().get_first_node_in_group("player")
	tile_map = get_tree().get_first_node_in_group("map")
	level = get_tree().get_first_node_in_group("level")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(delta: float) -> void:
	# Follow the player
	var desired_dir: Vector2 = (player.position - position).rotated(PI / 2)\
			if player.health > 0 else Vector2.ZERO
	
	if desired_dir.length() > 0:
		rotation = lerp_angle(rotation, desired_dir.angle(), max_rot_speed * delta)
		
		var rot_diff: float = absf(Util.get_rot_diff(rotation, desired_dir.angle()))
		
		# Accelerate when approaching the desired rotation, otherwise decelerate.
		if rot_diff <= PI / 6:
			speed = move_toward(speed, max_speed, acceleration)
		else:
			speed = move_toward(speed, max_speed * 0.75, deceleration)
		
		var player_in_sight: bool = rot_diff <= PI / 10
		
		# Start/Stop attacking depending on whether the player is in sight
		if player_in_sight && react_timer.is_stopped() && fire_timer.is_stopped():
				var reaction_time: float = randf_range(0.18, 0.35)
				react_timer.start(reaction_time)
		elif !player_in_sight && (!react_timer.is_stopped() || !fire_timer.is_stopped()):
				react_timer.stop()
				fire_timer.stop()
	else:
		speed = move_toward(speed, max_speed * 0.5, deceleration)
	
	velocity = -transform.y * speed # Apply forward movement
	move_and_slide()
	
	shadow_holder.rotation = -rotation
	shadow.rotation = rotation


# Triggered via timer to start firing after simulating the initial delay of a reaction time
func _start_firing_with_reaction() -> void:
	if fire_timer.is_stopped():
		_fire_bullets()
		fire_timer.start()


func _fire_bullets() -> void:
	if player.health == 0:
		fire_timer.stop()
	
	var bullet: Area2D = Bullet.instantiate()
	bullet.init_bullet(gun.global_position, rotation, speed)
	
	var bullet_2: Area2D = bullet.duplicate()
	bullet_2.init_bullet(gun_2.global_position, rotation, speed)
	
	tile_map.add_child(bullet)
	tile_map.add_child(bullet_2)


func update_health(delta: float) -> void:
	if health == 0:
		return # Ignore damage received while already exploding
	
	if delta < 0:
		%AnimationPlayer.play("impact") # Play the impact animation if the enemy is taking damage
	
	health = clamp(health + delta, 0, max_health)
	
	var low_health: float = max_health * 0.5
	
	if health <= low_health && !particles_smoke.emitting:
		particles_smoke.emitting = true
	elif health > low_health && particles_smoke.emitting:
		particles_smoke.emitting = false
	
	if health == 0:
		%AnimationPlayer.play("explode")
		
		# Stop firing (check if the nodes exist first 
		# since the Supplier extends from this script)
		if react_timer:
			react_timer.stop()
		
		if fire_timer:
			fire_timer.stop()
		
		if level:
			level.update_score(points)
