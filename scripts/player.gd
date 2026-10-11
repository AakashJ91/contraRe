extends CharacterBody2D

const SPEED: float = 180.0
const JUMP_VELOCITY: float = -450.0
const GRAVITY: float = 950.0

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	PRONE,
	DEAD,
	RESPAWNING
}

var state: PlayerState = PlayerState.IDLE
var facing_dir: int = 1 # 1 = right, -1 = left
var aim_dir: Vector2 = Vector2.RIGHT
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0
var shoot_cooldown: float = 0.0
var somersault_angle: float = 0.0
var run_frame: float = 0.0
var muzzle_flash_timer: float = 0.0
var respawn_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 1 << 0 # Layer 1: Player
	collision_mask = (1 << 1) # Layer 2: World
	queue_redraw()

func _physics_process(delta: float) -> void:
	if state == PlayerState.DEAD:
		return
	
	if state == PlayerState.RESPAWNING:
		respawn_timer -= delta
		velocity.y = 120.0
		var collision = move_and_collide(velocity * delta)
		if is_on_floor() or respawn_timer <= 0.0 or collision != null:
			state = PlayerState.IDLE
			is_invulnerable = true
			invulnerable_timer = 2.5
		queue_redraw()
		return
	
	# Invulnerability timer
	if is_invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
	
	# Muzzle flash timer
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
	
	# Shooting cooldown
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		state = PlayerState.JUMP
		somersault_angle += 14.0 * delta * facing_dir
	else:
		somersault_angle = 0.0
	
	# Input handling
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_y: float = Input.get_axis("move_up", "move_down") # -1 is up, 1 is down
	var is_jumping: bool = Input.is_action_just_pressed("jump")
	var is_shooting: bool = Input.is_action_pressed("shoot")
	
	# Handle drop through one-way platforms (Down + Jump)
	if is_on_floor() and input_y > 0.5 and is_jumping:
		position.y += 3.0
		velocity.y = 80.0
		is_jumping = false
	elif is_on_floor() and is_jumping:
		velocity.y = JUMP_VELOCITY
		state = PlayerState.JUMP
		Global.play_sfx("jump")
	
	# Determine facing direction
	if input_x > 0.1:
		facing_dir = 1
	elif input_x < -0.1:
		facing_dir = -1
	
	# Determine aiming direction (8-directional aiming)
	_calculate_aim_direction(input_x, input_y)
	
	# Movement logic
	if is_on_floor():
		if input_y > 0.6 and abs(input_x) < 0.2:
			# Prone state: cannot run, crouching flat to ground
			state = PlayerState.PRONE
			velocity.x = 0.0
		elif abs(input_x) > 0.1:
			state = PlayerState.RUN
			velocity.x = facing_dir * SPEED
			run_frame += delta * 10.0
		else:
			state = PlayerState.IDLE
			velocity.x = 0.0
	else:
		# Air control
		if abs(input_x) > 0.1:
			velocity.x = facing_dir * SPEED * 0.95
		else:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	
	move_and_slide()
	
	# Continuous shooting for Machine Gun, single tap or cooldown for others
	if is_shooting and shoot_cooldown <= 0.0:
		_shoot()
	
	queue_redraw()

func _calculate_aim_direction(input_x: float, input_y: float) -> void:
	if not is_on_floor():
		# Air aiming: full 8 directions
		if abs(input_x) < 0.2 and input_y < -0.3:
			aim_dir = Vector2.UP
		elif abs(input_x) < 0.2 and input_y > 0.3:
			aim_dir = Vector2.DOWN
		elif abs(input_x) > 0.2 and input_y < -0.3:
			aim_dir = Vector2(facing_dir, -1).normalized()
		elif abs(input_x) > 0.2 and input_y > 0.3:
			aim_dir = Vector2(facing_dir, 1).normalized()
		else:
			aim_dir = Vector2(facing_dir, 0.0)
	else:
		# Ground aiming
		if state == PlayerState.PRONE:
			# Shooting along ground
			aim_dir = Vector2(facing_dir, 0.0)
		elif input_y < -0.5:
			if abs(input_x) > 0.2:
				aim_dir = Vector2(facing_dir, -1).normalized() # Diagonal-up
			else:
				aim_dir = Vector2.UP # Straight up
		elif input_y > 0.5:
			if abs(input_x) > 0.2:
				aim_dir = Vector2(facing_dir, 1).normalized() # Diagonal-down running
			else:
				aim_dir = Vector2(facing_dir, 0.0)
		else:
			aim_dir = Vector2(facing_dir, 0.0)

func _shoot() -> void:
	var spawn_pos: Vector2 = global_position + _get_gun_barrel_offset()
	muzzle_flash_timer = 0.06
	
	match Global.current_weapon:
		Global.WeaponType.RIFLE:
			shoot_cooldown = 0.18
			Global.play_sfx("shoot_rifle")
			_spawn_bullet(spawn_pos, aim_dir, Global.WeaponType.RIFLE, 620.0, 1.0)
			
		Global.WeaponType.SPREAD:
			shoot_cooldown = 0.26
			Global.play_sfx("shoot_spread")
			# 5-way fan spread: -24, -12, 0, 12, 24 degrees
			var angles := [-0.42, -0.21, 0.0, 0.21, 0.42]
			for a in angles:
				var dir := aim_dir.rotated(a)
				_spawn_bullet(spawn_pos, dir, Global.WeaponType.SPREAD, 560.0, 1.2)
				
		Global.WeaponType.MACHINE:
			shoot_cooldown = 0.09 # Super fast automatic fire
			Global.play_sfx("shoot_rifle")
			_spawn_bullet(spawn_pos, aim_dir, Global.WeaponType.MACHINE, 720.0, 1.1)
			
		Global.WeaponType.LASER:
			shoot_cooldown = 0.22
			Global.play_sfx("shoot_laser")
			_spawn_bullet(spawn_pos, aim_dir, Global.WeaponType.LASER, 950.0, 2.8, 3)

func _spawn_bullet(pos: Vector2, dir: Vector2, wtype: Global.WeaponType, spd: float, dmg: float, pierce: int = 1) -> void:
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.PLAYER
	b.weapon_type = wtype
	b.direction = dir
	b.speed = spd
	b.damage = dmg
	b.pierce_count = pierce
	b.global_position = pos
	get_parent().add_child(b)

func _get_gun_barrel_offset() -> Vector2:
	if state == PlayerState.PRONE:
		return Vector2(facing_dir * 18.0, 8.0)
	elif state == PlayerState.JUMP:
		return aim_dir * 12.0
	else:
		return aim_dir * 20.0 + Vector2(0.0, -8.0)

func take_damage(_amount: float = 1.0) -> void:
	if is_invulnerable or state == PlayerState.DEAD or state == PlayerState.RESPAWNING:
		return
	
	state = PlayerState.DEAD
	velocity = Vector2.ZERO
	Global.play_sfx("player_death")
	
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	
	Global.lose_life()
	if Global.lives >= 0:
		get_tree().create_timer(1.2).timeout.connect(_respawn)

func _respawn() -> void:
	state = PlayerState.RESPAWNING
	respawn_timer = 2.0
	# Respawn drop from top of screen near current X position
	global_position.y = maxf(40.0, global_position.y - 250.0)
	velocity = Vector2.ZERO
	Global.set_weapon(Global.WeaponType.RIFLE) # Reset to default rifle on death

# Custom retro commando graphics rendering
func _draw() -> void:
	if state == PlayerState.DEAD:
		return
	
	# Flicker when invulnerable
	if is_invulnerable and fmod(invulnerable_timer * 12.0, 1.0) > 0.5:
		return
	
	var col_skin := Color(0.96, 0.76, 0.60) # Commando tanned skin
	var col_pants := Color(0.15, 0.35, 0.85) # Blue combat trousers
	var col_bandana := Color(0.9, 0.15, 0.15) # Red bandana
	var col_hair := Color(0.4, 0.2, 0.1) # Brown hair
	var col_boots := Color(0.1, 0.1, 0.12) # Black boots
	var col_gun := Color(0.65, 0.65, 0.70) # Gun steel
	
	if state == PlayerState.JUMP:
		# Somersault ball: spinning commando flip
		draw_set_transform(Vector2.ZERO, somersault_angle, Vector2.ONE)
		draw_circle(Vector2.ZERO, 10.0, col_pants)
		draw_circle(Vector2(2.0, -2.0), 6.5, col_skin)
		draw_circle(Vector2(-3.0, 3.0), 4.5, col_boots)
		draw_circle(Vector2(3.0, -5.0), 4.0, col_bandana)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	if state == PlayerState.PRONE:
		# Lying flat on ground
		var dir := float(facing_dir)
		# Legs
		draw_rect(Rect2(-dir * 14.0, 2.0, 14.0, 7.0), col_pants)
		draw_rect(Rect2(-dir * 16.0, 3.0, 5.0, 6.0), col_boots)
		# Torso
		draw_rect(Rect2(-dir * 2.0, 0.0, 10.0, 8.0), col_skin)
		# Head & bandana
		draw_circle(Vector2(dir * 10.0, 2.0), 5.0, col_skin)
		draw_rect(Rect2(dir * 7.0, -2.0, 7.0, 3.0), col_bandana)
		# Gun along ground
		draw_rect(Rect2(dir * 2.0, 5.0, dir * 18.0, 3.0), col_gun)
		return
	
	# Standing / Running Commando
	var dir_f := float(facing_dir)
	var leg_offset := sin(run_frame) * 5.0 if state == PlayerState.RUN else 0.0
	
	# Boots & Legs
	draw_line(Vector2(-3.0 * dir_f, 0.0), Vector2(-5.0 * dir_f - leg_offset, 14.0), col_pants, 5.0)
	draw_line(Vector2(3.0 * dir_f, 0.0), Vector2(5.0 * dir_f + leg_offset, 14.0), col_pants, 5.0)
	draw_rect(Rect2(-7.0 * dir_f - leg_offset, 11.0, 5.0, 5.0), col_boots)
	draw_rect(Rect2(3.0 * dir_f + leg_offset, 11.0, 5.0, 5.0), col_boots)
	
	# Belt
	draw_rect(Rect2(-6.0, -2.0, 12.0, 3.0), Color(0.2, 0.2, 0.2))
	
	# Muscular Torso (shirtless iconic Contra Bill)
	draw_rect(Rect2(-6.0, -14.0, 12.0, 12.0), col_skin)
	# Combat harness strap across chest
	draw_line(Vector2(-5.0, -14.0), Vector2(4.0, -3.0), Color(0.3, 0.25, 0.2), 2.5)
	
	# Head & Hair
	draw_circle(Vector2(0.0, -19.0), 6.0, col_skin)
	draw_circle(Vector2(-dir_f * 2.0, -23.0), 4.5, col_hair)
	# Red Bandana with flapping ribbon
	draw_rect(Rect2(-6.0, -22.0, 12.0, 3.5), col_bandana)
	draw_line(Vector2(-dir_f * 6.0, -21.0), Vector2(-dir_f * 13.0, -19.0), col_bandana, 2.5)
	
	# Gun & Arms aiming along aim_dir
	var gun_start := Vector2(dir_f * 2.0, -8.0)
	var gun_end := gun_start + aim_dir * 18.0
	draw_line(gun_start, gun_end, col_gun, 4.0)
	draw_circle(gun_start, 3.5, col_skin) # Hand/Arm
	
	# Muzzle flash
	if muzzle_flash_timer > 0.0:
		var flash_pos := gun_end + aim_dir * 4.0
		draw_circle(flash_pos, 7.0, Color(1.0, 0.9, 0.2))
		draw_circle(flash_pos, 4.0, Color(1.0, 1.0, 1.0))
