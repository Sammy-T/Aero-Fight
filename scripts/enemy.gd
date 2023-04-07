extends CharacterBody2D


const Bullet: PackedScene = preload("res://scenes/projectiles/enemy_bullet.tscn")

const MAX_SPEED: float = 100
const MAX_ROT_SPEED: float = 1
const ACCELERATION: float = 2
const DECELERATION: float = 1
const MAX_HEALTH: int = 4

var speed: float = MAX_SPEED / 2
var health: int = MAX_HEALTH
var player: CharacterBody2D
var tile_map: TileMap

@onready var shadow_holder: Node2D = %ShadowHolder
@onready var shadow: Sprite2D = %Shadow
@onready var gun: Node2D = %Gun
@onready var gun_2: Node2D = %Gun2
@onready var fire_timer: Timer = %FireTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	tile_map = get_tree().get_first_node_in_group("map")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(delta: float) -> void:
	# Follow the player
	var desired_dir: Vector2 = (player.position - position).rotated(PI / 2)\
			if player.health > 0 else Vector2.ZERO
	
	if desired_dir.length() > 0:
		rotation = lerp_angle(rotation, desired_dir.angle(), MAX_ROT_SPEED * delta)
		
		# If the enemy is already rotated in the desired direction, apply acceleration.
		if _is_rot_equal_approx(rotation, desired_dir.angle()):
			speed = move_toward(speed, MAX_SPEED, ACCELERATION)
			
			# Player is in sight begin attacking
			if fire_timer.is_stopped():
				_fire_bullets()
				fire_timer.start()
		elif !fire_timer.is_stopped():
			fire_timer.stop()
	else:
		speed = move_toward(speed, MAX_SPEED / 2, DECELERATION)
	
	velocity = -transform.y * speed # Apply forward movement
	move_and_slide()
	
	shadow_holder.rotation = -rotation
	shadow.rotation = rotation


func _fire_bullets() -> void:
	if player.health == 0:
		fire_timer.stop()
	
	var bullet: Area2D = Bullet.instantiate()
	bullet.init_bullet(gun.global_position, rotation, speed)
	
	var bullet_2: Area2D = bullet.duplicate()
	bullet_2.init_bullet(gun_2.global_position, rotation, speed)
	
	tile_map.add_child(bullet)
	tile_map.add_child(bullet_2)


func update_health(delta: int) -> void:
	if health == 0:
		return # Ignore damage received while already exploding
	
	if delta < 0:
		%AnimationPlayer.play("impact") # Play the impact animation if the enemy is taking damage
	
	health = clamp(health + delta, 0, MAX_HEALTH)
	print("hit! hp: %s" % health)
	
	if health == 0:
		%AnimationPlayer.play("explode")


# A helper to determine if two rotations (in rads) are approximately equal
func _is_rot_equal_approx(rot_1: float, rot_2: float) -> bool:
	var comp_rot: float = wrapf(rot_1, -PI + 0.01, PI)
	var comp_rot_2: float = wrapf(rot_2, -PI + 0.01, PI)
	
	return absf(comp_rot - comp_rot_2) <= 0.1
