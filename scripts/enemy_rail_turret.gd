extends CharacterBody2D

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
	var std_rect := Rect2(-30.0, -22.5, 60.0, 56.0)
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
