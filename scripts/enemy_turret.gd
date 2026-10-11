extends Area2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

var health: float = 4.0
var aim_angle: float = -PI * 0.75
var shoot_timer: float = 2.0
var burst_count: int = 0
var burst_timer: float = 0.0
var flash_timer: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	queue_redraw()

func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		var target_angle = (player.global_position - global_position).angle()
		# Snap to 8-directional or smooth tracking
		aim_angle = rotate_toward(aim_angle, target_angle, 2.5 * delta)
		
		# Shoot handling
		if burst_count > 0:
			burst_timer -= delta
			if burst_timer <= 0.0:
				burst_timer = 0.18
				burst_count -= 1
				_fire_bullet()
		else:
			shoot_timer -= delta
			if shoot_timer <= 0.0 and global_position.distance_to(player.global_position) < 550.0:
				shoot_timer = 2.8
				burst_count = 3
				burst_timer = 0.05
	
	queue_redraw()

func _fire_bullet() -> void:
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = Vector2(cos(aim_angle), sin(aim_angle))
	b.global_position = global_position + b.direction * 16.0
	get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	Global.add_score(500)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	queue_free()

func _draw() -> void:
	var col_base := Color(0.3, 0.35, 0.4)
	var col_trim := Color(0.5, 0.55, 0.6)
	var col_barrel := Color(0.2, 0.22, 0.25)
	
	if flash_timer > 0.0:
		col_base = Color(1.0, 0.4, 0.4)
		col_trim = Color(1.0, 0.8, 0.8)
	
	# Bunker base dome
	draw_circle(Vector2.ZERO, 15.0, col_base)
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, col_trim, 2.5)
	draw_circle(Vector2.ZERO, 8.0, Color(0.18, 0.2, 0.22))
	
	# Twin gun barrels pointing in aim_angle
	var barrel_dir := Vector2(cos(aim_angle), sin(aim_angle))
	var perp := Vector2(-barrel_dir.y, barrel_dir.x) * 4.0
	draw_line(perp, perp + barrel_dir * 18.0, col_barrel, 4.0)
	draw_line(-perp, -perp + barrel_dir * 18.0, col_barrel, 4.0)
