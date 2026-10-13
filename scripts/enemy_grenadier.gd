extends CharacterBody2D

@export var grenade_scene: PackedScene = preload("res://scenes/grenade.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/grenadier_data.tres")

const SPEED: float = 45.0
const GRAVITY: float = 950.0

var health: float = 3.5
var flash_timer: float = 0.0
var facing_dir: int = -1
var patrol_timer: float = 2.0
var shoot_timer: float = 2.6
var anim_timer: float = 0.0
var grenadier_texture: Texture2D = null

enum GrenadierState {
	PATROL,
	AIM_MORTAR,
	FIRE_MORTAR,
	RELOAD
}

var state: GrenadierState = GrenadierState.PATROL
var state_timer: float = 0.0
var recoil_offset: float = 0.0
var muzzle_flash_timer: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 1 << 1 # Layer 2: World
	
	if enemy_data != null:
		health = enemy_data.max_health
		grenadier_texture = enemy_data.sprite_texture
	elif ResourceLoader.exists("res://assets/enemies/enemy_grenadier.png"):
		grenadier_texture = load("res://assets/enemies/enemy_grenadier.png")
	
	shoot_timer = randf_range(2.0, 3.5)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if flash_timer > 0.0:
		flash_timer -= delta
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var has_player: bool = (player_node != null and is_instance_valid(player_node))
	
	if has_player:
		# Contact damage check
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"):
				player_node.take_damage(1.0)
	
	match state:
		GrenadierState.PATROL:
			recoil_offset = lerpf(recoil_offset, 0.0, delta * 8.0)
			shoot_timer -= delta
			patrol_timer -= delta
			
			if has_player:
				# Face toward player
				var diff_x := player_node.global_position.x - global_position.x
				facing_dir = 1 if diff_x > 0.0 else -1
				
				# Check if ready to launch mortar
				var dist := global_position.distance_to(player_node.global_position)
				if shoot_timer <= 0.0 and dist < 580.0 and dist > 40.0:
					state = GrenadierState.AIM_MORTAR
					state_timer = 0.6 # Aiming / shoulder mount charge
					velocity.x = 0.0
			
			if state == GrenadierState.PATROL:
				if patrol_timer <= 0.0:
					patrol_timer = randf_range(1.5, 3.0)
				
				# Ledge detection to avoid falling off platform
				var probe_pos := global_position + Vector2(facing_dir * 18.0, 0.0)
				var space_state := get_world_2d().direct_space_state
				if space_state != null and is_on_floor():
					var query := PhysicsRayQueryParameters2D.create(probe_pos, probe_pos + Vector2(0.0, 36.0), collision_mask)
					var res := space_state.intersect_ray(query)
					if res.is_empty() or is_on_wall():
						# Turn around at platform edges or walls
						facing_dir = -facing_dir
				
				velocity.x = facing_dir * SPEED
		
		GrenadierState.AIM_MORTAR:
			velocity.x = 0.0
			state_timer -= delta
			if has_player:
				facing_dir = 1 if player_node.global_position.x > global_position.x else -1
			
			if state_timer <= 0.0:
				state = GrenadierState.FIRE_MORTAR
				state_timer = 0.3
				_fire_mortar()
		
		GrenadierState.FIRE_MORTAR:
			state_timer -= delta
			velocity.x = 0.0
			if state_timer <= 0.0:
				state = GrenadierState.RELOAD
				state_timer = 0.5
		
		GrenadierState.RELOAD:
			state_timer -= delta
			velocity.x = 0.0
			if state_timer <= 0.0:
				state = GrenadierState.PATROL
				shoot_timer = randf_range(2.6, 4.0)
	
	move_and_slide()
	
	if global_position.y > 600.0:
		queue_free()
		return
	
	queue_redraw()

func _fire_mortar() -> void:
	if grenade_scene == null:
		return
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	
	muzzle_flash_timer = 0.12
	recoil_offset = -8.0 * float(facing_dir)
	Global.play_sfx("shoot_spread")
	
	# Calculate lobbed ballistic trajectory to reach near player position
	var target_pos := player_node.global_position
	var dx := target_pos.x - global_position.x
	# Desired flight time based on distance
	var flight_time := clampf(absf(dx) / 220.0, 0.65, 1.4)
	
	var g_vx := dx / flight_time
	# Parabolic gravity equation: dy = vy * t + 0.5 * g * t^2 => vy = (dy - 0.5 * g * t^2) / t
	var dy := target_pos.y - global_position.y
	var g_vy := (dy - 0.5 * 650.0 * flight_time * flight_time) / flight_time
	
	# Clamp initial upward velocity for classic high lob
	g_vy = clampf(g_vy, -480.0, -180.0)
	
	var grenade = grenade_scene.instantiate()
	var spawn_pos := global_position + Vector2(facing_dir * 14.0, -18.0)
	grenade.global_position = spawn_pos
	grenade.velocity = Vector2(g_vx, g_vy)
	get_parent().add_child(grenade)

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	var reward: int = enemy_data.score_reward if enemy_data != null else 500
	Global.add_score(reward)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	queue_free()

func _draw() -> void:
	var flash_col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var dir_f := float(facing_dir)
	var is_kneeling: bool = (state != GrenadierState.PATROL)
	
	if grenadier_texture != null:
		var spr_w: float = 38.0
		var spr_h: float = 40.0
		var scale_x: float = 1.0 if facing_dir > 0 else -1.0
		var base_y_tex: float = 2.0 if is_kneeling else -2.0
		draw_set_transform(Vector2(recoil_offset, base_y_tex), 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(grenadier_texture, Rect2(-spr_w * 0.5, -spr_h * 0.5 - 2.0, spr_w, spr_h), false, flash_col)
		
		# Overlay aiming laser when preparing mortar
		if state == GrenadierState.AIM_MORTAR:
			var aim_alpha := (sin(anim_timer * 15.0) + 1.0) * 0.4 + 0.2
			draw_line(Vector2(spr_w * 0.4, -spr_h * 0.25), Vector2(spr_w * 0.4 + 170.0, -spr_h * 0.25 - 65.0), Color(1.0, 0.2, 0.1, aim_alpha), 2.0)
		
		# Overlay muzzle blast
		if muzzle_flash_timer > 0.0:
			draw_circle(Vector2(spr_w * 0.4, -spr_h * 0.25), 10.0, Color(1.0, 0.9, 0.3))
			draw_circle(Vector2(spr_w * 0.4, -spr_h * 0.25), 6.0, Color.WHITE)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Stage camouflage palette
	var col_armor := Color(0.25, 0.28, 0.32) * flash_col # Reinforced dark steel
	var col_trim := Color(0.85, 0.22, 0.18) * flash_col # Elite crimson hazard markings
	var col_skin := Color(0.9, 0.75, 0.6)
	var col_cannon := Color(0.14, 0.14, 0.16)
	var col_brass := Color(0.9, 0.7, 0.2)
	
	# Adjust for Arctic or Volcanic stages
	if Global.current_stage == 4:
		col_armor = Color(0.80, 0.85, 0.92) * flash_col # Snow camo
	elif Global.current_stage == 5:
		col_armor = Color(0.35, 0.18, 0.15) * flash_col # Volcanic forge
	
	var base_y: float = 0.0 if not is_kneeling else 5.0
	var offset_x: float = recoil_offset
	
	# 1. Heavy Armored Boots and Legs
	if is_kneeling:
		# Kneeling pose
		draw_rect(Rect2(offset_x - 8.0, base_y + 4.0, 16.0, 6.0), col_armor)
		draw_circle(Vector2(offset_x + dir_f * 6.0, base_y + 8.0), 4.0, col_cannon)
	else:
		# Walking pose
		var walk_leg := sin(anim_timer * 6.0) * 4.0
		draw_line(Vector2(offset_x - 3.0, 0.0), Vector2(offset_x - 5.0 - walk_leg, 11.0), col_armor, 5.0)
		draw_line(Vector2(offset_x + 3.0, 0.0), Vector2(offset_x + 5.0 + walk_leg, 11.0), col_armor, 5.0)
	
	# 2. Heavy Torso Armor Plate & Ammo Backpack
	draw_rect(Rect2(offset_x - 7.0, base_y - 12.0, 14.0, 13.0), col_armor)
	# Heavy ammo drum on back
	draw_circle(Vector2(offset_x - dir_f * 8.0, base_y - 7.0), 6.0, col_cannon)
	draw_circle(Vector2(offset_x - dir_f * 8.0, base_y - 7.0), 3.5, col_brass)
	# Chest hazard stripe
	draw_rect(Rect2(offset_x - 5.0, base_y - 10.0, 10.0, 3.0), col_trim)
	
	# 3. Armored Helmet with Targeting Visor
	draw_circle(Vector2(offset_x, base_y - 16.0), 5.5, col_armor)
	draw_circle(Vector2(offset_x + dir_f * 2.0, base_y - 15.0), 3.0, col_skin)
	# Glowing cyan HUD visor line
	draw_line(Vector2(offset_x + dir_f * 1.0, base_y - 16.5), Vector2(offset_x + dir_f * 5.0, base_y - 16.5), Color(0.2, 0.9, 1.0), 2.0)
	
	# 4. Shoulder-Mounted Heavy Mortar Cannon
	var cannon_pivot := Vector2(offset_x + dir_f * 2.0, base_y - 12.0)
	var angle_f: float = -0.65 * dir_f if is_kneeling else -0.35 * dir_f
	var barrel_len := 22.0
	var barrel_end := cannon_pivot + Vector2(cos(angle_f), sin(angle_f)) * barrel_len
	
	# Large heavy mortar barrel
	draw_line(cannon_pivot - Vector2(dir_f * 6.0, 0.0), barrel_end, col_cannon, 6.0)
	# Barrel muzzle band and reinforce rings
	draw_line(barrel_end - Vector2(cos(angle_f), sin(angle_f)) * 4.0, barrel_end, col_brass, 7.0)
	
	# 5. Laser Sight / Warning Arc when Aiming
	if state == GrenadierState.AIM_MORTAR:
		var aim_alpha := (sin(anim_timer * 15.0) + 1.0) * 0.4 + 0.2
		var laser_dir := Vector2(cos(angle_f), sin(angle_f))
		draw_line(barrel_end, barrel_end + laser_dir * 180.0, Color(1.0, 0.2, 0.1, aim_alpha), 2.0)
		draw_circle(barrel_end + laser_dir * 30.0, 3.0, Color(1.0, 0.3, 0.2, aim_alpha))
	
	# 6. Muzzle Flash on Fire
	if muzzle_flash_timer > 0.0:
		draw_circle(barrel_end, 10.0, Color(1.0, 0.9, 0.3))
		draw_circle(barrel_end, 6.0, Color(1.0, 1.0, 1.0))
		draw_line(barrel_end, barrel_end + Vector2(cos(angle_f), sin(angle_f)) * 14.0, Color(1.0, 0.6, 0.1), 8.0)
