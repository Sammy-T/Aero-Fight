extends CharacterBody2D


const Bullet: PackedScene = preload("res://scenes/projectiles/bullet.tscn")

const MAX_SPEED: float = 175
const MAX_ROT_SPEED: float = 5
const ACCELERATION: float = 4
const DECELERATION: float = 1
const MAX_HEALTH: float = 6

var speed: float = MAX_SPEED / 2
var health: float = MAX_HEALTH
var tile_map: TileMap

@onready var shadow_holder: Node2D = %ShadowHolder
@onready var shadow: Sprite2D = %Shadow
@onready var gun: Node2D = %Gun
@onready var gun_2: Node2D = %Gun2
@onready var fire_timer: Timer = %FireTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tile_map = get_tree().get_first_node_in_group("map")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _physics_process(delta: float) -> void:
	var desired_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")\
			.rotated(PI / 2)
	
	if desired_dir.length() > 0:
		rotation = lerp_angle(rotation, desired_dir.angle(), MAX_ROT_SPEED * delta)
		
		# If there's input while the player is already rotated
		# in the desired direction, apply acceleration.
		if _is_rot_equal_approx(rotation, desired_dir.angle()):
			speed = move_toward(speed, MAX_SPEED, ACCELERATION)
	else:
		speed = move_toward(speed, MAX_SPEED / 2, DECELERATION)
	
	velocity = -transform.y * speed # Apply forward movement
	move_and_slide()
	
	shadow_holder.rotation = -rotation
	shadow.rotation = rotation


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		_fire_bullets()
		fire_timer.start()
	elif event.is_action_released("fire"):
		fire_timer.stop()


func _fire_bullets() -> void:
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
	
	health = clamp(health + delta, 0, MAX_HEALTH)
	print("player hit! hp: %s" % health)
	
	if health == 0:
		%AnimationPlayer.play("explode")
		
		# Delay setting the speed to zero so it isn't altered again 
		# before the animation stops physics process
		await get_tree().create_timer(0.25).timeout
		speed = 0


# A helper to determine if two rotations (in rads) are approximately equal
func _is_rot_equal_approx(rot_1: float, rot_2: float) -> bool:
	var comp_rot: float = wrapf(rot_1, -PI + 0.01, PI)
	var comp_rot_2: float = wrapf(rot_2, -PI + 0.01, PI)
	
	return absf(comp_rot - comp_rot_2) <= 0.1
