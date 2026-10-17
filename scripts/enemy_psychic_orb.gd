extends CharacterBody2D

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
	var std_rect := Rect2(-30.0, -30.0, 60.0, 60.0)
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
			var ca: float = hover_time * 4.0 + float(c)
			var cp := Vector2(cos(ca) * 26.0, sin(ca) * 16.0)
			draw_circle(cp, 3.5, Color(0.9, 0.3, 1.0, 0.85))
			draw_circle(cp, 1.8, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
