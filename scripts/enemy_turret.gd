extends Area2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/turret_data.tres")

enum TurretState {
	DORMANT,   # Closed inside armored bunker hatch
	OPENING,   # Hatch doors sliding open, turret elevating
	ACTIVE,    # Fully deployed, tracking and firing
	CLOSING    # Retracting back into bunker
}

var state: TurretState = TurretState.DORMANT
var deploy_progress: float = 0.0 # 0.0 = completely closed, 1.0 = fully raised
var anim_timer: float = 0.0

var health: float = 4.0
var aim_angle: float = -PI * 0.75
var shoot_timer: float = 2.0
var burst_count: int = 0
var burst_timer: float = 0.0
var flash_timer: float = 0.0

var turret_texture: Texture2D = null
var turret_base_texture: Texture2D = null
var turret_arm_texture: Texture2D = null
var deploy_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []

var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

# Refined Firing Arm and Barrel Recoil Mechanics
var left_barrel_recoil: float = 0.0
var right_barrel_recoil: float = 0.0
var chassis_recoil: float = 0.0
var next_barrel_left: bool = true
var muzzle_flash_timer: float = 0.0
var muzzle_flash_pos: Vector2 = Vector2.ZERO
var muzzle_flash_angle: float = 0.0

# Particles: Brass Casings, Propellant Smoke, Damage Smoke
var casing_particles: Array[Dictionary] = []
var muzzle_smoke_particles: Array[Dictionary] = []
var smoke_particles: Array[Dictionary] = []
var spark_timer: float = 0.0

const ACTIVATION_DIST: float = 520.0
const DEACTIVATE_DIST: float = 680.0

static var s_deploy_textures: Array[Texture2D] = []
static var s_death_textures: Array[Texture2D] = []
static var s_turret_base_texture: Texture2D = null
static var s_turret_arm_texture: Texture2D = null
static var s_turret_texture: Texture2D = null
static var s_assets_loaded: bool = false

static func _ensure_assets_loaded() -> void:
	if s_assets_loaded:
		return
	s_assets_loaded = true
	s_deploy_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/turret/movement/deploy_%d.png" % i
		if ResourceLoader.exists(p):
			s_deploy_textures.append(load(p))
	
	s_death_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/turret/death/destroy_%d.png" % i
		if ResourceLoader.exists(p):
			s_death_textures.append(load(p))
	
	if ResourceLoader.exists("res://assets/enemies/turret/turret_base.png"):
		s_turret_base_texture = load("res://assets/enemies/turret/turret_base.png")
	
	if ResourceLoader.exists("res://assets/enemies/turret/turret_arm.png"):
		s_turret_arm_texture = load("res://assets/enemies/turret/turret_arm.png")
	
	if ResourceLoader.exists("res://assets/enemies/turret/turret.png"):
		s_turret_texture = load("res://assets/enemies/turret/turret.png")
	elif ResourceLoader.exists("res://assets/enemies/enemy_turret.png"):
		s_turret_texture = load("res://assets/enemies/enemy_turret.png")

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	
	_ensure_assets_loaded()
	deploy_textures = s_deploy_textures
	death_textures = s_death_textures
	turret_base_texture = s_turret_base_texture
	turret_arm_texture = s_turret_arm_texture
	turret_texture = s_turret_texture
	
	if enemy_data != null:
		health = enemy_data.max_health
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 6.5), 0, 3)
		if death_timer >= 0.65:
			queue_free()
		queue_redraw()
		return
	
	if flash_timer > 0.0:
		flash_timer -= delta
	
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
	
	# Smoothly recover barrel recoils and chassis shudder
	left_barrel_recoil = maxf(0.0, left_barrel_recoil - 36.0 * delta)
	right_barrel_recoil = maxf(0.0, right_barrel_recoil - 36.0 * delta)
	chassis_recoil = maxf(0.0, chassis_recoil - 18.0 * delta)
	
	# Update active particles
	_update_casings(delta)
	_update_muzzle_smoke(delta)
	_update_smoke(delta)
	
	# Player tracking and deployment state machine
	var player = get_tree().get_first_node_in_group("player")
	var dist_to_player := 9999.0
	var dome_center := Vector2(0.0, -10.0 * deploy_progress)
	if player != null and is_instance_valid(player):
		dist_to_player = (global_position + dome_center).distance_to(player.global_position)
	
	match state:
		TurretState.DORMANT:
			deploy_progress = 0.0
			if dist_to_player < ACTIVATION_DIST:
				state = TurretState.OPENING
		
		TurretState.OPENING:
			deploy_progress = minf(1.0, deploy_progress + 2.4 * delta)
			if deploy_progress >= 1.0:
				state = TurretState.ACTIVE
		
		TurretState.ACTIVE:
			deploy_progress = 1.0
			if dist_to_player > DEACTIVATE_DIST:
				state = TurretState.CLOSING
			elif player != null and is_instance_valid(player):
				var target_vec: Vector2 = player.global_position - (global_position + dome_center)
				var raw_angle: float = target_vec.angle()
				
				# Refined elevation clamping: Ground bunker traverses upper hemisphere
				# Prevents firing arm from aiming down through the ground
				var clamped_angle: float = raw_angle
				if clamped_angle > 0.0:
					# Below horizon: snap to horizontal left or horizontal right
					clamped_angle = -PI if target_vec.x < 0.0 else 0.0
				else:
					clamped_angle = clampf(clamped_angle, -PI * 0.96, -PI * 0.04)
				
				# Smooth hydraulic angular rotation with acceleration / damping
				aim_angle = rotate_toward(aim_angle, clamped_angle, 3.2 * delta)
				
				# Burst fire handling with refined pacing and visual lock-on
				if burst_count > 0:
					burst_timer -= delta
					if burst_timer <= 0.0:
						burst_timer = 0.16
						burst_count -= 1
						_fire_bullet()
				else:
					shoot_timer -= delta
					if shoot_timer <= 0.0 and dist_to_player < ACTIVATION_DIST:
						shoot_timer = 2.4
						burst_count = 3
						burst_timer = 0.05
		
		TurretState.CLOSING:
			deploy_progress = maxf(0.0, deploy_progress - 2.0 * delta)
			if deploy_progress <= 0.0:
				state = TurretState.DORMANT
	
	# Spawn damage smoke when below half health
	if health <= 2.0 and state != TurretState.DORMANT:
		spark_timer += delta
		if spark_timer >= 0.12:
			spark_timer = 0.0
			_spawn_smoke_puff()
	
	queue_redraw()

func _update_casings(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for c in casing_particles:
		c["pos"] += c["vel"] * delta
		c["vel"].y += 420.0 * delta # Gravity
		c["rot"] += c["rot_spd"] * delta
		c["life"] -= delta
		if c["life"] > 0.0:
			remaining.append(c)
	casing_particles = remaining

func _update_muzzle_smoke(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for p in muzzle_smoke_particles:
		p["pos"] += p["vel"] * delta
		p["radius"] += 5.0 * delta
		p["life"] -= delta
		if p["life"] > 0.0:
			remaining.append(p)
	muzzle_smoke_particles = remaining

func _update_smoke(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for p in smoke_particles:
		p["pos"] += p["vel"] * delta
		p["radius"] += 6.0 * delta
		p["life"] -= delta
		if p["life"] > 0.0:
			remaining.append(p)
	smoke_particles = remaining

func _spawn_casing(pos: Vector2, forward: Vector2, perp: Vector2) -> void:
	var eject_dir := -perp if next_barrel_left else perp
	var vel := eject_dir * randf_range(45.0, 80.0) + Vector2(0.0, -randf_range(75.0, 130.0)) - forward * 22.0
	casing_particles.append({
		"pos": pos,
		"vel": vel,
		"rot": randf_range(0.0, TAU),
		"rot_spd": randf_range(-18.0, 18.0),
		"life": 0.45
	})

func _spawn_muzzle_smoke(pos: Vector2, dir: Vector2) -> void:
	muzzle_smoke_particles.append({
		"pos": pos,
		"vel": dir * randf_range(12.0, 24.0) + Vector2(randf_range(-6.0, 6.0), -randf_range(10.0, 20.0)),
		"radius": randf_range(2.0, 3.5),
		"life": randf_range(0.25, 0.45),
		"max_life": 0.45
	})

func _spawn_smoke_puff() -> void:
	smoke_particles.append({
		"pos": Vector2(randf_range(-10.0, 10.0), randf_range(-14.0, -4.0)),
		"vel": Vector2(randf_range(-15.0, 15.0), randf_range(-30.0, -15.0)),
		"radius": randf_range(3.0, 5.0),
		"life": randf_range(0.35, 0.65),
		"max_life": 0.65
	})

func _fire_bullet() -> void:
	if bullet_scene == null:
		return
	
	var base_w: float = 54.0
	var base_h: float = 44.0
	var socket_pos := Vector2(0.0, -base_h * 0.85 + base_h * 0.3435)
	var barrel_dir := Vector2(cos(aim_angle), sin(aim_angle))
	var perp := Vector2(-barrel_dir.y, barrel_dir.x) * 4.2
	
	# Recoil kickback on active barrel
	var active_perp := perp if next_barrel_left else -perp
	if next_barrel_left:
		left_barrel_recoil = 7.5
	else:
		right_barrel_recoil = 7.5
	
	chassis_recoil = 2.0
	
	# Exact muzzle position calculated at tip of the firing barrel
	var arm_w: float = 42.0
	var active_recoil := left_barrel_recoil if next_barrel_left else right_barrel_recoil
	var muzzle_pos := socket_pos + active_perp + barrel_dir * (arm_w * 0.92 - active_recoil)
	
	muzzle_flash_pos = muzzle_pos
	muzzle_flash_angle = aim_angle
	muzzle_flash_timer = 0.09
	
	# Eject spent brass casing & spawn muzzle smoke wisp
	_spawn_casing(socket_pos + active_perp * 0.5 + barrel_dir * 14.0, barrel_dir, perp)
	_spawn_muzzle_smoke(muzzle_pos, barrel_dir)
	
	next_barrel_left = not next_barrel_left
	Global.play_sfx("hit")
	Global.shake_screen(2.2, 0.08)
	
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = barrel_dir
	b.global_position = global_position + muzzle_pos
	get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying:
		return
	var actual_dmg := dmg * (0.5 if state == TurretState.DORMANT else 1.0)
	health -= actual_dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if state == TurretState.DORMANT:
		state = TurretState.OPENING
	if health <= 0.0:
		_die()

func _die() -> void:
	if is_dying:
		return
	is_dying = true
	collision_layer = 0
	var reward := 500
	if enemy_data != null and enemy_data.score_reward > 0:
		reward = enemy_data.score_reward
	Global.add_score(reward)
	Global.shake_screen(6.5, 0.25)
	Global.play_sfx("explosion")
	VFX.spawn_enemy_death_explosion(global_position + Vector2(0.0, -14.0), 1.25)

func _draw() -> void:
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var spr_w: float = 54.0
			var spr_h: float = 44.0
			var alpha: float = 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_texture_rect(d_tex, Rect2(-spr_w * 0.5, -spr_h * 0.85, spr_w, spr_h), false, Color(1, 1, 1, alpha))
			return
	
	var base_w: float = 54.0
	var base_h: float = 44.0
	var b_rect := Rect2(-base_w * 0.5, -base_h * 0.85, base_w, base_h)
	var flash_col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	
	# 1. Dormant or Deploying Animation (Hatch opening / elevating)
	if state != TurretState.ACTIVE:
		var dep_idx := clampi(int(deploy_progress * 3.0), 0, 3)
		if dep_idx < deploy_textures.size() and deploy_textures[dep_idx] != null:
			draw_texture_rect(deploy_textures[dep_idx], b_rect, false, flash_col)
		elif turret_base_texture != null:
			draw_texture_rect(turret_base_texture, b_rect, false, flash_col)
		return
	
	# 2. Fully Active State: Articulated Arm on Base
	if turret_base_texture != null:
		draw_texture_rect(turret_base_texture, b_rect, false, flash_col)
	else:
		draw_rect(Rect2(-24.0, -3.0, 48.0, 9.0), Color(0.25, 0.28, 0.34))
		draw_circle(Vector2(0.0, -14.0), 13.0, Color(0.32, 0.38, 0.46))
	
	# Trunnion bearing socket in the cupola dome
	var socket_pos := Vector2(0.0, b_rect.position.y + b_rect.size.y * 0.3435)
	var barrel_dir := Vector2(cos(aim_angle), sin(aim_angle))
	var perp := Vector2(-barrel_dir.y, barrel_dir.x) * 4.2
	
	# --- DRAW ROTATING FIRING ARM ---
	if turret_arm_texture != null:
		var arm_w: float = 42.0
		var arm_h: float = 14.8
		var arm_pivot_x: float = arm_w * 0.098
		var arm_pivot_y: float = arm_h * 0.590
		
		var avg_recoil := (left_barrel_recoil + right_barrel_recoil) * 0.5
		var arm_pivot := socket_pos - barrel_dir * (avg_recoil + chassis_recoil)
		
		draw_set_transform(arm_pivot, aim_angle, Vector2.ONE)
		draw_texture_rect(turret_arm_texture, Rect2(-arm_pivot_x, -arm_pivot_y, arm_w, arm_h), false, flash_col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# --- OPTIC SENSOR EYE PULSE ---
	var eye_pos := Vector2(b_rect.position.x + b_rect.size.x * 0.7485, b_rect.position.y + b_rect.size.y * 0.519)
	var eye_pulse := 0.75 + 0.25 * sin(anim_timer * 8.0)
	var is_locked := (burst_count > 0 or shoot_timer < 0.7)
	var eye_col := Color(1.0, 0.15, 0.15) if not is_locked else Color(1.0, 0.95, 0.40)
	draw_circle(eye_pos, 2.6, eye_col * eye_pulse)
	draw_circle(eye_pos, 1.2, Color.WHITE)
	
	# --- MUZZLE FLASH ---
	if muzzle_flash_timer > 0.0:
		_draw_muzzle_flash(muzzle_flash_pos, muzzle_flash_angle)
	
	# --- DRAW EJECTED BRASS BULLET CASINGS ---
	for c in casing_particles:
		var c_alpha: float = clampf(c["life"] / 0.45, 0.0, 1.0)
		draw_set_transform(c["pos"], c["rot"], Vector2.ONE)
		draw_rect(Rect2(-2.5, -1.2, 5.0, 2.4), Color(0.95, 0.80, 0.25, c_alpha))
		draw_rect(Rect2(1.5, -1.2, 1.0, 2.4), Color(0.70, 0.55, 0.15, c_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# --- MUZZLE PROPELLANT SMOKE WISPS ---
	for p in muzzle_smoke_particles:
		var alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0) * 0.45
		draw_circle(p["pos"], p["radius"], Color(0.80, 0.82, 0.88, alpha))
	
	# --- DAMAGE SMOKE PARTICLES AND SPARKS ---
	for p in smoke_particles:
		var alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0) * 0.7
		draw_circle(p["pos"], p["radius"], Color(0.25, 0.25, 0.30, alpha))
		draw_circle(p["pos"] + Vector2(1.0, -1.0), p["radius"] * 0.6, Color(0.45, 0.45, 0.52, alpha * 0.8))

func _draw_muzzle_flash(pos: Vector2, angle: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var perp := Vector2(-dir.y, dir.x)
	
	draw_circle(pos + dir * 3.0, 7.5, Color(1.0, 0.50, 0.10, 0.90))
	draw_circle(pos + dir * 3.0, 4.5, Color(1.0, 0.90, 0.35))
	draw_circle(pos + dir * 3.0, 2.2, Color.WHITE)
	
	draw_line(pos + dir * 3.0 - perp * 9.0, pos + dir * 3.0 + perp * 9.0, Color(1.0, 0.85, 0.30, 0.85), 2.0)
	draw_line(pos - dir * 2.0, pos + dir * 16.0, Color(1.0, 0.90, 0.50, 0.90), 2.2)
