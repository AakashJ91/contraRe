class_name Player
extends CharacterBody2D

const SPEED: float = 180.0
const JUMP_VELOCITY: float = -450.0
const GRAVITY: float = 950.0

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var border_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var border_width: float = 1.35

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
var idle_timer: float = 0.0

var tex_idle: Texture2D = null
var tex_aim: Texture2D = null
var tex_aim_diag_up: Texture2D = null
var tex_aim_up: Texture2D = null
var tex_fire: Texture2D = null
var tex_fire_1: Texture2D = null
var tex_fire_diag_up: Texture2D = null
var tex_fire_diag_up_1: Texture2D = null
var tex_fire_up: Texture2D = null
var tex_fire_up_1: Texture2D = null
var tex_jump: Texture2D = null
var tex_prone: Texture2D = null
var tex_aim_diag_down: Texture2D = null
var tex_fire_diag_down: Texture2D = null
var tex_run: Array[Texture2D] = []
var tex_run_fire: Array[Texture2D] = []
var tex_run_up: Array[Texture2D] = []
var tex_run_fire_up: Array[Texture2D] = []
var tex_run_down: Array[Texture2D] = []
var tex_run_fire_down: Array[Texture2D] = []
var fire_hold_timer: float = 0.0

var stage_gravity_scale: float = 1.0
var conveyor_push: float = 0.0
var is_on_ice: bool = false
var in_updraft: bool = false
var coyote_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1 << 0 # Layer 1: Player
	collision_mask = (1 << 1) # Layer 2: World
	if Global.current_stage == 7:
		stage_gravity_scale = 0.60 # Stage 7 Orbital Hangar Low Gravity
	else:
		stage_gravity_scale = 1.0
	if ResourceLoader.exists("res://assets/player/player_idle.png"):
		tex_idle = load("res://assets/player/player_idle.png")
	if ResourceLoader.exists("res://assets/player/player_aim.png"):
		tex_aim = load("res://assets/player/player_aim.png")
	if ResourceLoader.exists("res://assets/player/player_aim_diag_up.png"):
		tex_aim_diag_up = load("res://assets/player/player_aim_diag_up.png")
	if ResourceLoader.exists("res://assets/player/player_aim_up.png"):
		tex_aim_up = load("res://assets/player/player_aim_up.png")
	if ResourceLoader.exists("res://assets/player/player_fire.png"):
		tex_fire = load("res://assets/player/player_fire.png")
	if ResourceLoader.exists("res://assets/player/player_fire_1.png"):
		tex_fire_1 = load("res://assets/player/player_fire_1.png")
	if ResourceLoader.exists("res://assets/player/player_fire_diag_up.png"):
		tex_fire_diag_up = load("res://assets/player/player_fire_diag_up.png")
	if ResourceLoader.exists("res://assets/player/player_fire_diag_up_1.png"):
		tex_fire_diag_up_1 = load("res://assets/player/player_fire_diag_up_1.png")
	if ResourceLoader.exists("res://assets/player/player_fire_up.png"):
		tex_fire_up = load("res://assets/player/player_fire_up.png")
	if ResourceLoader.exists("res://assets/player/player_fire_up_1.png"):
		tex_fire_up_1 = load("res://assets/player/player_fire_up_1.png")
	if ResourceLoader.exists("res://assets/player/player_jump.png"):
		tex_jump = load("res://assets/player/player_jump.png")
	if ResourceLoader.exists("res://assets/player/player_prone.png"):
		tex_prone = load("res://assets/player/player_prone.png")
	if ResourceLoader.exists("res://assets/player/player_aim_diag_down.png"):
		tex_aim_diag_down = load("res://assets/player/player_aim_diag_down.png")
	if ResourceLoader.exists("res://assets/player/player_fire_diag_down.png"):
		tex_fire_diag_down = load("res://assets/player/player_fire_diag_down.png")
	for i in range(4):
		var p := "res://assets/player/player_run_%d.png" % i
		if ResourceLoader.exists(p):
			tex_run.append(load(p))
		var pf := "res://assets/player/player_run_fire_%d.png" % i
		if ResourceLoader.exists(pf):
			tex_run_fire.append(load(pf))
		var pu := "res://assets/player/player_run_up_%d.png" % i
		if ResourceLoader.exists(pu):
			tex_run_up.append(load(pu))
		var pfu := "res://assets/player/player_run_fire_up_%d.png" % i
		if ResourceLoader.exists(pfu):
			tex_run_fire_up.append(load(pfu))
		var pd := "res://assets/player/player_run_down_%d.png" % i
		if ResourceLoader.exists(pd):
			tex_run_down.append(load(pd))
		var pfd := "res://assets/player/player_run_fire_down_%d.png" % i
		if ResourceLoader.exists(pfd):
			tex_run_fire_down.append(load(pfd))
	Global.player_health = Global.PLAYER_MAX_HEALTH
	Global.player_health_changed.emit(Global.player_health, Global.PLAYER_MAX_HEALTH)
	
	# Apply soft shimmering white outline shader
	if ResourceLoader.exists("res://shaders/player_outline.gdshader"):
		var outline_shader = load("res://shaders/player_outline.gdshader")
		var outline_mat := ShaderMaterial.new()
		outline_mat.shader = outline_shader
		outline_mat.set_shader_parameter("outline_color", border_color)
		outline_mat.set_shader_parameter("outline_width", border_width)
		outline_mat.set_shader_parameter("shimmer_speed", 3.2)
		outline_mat.set_shader_parameter("shimmer_intensity", 0.38)
		material = outline_mat
	
	if not Global.is_maker_mode:
		state = PlayerState.RESPAWNING
		respawn_timer = 0.8
		global_position.y -= 140.0
		velocity.y = 320.0
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if state == PlayerState.DEAD:
		return
	
	if Global.is_boss_cutscene_active:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta * 5.0)
		if not is_on_floor():
			velocity.y += GRAVITY * stage_gravity_scale * delta
		else:
			state = PlayerState.IDLE
			facing_dir = 1
		move_and_slide()
		queue_redraw()
		return
	
	if state == PlayerState.RESPAWNING:
		respawn_timer -= delta
		velocity.y = 380.0
		var rx: float = Input.get_axis("move_left", "move_right")
		velocity.x = rx * SPEED * 0.8
		var collision = move_and_collide(velocity * delta)
		if is_on_floor() or respawn_timer <= 0.0 or collision != null:
			state = PlayerState.IDLE
			is_invulnerable = true
			invulnerable_timer = 2.5
			VFX.spawn_dust_puff(global_position + Vector2(0.0, 16.0), 3, Color(0.8, 0.85, 0.9, 0.6))
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
	if fire_hold_timer > 0.0:
		fire_hold_timer -= delta
	
	idle_timer += delta
	
	# Shooting cooldown
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	
	# Gravity & Stage Physics
	if not is_on_floor():
		coyote_timer = maxf(0.0, coyote_timer - delta)
		var eff_gravity: float = GRAVITY * stage_gravity_scale
		if in_updraft and velocity.y > -260.0:
			# Buoyant thermal mist updraft
			eff_gravity *= 0.35
			velocity.y = maxf(velocity.y - 420.0 * delta, -340.0)
		velocity.y += eff_gravity * delta
		state = PlayerState.JUMP
		somersault_angle += 14.0 * delta * facing_dir
	else:
		coyote_timer = 0.18
		somersault_angle = 0.0
	
	# Input handling
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_y: float = Input.get_axis("move_up", "move_down") # -1 is up, 1 is down
	var is_jumping: bool = Input.is_action_just_pressed("jump")
	var is_shooting: bool = Input.is_action_pressed("shoot")
	
	# Handle drop through one-way platforms (Down + Jump)
	var can_jump: bool = is_on_floor() or coyote_timer > 0.0
	if can_jump and input_y > 0.5 and is_jumping:
		position.y += 3.0
		velocity.y = 80.0
		is_jumping = false
		coyote_timer = 0.0
	elif can_jump and is_jumping:
		var jump_boost: float = 1.10 if stage_gravity_scale < 0.9 else 1.0
		velocity.y = JUMP_VELOCITY * jump_boost
		state = PlayerState.JUMP
		coyote_timer = 0.0
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
		var target_x: float = 0.0
		if input_y > 0.6 and abs(input_x) < 0.2:
			# Prone state: cannot run, crouching flat to ground
			state = PlayerState.PRONE
			target_x = 0.0
		elif abs(input_x) > 0.1:
			state = PlayerState.RUN
			target_x = facing_dir * SPEED
			run_frame += delta * 9.0
		else:
			state = PlayerState.IDLE
			target_x = 0.0
			run_frame = 0.0
		
		if is_on_ice:
			# Low-friction ice sliding inertia (skating momentum)
			var accel: float = 240.0 if abs(target_x) > 0.1 else 140.0
			velocity.x = move_toward(velocity.x, target_x, accel * delta)
			if abs(velocity.x) > 50.0 and randf() < 0.25:
				VFX.spawn_dust_puff(global_position + Vector2(0.0, 18.0), 2)
		else:
			velocity.x = target_x
	else:
		# Air control
		if abs(input_x) > 0.1:
			velocity.x = facing_dir * SPEED * 0.95
		else:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	
	# Apply motorized conveyor belt push
	if conveyor_push != 0.0:
		velocity.x += conveyor_push
	
	var was_in_air: bool = not is_on_floor()
	move_and_slide()
	if was_in_air and is_on_floor():
		VFX.spawn_dust_puff(global_position + Vector2(0.0, 18.0), 6)
	
	# Reset single-frame stage interaction flags
	conveyor_push = 0.0
	is_on_ice = false
	in_updraft = false
	
	# Bottomless pit hazard death
	if global_position.y > 545.0:
		if Global.is_maker_mode or Global.is_stage_intro_active():
			velocity = Vector2.ZERO
			var current_scene = get_tree().current_scene
			if current_scene != null and current_scene.has_method("get_safe_respawn_position"):
				global_position = current_scene.get_safe_respawn_position(global_position.x)
			else:
				global_position.y = 120.0
		else:
			take_damage(999.0)
			return
	
	if Global.is_stage_intro_active():
		queue_redraw()
	
	# Continuous shooting for Machine Gun, single tap or cooldown for others
	if is_shooting:
		fire_hold_timer = maxf(fire_hold_timer, 0.16)
		if shoot_cooldown <= 0.0:
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
		elif input_y > 0.4:
			if abs(input_x) > 0.2:
				aim_dir = Vector2(facing_dir, 1).normalized() # Diagonal-down running or standing
			else:
				aim_dir = Vector2(facing_dir, 0.0)
		else:
			aim_dir = Vector2(facing_dir, 0.0)

func _shoot() -> void:
	var spawn_pos: Vector2 = global_position + _get_gun_barrel_offset()
	muzzle_flash_timer = 0.10
	fire_hold_timer = 0.22
	VFX.spawn_muzzle_flash(spawn_pos, aim_dir, Global.current_weapon)
	
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
				_spawn_bullet(spawn_pos + dir * 4.0, dir, Global.WeaponType.SPREAD, 560.0, 1.2)
				
		Global.WeaponType.MACHINE:
			shoot_cooldown = 0.09 # Super fast automatic fire
			Global.play_sfx("shoot_rifle")
			_spawn_bullet(spawn_pos, aim_dir, Global.WeaponType.MACHINE, 720.0, 1.1)
			
		Global.WeaponType.LASER:
			shoot_cooldown = 0.22
			Global.play_sfx("shoot_laser")
			_spawn_bullet(spawn_pos, aim_dir, Global.WeaponType.LASER, 950.0, 2.8, 3)
			
		Global.WeaponType.FIRE:
			shoot_cooldown = 0.22
			Global.play_sfx("shoot_fire")
			_spawn_twisting_bullets(spawn_pos, aim_dir)

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

func _spawn_twisting_bullets(pos: Vector2, dir: Vector2) -> void:
	if bullet_scene == null:
		return
	# Spawn twin intertwining fireballs forming the iconic Contra double helix corkscrew
	var b1 = bullet_scene.instantiate()
	b1.bullet_owner = b1.BulletOwner.PLAYER
	b1.weapon_type = Global.WeaponType.FIRE
	b1.direction = dir
	b1.speed = 580.0
	b1.damage = 2.4
	b1.pierce_count = 2
	b1.is_twisting = true
	b1.twist_phase = 0.0
	b1.twist_amplitude = 16.0
	b1.twist_frequency = 18.0
	b1.global_position = pos
	get_parent().add_child(b1)
	
	var b2 = bullet_scene.instantiate()
	b2.bullet_owner = b2.BulletOwner.PLAYER
	b2.weapon_type = Global.WeaponType.FIRE
	b2.direction = dir
	b2.speed = 580.0
	b2.damage = 2.4
	b2.pierce_count = 2
	b2.is_twisting = true
	b2.twist_phase = PI # 180 degrees out of phase for intertwining double helix corkscrew
	b2.twist_amplitude = 16.0
	b2.twist_frequency = 18.0
	b2.global_position = pos
	get_parent().add_child(b2)

func _get_gun_barrel_offset() -> Vector2:
	if state == PlayerState.PRONE:
		return Vector2(facing_dir * 24.0, 9.0)
	elif state == PlayerState.JUMP:
		return aim_dir * 12.0
	else:
		if abs(aim_dir.x) < 0.2 and aim_dir.y < -0.3:
			# Straight vertical UP (90 deg) - directly at muzzle brake tip
			return Vector2(facing_dir * 0.2, -18.0)
		elif aim_dir.y < -0.3:
			# Diagonal UP (Upper-right / Upper-left)
			if state == PlayerState.RUN:
				return Vector2(facing_dir * 13.0, -13.8)
			return Vector2(facing_dir * 8.0, -15.0)
		elif aim_dir.y > 0.3:
			# Diagonal DOWN (Lower-right / Lower-left side gun point)
			if state == PlayerState.RUN:
				return Vector2(facing_dir * 15.0, -3.9)
			return Vector2(facing_dir * 12.5, -3.8)
		# Horizontal Forward (exact barrel tip)
		if state == PlayerState.RUN:
			return Vector2(facing_dir * 15.2, -11.5)
		return Vector2(facing_dir * 13.5, -12.0)

func take_damage(amount: float = 1.0) -> void:
	if Global.is_maker_mode or Global.is_stage_intro_active():
		return
	if is_invulnerable or state == PlayerState.DEAD or state == PlayerState.RESPAWNING:
		return
	
	# Lethal bottomless pit or instant-kill hazards (amount >= 900.0)
	if amount >= 900.0:
		Global.player_health = 0
		Global.player_health_changed.emit(0, Global.PLAYER_MAX_HEALTH)
		_die()
		return
	
	# Normal damage reduces health
	var dmg_int: int = maxi(1, int(amount))
	Global.player_health = maxi(0, Global.player_health - dmg_int)
	Global.player_health_changed.emit(Global.player_health, Global.PLAYER_MAX_HEALTH)
	
	if Global.player_health <= 0:
		_die()
	else:
		# Player survived hit: play hit SFX, sparks, screen shake and grant invulnerability window
		Global.play_sfx("hit")
		Global.shake_screen(4.5, 0.22)
		VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(1.0, 0.4, 0.3))
		is_invulnerable = true
		invulnerable_timer = 1.6
		queue_redraw()

func _die() -> void:
	state = PlayerState.DEAD
	velocity = Vector2.ZERO
	Global.play_sfx("player_death")
	
	VFX.spawn_blood_splatter(global_position, Vector2.UP, false)
	VFX.spawn_explosion(global_position, 1.2)
	
	Global.lose_life()
	if Global.lives >= 0:
		get_tree().create_timer(0.45).timeout.connect(_respawn)

func _respawn() -> void:
	state = PlayerState.RESPAWNING
	respawn_timer = 0.8
	Global.player_health = Global.PLAYER_MAX_HEALTH
	Global.player_health_changed.emit(Global.player_health, Global.PLAYER_MAX_HEALTH)
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_safe_respawn_position"):
		global_position = current_scene.get_safe_respawn_position(global_position.x)
	else:
		global_position.y = 80.0
	velocity = Vector2.ZERO
	Global.set_weapon(Global.WeaponType.RIFLE) # Reset to default rifle on death

func _draw_invincible_aura() -> void:
	var is_intro := Global.is_stage_intro_active()
	if not Global.is_maker_mode and not is_intro:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * 7.0)
	var center := Vector2.ZERO
	if state == PlayerState.PRONE:
		center = Vector2(0.0, 5.0)
	elif state != PlayerState.JUMP:
		center = Vector2(0.0, -8.0)
	
	var shield_color := Color(0.15, 0.85, 1.0, 0.45 + 0.35 * pulse) if not is_intro else Color(1.0, 0.85, 0.25, 0.40 + 0.30 * pulse)
	
	# Concentric glowing energy arcs
	draw_arc(center, 18.0 + 1.5 * pulse, 0.0, TAU, 28, shield_color, 2.0)
	draw_arc(center, 21.0 + 2.5 * pulse, 0.0, TAU, 20, Color(1.0, 0.85, 0.2, 0.35 * pulse), 1.2)
	
	# 3 orbiting energetic spark nodes
	for i in range(3):
		var angle: float = t * 4.5 + float(i) * (TAU / 3.0)
		var orb_pos := center + Vector2(cos(angle), sin(angle)) * (19.0 + 2.0 * pulse)
		draw_circle(orb_pos, 2.5, Color(1.0, 0.95, 0.45, 0.9))

# Custom retro commando graphics rendering with 16-bit arcade sprites
func _draw() -> void:
	if state == PlayerState.DEAD:
		return
	
	_draw_invincible_aura()
	
	# Flicker when invulnerable
	if is_invulnerable and fmod(invulnerable_timer * 12.0, 1.0) > 0.5:
		return
	
	# 1. JUMP STATE (Rotating Somersault Ball)
	if state == PlayerState.JUMP:
		if tex_jump != null:
			var j_size := Vector2(26.0, 26.0)
			draw_set_transform(Vector2.ZERO, somersault_angle, Vector2.ONE)
			draw_texture_rect(tex_jump, Rect2(-j_size * 0.5, j_size), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		
		# Procedural fallback
		var col_skin_fb := Color(0.96, 0.76, 0.60)
		var col_pants_fb := Color(0.15, 0.35, 0.85)
		draw_set_transform(Vector2.ZERO, somersault_angle, Vector2.ONE)
		draw_circle(Vector2.ZERO, 11.5, border_color)
		draw_circle(Vector2.ZERO, 10.0, col_pants_fb)
		draw_circle(Vector2(2.0, -2.0), 6.5, col_skin_fb)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# 2. PRONE STATE (Lying flat on ground)
	if state == PlayerState.PRONE:
		if tex_prone != null:
			var pr_w: float = 48.0
			var pr_h: float = 14.0
			var scale_x: float = 1.0 if facing_dir >= 0 else -1.0
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(tex_prone, Rect2(-pr_w * 0.5, 2.0, pr_w, pr_h), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		
		# Procedural fallback
		var dir := float(facing_dir)
		draw_rect(Rect2(-dir * 15.0, 1.0, 16.0, 9.0), border_color)
		draw_rect(Rect2(-dir * 14.0, 2.0, 14.0, 7.0), Color(0.15, 0.35, 0.85))
		draw_rect(Rect2(-dir * 2.0, 0.0, 10.0, 8.0), Color(0.96, 0.76, 0.60))
		draw_circle(Vector2(dir * 10.0, 2.0), 5.0, Color(0.96, 0.76, 0.60))
		draw_rect(Rect2(dir * 2.0, 5.0, dir * 18.0, 3.0), Color(0.65, 0.65, 0.70))
		return
	
	# Standardized canvas dimensions (240x230, anchor x=100, feet y=220)
	var std_w: float = 36.0
	var std_h: float = 34.5
	var std_rect := Rect2(-15.0, -19.5, std_w, std_h)
	
	# 3. RUNNING / WALKING STATE
	if state == PlayerState.RUN:
		if tex_run.size() > 0:
			var scale_x: float = 1.0 if facing_dir >= 0 else -1.0
			var idx: int = int(fmod(run_frame, float(tex_run.size())))
			var is_diag_up: bool = (aim_dir.y < -0.3)
			var is_diag_down: bool = (aim_dir.y > 0.3)
			var is_firing: bool = (muzzle_flash_timer > 0.0 or fire_hold_timer > 0.0 or Input.is_action_pressed("shoot"))
			var cur_tex: Texture2D = null
			
			if is_diag_up:
				if is_firing and tex_run_fire_up.size() > idx and tex_run_fire_up[idx] != null:
					cur_tex = tex_run_fire_up[idx]
				elif tex_run_up.size() > idx and tex_run_up[idx] != null:
					cur_tex = tex_run_up[idx]
				elif tex_run_fire_up.size() > idx:
					cur_tex = tex_run_fire_up[idx]
			elif is_diag_down:
				# Lower-Right / Lower-Left diagonal-down side gun point!
				if is_firing and tex_run_fire_down.size() > idx and tex_run_fire_down[idx] != null:
					cur_tex = tex_run_fire_down[idx]
				elif tex_run_down.size() > idx and tex_run_down[idx] != null:
					cur_tex = tex_run_down[idx]
				elif tex_run_fire_down.size() > idx:
					cur_tex = tex_run_fire_down[idx]
			else:
				# Horizontal run - gun position is identical and seamless between walking and firing!
				if is_firing and tex_run_fire.size() > idx and tex_run_fire[idx] != null:
					cur_tex = tex_run_fire[idx]
				elif tex_run.size() > idx and tex_run[idx] != null:
					cur_tex = tex_run[idx]
			
			if cur_tex == null and tex_run.size() > idx:
				cur_tex = tex_run[idx]
			
			# Subtle 1px vertical stride bobbing on passing frames
			var bob_y: float = -1.0 if (idx == 1 or idx == 3) else 0.0
			draw_set_transform(Vector2(0.0, bob_y), 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(cur_tex, std_rect, false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	
	# 4. IDLE / AIMING / FIRING STATE
	var cur_tex: Texture2D = tex_idle
	var breath: float = sin(idle_timer * 2.5) * 0.5
	var is_straight_up: bool = (abs(aim_dir.x) < 0.2 and aim_dir.y < -0.3)
	var is_diag_up: bool = (aim_dir.y < -0.3 and not is_straight_up)
	var is_diag_down: bool = (aim_dir.y > 0.3)
	var is_firing: bool = (muzzle_flash_timer > 0.0 or fire_hold_timer > 0.0 or Input.is_action_pressed("shoot"))
	
	if is_straight_up:
		if is_firing:
			if muzzle_flash_timer > 0.05 and tex_fire_up != null:
				cur_tex = tex_fire_up
			elif tex_fire_up_1 != null:
				cur_tex = tex_fire_up_1
			elif tex_fire_up != null:
				cur_tex = tex_fire_up
			elif tex_aim_up != null:
				cur_tex = tex_aim_up
		elif tex_aim_up != null:
			cur_tex = tex_aim_up
	elif is_diag_up:
		if is_firing:
			if muzzle_flash_timer > 0.05 and tex_fire_diag_up != null:
				cur_tex = tex_fire_diag_up
			elif tex_fire_diag_up_1 != null:
				cur_tex = tex_fire_diag_up_1
			elif tex_fire_diag_up != null:
				cur_tex = tex_fire_diag_up
			elif tex_aim_diag_up != null:
				cur_tex = tex_aim_diag_up
		elif tex_aim_diag_up != null:
			cur_tex = tex_aim_diag_up
	elif is_diag_down:
		# Standing lower-right / lower-left side gun point!
		if is_firing and tex_fire_diag_down != null:
			cur_tex = tex_fire_diag_down
		elif tex_aim_diag_down != null:
			cur_tex = tex_aim_diag_down
		elif tex_aim != null:
			cur_tex = tex_aim
		else:
			cur_tex = tex_idle
	else:
		# Horizontal
		if is_firing:
			if muzzle_flash_timer > 0.05 and tex_fire != null:
				cur_tex = tex_fire
			elif tex_fire_1 != null:
				cur_tex = tex_fire_1
			elif tex_fire != null:
				cur_tex = tex_fire
			elif tex_aim != null:
				cur_tex = tex_aim
		elif abs(aim_dir.x) > 0.1 and tex_aim != null:
			cur_tex = tex_aim
		else:
			cur_tex = tex_idle
	
	if cur_tex != null:
		var scale_x: float = 1.0 if facing_dir >= 0 else -1.0
		draw_set_transform(Vector2(0.0, breath), 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Procedural fallback for Standing / Running
	var col_skin := Color(0.96, 0.76, 0.60)
	var col_pants := Color(0.15, 0.35, 0.85)
	var col_bandana := Color(0.9, 0.15, 0.15)
	var col_boots := Color(0.1, 0.1, 0.12)
	var col_gun := Color(0.65, 0.65, 0.70)
	var dir_f := float(facing_dir)
	var leg_offset := sin(run_frame) * 5.0 if state == PlayerState.RUN else 0.0
	
	draw_line(Vector2(-3.0 * dir_f, 0.0), Vector2(-5.0 * dir_f - leg_offset, 14.0), col_pants, 5.0)
	draw_line(Vector2(3.0 * dir_f, 0.0), Vector2(5.0 * dir_f + leg_offset, 14.0), col_pants, 5.0)
	draw_rect(Rect2(-7.0 * dir_f - leg_offset, 11.0, 5.0, 5.0), col_boots)
	draw_rect(Rect2(3.0 * dir_f + leg_offset, 11.0, 5.0, 5.0), col_boots)
	draw_rect(Rect2(-6.0, -14.0, 12.0, 12.0), col_skin)
	draw_circle(Vector2(0.0, -19.0), 6.0, col_skin)
	draw_rect(Rect2(-6.0, -22.0, 12.0, 3.5), col_bandana)
	
	var gun_start := Vector2(dir_f * 2.0, -8.0)
	var gun_end := gun_start + aim_dir * 18.0
	draw_line(gun_start, gun_end, col_gun, 4.0)
	
	if muzzle_flash_timer > 0.0:
		var flash_pos := gun_end + aim_dir * 4.0
		draw_circle(flash_pos, 7.0, Color(1.0, 0.9, 0.2))
		draw_circle(flash_pos, 4.0, Color(1.0, 1.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_boss_cutscene_active and event.is_pressed():
		Global.skip_boss_cutscene()
