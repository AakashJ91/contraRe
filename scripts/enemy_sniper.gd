extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/sniper_data.tres")

const SPEED: float = 0.0
const GRAVITY: float = 950.0

var health: float = 2.0
var shoot_timer: float = 2.2
var flash_timer: float = 0.0
var facing_dir: int = -1
var sniper_texture: Texture2D = null

var aim_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var aim_frame: int = 0
var aim_timer: float = 0.0
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0
var has_grounded: bool = false

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 1 << 1  # Layer 2: World
	
	aim_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/sniper/movement/aim_%d.png" % i
		if ResourceLoader.exists(p):
			aim_textures.append(load(p))
	
	death_textures.clear()
	for i in range(4):
		var p := "res://assets/enemies/sniper/death/death_%d.png" % i
		if ResourceLoader.exists(p):
			death_textures.append(load(p))
	
	if ResourceLoader.exists("res://assets/enemies/sniper/sniper.png"):
		sniper_texture = load("res://assets/enemies/sniper/sniper.png")
	elif enemy_data != null and enemy_data.sprite_texture != null:
		sniper_texture = enemy_data.sprite_texture
	elif ResourceLoader.exists("res://assets/enemies/enemy_sniper.png"):
		sniper_texture = load("res://assets/enemies/enemy_sniper.png")
	
	if enemy_data != null:
		health = enemy_data.max_health
		shoot_timer = randf_range(enemy_data.attack_interval_min, enemy_data.attack_interval_max)
	else:
		shoot_timer = randf_range(2.0, 3.2)
	
	_snap_to_ground()
	_update_platform_floor_overlap()
	queue_redraw()

func _update_platform_floor_overlap() -> void:
	if is_dying:
		show_behind_parent = false
		z_index = 2
		return
	
	var is_overlapping := false
	var parent_node = get_parent()
	if parent_node != null:
		var spr_w: float = 36.0
		var spr_h: float = 30.0
		var sniper_box := Rect2(global_position.x - spr_w * 0.5, global_position.y - spr_h * 0.5 - 2.0, spr_w, spr_h)
		
		# Check overlap with platforms
		if "platforms" in parent_node:
			for p in parent_node.platforms:
				var pr: Rect2 = p.get("rect", Rect2())
				var visual_pr := Rect2(pr.position.x - 2.0, pr.position.y - 6.0, pr.size.x + 4.0, pr.size.y + 12.0)
				if sniper_box.intersects(visual_pr):
					is_overlapping = true
					break
		
		# Check overlap with ground segments (tile floors)
		if not is_overlapping and "ground_segments" in parent_node:
			for g in parent_node.ground_segments:
				var visual_gr := Rect2(g.position.x, g.position.y - 30.0, g.size.x, g.size.y + 30.0)
				if sniper_box.intersects(visual_gr):
					is_overlapping = true
					break
	else:
		is_overlapping = true
	
	if is_overlapping:
		show_behind_parent = true
		z_index = -1
	else:
		show_behind_parent = false
		z_index = 0

func _snap_to_ground() -> void:
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return
	var from_pos := global_position - Vector2(0.0, 10.0)
	var to_pos := global_position + Vector2(0.0, 350.0)
	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos, collision_mask)
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position.y = hit.position.y - 5.0
		velocity.y = 0.0
		has_grounded = true
		_update_platform_floor_overlap()

func _physics_process(delta: float) -> void:
	if not has_grounded:
		_snap_to_ground()
	
	_update_platform_floor_overlap()
	
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		velocity.x = move_toward(velocity.x, 0.0, 100.0 * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		if death_timer >= 0.5:
			queue_free()
		queue_redraw()
		return
	
	# Keep stationary on ground / platform with gravity
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	
	aim_timer += delta * 3.5
	aim_frame = int(aim_timer) % 4
	
	if flash_timer > 0.0:
		flash_timer -= delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		facing_dir = 1 if player.global_position.x > global_position.x else -1
		
		# Contact damage check
		if global_position.distance_to(player.global_position) < 20.0:
			if player.has_method("take_damage"):
				player.take_damage(1.0)
		
		shoot_timer -= delta
		if shoot_timer <= 0.0 and global_position.distance_to(player.global_position) < 600.0:
			if enemy_data != null:
				shoot_timer = randf_range(enemy_data.attack_interval_min, enemy_data.attack_interval_max)
			else:
				shoot_timer = randf_range(2.0, 3.2)
			_shoot(player.global_position)
	
	queue_redraw()

func _shoot(target_pos: Vector2) -> void:
	if bullet_scene == null:
		return
	var dir := (target_pos - global_position).normalized()
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.speed = 300.0
	b.z_index = 5
	b.global_position = global_position + dir * 18.0
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
	show_behind_parent = false
	z_index = 2
	var reward: int = enemy_data.score_reward if enemy_data != null else 300
	Global.add_score(reward)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 45.0, -110.0)
	Global.shake_screen(4.0, 0.16)
	Global.play_sfx("hit")
	VFX.spawn_dust_puff(global_position + Vector2(0.0, 6.0), 3)

func _draw() -> void:
	var col: Color = Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var scale_x: float = -1.0 if facing_dir > 0 else 1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var spr_w: float = 38.0
			var spr_h: float = 30.0
			var alpha: float = 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			var d_col := Color(col.r, col.g, col.b, alpha)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5 - 2.0, spr_w, spr_h), false, d_col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	
	var cur_tex: Texture2D = aim_textures[aim_frame] if (aim_textures.size() > 0 and aim_frame < aim_textures.size()) else sniper_texture
	if cur_tex != null:
		var spr_w: float = 36.0
		var spr_h: float = 30.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, Rect2(-spr_w * 0.5, -spr_h * 0.5 - 2.0, spr_w, spr_h), false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Procedural fallback
	var col_suit := Color(0.2, 0.45, 0.25) # Jungle camouflage green
	var col_skin := Color(0.9, 0.75, 0.6)
	var col_gun := Color(0.15, 0.15, 0.18)
	var dir_f := float(facing_dir)
	
	if flash_timer > 0.0:
		col_suit = Color(1.0, 0.4, 0.4)
	
	# Kneeling body
	draw_rect(Rect2(-6.0, -8.0, 12.0, 10.0), col_suit)
	# Helmet
	draw_circle(Vector2(0.0, -13.0), 5.0, col_suit)
	draw_circle(Vector2(dir_f * 2.0, -12.0), 3.0, col_skin)
	
	# Long sniper rifle pointing toward facing direction
	var barrel_start := Vector2(0.0, -7.0)
	var barrel_end := barrel_start + Vector2(dir_f * 22.0, 4.0)
	draw_line(barrel_start, barrel_end, col_gun, 3.5)
	# Scope
	draw_line(barrel_start + Vector2(dir_f * 6.0, -3.0), barrel_start + Vector2(dir_f * 14.0, -1.0), Color(0.3, 0.3, 0.35), 2.0)
