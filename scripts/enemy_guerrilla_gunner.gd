extends CharacterBody2D

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

static var s_base_texture: Texture2D = null
static var s_walk_textures: Array[Texture2D] = []
static var s_death_textures: Array[Texture2D] = []
static var s_assets_loaded: bool = false

static func _ensure_assets_loaded() -> void:
	if s_assets_loaded:
		return
	s_assets_loaded = true
	if ResourceLoader.exists("res://assets/enemies/guerrilla_gunner/guerrilla_gunner.png"):
		s_base_texture = load("res://assets/enemies/guerrilla_gunner/guerrilla_gunner.png")
	s_walk_textures.clear()
	s_death_textures.clear()
	for i in range(4):
		var p_walk := "res://assets/enemies/guerrilla_gunner/movement/walk_%d.png" % i
		if ResourceLoader.exists(p_walk): s_walk_textures.append(load(p_walk))
		var p_death := "res://assets/enemies/guerrilla_gunner/death/destroy_%d.png" % i
		if ResourceLoader.exists(p_death): s_death_textures.append(load(p_death))

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = 1 << 1  # Layer 2: World
	
	_ensure_assets_loaded()
	base_texture = s_base_texture
	walk_textures = s_walk_textures
	death_textures = s_death_textures
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
	VFX.spawn_enemy_death_explosion(global_position)

func _draw() -> void:
	var col := Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w := 54.0
	var spr_h := 56.0
	var std_rect := Rect2(-27.0, -38.0, 54.0, 56.0)
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
