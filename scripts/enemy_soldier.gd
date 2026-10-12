extends CharacterBody2D

const SPEED: float = 90.0
const GRAVITY: float = 950.0

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

var facing_dir: int = -1
var health: float = 1.0
var shoot_timer: float = 0.0
var run_frame: float = 0.0
var jump_cooldown: float = 0.0
var turn_cooldown: float = 0.0
var flash_timer: float = 0.0
var tex_run: Array[Texture2D] = []
var soldier_texture: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 1) # Layer 2: World
	shoot_timer = randf_range(1.5, 3.5)
	
	for i in range(4):
		var p := "res://assets/enemies/enemy_soldier_run_%d.png" % i
		if ResourceLoader.exists(p):
			tex_run.append(load(p))
	
	if tex_run.is_empty() and ResourceLoader.exists("res://assets/enemies/enemy_soldier.png"):
		soldier_texture = load("res://assets/enemies/enemy_soldier.png")
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		run_frame += delta * 9.0
	
	shoot_timer -= delta
	jump_cooldown -= delta
	if turn_cooldown > 0.0:
		turn_cooldown -= delta
	
	# Seek player horizontally with momentum commitment
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		var diff: float = player_node.global_position.x - global_position.x
		if turn_cooldown <= 0.0 and abs(diff) > 28.0:
			var desired_dir: int = 1 if diff > 0.0 else -1
			if desired_dir != facing_dir:
				facing_dir = desired_dir
				turn_cooldown = 0.6 # Maintain charge before turning around again
	
	velocity.x = facing_dir * SPEED
	
	# Hop over obstacles or gaps
	if is_on_wall() and is_on_floor() and jump_cooldown <= 0.0:
		velocity.y = -330.0
		jump_cooldown = 1.2
	
	move_and_slide()
	
	# Despawn if fallen into bottomless pit
	if global_position.y > 550.0:
		queue_free()
		return
	
	# Shoot at player
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.0, 4.0)
		_shoot()
	
	queue_redraw()

func _shoot() -> void:
	if bullet_scene == null:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	
	var dir: Vector2 = (player_node.global_position - global_position).normalized()
	# Check distance
	if global_position.distance_to(player_node.global_position) > 450.0:
		return
	
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.global_position = global_position + Vector2(facing_dir * 10.0, -8.0)
	get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	Global.add_score(100)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	queue_free()

func _draw() -> void:
	var col: Color = Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var spr_w: float = 32.0
	var spr_h: float = 32.0
	var std_rect := Rect2(-16.0, -17.2, spr_w, spr_h)
	var scale_x: float = 1.0 if facing_dir >= 0 else -1.0
	
	if tex_run.size() > 0:
		var cur_tex: Texture2D
		var bob_y: float = 0.0
		if is_on_floor():
			var idx: int = int(fmod(run_frame, float(tex_run.size())))
			cur_tex = tex_run[idx]
			bob_y = -1.0 if (idx == 1 or idx == 3) else 0.0
		else:
			cur_tex = tex_run[0] # Stride jump pose in air
		
		draw_set_transform(Vector2(0.0, bob_y), 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(cur_tex, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	if soldier_texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(soldier_texture, std_rect, false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Procedural fallback
	var col_suit := Color(0.85, 0.25, 0.20) # Red uniform
	var col_skin := Color(0.9, 0.75, 0.6)
	var col_helmet := Color(0.4, 0.15, 0.15)
	var col_boots := Color(0.2, 0.2, 0.2)
	var dir_f := float(facing_dir)
	var leg_offset := sin(run_frame) * 4.0
	
	# Boots & Legs
	draw_line(Vector2(-2.0 * dir_f, 0.0), Vector2(-4.0 * dir_f - leg_offset, 12.0), col_suit, 4.0)
	draw_line(Vector2(2.0 * dir_f, 0.0), Vector2(4.0 * dir_f + leg_offset, 12.0), col_suit, 4.0)
	draw_rect(Rect2(-5.0 * dir_f - leg_offset, 10.0, 4.0, 4.0), col_boots)
	draw_rect(Rect2(3.0 * dir_f + leg_offset, 10.0, 4.0, 4.0), col_boots)
	
	# Torso
	draw_rect(Rect2(-5.0, -12.0, 10.0, 12.0), col_suit)
	
	# Head & Helmet
	draw_circle(Vector2(0.0, -16.0), 5.0, col_skin)
	draw_arc(Vector2(0.0, -17.0), 5.5, -PI, 0.0, 12, col_helmet, 3.0)
	
	# Rifle
	var gun_start := Vector2(dir_f * 2.0, -7.0)
	var gun_end := gun_start + Vector2(dir_f * 14.0, 2.0)
	draw_line(gun_start, gun_end, Color(0.25, 0.25, 0.3), 3.0)

