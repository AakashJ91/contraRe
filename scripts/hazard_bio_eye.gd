extends Area2D

# =============================================================================
# CONTRA RE - LIVING BIO-EYE SENTRY (STAGE 8 HAZARD)
# =============================================================================
# Organic living eyeball sentry embedded in the bio-ribs of Mother Brain's
# Sanctum. Pupils smoothly track the player, blink, and fire optic needle darts.

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

var health: float = 3.0
var anim_timer: float = 0.0
var flash_timer: float = 0.0
var shoot_timer: float = 2.4
var blink_timer: float = 3.5
var is_blinking: bool = false
var look_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	shoot_timer = randf_range(1.8, 3.2)
	blink_timer = randf_range(2.5, 4.5)
	
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
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
	Global.add_score(400)
	VFX.spawn_blood_splatter(global_position, look_dir, true)
	VFX.spawn_explosion(global_position, 1.1, false, true)
	queue_free()

func _draw() -> void:
	var col_socket := Color(0.35, 0.05, 0.12)
	var col_sclera := Color(0.92, 0.88, 0.82) if flash_timer <= 0.0 else Color.WHITE
	var col_iris := Color(0.95, 0.15, 0.25)
	var col_pupil := Color(0.08, 0.02, 0.02)
	
	# Organic fleshy eye socket
	draw_circle(Vector2.ZERO, 16.0, col_socket)
	
	# Bloodshot eyeball sclera
	draw_circle(Vector2.ZERO, 13.0, col_sclera)
	
	# Blood vessels in sclera
	for v in range(5):
		var v_ang := float(v) * (TAU / 5.0) + 0.2
		var v_end := Vector2(cos(v_ang), sin(v_ang)) * 12.0
		draw_line(Vector2.ZERO, v_end, Color(0.8, 0.15, 0.2, 0.45), 1.0)
	
	# Iris tracking player
	var pupil_offset := look_dir * 5.0
	draw_circle(pupil_offset, 6.5, col_iris)
	draw_circle(pupil_offset, 3.8, col_pupil)
	
	# Cornea reflection glint
	draw_circle(pupil_offset + Vector2(-2.0, -2.0), 1.5, Color.WHITE)
	
	# Blinking fleshy eyelid
	if is_blinking:
		draw_rect(Rect2(-16.0, -16.0, 32.0, 32.0), col_socket)
		draw_line(Vector2(-15.0, 0.0), Vector2(15.0, 0.0), Color(0.2, 0.02, 0.06), 2.5)
