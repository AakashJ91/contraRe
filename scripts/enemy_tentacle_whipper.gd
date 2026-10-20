extends CharacterBody2D

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
	VFX.spawn_enemy_death_explosion(global_position)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 60.0
	var spr_h := 68.0
	var std_rect := Rect2(-30.0, -53.0, 60.0, 68.0)
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
