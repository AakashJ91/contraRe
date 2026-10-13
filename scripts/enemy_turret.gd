extends Area2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

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

# Recoil and Muzzle Animation
var left_barrel_recoil: float = 0.0
var right_barrel_recoil: float = 0.0
var next_barrel_left: bool = true
var muzzle_flash_timer: float = 0.0
var muzzle_flash_pos: Vector2 = Vector2.ZERO
var muzzle_flash_angle: float = 0.0

# Damage Smoke & Sparks
var smoke_particles: Array[Dictionary] = []
var spark_timer: float = 0.0

const ACTIVATION_DIST: float = 520.0
const DEACTIVATE_DIST: float = 680.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	if ResourceLoader.exists("res://assets/enemies/enemy_turret.png"):
		turret_texture = load("res://assets/enemies/enemy_turret.png")
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	
	if flash_timer > 0.0:
		flash_timer -= delta
	
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
	
	# Smoothly recover barrel recoils
	left_barrel_recoil = maxf(0.0, left_barrel_recoil - 38.0 * delta)
	right_barrel_recoil = maxf(0.0, right_barrel_recoil - 38.0 * delta)
	
	# Update damage smoke particles
	_update_smoke(delta)
	
	# Player tracking and deployment state machine
	var player = get_tree().get_first_node_in_group("player")
	var dist_to_player := 9999.0
	if player != null and is_instance_valid(player):
		dist_to_player = global_position.distance_to(player.global_position)
	
	match state:
		TurretState.DORMANT:
			deploy_progress = 0.0
			if dist_to_player < ACTIVATION_DIST:
				state = TurretState.OPENING
		
		TurretState.OPENING:
			deploy_progress = minf(1.0, deploy_progress + 2.2 * delta)
			if deploy_progress >= 1.0:
				state = TurretState.ACTIVE
		
		TurretState.ACTIVE:
			deploy_progress = 1.0
			if dist_to_player > DEACTIVATE_DIST:
				state = TurretState.CLOSING
			elif player != null and is_instance_valid(player):
				var target_angle = (player.global_position - global_position).angle()
				# Smooth tracking toward player
				aim_angle = rotate_toward(aim_angle, target_angle, 2.6 * delta)
				
				# Burst fire handling
				if burst_count > 0:
					burst_timer -= delta
					if burst_timer <= 0.0:
						burst_timer = 0.18
						burst_count -= 1
						_fire_bullet()
				else:
					shoot_timer -= delta
					if shoot_timer <= 0.0 and dist_to_player < ACTIVATION_DIST:
						shoot_timer = 2.6
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

func _update_smoke(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for p in smoke_particles:
		p["pos"] += p["vel"] * delta
		p["radius"] += 6.0 * delta
		p["life"] -= delta
		if p["life"] > 0.0:
			remaining.append(p)
	smoke_particles = remaining

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
	
	# Calculate barrel positions and alternate recoil
	var barrel_dir := Vector2(cos(aim_angle), sin(aim_angle))
	var perp := Vector2(-barrel_dir.y, barrel_dir.x) * 4.0
	var center_offset := Vector2(0.0, -2.0 - 10.0 * deploy_progress)
	
	var active_perp := perp if next_barrel_left else -perp
	if next_barrel_left:
		left_barrel_recoil = 6.5
	else:
		right_barrel_recoil = 6.5
	
	var muzzle_pos := center_offset + active_perp + barrel_dir * 18.0
	muzzle_flash_pos = muzzle_pos
	muzzle_flash_angle = aim_angle
	muzzle_flash_timer = 0.08
	next_barrel_left = not next_barrel_left
	
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = barrel_dir
	b.global_position = global_position + muzzle_pos
	get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	# Armored hatch takes reduced damage when dormant
	var actual_dmg := dmg * (0.5 if state == TurretState.DORMANT else 1.0)
	health -= actual_dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	# If hit while dormant, immediately wake up and open
	if state == TurretState.DORMANT:
		state = TurretState.OPENING
	if health <= 0.0:
		_die()

func _die() -> void:
	Global.add_score(500)
	if explosion_scene != null:
		for i in range(2):
			var exp_node = explosion_scene.instantiate()
			exp_node.global_position = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-10.0, 6.0))
			get_parent().add_child(exp_node)
	queue_free()

func _draw() -> void:
	# 1. Armored Bunker Base Rim (Fixed to ground)
	var col_steel := Color(0.25, 0.28, 0.34)
	var col_dark := Color(0.12, 0.14, 0.18)
	var col_trim := Color(0.55, 0.62, 0.70)
	
	# Base foundation bunker pit
	draw_rect(Rect2(-22.0, -3.0, 44.0, 9.0), col_steel)
	draw_rect(Rect2(-20.0, -1.0, 40.0, 5.0), col_dark)
	
	# 2. Rising Turret Dome and Cannons (Offset by deploy_progress)
	var rise_y := -10.0 * deploy_progress
	var dome_center := Vector2(0.0, rise_y)
	
	# Colors for turret chassis & flash
	var col_base := Color(0.32, 0.38, 0.45)
	var col_barrel := Color(0.20, 0.22, 0.26)
	
	if flash_timer > 0.0:
		col_base = Color(1.8, 0.4, 0.4)
		col_barrel = Color(1.5, 0.5, 0.5)
		col_trim = Color(1.8, 0.7, 0.7)
	
	if deploy_progress > 0.05:
		# Draw Gun Barrels with Recoil Kickback
		var barrel_dir := Vector2(cos(aim_angle), sin(aim_angle))
		var perp := Vector2(-barrel_dir.y, barrel_dir.x) * 4.0
		
		var l_len := 18.0 - left_barrel_recoil
		var r_len := 18.0 - right_barrel_recoil
		
		# Left Cannon Barrel
		var l_start := dome_center + perp - barrel_dir * left_barrel_recoil * 0.5
		var l_end := dome_center + perp + barrel_dir * l_len
		draw_line(l_start, l_end, col_barrel, 3.5)
		draw_line(l_end - barrel_dir * 3.0, l_end, col_trim, 4.2)
		
		# Right Cannon Barrel
		var r_start := dome_center - perp - barrel_dir * right_barrel_recoil * 0.5
		var r_end := dome_center - perp + barrel_dir * r_len
		draw_line(r_start, r_end, col_barrel, 3.5)
		draw_line(r_end - barrel_dir * 3.0, r_end, col_trim, 4.2)
		
		# Turret Head / Dome
		if turret_texture != null:
			var spr_w: float = 34.0
			var spr_h: float = 28.0
			var col: Color = Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
			draw_texture_rect(turret_texture, Rect2(dome_center.x - spr_w * 0.5, dome_center.y - spr_h * 0.5, spr_w, spr_h), false, col)
		else:
			draw_circle(dome_center, 14.0, col_base)
			draw_arc(dome_center, 14.0, 0.0, TAU, 24, col_trim, 2.0)
			draw_circle(dome_center, 7.0, col_dark)
		
		# Central Optic Sensor Lens
		var eye_pulse := 0.75 + 0.25 * sin(anim_timer * 8.0)
		var is_locked := (burst_count > 0 or shoot_timer < 0.7) and state == TurretState.ACTIVE
		var eye_col := Color(1.0, 0.15, 0.15) if not is_locked else Color(1.0, 0.95, 0.40)
		draw_circle(dome_center, 3.8, eye_col * eye_pulse)
		draw_circle(dome_center, 1.8, Color.WHITE)
		
		# Targeting Laser Sight Beam when locked on
		if is_locked and state == TurretState.ACTIVE:
			var laser_end := dome_center + barrel_dir * 420.0
			var laser_alpha := 0.55 + 0.35 * sin(anim_timer * 16.0)
			draw_line(dome_center + barrel_dir * 18.0, laser_end, Color(1.0, 0.15, 0.15, laser_alpha), 1.2)
			draw_circle(laser_end, 3.0, Color(1.0, 0.3, 0.3, laser_alpha))
		
		# Muzzle Flash FX
		if muzzle_flash_timer > 0.0:
			_draw_muzzle_flash(muzzle_flash_pos, muzzle_flash_angle)
	
	# 3. Armored Sliding Hatch Doors (Close over turret when dormant)
	var door_slide := 16.0 * deploy_progress
	var left_door_x := -18.0 - door_slide
	var right_door_x := 1.0 + door_slide
	var door_w := 17.0
	var door_h := 8.0
	
	if deploy_progress < 0.95:
		# Left Sliding Blast Door
		draw_rect(Rect2(left_door_x, -4.0, door_w, door_h), Color(0.22, 0.25, 0.32))
		draw_rect(Rect2(left_door_x, -4.0, door_w, door_h), col_trim, false, 1.0)
		
		# Right Sliding Blast Door
		draw_rect(Rect2(right_door_x, -4.0, door_w, door_h), Color(0.22, 0.25, 0.32))
		draw_rect(Rect2(right_door_x, -4.0, door_w, door_h), col_trim, false, 1.0)
		
		# Center standby light when completely closed
		if deploy_progress <= 0.05:
			var stand_pulse := 0.5 + 0.5 * sin(anim_timer * 4.0)
			draw_circle(Vector2(0.0, -1.0), 2.2, Color(1.0, 0.2, 0.2, stand_pulse))
	
	# 4. Damage Smoke Particles and Sparks
	for p in smoke_particles:
		var alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0) * 0.7
		draw_circle(p["pos"], p["radius"], Color(0.25, 0.25, 0.30, alpha))
		draw_circle(p["pos"] + Vector2(1.0, -1.0), p["radius"] * 0.6, Color(0.45, 0.45, 0.52, alpha * 0.8))

func _draw_muzzle_flash(pos: Vector2, angle: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var perp := Vector2(-dir.y, dir.x)
	
	# Multi-tiered radial muzzle flash flare
	draw_circle(pos + dir * 3.0, 7.5, Color(1.0, 0.50, 0.10, 0.90))
	draw_circle(pos + dir * 3.0, 4.5, Color(1.0, 0.90, 0.35))
	draw_circle(pos + dir * 3.0, 2.2, Color.WHITE)
	
	# Cross flare flash spikes
	draw_line(pos + dir * 3.0 - perp * 9.0, pos + dir * 3.0 + perp * 9.0, Color(1.0, 0.85, 0.30, 0.85), 2.0)
	draw_line(pos - dir * 2.0, pos + dir * 16.0, Color(1.0, 0.90, 0.50, 0.90), 2.2)
