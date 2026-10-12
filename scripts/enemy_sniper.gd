extends Area2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

var health: float = 2.0
var shoot_timer: float = 2.2
var flash_timer: float = 0.0
var facing_dir: int = -1
var sniper_texture: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	if ResourceLoader.exists("res://assets/enemies/enemy_sniper.png"):
		sniper_texture = load("res://assets/enemies/enemy_sniper.png")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		facing_dir = 1 if player.global_position.x > global_position.x else -1
		
		shoot_timer -= delta
		if shoot_timer <= 0.0 and global_position.distance_to(player.global_position) < 600.0:
			shoot_timer = randf_range(2.0, 3.2)
			_shoot(player.global_position)
	
	queue_redraw()

func _shoot(target_pos: Vector2) -> void:
	if bullet_scene == null:
		return
	var dir := (target_pos - global_position).normalized()
	var b = bullet_scene.instantiate()
	b.bullet_owner = b.BulletOwner.ENEMY
	b.direction = dir
	b.speed = 300.0
	b.global_position = global_position + dir * 18.0
	get_parent().add_child(b)

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	Global.add_score(300)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	queue_free()

func _draw() -> void:
	if sniper_texture != null:
		var spr_w: float = 34.0
		var spr_h: float = 28.0
		var col: Color = Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
		
		# Sniper sprite aims left by default (facing_dir == -1). Flip horizontally if facing_dir == 1.
		var scale_x: float = -1.0 if facing_dir > 0 else 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_texture_rect(sniper_texture, Rect2(-spr_w * 0.5, -spr_h * 0.5 - 2.0, spr_w, spr_h), false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	
	# Procedural fallback
	var col_suit := Color(0.2, 0.45, 0.25) # Jungle camouflage green
	var col_skin := Color(0.9, 0.75, 0.6)
	var col_gun := Color(0.15, 0.15, 0.18)
	var dir_f := float(facing_dir)
	
	if flash_timer > 0.0:
		col_suit = Color(1.0, 0.4, 0.4)
	
	# Kneeling body
	draw_rect(Rect2(-6.0, -8.0, 12.0, 10.0), col_suit)
	# Helmet
	draw_circle(Vector2(0.0, -13.0), 5.0, col_suit)
	draw_circle(Vector2(dir_f * 2.0, -12.0), 3.0, col_skin)
	
	# Long sniper rifle pointing toward facing direction
	var barrel_start := Vector2(0.0, -7.0)
	var barrel_end := barrel_start + Vector2(dir_f * 22.0, 4.0)
	draw_line(barrel_start, barrel_end, col_gun, 3.5)
	# Scope
	draw_line(barrel_start + Vector2(dir_f * 6.0, -3.0), barrel_start + Vector2(dir_f * 14.0, -1.0), Color(0.3, 0.3, 0.35), 2.0)
