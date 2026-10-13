extends Area2D

@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var damage: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var arc_gravity: float = 650.0
var spin_speed: float = 7.0
var lifetime: float = 4.0
var bounce_count: int = 1
var blink_timer: float = 0.0
var smoke_timer: float = 0.0
var trail_positions: Array[Vector2] = []
var grenade_texture: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 4 # Layer 5: EnemyBullets
	collision_mask = (1 << 0) | (1 << 1) # Layer 1: Player, Layer 2: World
	if ResourceLoader.exists("res://assets/enemies/grenade.png"):
		grenade_texture = load("res://assets/enemies/grenade.png")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	blink_timer += delta * 12.0
	smoke_timer += delta
	if smoke_timer >= 0.07:
		smoke_timer = 0.0
		VFX.spawn_dust_puff(global_position, 1, Color(0.7, 0.7, 0.75, 0.4))
	velocity.y += arc_gravity * delta
	global_position += velocity * delta
	rotation += spin_speed * delta
	lifetime -= delta
	
	# Trail positions for smoke effect
	trail_positions.push_front(global_position)
	if trail_positions.size() > 6:
		trail_positions.pop_back()
	
	if lifetime <= 0.0 or global_position.y > 600.0:
		_explode()
		return
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_explode()
	elif body.collision_layer & (1 << 1): # World collision
		if bounce_count > 0:
			bounce_count -= 1
			velocity.y = -absf(velocity.y) * 0.42
			velocity.x *= 0.7
			Global.play_sfx("hit")
		else:
			_explode()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.get_parent().is_in_group("player"):
		var p = area if area.is_in_group("player") else area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(damage)
		_explode()

func _explode() -> void:
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	
	# Blast radius damage check for player
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 55.0:
			if player_node.has_method("take_damage"):
				player_node.take_damage(damage)
	
	queue_free()

func _draw() -> void:
	if grenade_texture != null:
		var spr_s: float = 16.0
		draw_texture_rect(grenade_texture, Rect2(-spr_s * 0.5, -spr_s * 0.5, spr_s, spr_s), false)
		if fmod(blink_timer, 2.0) > 1.0:
			draw_circle(Vector2(5.0, -5.0), 3.5, Color(1.0, 0.2, 0.2, 0.65))
		return
	
	# Heavy tactical ordnance shell
	var col_body := Color(0.24, 0.28, 0.22) # Military olive drab
	var col_cap := Color(0.12, 0.12, 0.15) # Gunmetal
	var col_stripe := Color(0.95, 0.75, 0.1) # Warning hazard yellow
	var is_blinking: bool = fmod(blink_timer, 2.0) > 1.0
	var col_light := Color(1.0, 0.1, 0.1) if is_blinking else Color(0.3, 0.05, 0.05)
	
	# Main grenade body (capsule/oval)
	draw_rect(Rect2(-5.0, -4.0, 10.0, 8.0), col_body)
	draw_circle(Vector2(-5.0, 0.0), 4.0, col_body)
	draw_circle(Vector2(5.0, 0.0), 4.0, col_body)
	
	# Hazard ring
	draw_rect(Rect2(-2.0, -4.0, 4.0, 8.0), col_stripe)
	
	# Fuse head / impact cap
	draw_rect(Rect2(-6.5, -2.5, 3.0, 5.0), col_cap)
	draw_circle(Vector2(6.5, 0.0), 2.5, col_light)
	
	# Pulsing glow if blinking
	if is_blinking:
		draw_circle(Vector2(6.5, 0.0), 5.5, Color(1.0, 0.2, 0.2, 0.35))
