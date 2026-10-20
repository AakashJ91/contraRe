extends CharacterBody2D

@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/crawler_data.tres")

const SPEED: float = 185.0
const GRAVITY: float = 950.0

var health: float = 1.0
var flash_timer: float = 0.0
var anim_timer: float = 0.0
var facing_dir: int = -1
var leap_cooldown: float = 2.0
var is_coiling: bool = false
var coil_timer: float = 0.0
var is_alien_theme: bool = false
var crawler_texture: Texture2D = null
var crawl_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 1 << 1 # Layer 2: World
	is_alien_theme = (Global.current_stage == 3 or Global.current_stage == 8)
	
	crawl_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/crawler/movement/crawl_%d.png" % i
		if ResourceLoader.exists(p):
			crawl_textures.append(load(p))
	
	death_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/crawler/death/death_%d.png" % i
		if ResourceLoader.exists(p):
			death_textures.append(load(p))
	
	if ResourceLoader.exists("res://assets/enemies/crawler/crawler.png"):
		crawler_texture = load("res://assets/enemies/crawler/crawler.png")
	elif enemy_data != null and enemy_data.sprite_texture != null:
		crawler_texture = enemy_data.sprite_texture
	elif ResourceLoader.exists("res://assets/enemies/enemy_crawler.png"):
		crawler_texture = load("res://assets/enemies/enemy_crawler.png")
	
	if enemy_data != null:
		health = enemy_data.max_health
	
	leap_cooldown = randf_range(1.2, 2.5)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 6.5), 0, 3)
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 2.0 * delta)
		move_and_slide()
		if death_timer >= 0.65:
			queue_free()
		queue_redraw()
		return
	
	if flash_timer > 0.0:
		flash_timer -= delta
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var has_player: bool = (player_node != null and is_instance_valid(player_node))
	
	if has_player:
		# Player contact damage check
		if global_position.distance_to(player_node.global_position) < 20.0:
			if player_node.has_method("take_damage"):
				player_node.take_damage(1.0)
	
	# Pounce leap coiling state
	if is_coiling:
		coil_timer -= delta
		velocity.x = 0.0
		if coil_timer <= 0.0:
			is_coiling = false
			# Execute lunging pounce!
			velocity.y = -330.0
			velocity.x = facing_dir * 260.0
			leap_cooldown = randf_range(2.0, 3.5)
			Global.play_sfx("jump")
	else:
		leap_cooldown -= delta
		
		if has_player:
			var diff_x := player_node.global_position.x - global_position.x
			facing_dir = 1 if diff_x > 0.0 else -1
			var dist := global_position.distance_to(player_node.global_position)
			var dy := absf(player_node.global_position.y - global_position.y)
			
			# Trigger aggressive leap if within striking distance
			if is_on_floor() and leap_cooldown <= 0.0 and dist < 175.0 and dy < 80.0:
				is_coiling = true
				coil_timer = 0.16 # Brief pounce windup
		
		if not is_coiling:
			if is_on_floor():
				velocity.x = facing_dir * SPEED
				
				# Leap over bottomless pits or obstacle gaps
				var probe_pos := global_position + Vector2(facing_dir * 22.0, 0.0)
				var space_state := get_world_2d().direct_space_state
				if space_state != null:
					var query := PhysicsRayQueryParameters2D.create(probe_pos, probe_pos + Vector2(0.0, 48.0), collision_mask)
					var res := space_state.intersect_ray(query)
					if res.is_empty() or is_on_wall():
						velocity.y = -320.0
	
	move_and_slide()
	
	if global_position.y > 600.0:
		queue_free()
		return
	
	queue_redraw()

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
	velocity = Vector2(-facing_dir * 30.0, -80.0)
	var reward: int = enemy_data.score_reward if enemy_data != null else 250
	Global.add_score(reward)
	Global.shake_screen(4.5, 0.16)
	VFX.spawn_hit_explosion(global_position, 1.0)
	VFX.spawn_enemy_death_explosion(global_position)

func _draw() -> void:
	var flash_col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var dir_f := float(facing_dir)
	var in_air := not is_on_floor()
	var scale_x: float = 1.0 if facing_dir > 0 else -1.0
	var crouch_y: float = 4.0 if is_coiling else 0.0
	var scale_y: float = 0.88 if is_coiling else 1.0
	var air_tilt: float = clampf(velocity.y * 0.0008, -0.25, 0.25) if in_air else 0.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var spr_w: float = 52.0
			var spr_h: float = 35.0
			var alpha: float = 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			var d_col := Color(flash_col.r, flash_col.g, flash_col.b, alpha)
			draw_set_transform(Vector2(0.0, crouch_y), 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h), false, d_col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	
	var cur_tex: Texture2D = crawler_texture
	if crawl_textures.size() > 0:
		var c_idx: int = int(anim_timer * 10.0) % crawl_textures.size()
		cur_tex = crawl_textures[c_idx]
	
	if cur_tex != null:
		var spr_w: float = 44.0
		var spr_h: float = 30.0
		var x_scale: float = scale_x * (1.08 if is_coiling else 1.0)
		draw_set_transform(Vector2(0.0, crouch_y), air_tilt * scale_x, Vector2(x_scale, scale_y))
		draw_texture_rect(cur_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h), false, flash_col)
		
		# Eye lens flare and charging sparks when coiling for a pounce leap
		if is_coiling:
			var eye_pos := Vector2(spr_w * 0.32, -4.5)
			var pulse := (sin(anim_timer * 20.0) + 1.0) * 0.5
			draw_circle(eye_pos, 4.0 + pulse * 2.0, Color(1.0, 0.9, 0.2, 0.75))
			draw_circle(eye_pos, 2.0, Color.WHITE)
			var spark_x := spr_w * 0.40 + sin(anim_timer * 35.0) * 3.0
			var spark_y := -2.0 + cos(anim_timer * 30.0) * 3.0
			draw_line(eye_pos, Vector2(spark_x, spark_y), Color(0.4, 1.0, 0.3, 0.8), 1.5)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Palettes
	var col_body := (Color(0.25, 0.10, 0.28) if is_alien_theme else Color(0.20, 0.22, 0.26)) * flash_col
	var col_accent := (Color(0.3, 0.95, 0.3) if is_alien_theme else Color(0.9, 0.2, 0.2)) * flash_col
	var col_leg := (Color(0.15, 0.08, 0.18) if is_alien_theme else Color(0.12, 0.13, 0.15)) * flash_col
	
	var crouch_offset: float = 3.0 if is_coiling else 0.0
	
	# 1. Articulated Multi-Legs (3 on each side = 6 legs)
	for i in range(3):
		var leg_phase := anim_timer * 18.0 + float(i) * 1.8
		var step_x := sin(leg_phase) * 6.0 if not in_air else float(i - 1) * 6.0
		var step_y := cos(leg_phase) * 3.0 if not in_air else -4.0
		
		var hip_x := float(i - 1) * 6.0
		var knee_x := hip_x + dir_f * 6.0 + step_x * 0.5
		var knee_y := -6.0 + crouch_offset
		var foot_x := hip_x + dir_f * 11.0 + step_x
		var foot_y := 4.0 + crouch_offset + step_y
		
		# Draw upper leg & lower leg segments
		draw_line(Vector2(hip_x, -1.0 + crouch_offset), Vector2(knee_x, knee_y), col_leg, 2.5)
		draw_line(Vector2(knee_x, knee_y), Vector2(foot_x, foot_y), col_leg, 2.0)
	
	# 2. Segmented Low-Profile Carapace / Chassis
	draw_circle(Vector2(-4.0 * dir_f, -2.0 + crouch_offset), 6.5, col_body)
	draw_circle(Vector2(4.0 * dir_f, -3.0 + crouch_offset), 5.5, col_body)
	
	# Armor spine / hazard plate
	draw_rect(Rect2(-6.0, -6.0 + crouch_offset, 12.0, 3.0), col_accent)
	
	# 3. Glowing Compound Eyes / Sensor Cluster
	var eye_pulse := (sin(anim_timer * 12.0) + 1.0) * 0.5
	var eye_col := Color(1.0, 0.2, 0.1) if not is_alien_theme else Color(0.2, 1.0, 0.4)
	if is_coiling:
		eye_col = Color(1.0, 1.0, 0.3) # Flashes bright during windup
	
	draw_circle(Vector2(7.0 * dir_f, -4.0 + crouch_offset), 2.5, eye_col)
	draw_circle(Vector2(5.0 * dir_f, -6.0 + crouch_offset), 1.8, eye_col)
	
	# 4. Front Mandibles / Grabbing Claws
	var jaw_open := 2.5 if not is_coiling else 4.5
	draw_line(Vector2(7.0 * dir_f, -1.0 + crouch_offset), Vector2(12.0 * dir_f, -1.0 - jaw_open + crouch_offset), col_accent, 1.8)
	draw_line(Vector2(7.0 * dir_f, -1.0 + crouch_offset), Vector2(12.0 * dir_f, -1.0 + jaw_open + crouch_offset), col_accent, 1.8)
