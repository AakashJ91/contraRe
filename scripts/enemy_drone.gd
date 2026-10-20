extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/drone_data.tres")

var health: float = 2.0
var flash_timer: float = 0.0
var anim_timer: float = 0.0
var facing_dir: int = -1
var flight_speed: float = 110.0
var base_altitude: float = 180.0
var hover_offset_y: float = 0.0
var drone_texture: Texture2D = null
var fly_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

enum DroneState {
	PATROL,
	LOCK_ON,
	FIRE_BURST,
	SWOOP_AWAY
}

var state: DroneState = DroneState.PATROL
var state_timer: float = 0.0
var attack_cooldown: float = 2.5
var target_aim_dir: Vector2 = Vector2.DOWN
var is_alien_theme: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 0
	base_altitude = global_position.y
	is_alien_theme = (Global.current_stage == 2 or Global.current_stage == 8)
	
	fly_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/drone/movement/fly_%d.png" % i
		if ResourceLoader.exists(p):
			fly_textures.append(load(p))
	
	death_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/drone/death/crash_%d.png" % i
		if ResourceLoader.exists(p):
			death_textures.append(load(p))
	
	if ResourceLoader.exists("res://assets/enemies/drone/drone.png"):
		drone_texture = load("res://assets/enemies/drone/drone.png")
	elif enemy_data != null and enemy_data.sprite_texture != null:
		drone_texture = enemy_data.sprite_texture
	elif ResourceLoader.exists("res://assets/enemies/enemy_drone.png"):
		drone_texture = load("res://assets/enemies/enemy_drone.png")
	
	if enemy_data != null:
		health = enemy_data.max_health
		flight_speed = enemy_data.move_speed
	
	attack_cooldown = randf_range(1.5, 3.0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 6.5), 0, 3)
		velocity.y += 350.0 * delta # falling crash
		global_position += velocity * delta
		if death_timer >= 0.65:
			queue_free()
		queue_redraw()
		return

	if flash_timer > 0.0:
		flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var has_player: bool = (player_node != null and is_instance_valid(player_node))
	
	if has_player:
		# Contact damage check with player
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"):
				player_node.take_damage(1.0)
	
	# State Machine
	match state:
		DroneState.PATROL:
			attack_cooldown -= delta
			# Smooth sinusoidal hover wave
			hover_offset_y = sin(anim_timer * 3.8) * 32.0
			global_position.y = lerpf(global_position.y, base_altitude + hover_offset_y, delta * 3.0)
			
			if has_player:
				var diff_x := player_node.global_position.x - global_position.x
				facing_dir = 1 if diff_x > 0.0 else -1
				
				# Move toward player within horizontal airspace
				if absf(diff_x) > 160.0:
					velocity.x = facing_dir * flight_speed
				else:
					velocity.x = facing_dir * flight_speed * 0.4
				
				# Trigger attack lock when close enough
				if attack_cooldown <= 0.0 and absf(diff_x) < 260.0 and global_position.distance_to(player_node.global_position) < 420.0:
					state = DroneState.LOCK_ON
					state_timer = 0.45 # Lock-on telegraph duration
					target_aim_dir = (player_node.global_position - global_position).normalized()
			else:
				velocity.x = facing_dir * flight_speed
		
		DroneState.LOCK_ON:
			state_timer -= delta
			velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
			if has_player:
				target_aim_dir = (player_node.global_position - global_position).normalized()
				facing_dir = 1 if target_aim_dir.x > 0.0 else -1
			
			if state_timer <= 0.0:
				state = DroneState.FIRE_BURST
				state_timer = 0.25
				_fire_plasma_burst()
		
		DroneState.FIRE_BURST:
			state_timer -= delta
			if state_timer <= 0.0:
				state = DroneState.SWOOP_AWAY
				state_timer = 1.0
				# Boost away diagonally
				velocity = Vector2(facing_dir * 140.0, -120.0)
		
		DroneState.SWOOP_AWAY:
			state_timer -= delta
			velocity.y += 180.0 * delta # Arc back downwards
			if state_timer <= 0.0:
				state = DroneState.PATROL
				attack_cooldown = randf_range(2.2, 3.8)
	
	move_and_slide()
	
	# Despawn if fallen way off or too far below
	if global_position.y > 580.0:
		queue_free()
		return
	
	queue_redraw()

func _fire_plasma_burst() -> void:
	if bullet_scene == null:
		return
	
	Global.play_sfx("shoot_laser")
	
	# Twin barrel staggered volley
	for offset_x in [-8.0, 8.0]:
		var b = bullet_scene.instantiate()
		b.bullet_owner = b.BulletOwner.ENEMY
		b.direction = target_aim_dir
		b.speed = 290.0
		b.global_position = global_position + Vector2(offset_x, 8.0)
		get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying:
		return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	if is_dying:
		return
	is_dying = true
	collision_layer = 0
	velocity = Vector2(facing_dir * 40.0, -80.0)
	var reward: int = enemy_data.score_reward if enemy_data != null else 350
	Global.add_score(reward)
	Global.shake_screen(5.5, 0.2)
	Global.play_sfx("explosion")
	VFX.spawn_enemy_death_explosion(global_position, 1.1)

func _draw() -> void:
	var flash_col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var dir_f := float(facing_dir)
	var bank_tilt := clampf(velocity.x * 0.002, -0.3, 0.3)
	# New asset faces left by default (facing_dir == -1 -> scale_x = 1.0)
	var scale_x: float = -1.0 if facing_dir > 0 else 1.0
	var spr_w: float = 52.0
	var spr_h: float = 24.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha: float = 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			var d_col := Color(flash_col.r, flash_col.g, flash_col.b, alpha)
			draw_set_transform(Vector2.ZERO, bank_tilt + death_timer * 3.5, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h), false, d_col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	
	if not is_alien_theme:
		var cur_tex: Texture2D = drone_texture
		if fly_textures.size() > 0:
			var f_idx: int = int(anim_timer * 8.0) % fly_textures.size()
			cur_tex = fly_textures[f_idx]
		
		if cur_tex != null:
			draw_set_transform(Vector2.ZERO, bank_tilt, Vector2(scale_x, 1.0))
			draw_texture_rect(cur_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h), false, flash_col)
			
			# Thruster exhaust flame behind drone (drone faces left, exhaust on the right)
			var flame_len := 7.0 + sin(anim_timer * 25.0) * 4.0
			if state == DroneState.SWOOP_AWAY:
				flame_len *= 2.2 # Afterburner boost
			draw_line(Vector2(spr_w * 0.44, 2.0), Vector2(spr_w * 0.44 + flame_len, 2.0), Color(0.2, 0.8, 1.0, 0.85), 3.0)
			draw_line(Vector2(spr_w * 0.44, 2.0), Vector2(spr_w * 0.44 + flame_len * 0.5, 2.0), Color.WHITE, 1.5)
			
			# Dual autocannon muzzle flashes when firing
			if state == DroneState.FIRE_BURST:
				for mx in [-12.0, 0.0]:
					draw_circle(Vector2(mx, 8.0), 6.0, Color(1.0, 0.85, 0.2, 0.9))
					draw_circle(Vector2(mx, 8.0), 3.0, Color.WHITE)
			
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	
	draw_set_transform(Vector2.ZERO, bank_tilt, Vector2.ONE)
	
	if is_alien_theme:
		_draw_alien_wasp(flash_col, dir_f)
	else:
		_draw_cyber_drone(flash_col, dir_f)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_cyber_drone(tint: Color, dir_f: float) -> void:
	# 1. Thruster Exhaust Flames (animated flickering plasma cones)
	var flame_len := 6.0 + sin(anim_timer * 25.0) * 3.5
	var flame_col := Color(0.2, 0.8, 1.0, 0.8) # Electric cyan plasma
	draw_line(Vector2(-14.0, 3.0), Vector2(-14.0 - dir_f * flame_len, 3.0), flame_col, 3.0)
	draw_line(Vector2(-14.0, -3.0), Vector2(-14.0 - dir_f * flame_len, -3.0), flame_col, 3.0)
	
	# 2. Outer Hull / Armored Nacelles
	var col_hull := Color(0.18, 0.22, 0.28) * tint # Titanium gunmetal
	var col_plate := Color(0.35, 0.40, 0.48) * tint # High-contrast armor edging
	var col_warning := Color(0.95, 0.75, 0.1) * tint # Hazard stripes
	
	# Left and Right Jet Engines
	draw_rect(Rect2(-14.0, -9.0, 6.0, 18.0), col_hull)
	draw_rect(Rect2(-12.0, -7.0, 2.0, 14.0), col_plate)
	
	# Central Aerodynamic Fuselage
	var pts_fuselage := PackedVector2Array([
		Vector2(-10.0, -10.0),
		Vector2(10.0, -7.0),
		Vector2(16.0, 0.0),
		Vector2(10.0, 7.0),
		Vector2(-10.0, 10.0),
		Vector2(-12.0, 0.0)
	])
	draw_colored_polygon(pts_fuselage, col_hull)
	draw_polyline(pts_fuselage, col_plate, 1.5)
	
	# Hazard striping on top
	draw_line(Vector2(-6.0, -6.0), Vector2(-2.0, -6.0), col_warning, 2.0)
	
	# Twin underslung rail-cannons
	draw_line(Vector2(-2.0, 8.0), Vector2(14.0, 8.0), Color(0.12, 0.12, 0.15), 2.5)
	draw_line(Vector2(-2.0, -8.0), Vector2(14.0, -8.0), Color(0.12, 0.12, 0.15), 2.5)
	
	# 3. Glowing Sensor Optic / Visor (Cylon / Terminator eye)
	var optic_pulse := (sin(anim_timer * 8.0) + 1.0) * 0.5
	var col_eye := Color(1.0, 0.1 + optic_pulse * 0.3, 0.1)
	draw_circle(Vector2(8.0, 0.0), 3.5, col_eye)
	draw_circle(Vector2(9.0, 0.0), 1.5, Color.WHITE)
	
func _draw_alien_wasp(tint: Color, dir_f: float) -> void:
	# 1. Fluttering Chitin Wings (fast oscillation)
	var wing_angle := sin(anim_timer * 40.0) * 0.6
	var wing_col := Color(0.6, 0.9, 0.8, 0.5)
	var wing_edge := Color(0.8, 1.0, 0.9, 0.8)
	
	# Upper wing
	draw_line(Vector2(-2.0, -6.0), Vector2(-16.0 + wing_angle * 14.0, -22.0), wing_col, 4.0)
	draw_line(Vector2(-2.0, -6.0), Vector2(-16.0 + wing_angle * 14.0, -22.0), wing_edge, 1.5)
	
	# 2. Alien Carapace (chitinous purple / bio-green)
	var col_chitin := Color(0.28, 0.12, 0.35) * tint
	var col_bio_core := Color(0.2, 0.9, 0.3) * tint
	
	# Segmented Thorax and Abdomen
	draw_circle(Vector2(-4.0, 0.0), 7.0, col_chitin)
	draw_circle(Vector2(6.0, 0.0), 5.5, col_chitin)
	
	# Glowing acid bio-sac abdomen
	var pulse := (sin(anim_timer * 6.0) + 1.0) * 0.5
	draw_circle(Vector2(-10.0, 4.0), 6.0, Color(0.1, 0.8 * pulse + 0.2, 0.2, 0.8))
	
	# Sharp stinger
	draw_line(Vector2(-14.0, 6.0), Vector2(-20.0, 10.0), Color(0.1, 0.1, 0.1), 2.5)
	
	# Compound eyes
	draw_circle(Vector2(9.0, -2.0), 3.0, Color(1.0, 0.2, 0.2))
	draw_circle(Vector2(9.0, 2.0), 3.0, Color(1.0, 0.2, 0.2))
	
	if state == DroneState.LOCK_ON:
		draw_line(Vector2(10.0, 0.0), target_aim_dir * 180.0, Color(0.2, 1.0, 0.3, 0.5), 2.0)
