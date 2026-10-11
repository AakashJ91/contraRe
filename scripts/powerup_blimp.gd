extends Area2D

@export var powerup_scene: PackedScene = preload("res://scenes/powerup_item.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD
@export var speed: float = 140.0

var base_y: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	base_y = global_position.y
	queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta
	global_position.x += speed * delta
	global_position.y = base_y + sin(elapsed * 4.0) * 35.0
	queue_redraw()

func take_damage(_dmg: float = 1.0) -> void:
	_pop()

func _pop() -> void:
	Global.play_sfx("hit")
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	
	if powerup_scene != null:
		var item = powerup_scene.instantiate()
		item.weapon_type = weapon_type
		item.global_position = global_position
		get_parent().add_child(item)
	
	queue_free()

func _draw() -> void:
	var flash := fmod(elapsed * 6.0, 1.0) > 0.4
	var col_capsule := Color(0.9, 0.2, 0.2) if flash else Color(0.9, 0.9, 0.9)
	var col_falcon := Color(0.95, 0.8, 0.2)
	
	# Flying capsule body (rounded pill)
	draw_circle(Vector2(-10.0, 0.0), 7.0, col_capsule)
	draw_circle(Vector2(10.0, 0.0), 7.0, col_capsule)
	draw_rect(Rect2(-10.0, -7.0, 20.0, 14.0), col_capsule)
	
	# Wing flaps
	var wing_y := sin(elapsed * 12.0) * 4.0
	draw_line(Vector2(-5.0, wing_y - 8.0), Vector2(5.0, wing_y - 8.0), col_falcon, 3.0)
	draw_line(Vector2(-5.0, -wing_y + 8.0), Vector2(5.0, -wing_y + 8.0), col_falcon, 3.0)
	
	# Center falcon sensor core
	draw_circle(Vector2.ZERO, 3.5, Color(0.2, 0.8, 1.0))
