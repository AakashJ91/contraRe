extends CharacterBody2D

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
	VFX.spawn_enemy_death_explosion(global_position)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
	var spr_h := 56.0
	var std_rect := Rect2(-27.0, -39.0, 54.0, 56.0)
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
