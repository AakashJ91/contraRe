extends Node2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/alien_core_data.tres")

var max_health: float = 35.0
var current_health: float = 35.0
var is_active: bool = false
var is_dead: bool = false

var core_flash_timer: float = 0.0
var attack_timer_1: float = 1.6
var attack_timer_2: float = 2.4
var attack_timer_3: float = 4.2
var heavy_bullet_timer: float = 2.0
var is_enraged: bool = false
var enrage_threshold: float = 0.5
var enrage_flash_timer: float = 0.0
var core_pulse: float = 0.0
var anim_timer: float = 0.0

var death_chain_timer: float = 0.0
var death_explosions_left: int = 16

@onready var core_area: Area2D = $CoreArea
@onready var left_cannon: Area2D = $LeftCannon
@onready var right_cannon: Area2D = $RightCannon
@onready var solid_barrier: StaticBody2D = get_node_or_null("SolidBarrier")

var left_part_hp: float = 12.0
var right_part_hp: float = 12.0
var boss_texture: Texture2D = null
var core_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var death_frame_index: int = 0
var muzzle_flash_left: float = 0.0
var muzzle_flash_right: float = 0.0
var muzzle_flash_top: float = 0.0
var fire_textures: Array[Texture2D] = []
var fire_anim_timer: float = 0.0

# Stage 2 Hydro-Goliath Walking & Turbine Animation State
var walk_textures: Array[Texture2D] = []
var idle_textures: Array[Texture2D] = []
var boss_texture_red: Texture2D = null
var boss_texture_hg: Texture2D = null
var standing_textures: Array[Texture2D] = []
var is_standing_vulnerable: bool = false
var goliath_state_timer: float = 4.5
var standing_anim_timer: float = 0.0
var walk_frame_index: int = 0
var walk_anim_timer: float = 0.0
var walk_cycle_speed: float = 4.5
var walk_dir: float = -1.0 # -1.0 = forward (towards player / left), 1.0 = backward (retreating / right)
var walk_timer: float = 2.5
var walk_speed: float = 46.0
var arena_min_x: float = 8890.0
var arena_max_x: float = 9240.0
var is_walking: bool = false
var step_sound_cooldown: float = 0.0

var mg_burst_active: bool = false
var mg_burst_gun: int = 0 # 0: Mid-Left, 1: Top-Left, 2: Top-Right
var mg_burst_count: int = 0
var mg_burst_timer: float = 0.0

var recoil_mid: float = 0.0
var recoil_tl: float = 0.0
var recoil_tr: float = 0.0
var heat_mid: float = 0.0
var heat_tl: float = 0.0
var heat_tr: float = 0.0

var shell_casings: Array[Dictionary] = []

static var s_fire_textures: Array[Texture2D] = []
static var s_boss_cache: Dictionary = {}
static func get_cached_boss_tex(path: String) -> Texture2D:
	if s_boss_cache.has(path):
		return s_boss_cache[path]
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		s_boss_cache[path] = t
		return t
	return null

func _ready() -> void:
	if s_fire_textures.is_empty():
		for i in range(15):
			var fp := "res://assets/vfx/effect/fire/frame_%d.png" % i
			if ResourceLoader.exists(fp):
				s_fire_textures.append(load(fp))
	fire_textures = s_fire_textures
	
	_init_boss_stats()
	_setup_solid_barrier()
	Global.boss_health_changed.emit(current_health, max_health)
	core_area.area_entered.connect(_on_core_hit)
	left_cannon.area_entered.connect(_on_left_part_hit)
	right_cannon.area_entered.connect(_on_right_part_hit)
	if Global.current_stage == 1:
		core_textures.clear()
		for i in range(4):
			var cp := "res://assets/enemies/boss_fortress/movement/core_%d.png" % i
			var ct := get_cached_boss_tex(cp)
			if ct != null:
				core_textures.append(ct)
		
		death_textures.clear()
		for i in range(4):
			var dp := "res://assets/enemies/boss_fortress/death/destroy_%d.png" % i
			var dt := get_cached_boss_tex(dp)
			if dt != null:
				death_textures.append(dt)
		
		var b_tex := get_cached_boss_tex("res://assets/enemies/boss_fortress/boss_fortress.png")
		if b_tex == null:
			b_tex = get_cached_boss_tex("res://assets/enemies/boss_fortress.png")
		if b_tex == null:
			b_tex = get_cached_boss_tex("res://assets/enemies/boss_wall.png")
		boss_texture = b_tex
	elif Global.current_stage == 2:
		walk_textures.clear()
		for i in range(4):
			var wp := "res://assets/enemies/boss_hydro_goliath/movement/walk_%d.png" % i
			if ResourceLoader.exists(wp):
				walk_textures.append(load(wp))
		
		standing_textures.clear()
		if ResourceLoader.exists("res://assets/enemies/boss_hydro_goliath/boss_hydro_goliath.png"):
			boss_texture = load("res://assets/enemies/boss_hydro_goliath/boss_hydro_goliath.png")
			standing_textures.append(boss_texture)
		
		var red_p := "res://assets/enemies/boss_hydro_goliath/boss_hydro_goliath_red.png"
		if ResourceLoader.exists(red_p):
			boss_texture_red = load(red_p)
			standing_textures.append(boss_texture_red)
		
		var hg_p := "res://assets/enemies/boss_hydro_goliath/hg.png"
		if ResourceLoader.exists(hg_p):
			boss_texture_hg = load(hg_p)
			standing_textures.append(boss_texture_hg)
		
		death_textures.clear()
		for i in range(4):
			var dp := "res://assets/enemies/boss_hydro_goliath/death/destroy_%d.png" % i
			if ResourceLoader.exists(dp):
				death_textures.append(load(dp))
		
		left_cannon.position = Vector2(-110.0, -5.0)
		right_cannon.position = Vector2(65.0, -45.0)
		arena_min_x = 8890.0
		arena_max_x = 9240.0
		walk_dir = -1.0
		is_standing_vulnerable = false
		goliath_state_timer = 4.5
	elif Global.current_stage in [3, 4, 5, 6, 7, 8]:
		var stage_folder_map := {
			3: "boss_bio_heart",
			4: "boss_siege_tank",
			5: "boss_magma_forge",
			6: "boss_thunder_dynamo",
			7: "boss_star_cruiser",
			8: "boss_mother_brain"
		}
		var f_name: String = stage_folder_map.get(Global.current_stage, "")
		if f_name != "":
			var base_p := "res://assets/enemies/%s/%s.png" % [f_name, f_name]
			if ResourceLoader.exists(base_p):
				boss_texture = load(base_p)
			
			core_textures.clear()
			for i in range(4):
				var mp := "res://assets/enemies/%s/movement/frame_%d.png" % [f_name, i]
				if ResourceLoader.exists(mp):
					core_textures.append(load(mp))
			
			death_textures.clear()
			for i in range(4):
				var dp := "res://assets/enemies/%s/death/destroy_%d.png" % [f_name, i]
				if ResourceLoader.exists(dp):
					death_textures.append(load(dp))
		
		match Global.current_stage:
			3:
				left_cannon.position = Vector2(-75.0, -20.0)
				right_cannon.position = Vector2(75.0, -20.0)
			4:
				left_cannon.position = Vector2(-70.0, -40.0)
				right_cannon.position = Vector2(50.0, -65.0)
			5:
				left_cannon.position = Vector2(-80.0, 10.0)
				right_cannon.position = Vector2(80.0, 10.0)
			6:
				left_cannon.position = Vector2(-80.0, -10.0)
				right_cannon.position = Vector2(80.0, -10.0)
			7:
				left_cannon.position = Vector2(-120.0, -10.0)
				right_cannon.position = Vector2(-30.0, -40.0)
			8:
				left_cannon.position = Vector2(-80.0, 40.0)
				right_cannon.position = Vector2(80.0, 40.0)
	queue_redraw()

func _get_boss_resource() -> EnemyData:
	var path_map := {
		1: "res://resources/enemies/alien_core_data.tres",
		2: "res://resources/enemies/hydro_goliath_data.tres",
		3: "res://resources/enemies/bio_heart_data.tres",
		4: "res://resources/enemies/siege_tank_data.tres",
		5: "res://resources/enemies/magma_forge_data.tres",
		6: "res://resources/enemies/thunder_dynamo_data.tres",
		7: "res://resources/enemies/star_cruiser_data.tres",
		8: "res://resources/enemies/mother_brain_data.tres"
	}
	var res_path: String = path_map.get(Global.current_stage, "")
	if res_path != "" and ResourceLoader.exists(res_path):
		return load(res_path) as EnemyData
	return enemy_data

func _init_boss_stats() -> void:
	var res := _get_boss_resource()
	var default_hp := 35.0 + float(Global.current_stage - 1) * 3.5
	max_health = res.max_health if res != null else default_hp

	match Global.current_stage:
		1:
			left_part_hp = 12.0
			right_part_hp = 12.0
		2:
			left_part_hp = 14.0
			right_part_hp = 14.0
		3:
			left_part_hp = 14.0
			right_part_hp = 14.0
		4:
			left_part_hp = 15.0
			right_part_hp = 15.0
		5:
			left_part_hp = 16.0
			right_part_hp = 16.0
		6:
			left_part_hp = 18.0
			right_part_hp = 18.0
		7:
			left_part_hp = 20.0
			right_part_hp = 20.0
		8:
			left_part_hp = 22.0
			right_part_hp = 22.0
	current_health = max_health

func _setup_solid_barrier() -> void:
	if solid_barrier == null:
		solid_barrier = get_node_or_null("SolidBarrier")
	if solid_barrier == null:
		solid_barrier = StaticBody2D.new()
		solid_barrier.name = "SolidBarrier"
		solid_barrier.collision_layer = 2 # Layer 2: World
		solid_barrier.collision_mask = 0
		var col := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(320.0, 1000.0)
		col.shape = rect_shape
		col.position = Vector2(90.0, -100.0)
		solid_barrier.add_child(col)
		add_child(solid_barrier)

func activate() -> void:
	if not is_active and not is_dead:
		is_active = true
		Global.active_boss_name = "MAIN BOSS: " + Global.get_boss_name(Global.current_stage)
		Global.play_sfx("boss_alarm")
		Global.shake_screen(8.0, 0.45)
		Global.boss_health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	core_pulse += delta * 6.0
	anim_timer += delta
	fire_anim_timer += delta * 15.0
	
	if is_dead:
		_process_death_sequence(delta)
		queue_redraw()
		return
	
	if not is_active:
		if Global.is_boss_cutscene_active:
			core_pulse += delta * 12.0
			if fmod(anim_timer * 8.0, 1.0) < 0.25:
				core_flash_timer = 0.08
				recoil_mid = 1.5
				recoil_tl = 1.5
				recoil_tr = 1.5
			queue_redraw()
		return
	
	if core_flash_timer > 0.0:
		core_flash_timer -= delta
	if muzzle_flash_left > 0.0:
		muzzle_flash_left -= delta
	if muzzle_flash_right > 0.0:
		muzzle_flash_right -= delta
	if muzzle_flash_top > 0.0:
		muzzle_flash_top -= delta
	
	# Machinegun dynamic recoil recovery
	recoil_mid = maxf(0.0, recoil_mid - delta * 30.0)
	recoil_tl = maxf(0.0, recoil_tl - delta * 30.0)
	recoil_tr = maxf(0.0, recoil_tr - delta * 30.0)
	
	# Machinegun barrel heat cooldown
	heat_mid = maxf(0.0, heat_mid - delta * 0.75)
	heat_tl = maxf(0.0, heat_tl - delta * 0.75)
	heat_tr = maxf(0.0, heat_tr - delta * 0.75)
	
	# Process active machinegun burst sequence
	if mg_burst_active:
		mg_burst_timer -= delta
		if mg_burst_timer <= 0.0:
			mg_burst_timer = 0.09 # 90ms cadence between shots
			_fire_next_machinegun_shot()
	
	# Update spent shell casings physics
	var sc_idx := shell_casings.size() - 1
	while sc_idx >= 0:
		var sc: Dictionary = shell_casings[sc_idx]
		sc["lifetime"] -= delta
		if sc["lifetime"] <= 0.0:
			shell_casings.remove_at(sc_idx)
		else:
			sc["vel"].y += 650.0 * delta # gravity
			sc["pos"] += sc["vel"] * delta
			sc["rot"] += sc["rot_speed"] * delta
		sc_idx -= 1
	
	# Walking Movement AI (Stage 2: Hydro-Goliath Mech)
	if Global.current_stage == 2 and not is_dead and is_active:
		_process_hydro_goliath_movement(delta)
	
	if enrage_flash_timer > 0.0:
		enrage_flash_timer -= delta
	
	var rate_mult: float = 0.75 if is_enraged else 1.0
	
	# Attack Pattern 1: Primary side weapons
	attack_timer_1 -= delta
	if attack_timer_1 <= 0.0:
		var interval_1 := (2.2 - float(Global.current_stage) * 0.1) * rate_mult
		attack_timer_1 = maxf(0.9, interval_1)
		_execute_attack_1()
	
	# Attack Pattern 2: Secondary / Core heavy weapon
	attack_timer_2 -= delta
	if attack_timer_2 <= 0.0:
		var interval_2 := (2.6 - float(Global.current_stage) * 0.12) * rate_mult
		attack_timer_2 = maxf(1.1, interval_2)
		_execute_attack_2()
	
	# Attack Pattern 3: Specialized stage tactical weapon
	attack_timer_3 -= delta
	if attack_timer_3 <= 0.0:
		var interval_3 := (4.2 - float(Global.current_stage) * 0.18) * rate_mult
		attack_timer_3 = maxf(2.0, interval_3)
		_execute_attack_3()
	
	# Random Boss Heavy Energy Orbs / Slow Big Bullets
	heavy_bullet_timer -= delta
	if heavy_bullet_timer <= 0.0:
		var base_interval := 3.2 if is_enraged else 4.6
		heavy_bullet_timer = randf_range(base_interval * 0.8, base_interval * 1.25)
		_fire_random_heavy_bullet()
	
	queue_redraw()

func _process_hydro_goliath_movement(delta: float) -> void:
	if step_sound_cooldown > 0.0:
		step_sound_cooldown -= delta
	
	# Pacing state machine: alternate between Walking (armored) and Standing Still (vulnerable overheat)
	goliath_state_timer -= delta
	if goliath_state_timer <= 0.0:
		if is_standing_vulnerable:
			# Finished standing overheat state -> resume walking forward/backward
			is_standing_vulnerable = false
			goliath_state_timer = randf_range(4.0, 5.5)
			if global_position.x <= arena_min_x + 90.0:
				walk_dir = 1.0
			elif global_position.x >= arena_max_x - 50.0:
				walk_dir = -1.0
			else:
				walk_dir = -1.0 if randf() < 0.65 else 1.0
			walk_timer = randf_range(2.0, 3.5)
		else:
			# Finished walking -> stop still and enter vulnerable overheat state
			is_standing_vulnerable = true
			goliath_state_timer = randf_range(3.2, 4.2)
			standing_anim_timer = 0.0
			Global.play_sfx("boss_alarm")
			VFX.spawn_dust_puff(global_position + Vector2(0.0, 20.0), 8, Color(0.9, 0.4, 0.3, 0.75))

	if is_standing_vulnerable:
		# Standing still: stop movement and increment standing animation timer
		is_walking = false
		walk_frame_index = 0
		standing_anim_timer += delta
		return

	# If currently executing an attack or recovering from a shot, briefly pause walking to brace
	var is_bracing: bool = (muzzle_flash_left > 0.0 or muzzle_flash_right > 0.0)
	
	# Dynamic movement pacing while walking
	walk_timer -= delta
	if walk_timer <= 0.0:
		if walk_dir < 0.0:
			# If advancing toward player, after a while either halt to fire or retreat
			if randf() < 0.65 and global_position.x <= arena_min_x + 90.0:
				walk_dir = 1.0 # Retreat backward
				walk_timer = randf_range(2.0, 3.5)
			else:
				walk_timer = randf_range(1.5, 2.5)
		else:
			# If retreating, after reaching rear threshold, advance forward
			if global_position.x >= arena_max_x - 50.0 or randf() < 0.7:
				walk_dir = -1.0 # Advance forward
				walk_timer = randf_range(2.5, 4.0)
			else:
				walk_timer = randf_range(1.5, 2.5)

	# Arena boundary constraints
	if global_position.x <= arena_min_x:
		global_position.x = arena_min_x
		walk_dir = 1.0 # Push back
		walk_timer = randf_range(2.0, 3.2)
	elif global_position.x >= arena_max_x:
		global_position.x = arena_max_x
		walk_dir = -1.0 # Push forward
		walk_timer = randf_range(2.5, 3.8)

	var cur_speed: float = walk_speed if not is_bracing else 0.0
	var vel_x: float = walk_dir * cur_speed
	global_position.x += vel_x * delta
	global_position.x = clampf(global_position.x, arena_min_x, arena_max_x)
	is_walking = abs(vel_x) > 1.0

	if is_walking:
		var prev_frame := walk_frame_index
		if walk_dir < 0.0:
			# Forward stride
			walk_anim_timer += delta * walk_cycle_speed
			walk_frame_index = int(walk_anim_timer) % 4
		else:
			# Backward stride (reverse cycle)
			walk_anim_timer -= delta * walk_cycle_speed
			walk_frame_index = posmod(int(floor(walk_anim_timer)), 4)

		# Trigger foot stomp sound and terrain dust when switching to stance contact frames (0 or 2)
		if walk_frame_index != prev_frame and (walk_frame_index == 0 or walk_frame_index == 2):
			if step_sound_cooldown <= 0.0:
				step_sound_cooldown = 0.22
				Global.play_sfx("hit")
				Global.shake_screen(2.2, 0.08)
			var foot_x := -95.0 if walk_frame_index == 0 else 75.0
			var foot_world_pos := global_position + Vector2(foot_x, 105.0)
			VFX.spawn_dust_puff(foot_world_pos, 4, Color(0.65, 0.78, 0.88, 0.7))
	else:
		walk_frame_index = 0

func _execute_attack_1() -> void:
	if bullet_scene == null:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	
	match Global.current_stage:
		1: # Multi-gatling machinegun salvo
			_trigger_stage1_machinegun_burst(player_node)
		2: # Triple hydro spray
			_fire_spread_cannons(player_node, 270.0, 3)
		3: # Toxic bio-needle bursts
			_fire_spread_cannons(player_node, 260.0, 3)
		4: # Frost gatling bursts
			_fire_straight_cannons(player_node, 288.0)
		5: # Dual flamethrower jets
			_fire_spread_cannons(player_node, 243.0, 4)
		6: # High-voltage electric spark waves
			_fire_spread_cannons(player_node, 288.0, 4)
		7: # Twin plasma blasters
			_fire_straight_cannons(player_node, 306.0)
		8: # Optic drone dual laser streams
			_fire_spread_cannons(player_node, 297.0, 5)

func _trigger_stage1_machinegun_burst(player_node: Node2D) -> void:
	if is_dead:
		return
	
	var available_guns: Array[int] = []
	if left_part_hp > 0.0:
		available_guns.append(0) # Mid-Left Gatling
	if right_part_hp > 0.0:
		available_guns.append(1) # Top-Left Gatling
	
	# If both are destroyed or as an occasional heavy barrage, Top-Right Gun also fires
	if available_guns.size() == 0 or randf() < 0.35:
		available_guns.append(2) # Top-Right Gatling
	
	if available_guns.size() == 0:
		return
	
	var chosen_gun: int = available_guns[randi() % available_guns.size()]
	mg_burst_gun = chosen_gun
	mg_burst_count = randi_range(3, 4) # 3-4 round burst!
	mg_burst_active = true
	mg_burst_timer = 0.0 # Fire first shot immediately

func _fire_next_machinegun_shot() -> void:
	if is_dead or mg_burst_count <= 0:
		mg_burst_active = false
		return
	
	mg_burst_count -= 1
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var player_pos: Vector2 = player_node.global_position if (player_node != null and is_instance_valid(player_node)) else (global_position + Vector2(-300.0, 50.0))
	
	var muzzle_offset: Vector2 = Vector2.ZERO
	var shell_port: Vector2 = Vector2.ZERO
	var bullet_speed: float = 288.0
	
	match mg_burst_gun:
		0: # Middle-Left Lower Gatling
			if left_part_hp <= 0.0:
				mg_burst_active = false
				return
			muzzle_offset = Vector2(-161.0, 25.0)
			shell_port = Vector2(-100.0, 16.0)
			recoil_mid = 5.0
			heat_mid = minf(1.0, heat_mid + 0.35)
			muzzle_flash_left = 0.10
			bullet_speed = 288.0
		1: # Top-Left Upper Gatling
			if right_part_hp <= 0.0:
				mg_burst_active = false
				return
			muzzle_offset = Vector2(-116.0, -95.0)
			shell_port = Vector2(-68.0, -98.0)
			recoil_tl = 5.0
			heat_tl = minf(1.0, heat_tl + 0.35)
			muzzle_flash_top = 0.10
			bullet_speed = 270.0
		2: # Top-Right Upper Gatling
			muzzle_offset = Vector2(-2.0, -85.0)
			shell_port = Vector2(65.0, -98.0)
			recoil_tr = 5.0
			heat_tr = minf(1.0, heat_tr + 0.35)
			muzzle_flash_right = 0.10
			bullet_speed = 297.0
	
	var spawn_pos: Vector2 = global_position + muzzle_offset
	var aim_dir: Vector2 = (player_pos - spawn_pos).normalized()
	# Slight authentic spread dispersion
	var dispersion: float = randf_range(-0.06, 0.06)
	var final_dir: Vector2 = aim_dir.rotated(dispersion)
	
	_spawn_bullet(spawn_pos, final_dir, bullet_speed)
	Global.play_sfx("shoot")
	Global.shake_screen(2.0, 0.08)
	
	# Spawn ejecting brass shell casing
	var shell := {
		"pos": global_position + shell_port,
		"vel": Vector2(randf_range(50.0, 110.0), randf_range(-140.0, -220.0)),
		"rot": randf_range(0.0, TAU),
		"rot_speed": randf_range(12.0, 24.0),
		"lifetime": 0.75
	}
	shell_casings.append(shell)
	
	if mg_burst_count <= 0:
		mg_burst_active = false

func _execute_attack_2() -> void:
	if bullet_scene == null:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	
	var dir: Vector2 = (player_node.global_position - (global_position + Vector2(0.0, -45.0))).normalized()
	
	match Global.current_stage:
		1: # Top bunker twin rocket hatch
			muzzle_flash_top = 0.16
			for angle in [-0.22, 0.22]:
				var rocket_spawn := global_position + Vector2(-30.0, -35.0) if angle < 0 else global_position + Vector2(30.0, -35.0)
				_spawn_bullet(rocket_spawn, dir.rotated(angle), 260.0)
		2: # Core hydro-plasma surge
			for angle in [-0.30, 0.0, 0.30]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 280.0)
		3: # Bio-heart toxic spore cluster
			for angle in [-0.35, -0.12, 0.12, 0.35]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 250.0)
		4: # High-trajectory freeze mortar shell
			_spawn_bullet(global_position + Vector2(0.0, -60.0), Vector2(-0.7, -0.7).normalized(), 295.0)
			_spawn_bullet(global_position + Vector2(0.0, -60.0), dir, 270.0)
		5: # Magma slag volcanic eruption
			for angle in [-0.4, -0.15, 0.15, 0.4]:
				_spawn_bullet(global_position + Vector2(0.0, -40.0), dir.rotated(angle), 260.0)
		6: # Rotating electrostatic laser arc
			for angle in [-0.45, -0.22, 0.0, 0.22, 0.45]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 288.0)
		7: # Cluster micro-missiles
			for i in range(4):
				var offset_ang := (float(i) - 1.5) * 0.18
				_spawn_bullet(global_position + Vector2(0.0, -35.0), dir.rotated(offset_ang), 306.0)
		8: # Mother Brain 5-way psychic wave spread
			for angle in [-0.55, -0.28, 0.0, 0.28, 0.55]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 297.0)

func _execute_attack_3() -> void:
	if is_dead:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var parent_node = get_parent()
	if parent_node == null:
		return
	
	var p_x: float = player_node.global_position.x
	var dir_to_p: Vector2 = (player_node.global_position - (global_position + Vector2(0.0, -20.0))).normalized()
	
	match Global.current_stage:
		1: # Stage 1 Wall Fortress: Top Artillery Mortar & Flak Airburst
			muzzle_flash_top = 0.22
			Global.play_sfx("shoot_spread")
			Global.shake_screen(5.0, 0.22)
			var shell = EnemySpecialProjectile.new()
			shell.proj_type = EnemySpecialProjectile.ProjectileType.ARTILLERY_SHELL
			shell.global_position = global_position + Vector2(0.0, -85.0)
			var dist_x: float = p_x - (global_position.x)
			shell.velocity = Vector2(clampf(dist_x * 0.85, -340.0, 340.0), -360.0)
			parent_node.add_child(shell)
			if is_enraged:
				for ang in [-0.35, 0.35]:
					_spawn_bullet(global_position + Vector2(0.0, -40.0), dir_to_p.rotated(ang), 280.0)
		2: # Stage 2 Hydro-Goliath: High-Pressure Hydro Cutter Beam & Swimming Torpedoes
			Global.play_sfx("shoot_laser")
			Global.shake_screen(4.0, 0.2)
			for i in range(2):
				var cutter = EnemySpecialProjectile.new()
				cutter.proj_type = EnemySpecialProjectile.ProjectileType.HYDRO_CUTTER
				cutter.global_position = global_position + Vector2(-110.0, -25.0)
				cutter.velocity = dir_to_p.rotated(float(i) * 0.12 - 0.06) * 440.0
				parent_node.add_child(cutter)
			var torp = EnemySpecialProjectile.new()
			torp.proj_type = EnemySpecialProjectile.ProjectileType.WATER_TORPEDO
			torp.global_position = global_position + Vector2(-90.0, 80.0)
			torp.velocity = Vector2(-280.0, 0.0)
			parent_node.add_child(torp)
		3: # Stage 3 Bio-Heart: Sinusoidal Spore Wave & Chitin Spine Nova
			Global.play_sfx("shoot_spread")
			Global.shake_screen(5.0, 0.2)
			for i in range(8):
				var ang := float(i) * (TAU / 8.0)
				var spine = EnemySpecialProjectile.new()
				spine.proj_type = EnemySpecialProjectile.ProjectileType.CHITIN_SPINE
				spine.global_position = global_position + Vector2(0.0, 8.0)
				spine.velocity = Vector2(cos(ang), sin(ang)) * 260.0
				parent_node.add_child(spine)
			for i in range(2):
				var glob = EnemySpecialProjectile.new()
				glob.proj_type = EnemySpecialProjectile.ProjectileType.ACID_GLOB
				glob.global_position = global_position + Vector2(-40.0 + float(i) * 80.0, 0.0)
				glob.velocity = Vector2(-180.0 - float(i) * 60.0, -260.0)
				parent_node.add_child(glob)
		4: # Stage 4 Polar Siege Tank: Sub-Zero Cryo Beam Lance & Rolling Frost Mines
			Global.play_sfx("shoot_laser")
			Global.shake_screen(5.0, 0.25)
			for i in range(2):
				var beam = EnemySpecialProjectile.new()
				beam.proj_type = EnemySpecialProjectile.ProjectileType.CRYO_BEAM
				beam.global_position = global_position + Vector2(-70.0, -40.0)
				beam.velocity = dir_to_p.rotated(float(i) * 0.08 - 0.04) * 450.0
				parent_node.add_child(beam)
			var mine = EnemySpecialProjectile.new()
			mine.proj_type = EnemySpecialProjectile.ProjectileType.FROST_MINE
			mine.global_position = global_position + Vector2(-60.0, 10.0)
			mine.velocity = Vector2(-210.0, -100.0)
			parent_node.add_child(mine)
		5: # Stage 5 Magma Forge: Rolling Molten Fire Wheels & Magma Bomb
			Global.play_sfx("shoot")
			for i in range(2):
				var wheel = EnemySpecialProjectile.new()
				wheel.proj_type = EnemySpecialProjectile.ProjectileType.FIRE_WHEEL
				wheel.global_position = global_position + Vector2(-60.0, 20.0)
				wheel.velocity = Vector2(-220.0 - float(i) * 80.0, 0.0)
				parent_node.add_child(wheel)
			Global.play_sfx("shoot_spread")
			var bomb = EnemySpecialProjectile.new()
			bomb.proj_type = EnemySpecialProjectile.ProjectileType.MAGMA_BOMB
			bomb.global_position = global_position + Vector2(0.0, -50.0)
			var dist_x: float = p_x - global_position.x
			bomb.velocity = Vector2(clampf(dist_x * 0.85, -290.0, 290.0), -340.0)
			parent_node.add_child(bomb)
		6: # Stage 6 Thunder Dynamo: Lightning Sky Storm & Electric Ring Nova
			Global.play_sfx("shoot_laser")
			Global.shake_screen(6.0, 0.25)
			for offset in [-60.0, 60.0]:
				var strike = EnemySpecialProjectile.new()
				strike.proj_type = EnemySpecialProjectile.ProjectileType.LIGHTNING_STRIKE
				strike.global_position = Vector2(p_x + offset, 440.0)
				strike.velocity = Vector2.ZERO
				parent_node.add_child(strike)
			var ring = EnemySpecialProjectile.new()
			ring.proj_type = EnemySpecialProjectile.ProjectileType.ELECTRIC_RING
			ring.global_position = global_position + Vector2(0.0, 8.0)
			ring.velocity = Vector2(-150.0, 0.0)
			parent_node.add_child(ring)
		7: # Stage 7 Star Cruiser: Twin Orbital Laser Sweeps & Plasma Drone
			Global.play_sfx("shoot_laser")
			Global.shake_screen(6.0, 0.3)
			for off_x in [-80.0, 80.0]:
				var beam = EnemySpecialProjectile.new()
				beam.proj_type = EnemySpecialProjectile.ProjectileType.ORBITAL_BEAM
				beam.global_position = Vector2(p_x + off_x, 270.0)
				beam.velocity = Vector2.ZERO
				parent_node.add_child(beam)
			var drone = EnemySpecialProjectile.new()
			drone.proj_type = EnemySpecialProjectile.ProjectileType.PLASMA_DRONE
			drone.global_position = global_position + Vector2(-60.0, -40.0)
			drone.velocity = Vector2(-180.0, -90.0)
			parent_node.add_child(drone)
		8: # Stage 8 Mother Brain: Void Spiral Vortex & Mind Blast Pillar
			Global.play_sfx("shoot_laser")
			Global.shake_screen(7.0, 0.35)
			for i in range(8):
				var ang := float(i) * (TAU / 8.0) + anim_timer * 4.0
				var orb = EnemySpecialProjectile.new()
				orb.proj_type = EnemySpecialProjectile.ProjectileType.VOID_ORB
				orb.global_position = global_position + Vector2(0.0, 8.0)
				orb.velocity = Vector2(cos(ang), sin(ang)) * 180.0
				parent_node.add_child(orb)
			var pillar = EnemySpecialProjectile.new()
			pillar.proj_type = EnemySpecialProjectile.ProjectileType.MIND_PILLAR
			pillar.global_position = Vector2(p_x, 440.0)
			pillar.velocity = Vector2.ZERO
			parent_node.add_child(pillar)

func _fire_straight_cannons(player_node: Node2D, spd: float) -> void:
	if left_part_hp > 0.0:
		muzzle_flash_left = 0.12
		var p1 := global_position + Vector2(-60.0, 40.0)
		var d1 := (player_node.global_position - p1).normalized()
		_spawn_bullet(p1, d1, spd)
	if right_part_hp > 0.0:
		muzzle_flash_right = 0.12
		var p2 := global_position + Vector2(60.0, 40.0)
		var d2 := (player_node.global_position - p2).normalized()
		_spawn_bullet(p2, d2, spd)

func _fire_spread_cannons(player_node: Node2D, spd: float, count: int) -> void:
	var mid := float(count - 1) * 0.5
	if left_part_hp > 0.0:
		muzzle_flash_left = 0.12
		var p1 := global_position + (Vector2(-110.0, -5.0) if Global.current_stage == 2 else Vector2(-60.0, 40.0))
		var d1 := (player_node.global_position - p1).normalized()
		for i in range(count):
			var ang := (float(i) - mid) * 0.16
			_spawn_bullet(p1, d1.rotated(ang), spd)
	if right_part_hp > 0.0:
		muzzle_flash_right = 0.12
		var p2 := global_position + (Vector2(65.0, -45.0) if Global.current_stage == 2 else Vector2(60.0, 40.0))
		var d2 := (player_node.global_position - p2).normalized()
		for i in range(count):
			var ang := (float(i) - mid) * 0.16
			_spawn_bullet(p2, d2.rotated(ang), spd)

func _spawn_bullet(start_pos: Vector2, dir: Vector2, spd: float) -> void:
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.speed = spd
	b.global_position = start_pos + dir * 16.0
	get_parent().add_child(b)

func _spawn_heavy_bullet(start_pos: Vector2, dir: Vector2, spd: float = 117.0) -> void:
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.is_boss_heavy = true
	b.direction = dir
	b.speed = spd
	b.damage = 1.0
	b.global_position = start_pos + dir * 22.0
	get_parent().add_child(b)

func _fire_random_heavy_bullet() -> void:
	if is_dead or not is_active:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var player_pos: Vector2 = player_node.global_position if (player_node != null and is_instance_valid(player_node)) else (global_position + Vector2(-300.0, 30.0))
	
	var spawn_pos: Vector2 = global_position
	match Global.current_stage:
		1:
			# Stage 1 Wall Fortress: alternates between central alien core and upper heavy turret hatch
			if randf() < 0.55:
				spawn_pos = global_position + Vector2(-60.0, -10.0)
				core_flash_timer = 0.22
			else:
				spawn_pos = global_position + Vector2(-30.0, -80.0)
				muzzle_flash_top = 0.22
		2:
			# Stage 2 Hydro Goliath: Chest turbine or left heavy arm
			spawn_pos = global_position + (Vector2(-80.0, 10.0) if randf() < 0.6 else Vector2(-110.0, -25.0))
			muzzle_flash_left = 0.22
		_:
			spawn_pos = global_position + Vector2(-40.0, 0.0)
			core_flash_timer = 0.22
	
	var to_player := (player_pos - spawn_pos).normalized()
	# Slow speed between 103 and 130 px/s (10% slower)
	var slow_spd := randf_range(103.0, 130.0)
	
	# Randomize attack flavor:
	# 70% single heavy aimed shot with slight dispersion
	# 30% dual angled heavy salvo
	var pattern_roll := randf()
	if pattern_roll < 0.70 or not is_enraged:
		var disp := randf_range(-0.16, 0.16)
		_spawn_heavy_bullet(spawn_pos, to_player.rotated(disp), slow_spd)
	else:
		# Dual heavy spread
		for angle in [-0.22, 0.22]:
			_spawn_heavy_bullet(spawn_pos, to_player.rotated(angle), slow_spd)
	
	Global.play_sfx("shoot_spread")
	Global.shake_screen(3.5, 0.14)
	if has_node("/root/VFX"):
		VFX.spawn_hit_sparks(spawn_pos, to_player, Color(1.0, 0.55, 0.2))

func _on_core_hit(area: Area2D) -> void:
	if is_dead:
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

func _on_left_part_hit(area: Area2D) -> void:
	if left_part_hp <= 0.0:
		return
	var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
	var actual_dmg := dmg
	if Global.current_stage == 2:
		if is_standing_vulnerable:
			actual_dmg = dmg * 2.5
		else:
			actual_dmg = maxf(0.2, dmg * 0.25)
	left_part_hp -= actual_dmg
	Global.play_sfx("hit")
	if area.get("pierce_count") != null:
		area.pierce_count -= 1
		if area.pierce_count <= 0:
			area.queue_free()
	else:
		area.queue_free()
	if left_part_hp <= 0.0:
		var d_offset := Vector2(-110.0, -5.0) if Global.current_stage == 2 else (Vector2(-120.0, 25.0) if Global.current_stage == 1 else Vector2(-60.0, 40.0))
		_destroy_sub_part(global_position + d_offset)

func _on_right_part_hit(area: Area2D) -> void:
	if right_part_hp <= 0.0:
		return
	var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
	var actual_dmg := dmg
	if Global.current_stage == 2:
		if is_standing_vulnerable:
			actual_dmg = dmg * 2.5
		else:
			actual_dmg = maxf(0.2, dmg * 0.25)
	right_part_hp -= actual_dmg
	Global.play_sfx("hit")
	if area.get("pierce_count") != null:
		area.pierce_count -= 1
		if area.pierce_count <= 0:
			area.queue_free()
	else:
		area.queue_free()
	if right_part_hp <= 0.0:
		var d_offset := Vector2(65.0, -45.0) if Global.current_stage == 2 else (Vector2(-74.0, -87.0) if Global.current_stage == 1 else Vector2(60.0, 40.0))
		_destroy_sub_part(global_position + d_offset)

func _destroy_sub_part(pos: Vector2) -> void:
	Global.add_score(1500)
	Global.shake_screen(6.0, 0.3)
	if has_node("/root/VFX"):
		VFX.spawn_boss_fire(pos, 0.85, 2.5)
	Global.play_sfx("explosion")

func take_damage(dmg: float = 1.0) -> void:
	if not is_active or is_dead:
		return
	
	var actual_dmg := dmg
	if Global.current_stage == 2:
		if is_standing_vulnerable:
			# While standing still: takes BIG damage from player!
			actual_dmg = dmg * 3.0
			core_flash_timer = 0.14
			Global.play_sfx("hit")
			Global.shake_screen(4.0, 0.15)
			VFX.spawn_hit_sparks(global_position + Vector2(0.0, 8.0), Vector2.UP, Color(1.0, 0.25, 0.15))
		else:
			# While walking: heavy armor deflects shots, takes very less damage!
			actual_dmg = maxf(0.15, dmg * 0.20)
			core_flash_timer = 0.05
			Global.play_sfx("hit")
			VFX.spawn_hit_sparks(global_position + Vector2(-40.0, 0.0), Vector2(-walk_dir, -0.6).normalized(), Color(0.75, 0.85, 1.0))
	else:
		core_flash_timer = 0.08
		Global.play_sfx("hit")
	
	current_health -= actual_dmg
	Global.boss_health_changed.emit(maxf(0.0, current_health), max_health)
	
	if not is_enraged and current_health <= max_health * enrage_threshold:
		is_enraged = true
		enrage_flash_timer = 0.5
		Global.play_sfx("boss_alarm")
		Global.shake_screen(8.0, 0.45)
		if has_node("/root/VFX"):
			VFX.spawn_explosion(global_position, 1.8)
		attack_timer_3 = 0.1
	
	if current_health <= 0.0:
		_trigger_death()

func _trigger_death() -> void:
	is_dead = true
	var res := _get_boss_resource()
	var score_to_add: int = res.score_reward if res != null else (10000 + (Global.current_stage - 1) * 2000)
	Global.add_score(score_to_add)
	Global.is_victory = true
	Global.boss_defeated.emit()
	death_explosions_left = 18
	death_chain_timer = 0.05
	core_area.monitoring = false
	core_area.monitorable = false

func _process_death_sequence(delta: float) -> void:
	death_chain_timer -= delta
	if death_chain_timer <= 0.0:
		if death_explosions_left > 0:
			death_chain_timer = 0.11
			death_explosions_left -= 1
			death_frame_index = clampi(int((18 - death_explosions_left) / 4), 0, 3)
			Global.shake_screen(9.0, 0.22)
			var offset := Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
			var exp_pos := global_position + offset
			if has_node("/root/VFX"):
				VFX.spawn_explosion(exp_pos, 1.4)
			elif explosion_scene != null:
				var exp_node = explosion_scene.instantiate()
				exp_node.global_position = exp_pos
				get_parent().add_child(exp_node)
		else:
			# Final massive boss destruction explosion! (192x192 big_explosion)
			Global.play_sfx("boss_defeat")
			Global.shake_screen(18.0, 0.75)
			if has_node("/root/VFX"):
				VFX.spawn_big_explosion(global_position, 1.35)
				VFX.spawn_dust_puff(global_position + Vector2(0.0, 30.0), 24, Color(0.2, 0.2, 0.25, 0.9))

func _draw() -> void:
	match Global.current_stage:
		1: _draw_boss_1_wall()
		2: _draw_boss_2_hydro_mech()
		3: _draw_boss_3_bio_heart()
		4: _draw_boss_4_siege_tank()
		5: _draw_boss_5_magma_forge()
		6: _draw_boss_6_thunder_dynamo()
		7: _draw_boss_7_star_cruiser()
		8: _draw_boss_8_mother_brain()

# -----------------------------------------------------------------------------
# BOSS 1: WALL DEFENSE FORTRESS
# -----------------------------------------------------------------------------
func _draw_boss_1_wall() -> void:
	var wall_w: float = 270.0
	var wall_h: float = 230.0
	var draw_rect := Rect2(-161.0, -120.0, wall_w, wall_h)
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead and core_textures.size() > 0:
		var speed_mult := 1.5 if current_health < max_health * 0.35 else 1.0
		if mg_burst_active:
			speed_mult *= 3.0 # Frantic high-speed barrel spin during firing burst!
		var tex_idx := int(anim_timer * 7.5 * speed_mult) % core_textures.size()
		var col: Color = Color(2.0, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
		draw_texture_rect(core_textures[tex_idx], draw_rect, false, col)
	elif boss_texture != null:
		var col: Color = Color(2.0, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
		draw_texture_rect(boss_texture, draw_rect, false, col)
	else:
		draw_rect(Rect2(-120.0, -110.0, 240.0, 210.0), Color(0.16, 0.18, 0.22))
		draw_rect(Rect2(-110.0, -100.0, 220.0, 190.0), Color(0.24, 0.27, 0.32))

	# Structural Foundation Plinth (anchoring wall fortress to floor at y = 110)
	var base_w: float = 274.0
	var base_h: float = 8.0
	var base_rect := Rect2(-163.0, 106.0, base_w, base_h)
	draw_rect(base_rect, Color(0.12, 0.14, 0.18, 0.95))
	draw_rect(base_rect, Color(0.40, 0.46, 0.52, 0.85), false, 1.2)
	draw_line(Vector2(-163.0, 106.0), Vector2(-163.0 + base_w, 106.0), Color(0.75, 0.82, 0.90, 0.65), 1.0)
	for b in range(12):
		var bx := -155.0 + float(b) * 23.5
		draw_circle(Vector2(bx, 110.0), 2.0, Color(0.06, 0.08, 0.10))
		draw_circle(Vector2(bx, 109.5), 1.2, Color(0.60, 0.68, 0.75))

	if is_dead:
		return
	
	# Boss Cutscene Awakening Energy Charging
	if Global.is_boss_cutscene_active:
		var cp := Vector2(0.0, 8.0)
		var flare_r := 22.0 + 8.0 * sin(anim_timer * 18.0)
		draw_circle(cp, flare_r, Color(1.0, 0.2, 0.2, 0.55))
		draw_circle(cp, flare_r * 0.55, Color(1.0, 0.9, 0.3, 0.85))
		draw_circle(cp, 4.0, Color.WHITE)
		for a in range(5):
			var ang := anim_timer * 15.0 + float(a) * (TAU / 5.0)
			var p1 := cp + Vector2(cos(ang) * 10.0, sin(ang) * 10.0)
			var p2 := cp + Vector2(cos(ang + 0.4) * 44.0, sin(ang + 0.4) * 44.0)
			draw_line(p1, p2, Color(0.3, 0.9, 1.0, 0.85), 2.0)

	# Active cyan plasma lightning arcs in core containment chamber
	if is_active:
		var core_pos := Vector2(0.0, 8.0)
		var is_low_hp := (current_health < max_health * 0.35)
		var arc_count := 6 if is_low_hp else 3
		var arc_speed := 12.0 if is_low_hp else 6.5
		for i in range(arc_count):
			var a := float(i) * (TAU / float(arc_count)) + anim_timer * arc_speed
			var arc_p := core_pos + Vector2(cos(a) * 22.0, sin(a) * 16.0)
			var a_col := Color(1.0, 0.3, 0.3, 0.85) if is_low_hp else Color(0.25, 1.0, 0.85, 0.70)
			draw_line(core_pos, arc_p, a_col, 2.0)
		
		# Low Health Alarm Beacons flashing on towers
		if is_low_hp and sin(anim_timer * 14.0) > 0.0:
			draw_circle(Vector2(-68.0, -85.0), 6.0, Color(1.0, 0.1, 0.1, 0.9))
			draw_circle(Vector2(61.0, -91.0), 6.0, Color(1.0, 0.1, 0.1, 0.9))

	# Machinegun Barrel Heat Dissipation Glows
	if heat_mid > 0.05:
		draw_circle(Vector2(-158.0 + recoil_mid, 25.0), 5.0, Color(1.0, 0.4, 0.1, heat_mid * 0.75))
		draw_circle(Vector2(-158.0 + recoil_mid, 25.0), 2.5, Color(1.0, 0.8, 0.2, heat_mid * 0.9))
	if heat_tl > 0.05:
		draw_circle(Vector2(-114.0 + recoil_tl, -95.0), 5.0, Color(1.0, 0.4, 0.1, heat_tl * 0.75))
		draw_circle(Vector2(-114.0 + recoil_tl, -95.0), 2.5, Color(1.0, 0.8, 0.2, heat_tl * 0.9))
	if heat_tr > 0.05:
		draw_circle(Vector2(-2.0 + recoil_tr, -85.0), 5.0, Color(1.0, 0.4, 0.1, heat_tr * 0.75))
		draw_circle(Vector2(-2.0 + recoil_tr, -85.0), 2.5, Color(1.0, 0.8, 0.2, heat_tr * 0.9))

	# Dynamic Multi-Point Muzzle Flashes at exact gun tips
	if muzzle_flash_left > 0.0:
		var mfp := Vector2(-161.0 + recoil_mid, 25.0)
		var s := muzzle_flash_left / 0.10
		draw_circle(mfp, 16.0 * s, Color(1.0, 0.8, 0.2, 0.9))
		draw_circle(mfp, 9.0 * s, Color(1.0, 1.0, 0.9))
		for k in range(5):
			var a := float(k) * (TAU / 5.0) + anim_timer * 12.0
			draw_line(mfp, mfp + Vector2(cos(a) * 22.0 * s, sin(a) * 22.0 * s), Color(1.0, 0.5, 0.1), 2.5)

	if muzzle_flash_top > 0.0:
		var mfp := Vector2(-116.0 + recoil_tl, -95.0)
		var s := muzzle_flash_top / 0.10
		draw_circle(mfp, 16.0 * s, Color(1.0, 0.8, 0.2, 0.9))
		draw_circle(mfp, 9.0 * s, Color(1.0, 1.0, 0.9))
		for k in range(5):
			var a := float(k) * (TAU / 5.0) + anim_timer * 12.0
			draw_line(mfp, mfp + Vector2(cos(a) * 22.0 * s, sin(a) * 22.0 * s), Color(1.0, 0.5, 0.1), 2.5)

	if muzzle_flash_right > 0.0:
		var mfp := Vector2(-2.0 + recoil_tr, -85.0)
		var s := muzzle_flash_right / 0.10
		draw_circle(mfp, 16.0 * s, Color(1.0, 0.8, 0.2, 0.9))
		draw_circle(mfp, 9.0 * s, Color(1.0, 1.0, 0.9))
		for k in range(5):
			var a := float(k) * (TAU / 5.0) + anim_timer * 12.0
			draw_line(mfp, mfp + Vector2(cos(a) * 22.0 * s, sin(a) * 22.0 * s), Color(1.0, 0.5, 0.1), 2.5)

	# Spent Brass Shell Casings
	for sc in shell_casings:
		var lp: Vector2 = sc["pos"] - global_position
		var a: float = sc["rot"]
		var w_sc: float = 3.5
		var h_sc: float = 2.0
		var p1 := lp + Vector2(-w_sc, -h_sc).rotated(a)
		var p2 := lp + Vector2(w_sc, -h_sc).rotated(a)
		var p3 := lp + Vector2(w_sc, h_sc).rotated(a)
		var p4 := lp + Vector2(-w_sc, h_sc).rotated(a)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(1.0, 0.82, 0.25))
		draw_line(p1, p2, Color(1.0, 0.95, 0.6), 1.0)
		draw_line(p4, p3, Color(0.65, 0.45, 0.1), 1.0)

	# Destroyed side cannon damage states (active fire animation from Fire.png 80x128)
	if left_part_hp <= 0.0:
		var d_pos := Vector2(-120.0, 25.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		_draw_fire(d_pos, 0.55, 0.0)

	if right_part_hp <= 0.0:
		var d_pos := Vector2(-74.0, -87.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		_draw_fire(d_pos, 0.55, 0.5)

	# Wall breach fire when boss is heavily damaged
	if current_health <= max_health * 0.4 and not is_dead:
		_draw_fire(Vector2(-10.0, -15.0), 0.45, 0.3)

# -----------------------------------------------------------------------------
# BOSS 2: HYDRO-GOLIATH MECH
# -----------------------------------------------------------------------------
func _draw_boss_2_hydro_mech() -> void:
	var draw_w: float = 290.0
	var draw_h: float = 225.0
	var draw_rect := Rect2(-116.0, -110.0, draw_w, draw_h)
	var flash_col: Color
	if core_flash_timer > 0.0:
		if is_standing_vulnerable:
			flash_col = Color(2.5, 0.4, 0.4)
		else:
			flash_col = Color(1.3, 1.4, 1.8)
	else:
		flash_col = Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = null
		
		if not is_standing_vulnerable and is_walking and walk_textures.size() > 0:
			# Walking: cycle articulated walking animation frames (0 -> 1 -> 2 -> 3)
			var cur_frame := clampi(walk_frame_index, 0, walk_textures.size() - 1)
			active_tex = walk_textures[cur_frame]
		elif standing_textures.size() > 0:
			# Standing still: animate sequential cycle across the 3 PNGs:
			# 0: boss_hydro_goliath.png (base standing)
			# 1: boss_hydro_goliath_red.png (red turbine)
			# 2: hg.png (overheated red glowing turbine)
			var stand_fps := 3.0
			var stand_idx := int(standing_anim_timer * stand_fps) % standing_textures.size()
			active_tex = standing_textures[stand_idx]
		elif boss_texture != null:
			active_tex = boss_texture
		
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_rect(Rect2(-95.0, -75.0, 190.0, 140.0), Color(0.18, 0.28, 0.38))
		
		core_area.position = Vector2(0.0, 8.0)
		
		# Torrential Water Mist & Hydro Exhaust effects
		if is_standing_vulnerable:
			# Overheated exhaust steam & warning heat pulse when standing still
			var heat_pulse := 0.7 + 0.3 * sin(anim_timer * 14.0)
			draw_circle(Vector2(-112.0, -5.0), 16.0 * heat_pulse, Color(1.0, 0.4, 0.2, 0.50))
			draw_circle(Vector2(-112.0, -5.0), 8.0 * heat_pulse, Color(1.0, 0.8, 0.3, 0.70))
			draw_circle(Vector2(20.0, -100.0), 10.0 * heat_pulse, Color(0.9, 0.3, 0.2, 0.40))
		else:
			# Normal hydro-mist while moving
			var mist_pulse := 0.6 + 0.4 * sin(anim_timer * 10.0)
			draw_circle(Vector2(-112.0, -5.0), 12.0 * mist_pulse, Color(0.3, 0.85, 1.0, 0.35))
		
		# Twin Hydro-Cannon Muzzle Flashes when firing
		if muzzle_flash_left > 0.0:
			var s := muzzle_flash_left / 0.10
			var mfp1 := Vector2(-116.0, -18.0)
			var mfp2 := Vector2(-116.0, 10.0)
			draw_circle(mfp1, 14.0 * s, Color(0.3, 0.85, 1.0, 0.9))
			draw_circle(mfp1, 7.0 * s, Color.WHITE)
			draw_circle(mfp2, 14.0 * s, Color(0.3, 0.85, 1.0, 0.9))
			draw_circle(mfp2, 7.0 * s, Color.WHITE)
			
		# Torpedo pod muzzle flash when firing
		if muzzle_flash_right > 0.0:
			var s := muzzle_flash_right / 0.10
			var mfp3 := Vector2(65.0, -45.0)
			draw_circle(mfp3, 16.0 * s, Color(1.0, 0.7, 0.2, 0.9))
			draw_circle(mfp3, 8.0 * s, Color.WHITE)

	# Destroyed side cannon damage states (active fire animation from Fire.png 80x128)
	if left_part_hp <= 0.0:
		var d_pos := Vector2(-105.0, -5.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		_draw_fire(d_pos, 0.55, 0.0)

	if right_part_hp <= 0.0:
		var d_pos := Vector2(65.0, -45.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		_draw_fire(d_pos, 0.55, 0.5)

	# Hull breach fire when boss is heavily damaged
	if current_health <= max_health * 0.4 and not is_dead:
		_draw_fire(Vector2(0.0, 8.0), 0.5, 0.25)

# -----------------------------------------------------------------------------
# BOSS 3: GIGA BIO-HEART
# -----------------------------------------------------------------------------
func _draw_boss_3_bio_heart() -> void:
	var draw_rect := Rect2(-135.0, -110.0, 270.0, 220.0)
	var flash_col := Color(2.2, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 4.5) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			var pulse := 1.0 + 0.12 * sin(core_pulse)
			draw_circle(Vector2(0.0, 8.0), 65.0 * pulse, Color(0.70, 0.15, 0.25))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-35.0, -10.0), 0.45, 0.1)

# -----------------------------------------------------------------------------
# BOSS 4: FROSTBITE SIEGE TANK
# -----------------------------------------------------------------------------
func _draw_boss_4_siege_tank() -> void:
	var draw_rect := Rect2(-140.0, -100.0, 280.0, 200.0)
	var flash_col := Color(2.0, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 4.0) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_rect(Rect2(-105.0, -60.0, 210.0, 110.0), Color(0.22, 0.28, 0.36))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-50.0, -20.0), 0.45, 0.0)
			_draw_fire(Vector2(45.0, -15.0), 0.4, 0.5)

# -----------------------------------------------------------------------------
# BOSS 5: MAGMA FORGE GOLEM
# -----------------------------------------------------------------------------
func _draw_boss_5_magma_forge() -> void:
	var draw_rect := Rect2(-125.0, -125.0, 250.0, 250.0)
	var flash_col := Color(2.2, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 4.0) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_rect(Rect2(-100.0, -75.0, 200.0, 155.0), Color(0.22, 0.16, 0.16))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-30.0, -25.0), 0.5, 0.0)
			_draw_fire(Vector2(35.0, 15.0), 0.45, 0.4)

# -----------------------------------------------------------------------------
# BOSS 6: THUNDER OVERLORD DYNAMO
# -----------------------------------------------------------------------------
func _draw_boss_6_thunder_dynamo() -> void:
	var draw_rect := Rect2(-130.0, -105.0, 260.0, 210.0)
	var flash_col := Color(2.0, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 6.0) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_circle(Vector2(0.0, 8.0), 80.0, Color(0.16, 0.18, 0.26))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-45.0, -10.0), 0.45, 0.2)

# -----------------------------------------------------------------------------
# BOSS 7: VANGUARD STAR CRUISER
# -----------------------------------------------------------------------------
func _draw_boss_7_star_cruiser() -> void:
	var draw_rect := Rect2(-168.0, -75.0, 336.0, 150.0)
	var flash_col := Color(2.0, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 5.0) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_rect(Rect2(-120.0, -50.0, 240.0, 100.0), Color(0.30, 0.32, 0.42))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-60.0, -15.0), 0.45, 0.0)
			_draw_fire(Vector2(55.0, 5.0), 0.45, 0.5)

# -----------------------------------------------------------------------------
# BOSS 8: EMPEROR MOTHER BRAIN
# -----------------------------------------------------------------------------
func _draw_boss_8_mother_brain() -> void:
	var draw_rect := Rect2(-145.0, -110.0, 290.0, 220.0)
	var flash_col := Color(2.2, 0.4, 0.4) if core_flash_timer > 0.0 else Color.WHITE
	
	if is_dead and death_textures.size() > 0:
		var tex: Texture2D = death_textures[clampi(death_frame_index, 0, death_textures.size() - 1)]
		if tex != null:
			draw_texture_rect(tex, draw_rect, false, Color.WHITE)
	elif not is_dead:
		var active_tex: Texture2D = boss_texture
		if core_textures.size() > 0:
			var idx := int(anim_timer * 3.5) % core_textures.size()
			active_tex = core_textures[idx]
		if active_tex != null:
			draw_texture_rect(active_tex, draw_rect, false, flash_col)
		else:
			draw_circle(Vector2(0.0, 4.0), 55.0, Color(0.95, 0.35, 0.45))
		
		if current_health <= max_health * 0.4:
			_draw_fire(Vector2(-40.0, -15.0), 0.5, 0.3)

# -----------------------------------------------------------------------------
# COMMON SUB-PART CANNONS & VITAL CORE
# -----------------------------------------------------------------------------
func _draw_cannons_and_core(primary_col: Color) -> void:
	# Left Sub-part / Cannon
	if left_part_hp > 0.0:
		draw_circle(Vector2(-60.0, 40.0), 16.0, Color(0.30, 0.34, 0.40))
		draw_rect(Rect2(-97.0, 34.0, 22.0, 12.0), Color(0.15, 0.18, 0.22))
		draw_circle(Vector2(-60.0, 40.0), 8.0, primary_col)
	else:
		draw_circle(Vector2(-60.0, 40.0), 14.0, Color(0.10, 0.10, 0.12))
		_draw_fire(Vector2(-60.0, 40.0), 0.5, 0.0)
	
	# Right Sub-part / Cannon
	if right_part_hp > 0.0:
		draw_circle(Vector2(60.0, 40.0), 16.0, Color(0.30, 0.34, 0.40))
		draw_rect(Rect2(75.0, 34.0, 22.0, 12.0), Color(0.15, 0.18, 0.22))
		draw_circle(Vector2(60.0, 40.0), 8.0, primary_col)
	else:
		draw_circle(Vector2(60.0, 40.0), 14.0, Color(0.10, 0.10, 0.12))
		_draw_fire(Vector2(60.0, 40.0), 0.5, 0.5)
	
	# Core Vital Chamber
	var core_color := primary_col
	if core_flash_timer > 0.0:
		core_color = Color(1.0, 0.25, 0.25)
	elif is_dead:
		core_color = Color(0.15, 0.15, 0.15)
	
	draw_rect(Rect2(-24.0, -12.0, 48.0, 40.0), Color(0.08, 0.10, 0.14))
	var pulse_glow := (sin(core_pulse) + 1.0) * 0.5
	draw_circle(Vector2(0.0, 8.0), 16.0 + pulse_glow * 3.0, Color(core_color.r, core_color.g, core_color.b, 0.35))
	draw_circle(Vector2(0.0, 8.0), 13.0, core_color)
	draw_circle(Vector2(0.0, 8.0), 6.0, Color(1.0, 1.0, 1.0, 0.85))
	
	if current_health <= max_health * 0.4 and not is_dead:
		_draw_fire(Vector2(0.0, 8.0), 0.45, 0.2)

# -----------------------------------------------------------------------------
# DAMAGED PART BURNING FIRE ANIMATION HELPER (Fire.png 80x128)
# -----------------------------------------------------------------------------
func _draw_fire(pos: Vector2, scale_mult: float = 0.5, time_offset: float = 0.0) -> void:
	if fire_textures.size() == 0:
		return
	var frame_idx := int(fmod(fire_anim_timer + time_offset * 15.0, float(fire_textures.size())))
	frame_idx = clampi(frame_idx, 0, fire_textures.size() - 1)
	var tex: Texture2D = fire_textures[frame_idx]
	if tex != null:
		var fw := 80.0 * scale_mult
		var fh := 128.0 * scale_mult
		draw_texture_rect(tex, Rect2(pos.x - fw * 0.5, pos.y - fh * 0.85, fw, fh), false)
