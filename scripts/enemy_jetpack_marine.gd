extends CharacterBody2D

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
	VFX.spawn_enemy_death_explosion(global_position)
	Global.shake_screen(3.5, 0.2)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 56.0
	var spr_h := 60.0
	var std_rect := Rect2(-28.0, -30.0, 56.0, 60.0)
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
