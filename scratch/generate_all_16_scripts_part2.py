import os

out_dir = "scripts"
os.makedirs(out_dir, exist_ok=True)

files = {}

# 9. slag_mech
files["enemy_slag_mech.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/slag_mech_data.tres")

const SPEED: float = 50.0
const GRAVITY: float = 950.0

var health: float = 7.0
var facing_dir: int = -1
var shoot_timer: float = 2.5
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var stomp_timer: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	
	if ResourceLoader.exists("res://assets/enemies/slag_mech/slag_mech.png"):
		base_texture = load("res://assets/enemies/slag_mech/slag_mech.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/slag_mech/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/slag_mech/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		if not is_on_floor(): velocity.y += GRAVITY * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	if not is_on_floor(): velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 30.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.6, 4.0)
		_execute_slag_attack()
		
	anim_frame += delta * 3.8
	# Heavy footsteps
	stomp_timer += delta
	if stomp_timer >= 0.75:
		stomp_timer = 0.0
		if is_on_floor():
			Global.shake_screen(2.0, 0.1)
			VFX.spawn_dust_puff(global_position + Vector2(0.0, 14.0), 2)
			
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 30.0:
			if player_node.has_method("take_damage"): player_node.take_damage(2.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _execute_slag_attack() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.shake_screen(4.5, 0.25)
	Global.play_sfx("explosion")
	
	# Slag wave along floor
	var wave = EnemySpecialProjectile.new()
	wave.proj_type = EnemySpecialProjectile.ProjectileType.SLAG_WAVE
	wave.damage = 1.0
	wave.velocity = Vector2(facing_dir * 170.0, 0.0)
	wave.global_position = global_position + Vector2(facing_dir * 18.0, 8.0)
	parent_node.add_child(wave)
	
	# Hot molten rivets
	for a in [-0.15, 0.15]:
		var rivet = EnemySpecialProjectile.new()
		rivet.proj_type = EnemySpecialProjectile.ProjectileType.RIVET
		rivet.damage = 1.0
		rivet.velocity = Vector2(facing_dir, 0.0).rotated(a) * 280.0
		rivet.global_position = global_position + Vector2(facing_dir * 20.0, -10.0)
		parent_node.add_child(rivet)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(500)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 40.0, -90.0)
	VFX.spawn_explosion(global_position)
	Global.shake_screen(6.0, 0.3)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 72.0
	var spr_h := 72.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 10. conveyor_droid
files["enemy_conveyor_droid.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/conveyor_droid_data.tres")

const SPEED: float = 80.0
const GRAVITY: float = 950.0

var health: float = 3.5
var facing_dir: int = -1
var shoot_timer: float = 2.2
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var is_firing_laser: bool = false
var laser_duration: float = 0.0
var laser_charge: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	
	if ResourceLoader.exists("res://assets/enemies/conveyor_droid/conveyor_droid.png"):
		base_texture = load("res://assets/enemies/conveyor_droid/conveyor_droid.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/conveyor_droid/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/conveyor_droid/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		if not is_on_floor(): velocity.y += GRAVITY * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	if not is_on_floor(): velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 20.0 and not is_firing_laser: facing_dir = 1 if diff > 0.0 else -1
	
	if is_firing_laser:
		velocity.x = 0.0
		laser_duration -= delta
		if laser_duration <= 0.0:
			is_firing_laser = false
			shoot_timer = randf_range(2.4, 3.8)
		else:
			# Laser hit detection
			if player_node != null and is_instance_valid(player_node):
				var laser_target := global_position + Vector2(facing_dir * 180.0, 80.0)
				var to_player := player_node.global_position - global_position
				if to_player.x * facing_dir > 0 and absf(to_player.x) < 180.0 and to_player.y > -20.0 and to_player.y < 90.0:
					if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	elif laser_charge > 0.0:
		velocity.x = 0.0
		laser_charge -= delta
		if laser_charge <= 0.0:
			is_firing_laser = true
			laser_duration = 1.0
			Global.play_sfx("shoot")
	else:
		velocity.x = facing_dir * SPEED
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			laser_charge = 0.5 # Warning laser charge
			
	anim_frame += delta * 6.5
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(300)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 50.0, -110.0)
	VFX.spawn_explosion(global_position)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 52.0
	var spr_h := 52.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	# Warning charge sight
	if laser_charge > 0.0:
		var end_pt := Vector2(facing_dir * 180.0, 70.0)
		draw_line(Vector2(facing_dir * 12.0, 0.0), end_pt, Color(1.0, 0.1, 0.1, 0.4), 1.5)
	elif is_firing_laser:
		var end_pt := Vector2(facing_dir * 200.0, 80.0)
		draw_line(Vector2(facing_dir * 12.0, 0.0), end_pt, Color(1.0, 0.2, 0.1, 0.9), 5.0)
		draw_line(Vector2(facing_dir * 12.0, 0.0), end_pt, Color.WHITE, 2.0)
"""

# 11. tesla_trooper
files["enemy_tesla_trooper.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/tesla_trooper_data.tres")

const SPEED: float = 65.0
const GRAVITY: float = 950.0

var health: float = 5.0
var facing_dir: int = -1
var shoot_timer: float = 2.2
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var shield_pulse: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	
	if ResourceLoader.exists("res://assets/enemies/tesla_trooper/tesla_trooper.png"):
		base_texture = load("res://assets/enemies/tesla_trooper/tesla_trooper.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/tesla_trooper/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/tesla_trooper/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	shield_pulse += delta * 12.0
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)
		if not is_on_floor(): velocity.y += GRAVITY * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	if not is_on_floor(): velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 25.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.5, 3.8)
		_fire_ball_lightning()
		
	anim_frame += delta * 4.8
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.5)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _fire_ball_lightning() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var bl = EnemySpecialProjectile.new()
	bl.proj_type = EnemySpecialProjectile.ProjectileType.BALL_LIGHTNING
	bl.damage = 1.0
	bl.velocity = Vector2(facing_dir * 130.0, -20.0)
	bl.global_position = global_position + Vector2(facing_dir * 18.0, -10.0)
	parent_node.add_child(bl)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var from_x := player_node.global_position.x - global_position.x
		# Frontal electric shield deflecting hits!
		if (facing_dir == 1 and from_x > 0.0) or (facing_dir == -1 and from_x < 0.0):
			VFX.spawn_hit_sparks(global_position + Vector2(facing_dir * 16.0, -8.0), Vector2(-facing_dir, 0.0), Color.CYAN)
			Global.play_sfx("hit")
			return
			
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(450)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 45.0, -120.0)
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color.CYAN)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 58.0
	var spr_h := 62.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		# Draw front electric energy shield
		var shield_a := (sin(shield_pulse) + 1.0) * 0.35 + 0.3
		draw_arc(Vector2(spr_w * 0.35, -4.0), 20.0, -PI * 0.4, PI * 0.4, 12, Color(0.2, 0.8, 1.0, shield_a), 3.0)
		draw_arc(Vector2(spr_w * 0.35, -4.0), 20.0, -PI * 0.4, PI * 0.4, 12, Color(1.0, 1.0, 1.0, shield_a * 0.8), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 12. spark_drone
files["enemy_spark_drone.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/spark_drone_data.tres")

const SPEED: float = 95.0

var health: float = 3.0
var facing_dir: int = -1
var shoot_timer: float = 2.0
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var hover_time: float = 0.0
var start_y: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	start_y = global_position.y
	
	if ResourceLoader.exists("res://assets/enemies/spark_drone/spark_drone.png"):
		base_texture = load("res://assets/enemies/spark_drone/spark_drone.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/spark_drone/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/spark_drone/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	hover_time += delta
	if is_dying:
		velocity.y += 600.0 * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 25.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	global_position.y = start_y + cos(hover_time * 3.2) * 20.0
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.2, 3.4)
		_fire_cross_zap()
		
	anim_frame += delta * 7.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	queue_redraw()

func _fire_cross_zap() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		var spk = EnemySpecialProjectile.new()
		spk.proj_type = EnemySpecialProjectile.ProjectileType.SPARK_CROSS
		spk.damage = 1.0
		spk.velocity = d * 200.0
		spk.global_position = global_position
		parent_node.add_child(spk)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(350)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 50.0, -100.0)
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color.CYAN)
	Global.shake_screen(3.5, 0.15)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
	var spr_h := 54.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		# Orbiting electric spark
		var sa := hover_time * 8.0
		draw_circle(Vector2(cos(sa) * 18.0, sin(sa) * 18.0), 2.5, Color.CYAN)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 13. jetpack_marine
files["enemy_jetpack_marine.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/jetpack_marine_data.tres")
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

const SPEED: float = 115.0

var health: float = 4.5
var facing_dir: int = -1
var shoot_timer: float = 1.8
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var hover_time: float = 0.0
var start_y: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	start_y = global_position.y
	
	if ResourceLoader.exists("res://assets/enemies/jetpack_marine/jetpack_marine.png"):
		base_texture = load("res://assets/enemies/jetpack_marine/jetpack_marine.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/jetpack_marine/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/jetpack_marine/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	hover_time += delta
	if is_dying:
		velocity.y += 650.0 * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 30.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	global_position.y = start_y + sin(hover_time * 2.5) * 18.0
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.0, 3.4)
		if randf() < 0.6: _fire_rifle_burst()
		else: _fire_homing_missiles()
		
	anim_frame += delta * 6.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.5)
	queue_redraw()

func _fire_rifle_burst() -> void:
	if bullet_scene == null: return
	var parent_node = get_parent()
	if parent_node == null: return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node): return
	
	Global.play_sfx("shoot")
	var dir := (player_node.global_position - global_position).normalized()
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.global_position = global_position + Vector2(facing_dir * 14.0, -4.0)
	parent_node.add_child(b)

func _fire_homing_missiles() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	for y_off in [-8.0, 8.0]:
		var m = EnemySpecialProjectile.new()
		m.proj_type = EnemySpecialProjectile.ProjectileType.HOMING_MISSILE
		m.damage = 1.0
		m.velocity = Vector2(facing_dir * 180.0, y_off * 10.0)
		m.global_position = global_position + Vector2(facing_dir * 12.0, y_off)
		parent_node.add_child(m)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(450)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 60.0, -120.0)
	VFX.spawn_explosion(global_position)
	Global.shake_screen(3.5, 0.2)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 56.0
	var spr_h := 60.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		# Jet thruster fire
		draw_circle(Vector2(-spr_w * 0.25, spr_h * 0.28), 3.5, Color(1.0, 0.6, 0.2))
		draw_circle(Vector2(-spr_w * 0.25, spr_h * 0.28), 1.8, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 14. rail_turret
files["enemy_rail_turret.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/rail_turret_data.tres")

const SPEED: float = 60.0

var health: float = 6.0
var facing_dir: int = -1
var shoot_timer: float = 2.4
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var is_firing_beam: bool = false
var beam_timer: float = 0.0
var target_laser_alpha: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	
	if ResourceLoader.exists("res://assets/enemies/rail_turret/rail_turret.png"):
		base_texture = load("res://assets/enemies/rail_turret/rail_turret.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/rail_turret/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/rail_turret/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.y += 600.0 * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 20.0 and not is_firing_beam: facing_dir = 1 if diff > 0.0 else -1
	
	if is_firing_beam:
		velocity.x = 0.0
		beam_timer -= delta
		if beam_timer <= 0.0:
			is_firing_beam = false
			shoot_timer = randf_range(2.5, 4.0)
		else:
			# Damage player if under vertical particle beam
			if player_node != null and is_instance_valid(player_node):
				if absf(player_node.global_position.x - global_position.x) < 20.0 and player_node.global_position.y > global_position.y:
					if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	else:
		velocity.x = facing_dir * SPEED
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			is_firing_beam = true
			beam_timer = 0.9
			Global.shake_screen(4.0, 0.2)
			Global.play_sfx("shoot")
			
	anim_frame += delta * 5.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.5)
	queue_redraw()

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(500)
	collision_layer = 0
	velocity = Vector2(0.0, 100.0)
	VFX.spawn_explosion(global_position)
	Global.shake_screen(4.0, 0.25)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 60.0
	var spr_h := 56.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	# Vertical rail guide & targeting beam
	draw_line(Vector2(-16.0, -spr_h * 0.4), Vector2(16.0, -spr_h * 0.4), Color(0.4, 0.45, 0.5), 3.0)
	if is_firing_beam:
		# Blasting vertical particle beam
		draw_line(Vector2.ZERO, Vector2(0.0, 350.0), Color(0.3, 0.8, 1.0, 0.9), 12.0)
		draw_line(Vector2.ZERO, Vector2(0.0, 350.0), Color.WHITE, 6.0)
	else:
		# Tracking targeting sight
		draw_line(Vector2.ZERO, Vector2(0.0, 350.0), Color(1.0, 0.2, 0.2, 0.35), 1.5)
"""

# 15. tentacle_whipper
files["enemy_tentacle_whipper.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/tentacle_whipper_data.tres")

var health: float = 5.5
var facing_dir: int = -1
var shoot_timer: float = 1.6
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var is_whipping: bool = false
var whip_timer: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	
	if ResourceLoader.exists("res://assets/enemies/tentacle_whipper/tentacle_whipper.png"):
		base_texture = load("res://assets/enemies/tentacle_whipper/tentacle_whipper.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/tentacle_whipper/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/tentacle_whipper/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 20.0: facing_dir = 1 if diff > 0.0 else -1
	
	if is_whipping:
		whip_timer -= delta
		if whip_timer <= 0.0:
			is_whipping = false
			shoot_timer = randf_range(1.6, 2.8)
		else:
			# Melee sweep damage
			if player_node != null and is_instance_valid(player_node):
				if global_position.distance_to(player_node.global_position) < 85.0:
					if player_node.has_method("take_damage"): player_node.take_damage(2.0)
	else:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = randf_range(1.8, 3.0)
			if player_node != null and is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) < 110.0:
				is_whipping = true
				whip_timer = 0.5
				Global.play_sfx("shoot")
				Global.shake_screen(3.0, 0.15)
			else:
				_spew_needle_darts()
				
	anim_frame += delta * 6.0
	queue_redraw()

func _spew_needle_darts() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var base_dir := Vector2(facing_dir, -0.3).normalized()
	for a in [-0.3, -0.15, 0.0, 0.15, 0.3]:
		var dart = EnemySpecialProjectile.new()
		dart.proj_type = EnemySpecialProjectile.ProjectileType.NEEDLE_DART
		dart.damage = 1.0
		dart.velocity = base_dir.rotated(a) * 260.0
		dart.global_position = global_position + Vector2(facing_dir * 10.0, -18.0)
		parent_node.add_child(dart)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(450)
	collision_layer = 0
	VFX.spawn_dust_puff(global_position, 6, Color(0.8, 0.2, 0.4))

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 60.0
	var spr_h := 68.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	if is_whipping:
		# Sweeping blade lash arc
		var whip_a := (0.5 - whip_timer) * (PI / 0.5)
		draw_arc(Vector2.ZERO, 70.0, -PI * 0.5, PI * 0.2, 16, Color(1.0, 0.3, 0.6, 0.7), 6.0)
		draw_arc(Vector2.ZERO, 70.0, -PI * 0.5, PI * 0.2, 16, Color.WHITE, 2.5)
"""

# 16. psychic_orb
files["enemy_psychic_orb.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/psychic_orb_data.tres")

const SPEED: float = 75.0

var health: float = 6.0
var facing_dir: int = -1
var shoot_timer: float = 2.0
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var teleport_timer: float = 3.5
var hover_time: float = 0.0
var start_y: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	start_y = global_position.y
	
	if ResourceLoader.exists("res://assets/enemies/psychic_orb/psychic_orb.png"):
		base_texture = load("res://assets/enemies/psychic_orb/psychic_orb.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/psychic_orb/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/psychic_orb/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	hover_time += delta
	if is_dying:
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 20.0: facing_dir = 1 if diff > 0.0 else -1
	
	teleport_timer -= delta
	if teleport_timer <= 0.0:
		teleport_timer = randf_range(3.5, 4.8)
		_teleport_near_player()
		
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.2, 3.5)
		_unleash_psychic_ring()
		
	global_position.y = start_y + sin(hover_time * 2.2) * 12.0
	anim_frame += delta * 5.0
	queue_redraw()

func _teleport_near_player() -> void:
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node): return
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(0.9, 0.3, 1.0))
	var offset_x := 180.0 if randf() < 0.5 else -180.0
	var offset_y := randf_range(-80.0, -20.0)
	global_position = player_node.global_position + Vector2(offset_x, offset_y)
	start_y = global_position.y
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(0.9, 0.3, 1.0))
	Global.play_sfx("hit")

func _unleash_psychic_ring() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	Global.shake_screen(3.5, 0.15)
	var ring = EnemySpecialProjectile.new()
	ring.proj_type = EnemySpecialProjectile.ProjectileType.PSYCHIC_RING
	ring.damage = 1.0
	ring.velocity = Vector2(facing_dir * 45.0, 0.0)
	ring.global_position = global_position
	parent_node.add_child(ring)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(600)
	collision_layer = 0
	VFX.spawn_explosion(global_position)
	Global.shake_screen(4.5, 0.25)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 60.0
	var spr_h := 60.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	
	if is_dying:
		var d_tex: Texture2D = death_textures[death_frame] if death_frame < death_textures.size() else null
		if d_tex != null:
			var alpha := 1.0 - clampf((death_timer - 0.45) / 0.20, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
			draw_texture_rect(d_tex, std_rect, false, Color(col.r, col.g, col.b, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
			
	var cur_tex: Texture2D = base_texture
	if walk_textures.size() > 0:
		var idx := int(fmod(anim_frame, float(walk_textures.size())))
		cur_tex = walk_textures[idx]
	if cur_tex != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		# Rotating psionic crystals
		for c in [0.0, 2.09, 4.18]:
			var ca := hover_time * 4.0 + c
			var cp := Vector2(cos(ca) * 26.0, sin(ca) * 16.0)
			draw_circle(cp, 3.5, Color(0.9, 0.3, 1.0, 0.85))
			draw_circle(cp, 1.8, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

for fname, content in files.items():
    with open(f"{out_dir}/{fname}", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Wrote {fname}")
