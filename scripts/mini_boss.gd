extends Node2D
class_name MiniBoss

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var grenade_scene: PackedScene = preload("res://scenes/grenade.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/powerup_item.tscn")

enum State {
	INACTIVE,
	ENTRANCE,
	COMBAT,
	DEATH
}

var current_state: State = State.INACTIVE
var max_health: float = 26.0
var current_health: float = 26.0
var is_active: bool = false
var is_dead: bool = false

var facing: float = -1.0 # -1 = facing left (towards player), 1 = facing right
var mech_width: float = 108.0
var mech_height: float = 135.0
var ground_y: float = 440.0

var arena_min_x: float = 3360.0
var arena_max_x: float = 3700.0

var vel_x: float = 0.0
var vel_y: float = 0.0
var is_on_ground: bool = true

var walk_timer: float = 2.0
var walk_dir: float = -1.0
var attack_timer: float = 1.4
var missile_timer: float = 3.6
var leap_timer: float = 6.2

var flash_timer: float = 0.0
var anim_timer: float = 0.0
var muzzle_flash_timer: float = 0.0

var burst_count: int = 0
var burst_timer: float = 0.0

var death_chain_timer: float = 0.0
var death_explosions_left: int = 12

var mech_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var walk_frame_index: int = 0
var death_frame_index: int = 0
var walk_anim_timer: float = 0.0
var walk_cycle_speed: float = 5.2
var is_moving: bool = false
var step_sound_cooldown: float = 0.0

@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	walk_textures.clear()
	death_textures.clear()
	
	var stg := clampi(Global.current_stage, 1, 8)
	var is_stage1: bool = (stg == 1)
	var move_prefix: String = "res://assets/enemies/mini_boss/movement/walk_%d.png" if is_stage1 else ("res://assets/enemies/mini_boss_stage%d/movement/walk_%%d.png" % stg)
	var death_prefix: String = "res://assets/enemies/mini_boss/death/death_%d.png" if is_stage1 else ("res://assets/enemies/mini_boss_stage%d/death/death_%%d.png" % stg)
	var base_mech_path: String = "res://assets/enemies/mini_boss/mini_boss_mech.png" if is_stage1 else ("res://assets/enemies/mini_boss_stage%d/mini_boss_stage%d.png" % [stg, stg])
	
	for i in range(4):
		var p := move_prefix % i
		if not ResourceLoader.exists(p) and is_stage1:
			p = "res://assets/enemies/mini_boss_walk_%d.png" % i
		if ResourceLoader.exists(p):
			walk_textures.append(load(p))
	
	for i in range(4):
		var p := death_prefix % i
		if ResourceLoader.exists(p):
			death_textures.append(load(p))
	
	if ResourceLoader.exists(base_mech_path):
		mech_texture = load(base_mech_path)
	elif is_stage1 and ResourceLoader.exists("res://assets/enemies/mini_boss_mech.png"):
		mech_texture = load("res://assets/enemies/mini_boss_mech.png")
	elif walk_textures.size() > 0:
		mech_texture = walk_textures[0]
	
	var res_path := "res://resources/enemies/mini_boss_stage%d_data.tres" % stg
	var res: EnemyData = load(res_path) if ResourceLoader.exists(res_path) else null
	
	if res != null:
		max_health = res.max_health
		if res.sprite_size != Vector2.ZERO:
			mech_width = res.sprite_size.x
			mech_height = res.sprite_size.y
	else:
		max_health = 26.0 + float(stg) * 4.0
	current_health = max_health
	
	if hurtbox != null:
		hurtbox.area_entered.connect(_on_hurtbox_entered)
	
	arena_min_x = global_position.x - 260.0
	arena_max_x = global_position.x + 80.0
	
	queue_redraw()

func activate() -> void:
	if is_active or is_dead:
		return
	is_active = true
	current_state = State.ENTRANCE
	global_position.y = ground_y - 220.0
	vel_y = 280.0
	match Global.current_stage:
		1: Global.active_boss_name = "MINI-BOSS: TITAN GOLIATH"
		2: Global.active_boss_name = "MINI-BOSS: AQUA ASSAULT RIG"
		3: Global.active_boss_name = "MINI-BOSS: CHITIN BEHEMOTH"
		4: Global.active_boss_name = "MINI-BOSS: POLAR SIEGE COLOSSUS"
		5: Global.active_boss_name = "MINI-BOSS: VULCAN DREADNOUGHT"
		6: Global.active_boss_name = "MINI-BOSS: TESLA OVERLORD"
		7: Global.active_boss_name = "MINI-BOSS: ORBITAL VANGUARD"
		8: Global.active_boss_name = "MINI-BOSS: PSIONIC LEVIATHAN"
		_: Global.active_boss_name = "MINI-BOSS: TITAN GOLIATH"
	Global.play_sfx("boss_alarm")
	Global.shake_screen(6.0, 0.35)
	Global.boss_health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	anim_timer += delta
	
	if flash_timer > 0.0:
		flash_timer -= delta
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
	
	match current_state:
		State.INACTIVE:
			pass
		State.ENTRANCE:
			_process_entrance(delta)
		State.COMBAT:
			_process_combat(delta)
		State.DEATH:
			_process_death(delta)
	
	queue_redraw()

func _process_entrance(delta: float) -> void:
	vel_y += 750.0 * delta
	global_position.y += vel_y * delta
	if global_position.y >= ground_y:
		global_position.y = ground_y
		vel_y = 0.0
		is_on_ground = true
		current_state = State.COMBAT
		Global.shake_screen(9.0, 0.4)
		Global.play_sfx("explosion")
		VFX.spawn_dust_puff(global_position, 8, Color(0.85, 0.75, 0.55))
		VFX.spawn_hit_sparks(global_position + Vector2(0.0, -10.0), Vector2.UP, Color(1.0, 0.7, 0.2))

func _process_combat(delta: float) -> void:
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		# Face towards player
		facing = -1.0 if player_node.global_position.x < global_position.x else 1.0
	
	# Gravity & leaping mechanics
	if not is_on_ground:
		vel_y += 980.0 * delta
		global_position.y += vel_y * delta
		global_position.x += vel_x * delta
		if global_position.y >= ground_y:
			global_position.y = ground_y
			vel_y = 0.0
			vel_x = 0.0
			is_on_ground = true
			Global.shake_screen(5.0, 0.2)
			VFX.spawn_dust_puff(global_position, 4, Color(0.8, 0.7, 0.5))
	else:
		# Pacing ground movement
		walk_timer -= delta
		if walk_timer <= 0.0:
			walk_timer = randf_range(1.5, 3.0)
			walk_dir = -1.0 if randf() < 0.6 else 1.0
		
		# Move within arena boundary
		var target_speed: float = walk_dir * 55.0
		if (walk_dir < 0 and global_position.x <= arena_min_x) or (walk_dir > 0 and global_position.x >= arena_max_x):
			walk_dir *= -1.0
			target_speed = walk_dir * 55.0
		
		global_position.x += target_speed * delta
		global_position.x = clampf(global_position.x, arena_min_x, arena_max_x)
		is_moving = abs(target_speed) > 1.0
		
		if is_moving:
			walk_anim_timer += delta * walk_cycle_speed
			var prev_frame := walk_frame_index
			walk_frame_index = int(walk_anim_timer) % 4
			
			if step_sound_cooldown > 0.0:
				step_sound_cooldown -= delta
			
			# Trigger foot plant effect when switching to contact frames (0 or 2)
			if walk_frame_index != prev_frame and (walk_frame_index == 0 or walk_frame_index == 2):
				if step_sound_cooldown <= 0.0:
					step_sound_cooldown = 0.18
					Global.play_sfx("hit")
					Global.shake_screen(1.6, 0.07)
				var foot_offset_x := (22.0 if walk_frame_index == 0 else -18.0) * facing
				VFX.spawn_dust_puff(global_position + Vector2(foot_offset_x, -4.0), 2, Color(0.75, 0.70, 0.60, 0.6))
		else:
			walk_frame_index = 0
	
	# Gatling cannon bursts
	if burst_count > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			burst_timer = 0.14
			burst_count -= 1
			_fire_gatling_bullet(player_node)
	else:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = randf_range(1.8, 2.8)
			burst_count = 4
			burst_timer = 0.05
	
	# Shoulder micro-missiles
	missile_timer -= delta
	if missile_timer <= 0.0:
		missile_timer = randf_range(4.0, 6.0)
		_fire_shoulder_missiles(player_node)
	
	# Jet thruster leap reposition
	leap_timer -= delta
	if leap_timer <= 0.0 and is_on_ground:
		leap_timer = randf_range(6.5, 9.0)
		_execute_jet_leap(player_node)

func get_muzzle_pos() -> Vector2:
	var bob_y := 0.0
	if is_on_ground and is_moving and not is_dead:
		bob_y = sin(walk_anim_timer * PI) * 2.5
	return global_position + Vector2(facing * 52.0, -68.0 + bob_y)

func get_missile_pod_pos() -> Vector2:
	var bob_y := 0.0
	if is_on_ground and is_moving and not is_dead:
		bob_y = sin(walk_anim_timer * PI) * 2.5
	return global_position + Vector2(facing * 18.0, -118.0 + bob_y)

func _fire_gatling_bullet(player_node: Node2D) -> void:
	muzzle_flash_timer = 0.10
	var spawn_pos := get_muzzle_pos()
	var dir := Vector2(facing, 0.0)
	if player_node != null and is_instance_valid(player_node):
		var aim_vec := (player_node.global_position - spawn_pos).normalized()
		dir = aim_vec.rotated(randf_range(-0.08, 0.08))
	
	var parent_node = get_parent()
	if parent_node == null:
		return
	
	match Global.current_stage:
		2: # Aqua Assault Rig: Harpoon
			Global.play_sfx("shoot")
			var harpoon = EnemySpecialProjectile.new()
			harpoon.proj_type = EnemySpecialProjectile.ProjectileType.HARPOON
			harpoon.global_position = spawn_pos
			harpoon.velocity = dir * 370.0
			parent_node.add_child(harpoon)
			VFX.spawn_hit_sparks(spawn_pos, dir, Color(0.35, 0.90, 1.0))
		3: # Chitin Behemoth: Toxic Needle Dart Flurry
			Global.play_sfx("shoot")
			var dart = EnemySpecialProjectile.new()
			dart.proj_type = EnemySpecialProjectile.ProjectileType.NEEDLE_DART
			dart.global_position = spawn_pos
			dart.velocity = dir * 350.0
			parent_node.add_child(dart)
			VFX.spawn_hit_sparks(spawn_pos, dir, Color(0.8, 0.2, 0.6))
		5: # Vulcan Dreadnought: Superheated Industrial Rivets
			Global.play_sfx("shoot")
			var rivet = EnemySpecialProjectile.new()
			rivet.proj_type = EnemySpecialProjectile.ProjectileType.RIVET
			rivet.global_position = spawn_pos
			rivet.velocity = dir * 360.0
			parent_node.add_child(rivet)
			VFX.spawn_hit_sparks(spawn_pos, dir, Color(1.0, 0.5, 0.1))
		6: # Tesla Overlord: Spark Crossfire
			Global.play_sfx("shoot_laser")
			var spk = EnemySpecialProjectile.new()
			spk.proj_type = EnemySpecialProjectile.ProjectileType.SPARK_CROSS
			spk.global_position = spawn_pos
			spk.velocity = dir * 340.0
			parent_node.add_child(spk)
			VFX.spawn_hit_sparks(spawn_pos, dir, Color(0.3, 0.9, 1.0))
		8: # Psionic Leviathan: Psionic Needle Dart
			Global.play_sfx("shoot")
			var p_dart = EnemySpecialProjectile.new()
			p_dart.proj_type = EnemySpecialProjectile.ProjectileType.NEEDLE_DART
			p_dart.global_position = spawn_pos
			p_dart.velocity = dir * 360.0
			parent_node.add_child(p_dart)
			VFX.spawn_hit_sparks(spawn_pos, dir, Color(0.9, 0.3, 1.0))
		_: # Stages 1, 4, 7: Standard machine/autocannon/particle rounds
			if bullet_scene == null:
				return
			Global.play_sfx("shoot_machine")
			var b = bullet_scene.instantiate()
			b.bullet_owner = b.BulletOwner.ENEMY
			b.direction = dir
			b.speed = 360.0 if Global.current_stage >= 4 else 340.0
			b.global_position = spawn_pos
			parent_node.add_child(b)
			var spark_col := Color(0.4, 0.9, 1.0) if Global.current_stage == 7 else Color(1.0, 0.85, 0.3)
			VFX.spawn_hit_sparks(spawn_pos, dir, spark_col)

func _fire_shoulder_missiles(player_node: Node2D) -> void:
	Global.shake_screen(4.0, 0.2)
	var pod_pos := get_missile_pod_pos()
	var dust_col := Color(0.9, 0.8, 0.4)
	match Global.current_stage:
		2: dust_col = Color(0.40, 0.85, 1.0, 0.7)
		3: dust_col = Color(0.5, 0.9, 0.3, 0.7)
		4: dust_col = Color(0.7, 0.9, 1.0, 0.8)
		5: dust_col = Color(1.0, 0.5, 0.1, 0.8)
		6: dust_col = Color(0.4, 0.9, 1.0, 0.8)
		7: dust_col = Color(0.8, 0.4, 1.0, 0.8)
		8: dust_col = Color(0.9, 0.3, 0.9, 0.8)
	VFX.spawn_dust_puff(pod_pos, 4, dust_col)
	
	var target_x: float = global_position.x + facing * 200.0
	if player_node != null and is_instance_valid(player_node):
		target_x = player_node.global_position.x
	
	var parent_node = get_parent()
	if parent_node == null:
		return
	
	match Global.current_stage:
		2: # Depth Charge
			Global.play_sfx("shoot_spread")
			var dc = EnemySpecialProjectile.new()
			dc.proj_type = EnemySpecialProjectile.ProjectileType.DEPTH_CHARGE
			dc.global_position = pod_pos
			var dist_x: float = target_x - pod_pos.x + randf_range(-40.0, 40.0)
			dc.velocity = Vector2(clampf(dist_x * 0.9, -260.0, 260.0), -260.0)
			parent_node.add_child(dc)
		3: # Corrosive Acid Globs
			Global.play_sfx("shoot_spread")
			for i in range(2):
				var glob = EnemySpecialProjectile.new()
				glob.proj_type = EnemySpecialProjectile.ProjectileType.ACID_GLOB
				glob.global_position = pod_pos
				var dist_x: float = target_x - pod_pos.x + randf_range(-60.0, 60.0)
				glob.velocity = Vector2(clampf(dist_x * 0.8, -250.0, 250.0), -280.0 - float(i) * 50.0)
				parent_node.add_child(glob)
		4: # Cryogenic Ice Mortar
			Global.play_sfx("shoot_spread")
			var im = EnemySpecialProjectile.new()
			im.proj_type = EnemySpecialProjectile.ProjectileType.ICE_MORTAR
			im.global_position = pod_pos
			var dist_x: float = target_x - pod_pos.x + randf_range(-30.0, 30.0)
			im.velocity = Vector2(clampf(dist_x * 0.85, -280.0, 280.0), -300.0)
			parent_node.add_child(im)
		5: # Slag Shockwave along floor
			Global.play_sfx("explosion")
			Global.shake_screen(6.0, 0.25)
			var sw = EnemySpecialProjectile.new()
			sw.proj_type = EnemySpecialProjectile.ProjectileType.SLAG_WAVE
			sw.global_position = global_position + Vector2(facing * 30.0, -8.0)
			sw.velocity = Vector2(facing * 280.0, 0.0)
			parent_node.add_child(sw)
		6: # Homing Ball Lightning
			Global.play_sfx("shoot_laser")
			var bl = EnemySpecialProjectile.new()
			bl.proj_type = EnemySpecialProjectile.ProjectileType.BALL_LIGHTNING
			bl.global_position = pod_pos
			bl.velocity = Vector2(facing * 190.0, -90.0)
			parent_node.add_child(bl)
		7: # Dual Homing Micro-Missiles
			Global.play_sfx("shoot_spread")
			for i in range(2):
				var m = EnemySpecialProjectile.new()
				m.proj_type = EnemySpecialProjectile.ProjectileType.HOMING_MISSILE
				m.global_position = pod_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
				m.velocity = Vector2(randf_range(-80.0, 80.0), -260.0 - float(i) * 60.0)
				parent_node.add_child(m)
		8: # Expanding Psionic Energy Ring
			Global.play_sfx("shoot_laser")
			var ring = EnemySpecialProjectile.new()
			ring.proj_type = EnemySpecialProjectile.ProjectileType.PSYCHIC_RING
			ring.global_position = global_position + Vector2(facing * 40.0, -70.0)
			ring.velocity = Vector2(facing * 160.0, 0.0)
			parent_node.add_child(ring)
		_: # Stage 1: Lobbed Frag Grenades
			if grenade_scene == null:
				return
			Global.play_sfx("shoot_spread")
			for i in range(2):
				var g = grenade_scene.instantiate()
				g.global_position = pod_pos
				var dist_x: float = target_x - pod_pos.x + randf_range(-40.0, 40.0)
				var vx: float = clampf(dist_x * 0.9, -280.0, 280.0)
				var vy: float = -280.0 - float(i) * 50.0
				g.velocity = Vector2(vx, vy)
				parent_node.add_child(g)

func _execute_jet_leap(player_node: Node2D) -> void:
	is_on_ground = false
	vel_y = -380.0
	var leap_dir := 1.0 if global_position.x < (arena_min_x + arena_max_x) * 0.5 else -1.0
	vel_x = leap_dir * 120.0
	Global.play_sfx("shoot_laser")
	VFX.spawn_explosion(global_position + Vector2(0.0, -20.0), 0.7, false, false)

func _on_hurtbox_entered(area: Area2D) -> void:
	if is_dead or not is_active:
		return
	if area.is_in_group("bullet") or area.has_method("_handle_hit"):
		var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
		take_damage(dmg)
		if area.get("pierce_count") != null:
			area.pierce_count -= 1
			if area.pierce_count <= 0:
				area.queue_free()
		else:
			area.queue_free()

func take_damage(dmg: float = 1.0) -> void:
	if is_dead or not is_active:
		return
	current_health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	Global.boss_health_changed.emit(maxf(0.0, current_health), max_health)
	
	if current_health <= 0.0:
		_trigger_death()

func _trigger_death() -> void:
	is_dead = true
	var res_path := "res://resources/enemies/mini_boss_stage%d_data.tres" % Global.current_stage
	var res: EnemyData = load(res_path) if ResourceLoader.exists(res_path) else null
	var fallback_score: int = 6000 + (Global.current_stage - 1) * 2000
	var score_val: int = res.score_reward if res != null else fallback_score
	Global.add_score(score_val)
	Global.shake_screen(10.0, 0.5)
	death_explosions_left = 12
	death_chain_timer = 0.05
	
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	
	# Spawn powerup medal reward
	if powerup_scene != null:
		var p_item = powerup_scene.instantiate()
		p_item.global_position = global_position + Vector2(0.0, -70.0)
		p_item.weapon_type = Global.WeaponType.SPREAD if randf() < 0.6 else Global.WeaponType.LASER
		get_parent().call_deferred("add_child", p_item)
	
	Global.active_boss_name = ""
	Global.mini_boss_defeated.emit()

func _process_death(delta: float) -> void:
	death_chain_timer -= delta
	if death_chain_timer <= 0.0 and death_explosions_left > 0:
		death_chain_timer = 0.10
		death_explosions_left -= 1
		death_frame_index = clampi(int((12 - death_explosions_left) / 3), 0, 3)
		Global.shake_screen(7.0, 0.2)
		if explosion_scene != null:
			var exp_node = explosion_scene.instantiate()
			var rx := randf_range(-mech_width * 0.45, mech_width * 0.45)
			var ry := randf_range(-mech_height * 0.95, -10.0)
			exp_node.global_position = global_position + Vector2(rx, ry)
			get_parent().add_child(exp_node)
	elif death_explosions_left <= 0:
		# Final smoke puff and removal
		VFX.spawn_dust_puff(global_position + Vector2(0.0, -40.0), 6, Color(0.2, 0.2, 0.25, 0.8))
		queue_free()

func _draw() -> void:
	if current_state == State.INACTIVE:
		return
	
	# Current texture based on walk frame
	var current_tex: Texture2D = mech_texture
	if is_dead and death_textures.size() > 0:
		current_tex = death_textures[death_frame_index]
	elif walk_textures.size() > 0:
		if not is_on_ground:
			current_tex = walk_textures[1] # extended leap / air pose
		else:
			current_tex = walk_textures[walk_frame_index]
	
	# Hydraulic suspension bobbing during walk cycle
	var bob_y := 0.0
	var tilt_deg := 0.0
	if is_on_ground and is_moving and not is_dead:
		# Suspension dips on foot plant (frames 0 and 2), lifts on swing (frames 1 and 3)
		bob_y = sin(walk_anim_timer * PI) * 2.5
		tilt_deg = (walk_dir * facing) * 2.2 # subtle aggressive forward lean
	
	if current_tex != null:
		var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
		if is_dead:
			col = Color.WHITE if death_textures.size() > 0 else Color(0.4, 0.4, 0.45)
		
		var draw_w := mech_width
		var draw_h := mech_height
		
		if facing < 0.0:
			if abs(tilt_deg) > 0.1:
				draw_set_transform(Vector2(0.0, -draw_h * 0.5), deg_to_rad(tilt_deg), Vector2.ONE)
				draw_texture_rect(current_tex, Rect2(-draw_w * 0.5, -draw_h * 0.5 + bob_y, draw_w, draw_h), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_texture_rect(current_tex, Rect2(-draw_w * 0.5, -draw_h + bob_y, draw_w, draw_h), false, col)
		else:
			# Flipped horizontally
			if abs(tilt_deg) > 0.1:
				draw_set_transform(Vector2(0.0, -draw_h * 0.5), deg_to_rad(-tilt_deg), Vector2(-1.0, 1.0))
				draw_texture_rect(current_tex, Rect2(-draw_w * 0.5, -draw_h * 0.5 + bob_y, draw_w, draw_h), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
				draw_texture_rect(current_tex, Rect2(-draw_w * 0.5, -draw_h + bob_y, draw_w, draw_h), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))
	else:
		# Procedural fallback
		var b_col := Color(0.25, 0.32, 0.22)
		draw_rect(Rect2(-mech_width * 0.5, -mech_height + bob_y, mech_width, mech_height), b_col)
	
	# Muzzle flash spark effect at dynamic muzzle location
	if muzzle_flash_timer > 0.0:
		var muzzle_p := Vector2(facing * 52.0, -68.0 + bob_y)
		draw_circle(muzzle_p, 10.0, Color(1.0, 0.9, 0.4, 0.85))
		draw_circle(muzzle_p, 5.0, Color.WHITE)
		for i in range(4):
			var a := float(i) * (PI * 0.5) + anim_timer * 10.0
			draw_line(muzzle_p, muzzle_p + Vector2(cos(a) * 16.0, sin(a) * 16.0), Color(1.0, 0.5, 0.1), 2.0)
	
	# Jet thruster exhaust flame during leap
	if not is_on_ground and vel_y < 100.0:
		var jet_pos := Vector2(-facing * 24.0, -75.0)
		var flame_len := 18.0 + sin(anim_timer * 20.0) * 8.0
		var fl_col := Color(1.0, 0.4, 0.1)
		match Global.current_stage:
			2: fl_col = Color(0.2, 0.8, 1.0)
			3: fl_col = Color(0.4, 1.0, 0.3)
			4: fl_col = Color(0.5, 0.9, 1.0)
			5: fl_col = Color(1.0, 0.5, 0.1)
			6: fl_col = Color(0.3, 0.9, 1.0)
			7: fl_col = Color(0.3, 0.8, 1.0)
			8: fl_col = Color(0.9, 0.2, 1.0)
		draw_line(jet_pos, jet_pos + Vector2(-facing * flame_len, 12.0), fl_col, 4.5)
		draw_line(jet_pos, jet_pos + Vector2(-facing * (flame_len * 0.6), 8.0), Color.WHITE, 2.5)
