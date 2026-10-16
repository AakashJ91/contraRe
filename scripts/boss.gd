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

# Stage 1 Machineguns State
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

func _ready() -> void:
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
			if ResourceLoader.exists(cp):
				core_textures.append(load(cp))
		
		death_textures.clear()
		for i in range(4):
			var dp := "res://assets/enemies/boss_fortress/death/destroy_%d.png" % i
			if ResourceLoader.exists(dp):
				death_textures.append(load(dp))
		
		if ResourceLoader.exists("res://assets/enemies/boss_fortress/boss_fortress.png"):
			boss_texture = load("res://assets/enemies/boss_fortress/boss_fortress.png")
		elif ResourceLoader.exists("res://assets/enemies/boss_fortress.png"):
			boss_texture = load("res://assets/enemies/boss_fortress.png")
		elif ResourceLoader.exists("res://assets/enemies/boss_wall.png"):
			boss_texture = load("res://assets/enemies/boss_wall.png")
	queue_redraw()

func _init_boss_stats() -> void:
	match Global.current_stage:
		1: # Wall Defense Fortress
			if enemy_data != null:
				max_health = enemy_data.max_health
			else:
				max_health = 35.0
			left_part_hp = 12.0
			right_part_hp = 12.0
		2: # Hydro-Goliath Mech
			max_health = 38.0
			left_part_hp = 14.0
			right_part_hp = 14.0
		3: # Giga Bio-Heart
			max_health = 42.0
			left_part_hp = 14.0
			right_part_hp = 14.0
		4: # Frostbite Siege Tank
			max_health = 45.0
			left_part_hp = 15.0
			right_part_hp = 15.0
		5: # Magma Forge Golem
			max_health = 48.0
			left_part_hp = 16.0
			right_part_hp = 16.0
		6: # Thunder Dynamo
			max_health = 52.0
			left_part_hp = 18.0
			right_part_hp = 18.0
		7: # Vanguard Star Cruiser
			max_health = 55.0
			left_part_hp = 20.0
			right_part_hp = 20.0
		8: # Emperor Mother Brain
			max_health = 60.0
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
	
	# Attack Pattern 1: Primary side weapons
	attack_timer_1 -= delta
	if attack_timer_1 <= 0.0:
		var interval_1 := 2.2 - float(Global.current_stage) * 0.1
		attack_timer_1 = maxf(1.1, interval_1)
		_execute_attack_1()
	
	# Attack Pattern 2: Secondary / Core heavy weapon
	attack_timer_2 -= delta
	if attack_timer_2 <= 0.0:
		var interval_2 := 2.6 - float(Global.current_stage) * 0.12
		attack_timer_2 = maxf(1.3, interval_2)
		_execute_attack_2()
	
	queue_redraw()

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
			_fire_spread_cannons(player_node, 300.0, 3)
		3: # Toxic bio-needle bursts
			_fire_spread_cannons(player_node, 290.0, 3)
		4: # Frost gatling bursts
			_fire_straight_cannons(player_node, 320.0)
		5: # Dual flamethrower jets
			_fire_spread_cannons(player_node, 270.0, 4)
		6: # High-voltage electric spark waves
			_fire_spread_cannons(player_node, 320.0, 4)
		7: # Twin plasma blasters
			_fire_straight_cannons(player_node, 340.0)
		8: # Optic drone dual laser streams
			_fire_spread_cannons(player_node, 330.0, 5)

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
	var bullet_speed: float = 320.0
	
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
			bullet_speed = 320.0
		1: # Top-Left Upper Gatling
			if right_part_hp <= 0.0:
				mg_burst_active = false
				return
			muzzle_offset = Vector2(-116.0, -95.0)
			shell_port = Vector2(-68.0, -98.0)
			recoil_tl = 5.0
			heat_tl = minf(1.0, heat_tl + 0.35)
			muzzle_flash_top = 0.10
			bullet_speed = 300.0
		2: # Top-Right Upper Gatling
			muzzle_offset = Vector2(-2.0, -85.0)
			shell_port = Vector2(65.0, -98.0)
			recoil_tr = 5.0
			heat_tr = minf(1.0, heat_tr + 0.35)
			muzzle_flash_right = 0.10
			bullet_speed = 330.0
	
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
				_spawn_bullet(rocket_spawn, dir.rotated(angle), 290.0)
		2: # Core hydro-plasma surge
			for angle in [-0.30, 0.0, 0.30]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 310.0)
		3: # Bio-heart toxic spore cluster
			for angle in [-0.35, -0.12, 0.12, 0.35]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 280.0)
		4: # High-trajectory freeze mortar shell
			_spawn_bullet(global_position + Vector2(0.0, -60.0), Vector2(-0.7, -0.7).normalized(), 330.0)
			_spawn_bullet(global_position + Vector2(0.0, -60.0), dir, 300.0)
		5: # Magma slag volcanic eruption
			for angle in [-0.4, -0.15, 0.15, 0.4]:
				_spawn_bullet(global_position + Vector2(0.0, -40.0), dir.rotated(angle), 290.0)
		6: # Rotating electrostatic laser arc
			for angle in [-0.45, -0.22, 0.0, 0.22, 0.45]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 320.0)
		7: # Cluster micro-missiles
			for i in range(4):
				var offset_ang := (float(i) - 1.5) * 0.18
				_spawn_bullet(global_position + Vector2(0.0, -35.0), dir.rotated(offset_ang), 340.0)
		8: # Mother Brain 5-way psychic wave spread
			for angle in [-0.55, -0.28, 0.0, 0.28, 0.55]:
				_spawn_bullet(global_position + Vector2(0.0, 8.0), dir.rotated(angle), 330.0)

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
		var p1 := global_position + Vector2(-60.0, 40.0)
		var d1 := (player_node.global_position - p1).normalized()
		for i in range(count):
			var ang := (float(i) - mid) * 0.16
			_spawn_bullet(p1, d1.rotated(ang), spd)
	if right_part_hp > 0.0:
		var p2 := global_position + Vector2(60.0, 40.0)
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
	left_part_hp -= dmg
	Global.play_sfx("hit")
	if area.get("pierce_count") != null:
		area.pierce_count -= 1
		if area.pierce_count <= 0:
			area.queue_free()
	else:
		area.queue_free()
	if left_part_hp <= 0.0:
		var d_offset := Vector2(-120.0, 25.0) if Global.current_stage == 1 else Vector2(-60.0, 40.0)
		_destroy_sub_part(global_position + d_offset)

func _on_right_part_hit(area: Area2D) -> void:
	if right_part_hp <= 0.0:
		return
	var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
	right_part_hp -= dmg
	Global.play_sfx("hit")
	if area.get("pierce_count") != null:
		area.pierce_count -= 1
		if area.pierce_count <= 0:
			area.queue_free()
	else:
		area.queue_free()
	if right_part_hp <= 0.0:
		var d_offset := Vector2(-74.0, -87.0) if Global.current_stage == 1 else Vector2(60.0, 40.0)
		_destroy_sub_part(global_position + d_offset)

func _destroy_sub_part(pos: Vector2) -> void:
	Global.add_score(1500)
	Global.shake_screen(6.0, 0.3)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = pos
		get_parent().add_child(exp_node)

func take_damage(dmg: float = 1.0) -> void:
	if not is_active or is_dead:
		return
	current_health -= dmg
	core_flash_timer = 0.08
	Global.play_sfx("hit")
	Global.boss_health_changed.emit(maxf(0.0, current_health), max_health)
	if current_health <= 0.0:
		_trigger_death()

func _trigger_death() -> void:
	is_dead = true
	var base_score := enemy_data.score_reward if (enemy_data != null and Global.current_stage == 1) else 10000
	var bonus_score := base_score + (Global.current_stage - 1) * 2000
	Global.add_score(bonus_score)
	Global.is_victory = true
	Global.boss_defeated.emit()
	death_explosions_left = 18
	death_chain_timer = 0.05
	core_area.monitoring = false
	core_area.monitorable = false

func _process_death_sequence(delta: float) -> void:
	death_chain_timer -= delta
	if death_chain_timer <= 0.0 and death_explosions_left > 0:
		death_chain_timer = 0.12
		death_explosions_left -= 1
		death_frame_index = clampi(int((18 - death_explosions_left) / 4), 0, 3)
		Global.shake_screen(10.0, 0.25)
		if explosion_scene != null:
			var offset := Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
			var exp_node = explosion_scene.instantiate()
			exp_node.global_position = global_position + offset
			get_parent().add_child(exp_node)

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

	# Destroyed side cannon damage states (smoke + sparks)
	if left_part_hp <= 0.0:
		var d_pos := Vector2(-120.0, 25.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		if sin(anim_timer * 18.0) > 0.3:
			draw_circle(d_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 4.0, Color(1.0, 0.7, 0.2))
		draw_circle(d_pos + Vector2(0.0, -10.0 - fmod(anim_timer * 20.0, 18.0)), 7.0, Color(0.2, 0.2, 0.25, 0.6))

	if right_part_hp <= 0.0:
		var d_pos := Vector2(-74.0, -87.0)
		draw_circle(d_pos, 14.0, Color(0.10, 0.10, 0.12, 0.95))
		if sin(anim_timer * 18.0 + 1.0) > 0.3:
			draw_circle(d_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 4.0, Color(1.0, 0.7, 0.2))
		draw_circle(d_pos + Vector2(0.0, -10.0 - fmod(anim_timer * 20.0, 18.0)), 7.0, Color(0.2, 0.2, 0.25, 0.6))

# -----------------------------------------------------------------------------
# BOSS 2: HYDRO-GOLIATH MECH
# -----------------------------------------------------------------------------
func _draw_boss_2_hydro_mech() -> void:
	var col_mech := Color(0.18, 0.28, 0.38)
	var col_armor := Color(0.25, 0.42, 0.55)
	# Heavy hydraulic legs
	draw_line(Vector2(-70.0, 30.0), Vector2(-90.0, 95.0), Color(0.12, 0.16, 0.22), 12.0)
	draw_line(Vector2(70.0, 30.0), Vector2(90.0, 95.0), Color(0.12, 0.16, 0.22), 12.0)
	# Walker chassis
	draw_rect(Rect2(-95.0, -75.0, 190.0, 140.0), col_mech)
	draw_rect(Rect2(-80.0, -60.0, 160.0, 110.0), col_armor)
	# Rotating top water turbine
	draw_circle(Vector2(0.0, -65.0), 22.0, Color(0.15, 0.30, 0.45))
	draw_arc(Vector2(0.0, -65.0), 22.0, anim_timer * 4.0, anim_timer * 4.0 + PI, 16, Color(0.35, 0.85, 1.0), 2.5)
	_draw_cannons_and_core(Color(0.2, 0.6, 1.0))

# -----------------------------------------------------------------------------
# BOSS 3: GIGA BIO-HEART
# -----------------------------------------------------------------------------
func _draw_boss_3_bio_heart() -> void:
	var pulse := 1.0 + 0.12 * sin(core_pulse)
	var col_flesh := Color(0.70, 0.15, 0.25)
	var col_vein := Color(0.95, 0.25, 0.40)
	# Waving alien tentacles
	for t in range(4):
		var side := -1.0 if t < 2 else 1.0
		var ty := -50.0 + float(t % 2) * 80.0
		var sweep := sin(anim_timer * 3.0 + float(t)) * 25.0
		draw_line(Vector2(side * 60.0, ty), Vector2(side * 115.0 + sweep, ty + 20.0), col_flesh, 7.0)
	# Pulsing heart chamber
	draw_circle(Vector2(0.0, 8.0), 65.0 * pulse, col_flesh)
	draw_circle(Vector2(-25.0, -15.0), 38.0 * pulse, Color(0.55, 0.10, 0.20))
	draw_circle(Vector2(25.0, -15.0), 38.0 * pulse, Color(0.55, 0.10, 0.20))
	# Glowing veins
	for v in range(6):
		var a := float(v) * (TAU / 6.0) + core_pulse * 0.2
		draw_line(Vector2(0.0, 8.0), Vector2(cos(a) * 45.0, 8.0 + sin(a) * 45.0), col_vein, 2.5)
	_draw_cannons_and_core(Color(1.0, 0.20, 0.30))

# -----------------------------------------------------------------------------
# BOSS 4: FROSTBITE SIEGE TANK
# -----------------------------------------------------------------------------
func _draw_boss_4_siege_tank() -> void:
	var col_tank := Color(0.22, 0.28, 0.36)
	var col_ice := Color(0.75, 0.88, 1.0)
	# Heavy treads
	draw_rect(Rect2(-115.0, 50.0, 230.0, 38.0), Color(0.12, 0.14, 0.18))
	for w in range(7):
		draw_circle(Vector2(-90.0 + float(w) * 30.0, 69.0), 12.0, Color(0.25, 0.30, 0.38))
	# Armored hull & snow-plow
	draw_rect(Rect2(-105.0, -60.0, 210.0, 110.0), col_tank)
	draw_line(Vector2(-105.0, -60.0), Vector2(105.0, -60.0), col_ice, 4.0)
	# Heavy Mortar Cannon Barrel
	draw_rect(Rect2(-18.0, -95.0, 36.0, 45.0), Color(0.15, 0.18, 0.24))
	draw_rect(Rect2(-24.0, -100.0, 48.0, 12.0), col_ice)
	_draw_cannons_and_core(Color(0.40, 0.90, 1.0))

# -----------------------------------------------------------------------------
# BOSS 5: MAGMA FORGE GOLEM
# -----------------------------------------------------------------------------
func _draw_boss_5_magma_forge() -> void:
	var col_iron := Color(0.22, 0.16, 0.16)
	var col_lava := Color(1.0, 0.40, 0.08)
	# Smelting furnace body
	draw_rect(Rect2(-100.0, -75.0, 200.0, 155.0), col_iron)
	draw_rect(Rect2(-85.0, -60.0, 170.0, 125.0), Color(0.14, 0.10, 0.10))
	# Boiling lava exhaust conduits
	for l in range(5):
		var lx := -70.0 + float(l) * 35.0
		draw_rect(Rect2(lx, -50.0, 15.0, 95.0), col_lava * (0.8 + 0.2 * sin(core_pulse + float(l))))
	# Top smokestack chimneys
	draw_rect(Rect2(-55.0, -95.0, 30.0, 26.0), col_iron)
	draw_rect(Rect2(25.0, -95.0, 30.0, 26.0), col_iron)
	_draw_cannons_and_core(Color(1.0, 0.45, 0.10))

# -----------------------------------------------------------------------------
# BOSS 6: THUNDER OVERLORD DYNAMO
# -----------------------------------------------------------------------------
func _draw_boss_6_thunder_dynamo() -> void:
	var col_stator := Color(0.16, 0.18, 0.26)
	var col_electric := Color(0.25, 0.85, 1.0)
	# Rotating stator ring
	draw_circle(Vector2(0.0, 8.0), 80.0, col_stator)
	draw_arc(Vector2(0.0, 8.0), 75.0, anim_timer * 5.0, anim_timer * 5.0 + TAU, 28, col_electric, 3.0)
	# Tesla coil spikes
	for i in range(8):
		var a := float(i) * (TAU / 8.0) + anim_timer * 2.0
		var p1 := Vector2(0.0, 8.0) + Vector2(cos(a), sin(a)) * 60.0
		var p2 := Vector2(0.0, 8.0) + Vector2(cos(a), sin(a)) * 95.0
		draw_line(p1, p2, Color(1.0, 0.90, 0.25), 3.0)
	_draw_cannons_and_core(Color(0.20, 0.85, 1.0))

# -----------------------------------------------------------------------------
# BOSS 7: VANGUARD STAR CRUISER
# -----------------------------------------------------------------------------
func _draw_boss_7_star_cruiser() -> void:
	var col_hull := Color(0.30, 0.32, 0.42)
	var col_trim := Color(0.65, 0.40, 0.95)
	# Dreadnought wing aerofoils
	var wing_pts := PackedVector2Array([
		Vector2(-125.0, 55.0),
		Vector2(-80.0, -45.0),
		Vector2(0.0, -85.0),
		Vector2(80.0, -45.0),
		Vector2(125.0, 55.0),
		Vector2(0.0, 40.0)
	])
	draw_colored_polygon(wing_pts, col_hull)
	# Glowing warp lines
	draw_line(Vector2(-105.0, 45.0), Vector2(0.0, -75.0), col_trim, 2.5)
	draw_line(Vector2(105.0, 45.0), Vector2(0.0, -75.0), col_trim, 2.5)
	_draw_cannons_and_core(Color(0.70, 0.35, 1.0))

# -----------------------------------------------------------------------------
# BOSS 8: EMPEROR MOTHER BRAIN
# -----------------------------------------------------------------------------
func _draw_boss_8_mother_brain() -> void:
	var pulse := 1.0 + 0.10 * sin(core_pulse * 1.5)
	var col_brain := Color(0.95, 0.35, 0.45)
	var col_glass := Color(0.35, 0.75, 1.0, 0.45)
	# Glass bio-containment cylinder
	draw_rect(Rect2(-85.0, -85.0, 170.0, 170.0), Color(0.08, 0.12, 0.18, 0.85))
	draw_rect(Rect2(-85.0, -85.0, 170.0, 170.0), col_glass, false, 3.0)
	# Pulsing cerebrum convolutions
	draw_circle(Vector2(0.0, 4.0), 55.0 * pulse, col_brain)
	draw_circle(Vector2(-24.0, -18.0), 32.0 * pulse, Color(1.0, 0.50, 0.60))
	draw_circle(Vector2(24.0, -18.0), 32.0 * pulse, Color(1.0, 0.50, 0.60))
	draw_circle(Vector2(0.0, 24.0), 36.0 * pulse, Color(0.80, 0.25, 0.35))
	# Crack lines across glass
	draw_line(Vector2(-60.0, -70.0), Vector2(-15.0, -25.0), Color(1.0, 1.0, 1.0, 0.8), 1.5)
	draw_line(Vector2(-15.0, -25.0), Vector2(30.0, -50.0), Color(1.0, 1.0, 1.0, 0.8), 1.5)
	# Orbiting optic eye drones
	var eye_ang := anim_timer * 4.0
	var eye1_pos := Vector2(cos(eye_ang) * 95.0, sin(eye_ang) * 55.0)
	var eye2_pos := Vector2(cos(eye_ang + PI) * 95.0, sin(eye_ang + PI) * 55.0)
	draw_circle(eye1_pos, 12.0, Color(1.0, 0.2, 0.2))
	draw_circle(eye1_pos, 5.0, Color.WHITE)
	draw_circle(eye2_pos, 12.0, Color(1.0, 0.2, 0.2))
	draw_circle(eye2_pos, 5.0, Color.WHITE)
	_draw_cannons_and_core(Color(1.0, 0.2, 0.2))

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
	
	# Right Sub-part / Cannon
	if right_part_hp > 0.0:
		draw_circle(Vector2(60.0, 40.0), 16.0, Color(0.30, 0.34, 0.40))
		draw_rect(Rect2(75.0, 34.0, 22.0, 12.0), Color(0.15, 0.18, 0.22))
		draw_circle(Vector2(60.0, 40.0), 8.0, primary_col)
	else:
		draw_circle(Vector2(60.0, 40.0), 14.0, Color(0.10, 0.10, 0.12))
	
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
