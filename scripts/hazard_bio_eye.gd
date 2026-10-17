extends Area2D

# =============================================================================
# CONTRA RE - LIVING BIO-EYE SENTRY (STAGE 8 HAZARD)
# =============================================================================
# Organic living eyeball sentry embedded in the bio-ribs of Mother Brain's
# Sanctum. Pupils smoothly track the player, blink, and fire optic needle darts.

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/bio_eye_data.tres")

var health: float = 3.0
var anim_timer: float = 0.0
var flash_timer: float = 0.0
var shoot_timer: float = 2.4
var blink_timer: float = 3.5
var is_blinking: bool = false
var look_dir: Vector2 = Vector2.DOWN

var tex_center: Texture2D = null
var tex_left: Texture2D = null
var tex_right: Texture2D = null
var tex_down: Texture2D = null
var tex_blink: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	if enemy_data != null:
		health = enemy_data.max_health
	shoot_timer = randf_range(1.8, 3.2)
	blink_timer = randf_range(2.5, 4.5)
	
	if ResourceLoader.exists("res://assets/enemies/hazards/bio_eye.png"):
		tex_center = load("res://assets/enemies/hazards/bio_eye.png")
	if ResourceLoader.exists("res://assets/enemies/hazards/bio_eye_left.png"):
		tex_left = load("res://assets/enemies/hazards/bio_eye_left.png")
	if ResourceLoader.exists("res://assets/enemies/hazards/bio_eye_right.png"):
		tex_right = load("res://assets/enemies/hazards/bio_eye_right.png")
	if ResourceLoader.exists("res://assets/enemies/hazards/bio_eye_down.png"):
		tex_down = load("res://assets/enemies/hazards/bio_eye_down.png")
	if ResourceLoader.exists("res://assets/enemies/hazards/bio_eye_blink.png"):
		tex_blink = load("res://assets/enemies/hazards/bio_eye_blink.png")
	
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	col_shape.shape = circle
	col_shape.position = Vector2.ZERO
	add_child(col_shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if flash_timer > 0.0:
		flash_timer -= delta
	
	# Blink animation cycle
	blink_timer -= delta
	if blink_timer <= 0.0:
		is_blinking = true
		if blink_timer <= -0.22:
			is_blinking = false
			blink_timer = randf_range(3.0, 5.5)
	
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		var to_player: Vector2 = (player.global_position - global_position).normalized()
		look_dir = look_dir.slerp(to_player, 8.0 * delta)
		
		# Shooting optic dart
		shoot_timer -= delta
		if shoot_timer <= 0.0 and global_position.distance_to(player.global_position) < 550.0:
			shoot_timer = randf_range(2.6, 3.6)
			_fire_optic_dart(player.global_position)
	
	queue_redraw()

func _fire_optic_dart(target_pos: Vector2) -> void:
	if bullet_scene == null or is_blinking:
		return
	var dir := (target_pos - global_position).normalized()
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.speed = 280.0
	b.damage = 1.0
	b.global_position = global_position + dir * 14.0
	get_parent().add_child(b)
	Global.play_sfx("hit")

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	var score_val := enemy_data.score_reward if enemy_data != null else 500
	Global.add_score(score_val)
	VFX.spawn_blood_splatter(global_position, look_dir, true)
	VFX.spawn_explosion(global_position, 1.1, false, true)
	queue_free()

func _draw() -> void:
	var flash_col := Color(2.0, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var cur_tex: Texture2D = tex_center
	
	if is_blinking and tex_blink != null:
		cur_tex = tex_blink
	elif look_dir.x < -0.3 and tex_left != null:
		cur_tex = tex_left
	elif look_dir.x > 0.3 and tex_right != null:
		cur_tex = tex_right
	elif look_dir.y > 0.3 and tex_down != null:
		cur_tex = tex_down
	
	if cur_tex != null:
		var draw_w := 36.0
		var draw_h := 34.0
		draw_texture_rect(cur_tex, Rect2(-draw_w * 0.5, -draw_h * 0.5, draw_w, draw_h), false, flash_col)
	else:
		# Fallback procedural
		var col_socket := Color(0.35, 0.05, 0.12)
		var col_sclera := Color(0.92, 0.88, 0.82) if flash_timer <= 0.0 else Color.WHITE
		draw_circle(Vector2.ZERO, 16.0, col_socket)
		draw_circle(Vector2.ZERO, 13.0, col_sclera)
