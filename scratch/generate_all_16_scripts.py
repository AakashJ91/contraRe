import os

out_dir = "scripts"
os.makedirs(out_dir, exist_ok=True)

# We will write all 16 scripts cleanly.
files = {}

# 1. guerrilla_gunner
files["enemy_guerrilla_gunner.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/guerrilla_gunner_data.tres")
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

const SPEED: float = 90.0
const GRAVITY: float = 950.0

var health: float = 2.0
var facing_dir: int = -1
var shoot_timer: float = 2.0
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var roll_timer: float = 0.0

var is_ambushing: bool = true
var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 1 << 1  # Layer 2: World
	
	if ResourceLoader.exists("res://assets/enemies/guerrilla_gunner/guerrilla_gunner.png"):
		base_texture = load("res://assets/enemies/guerrilla_gunner/guerrilla_gunner.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/guerrilla_gunner/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/guerrilla_gunner/death/destroy_%d.png" % i
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
		if absf(diff) < 260.0 and is_ambushing:
			is_ambushing = false # Spring ambush!
			VFX.spawn_dust_puff(global_position + Vector2(0.0, 10.0), 4)
			Global.play_sfx("hit")
		if not is_ambushing:
			facing_dir = 1 if diff > 0.0 else -1
	
	if is_ambushing:
		velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return
		
	if roll_timer > 0.0:
		roll_timer -= delta
		velocity.x = -facing_dir * 130.0 # Evasive backwards roll
	else:
		velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = randf_range(2.0, 3.2)
			_fire_spread_burst()
			roll_timer = 0.45
			
	anim_frame += delta * 6.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _fire_spread_burst() -> void:
	if bullet_scene == null: return
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var base_dir := Vector2(facing_dir, 0.0)
	var angles := [-0.22, 0.0, 0.22]
	for a in angles:
		var b = bullet_scene.instantiate()
		b.bullet_owner = b.BulletOwner.ENEMY
		b.direction = base_dir.rotated(a)
		b.global_position = global_position + Vector2(facing_dir * 14.0, -8.0)
		parent_node.add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	is_ambushing = false
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(200)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 60.0, -140.0)
	Global.shake_screen(3.5, 0.15)
	VFX.spawn_dust_puff(global_position + Vector2(0.0, 8.0), 4)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
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
		if is_ambushing:
			draw_texture_rect(cur_tex, Rect2(-spr_w * 0.5, -spr_h * 0.35, spr_w, spr_h * 0.8), false, col)
			draw_circle(Vector2(0.0, -8.0), 12.0, Color(0.2, 0.45, 0.2, 0.85))
		else:
			draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 2. flame_trooper
files["enemy_flame_trooper.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/flame_trooper_data.tres")

const SPEED: float = 65.0
const GRAVITY: float = 950.0

var health: float = 4.5
var facing_dir: int = -1
var shoot_timer: float = 2.2
var anim_frame: float = 0.0
var flash_timer: float = 0.0
var flamethrower_stream_count: int = 0
var stream_delay: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/flame_trooper/flame_trooper.png"):
		base_texture = load("res://assets/enemies/flame_trooper/flame_trooper.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/flame_trooper/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/flame_trooper/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)
		if not is_on_floor(): velocity.y += GRAVITY * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5:
			_explode_fuel_tank()
			queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	if not is_on_floor(): velocity.y += GRAVITY * delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff := player_node.global_position.x - global_position.x
		if absf(diff) > 20.0: facing_dir = 1 if diff > 0.0 else -1
	
	if flamethrower_stream_count > 0:
		velocity.x = 0.0
		stream_delay -= delta
		if stream_delay <= 0.0:
			stream_delay = 0.12
			flamethrower_stream_count -= 1
			_emit_flame()
	else:
		velocity.x = facing_dir * SPEED
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = randf_range(2.5, 3.8)
			flamethrower_stream_count = 3
			stream_delay = 0.05
			
	anim_frame += delta * 4.5
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 26.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.5)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _emit_flame() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("hit")
	var flame = EnemySpecialProjectile.new()
	flame.proj_type = EnemySpecialProjectile.ProjectileType.FLAME
	flame.damage = 1.0
	flame.velocity = Vector2(facing_dir * randf_range(170.0, 220.0), randf_range(-70.0, -20.0))
	flame.global_position = global_position + Vector2(facing_dir * 18.0, -8.0)
	parent_node.add_child(flame)

func _explode_fuel_tank() -> void:
	VFX.spawn_explosion(global_position)
	Global.shake_screen(6.0, 0.25)
	Global.play_sfx("explosion")
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 65.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)

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
	velocity = Vector2(-facing_dir * 45.0, -110.0)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 68.0
	var spr_h := 64.0
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

# 3. scuba_commando
files["enemy_scuba_commando.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/scuba_commando_data.tres")

const SPEED: float = 75.0
const GRAVITY: float = 950.0

var health: float = 2.5
var facing_dir: int = -1
var shoot_timer: float = 1.8
var anim_frame: float = 0.0
var flash_timer: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/scuba_commando/scuba_commando.png"):
		base_texture = load("res://assets/enemies/scuba_commando/scuba_commando.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/scuba_commando/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/scuba_commando/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
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
		if absf(diff) > 20.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.0, 3.2)
		_fire_harpoon()
		
	anim_frame += delta * 5.5
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _fire_harpoon() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node): return
	
	Global.play_sfx("shoot")
	var dir := (player_node.global_position - global_position).normalized()
	var harpoon = EnemySpecialProjectile.new()
	harpoon.proj_type = EnemySpecialProjectile.ProjectileType.HARPOON
	harpoon.damage = 1.0
	harpoon.velocity = dir * 360.0
	harpoon.global_position = global_position + Vector2(facing_dir * 14.0, -6.0)
	parent_node.add_child(harpoon)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(250)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 50.0, -130.0)
	Global.shake_screen(3.5, 0.15)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
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
"""

# 4. torpedo_drone
files["enemy_torpedo_drone.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/torpedo_drone_data.tres")

const SPEED: float = 85.0

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
	
	if ResourceLoader.exists("res://assets/enemies/torpedo_drone/torpedo_drone.png"):
		base_texture = load("res://assets/enemies/torpedo_drone/torpedo_drone.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/torpedo_drone/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/torpedo_drone/death/destroy_%d.png" % i
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
		if absf(diff) > 30.0: facing_dir = 1 if diff > 0.0 else -1
		
		if absf(diff) < 90.0:
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				shoot_timer = randf_range(2.2, 3.4)
				_drop_depth_charge()
	
	velocity.x = facing_dir * SPEED
	global_position.y = start_y + sin(hover_time * 2.8) * 16.0
	move_and_slide()
	
	anim_frame += delta * 6.0
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	queue_redraw()

func _drop_depth_charge() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var dc = EnemySpecialProjectile.new()
	dc.proj_type = EnemySpecialProjectile.ProjectileType.DEPTH_CHARGE
	dc.damage = 1.0
	dc.velocity = Vector2(facing_dir * 30.0, 40.0)
	dc.global_position = global_position + Vector2(0.0, 10.0)
	parent_node.add_child(dc)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(250)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 50.0, -100.0)
	VFX.spawn_explosion(global_position)
	Global.shake_screen(3.5, 0.2)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 56.0
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
		draw_circle(Vector2(-spr_w * 0.4, 0.0), 3.0, Color(0.4, 0.8, 1.0, 0.7))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 5. acid_spitter
files["enemy_acid_spitter.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/acid_spitter_data.tres")

const SPEED: float = 70.0
const GRAVITY: float = 950.0

var health: float = 4.0
var facing_dir: int = -1
var shoot_timer: float = 2.2
var anim_frame: float = 0.0
var flash_timer: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/acid_spitter/acid_spitter.png"):
		base_texture = load("res://assets/enemies/acid_spitter/acid_spitter.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/acid_spitter/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/acid_spitter/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
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
		shoot_timer = randf_range(2.4, 3.6)
		_spit_acid()
		
	anim_frame += delta * 5.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 26.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.5)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _spit_acid() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("hit")
	var glob = EnemySpecialProjectile.new()
	glob.proj_type = EnemySpecialProjectile.ProjectileType.ACID_GLOB
	glob.damage = 1.0
	glob.velocity = Vector2(facing_dir * randf_range(160.0, 220.0), randf_range(-320.0, -260.0))
	glob.global_position = global_position + Vector2(facing_dir * 18.0, -12.0)
	parent_node.add_child(glob)

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
	velocity = Vector2(-facing_dir * 50.0, -120.0)
	VFX.spawn_dust_puff(global_position, 5, Color(0.3, 0.9, 0.4))

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 62.0
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
"""

# 6. ceiling_stalker
files["enemy_ceiling_stalker.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/ceiling_stalker_data.tres")

const SPEED: float = 140.0
const GRAVITY: float = 950.0

enum State { CEILING, PLUNGING, CRAWL }
var state: State = State.CEILING

var health: float = 2.5
var facing_dir: int = -1
var anim_frame: float = 0.0
var flash_timer: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/ceiling_stalker/ceiling_stalker.png"):
		base_texture = load("res://assets/enemies/ceiling_stalker/ceiling_stalker.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/ceiling_stalker/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/ceiling_stalker/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
		if not is_on_floor(): velocity.y += GRAVITY * delta
		move_and_slide()
		death_timer += delta
		death_frame = clampi(int(death_timer * 8.0), 0, 3)
		if death_timer >= 0.5: queue_free()
		queue_redraw()
		return
		
	if flash_timer > 0.0: flash_timer -= delta
	
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.CEILING:
			velocity = Vector2.ZERO
			if player_node != null and is_instance_valid(player_node):
				var diff_x := absf(player_node.global_position.x - global_position.x)
				if diff_x < 85.0 and player_node.global_position.y > global_position.y:
					state = State.PLUNGING
					velocity.y = 380.0
					Global.play_sfx("shoot")
		State.PLUNGING:
			velocity.y += GRAVITY * delta
			if is_on_floor() or is_on_wall():
				state = State.CRAWL
				VFX.spawn_dust_puff(global_position + Vector2(0.0, 10.0), 5)
				Global.shake_screen(3.0, 0.15)
		State.CRAWL:
			if not is_on_floor(): velocity.y += GRAVITY * delta
			if player_node != null and is_instance_valid(player_node):
				facing_dir = 1 if player_node.global_position.x > global_position.x else -1
			velocity.x = facing_dir * SPEED
			
	move_and_slide()
	anim_frame += delta * 8.0
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 22.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	if state == State.CEILING: state = State.PLUNGING
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(300)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 50.0, -120.0)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
	var spr_h := 52.0
	var std_rect := Rect2(-spr_w * 0.5, -spr_h * 0.5, spr_w, spr_h)
	var scale_x := 1.0 if facing_dir >= 0 else -1.0
	var scale_y := -1.0 if state == State.CEILING else 1.0
	
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
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, scale_y))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 7. cryo_trooper
files["enemy_cryo_trooper.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/cryo_trooper_data.tres")

const SPEED: float = 60.0
const GRAVITY: float = 950.0

var health: float = 4.5
var facing_dir: int = -1
var shoot_timer: float = 2.4
var anim_frame: float = 0.0
var flash_timer: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/cryo_trooper/cryo_trooper.png"):
		base_texture = load("res://assets/enemies/cryo_trooper/cryo_trooper.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/cryo_trooper/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/cryo_trooper/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
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
		shoot_timer = randf_range(2.6, 4.0)
		_launch_cryo_mortar()
		
	anim_frame += delta * 4.5
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 24.0:
			if player_node.has_method("take_damage"): player_node.take_damage(1.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _launch_cryo_mortar() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	var mortar = EnemySpecialProjectile.new()
	mortar.proj_type = EnemySpecialProjectile.ProjectileType.ICE_MORTAR
	mortar.damage = 1.0
	mortar.velocity = Vector2(facing_dir * randf_range(160.0, 230.0), randf_range(-340.0, -280.0))
	mortar.global_position = global_position + Vector2(facing_dir * 16.0, -14.0)
	parent_node.add_child(mortar)

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
	velocity = Vector2(-facing_dir * 45.0, -110.0)
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(0.6, 0.9, 1.0))

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 58.0
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
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""

# 8. sled_raider
files["enemy_sled_raider.gd"] = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/sled_raider_data.tres")
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

const SPEED: float = 190.0
const GRAVITY: float = 950.0

var health: float = 5.0
var facing_dir: int = -1
var shoot_timer: float = 1.2
var anim_frame: float = 0.0
var flash_timer: float = 0.0

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
	
	if ResourceLoader.exists("res://assets/enemies/sled_raider/sled_raider.png"):
		base_texture = load("res://assets/enemies/sled_raider/sled_raider.png")
	for i in range(4):
		var p_walk := "res://assets/enemies/sled_raider/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/sled_raider/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): death_textures.append(load(p_death))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
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
		if absf(diff) > 40.0: facing_dir = 1 if diff > 0.0 else -1
	
	velocity.x = facing_dir * SPEED
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(1.4, 2.2)
		_fire_twin_guns()
		
	# Snow track spray
	if is_on_floor() and randf() < 0.3:
		VFX.spawn_dust_puff(global_position + Vector2(-facing_dir * 18.0, 10.0), 2, Color(0.85, 0.95, 1.0, 0.7))
		
	anim_frame += delta * 9.0
	move_and_slide()
	
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 28.0:
			if player_node.has_method("take_damage"): player_node.take_damage(2.0)
	if global_position.y > 600.0: queue_free()
	queue_redraw()

func _fire_twin_guns() -> void:
	if bullet_scene == null: return
	var parent_node = get_parent()
	if parent_node == null: return
	Global.play_sfx("shoot")
	for y_off in [-4.0, 4.0]:
		var b = bullet_scene.instantiate()
		b.bullet_owner = b.BulletOwner.ENEMY
		b.direction = Vector2(facing_dir, 0.0)
		b.global_position = global_position + Vector2(facing_dir * 22.0, -6.0 + y_off)
		parent_node.add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	if is_dying: return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0: _die()

func _die() -> void:
	if is_dying: return
	is_dying = true
	Global.add_score(400)
	collision_layer = 0
	velocity = Vector2(-facing_dir * 80.0, -150.0)
	VFX.spawn_explosion(global_position)
	Global.shake_screen(4.5, 0.2)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 68.0
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
"""

# Write chunk 1
for fname, content in files.items():
    with open(f"{out_dir}/{fname}", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Wrote {fname}")
