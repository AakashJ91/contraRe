extends Area2D

@export var powerup_scene: PackedScene = preload("res://scenes/powerup_item.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD
@export var speed: float = 240.0

var base_y: float = 0.0
var elapsed: float = 0.0
var blimp_texture: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	base_y = global_position.y
	if ResourceLoader.exists("res://assets/powerups/powerup_blimp.png"):
		blimp_texture = load("res://assets/powerups/powerup_blimp.png")
	queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta
	global_position.x += speed * delta
	global_position.y = base_y + sin(elapsed * 4.0) * 35.0
	
	# Clean despawn when blimp flies far past the visible screen
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var half_w: float = (get_viewport_rect().size.x / cam.zoom.x) * 0.5 if cam.zoom.x > 0.0 else 520.0
		if (speed > 0.0 and global_position.x > cam.global_position.x + half_w + 140.0) or \
		   (speed < 0.0 and global_position.x < cam.global_position.x - half_w - 140.0):
			queue_free()
			return
	
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
		if "velocity_x" in item:
			item.velocity_x = speed * 0.35
		get_parent().add_child(item)
	
	queue_free()

func _draw() -> void:
	var flash := fmod(elapsed * 8.0, 1.0) > 0.5
	var moving_left: bool = speed < 0.0
	
	if blimp_texture != null:
		var spr_w := 46.0
		var spr_h := 24.0
		var col: Color = Color(1.2, 1.15, 1.0) if flash else Color.WHITE
		var draw_x := spr_w * 0.5 if moving_left else -spr_w * 0.5
		var draw_w := -spr_w if moving_left else spr_w
		draw_texture_rect(blimp_texture, Rect2(draw_x, -spr_h * 0.5, draw_w, spr_h), false, col)
		
		# Glowing propulsion engine light at the tail
		var thruster_x: float = (spr_w * 0.5 - 4.0) if moving_left else (-spr_w * 0.5 + 4.0)
		var thruster_pos := Vector2(thruster_x, 0.0)
		var flicker_r := 3.0 + randf() * 2.0
		draw_circle(thruster_pos, flicker_r, Color(1.0, 0.6, 0.2, 0.8))
		return
	
	# Procedural fallback
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
