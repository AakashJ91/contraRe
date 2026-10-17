extends CharacterBody2D

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
	var std_rect := Rect2(-29.0, -41.0, 58.0, 60.0)
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
