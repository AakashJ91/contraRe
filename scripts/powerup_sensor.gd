extends Area2D

@export var powerup_scene: PackedScene = preload("res://scenes/powerup_item.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD

var health: float = 3.0
var flash_timer: float = 0.0
var anim_timer: float = 0.0
var sensor_texture: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies (can be shot by player bullets)
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	if ResourceLoader.exists("res://assets/powerups/powerup_sensor.png"):
		sensor_texture = load("res://assets/powerups/powerup_sensor.png")
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	if flash_timer > 0.0:
		flash_timer -= delta
	queue_redraw()

func take_damage(dmg: float = 1.0) -> void:
	health -= dmg
	flash_timer = 0.1
	Global.play_sfx("hit")
	if health <= 0.0:
		_die()

func _die() -> void:
	Global.add_score(500)
	Global.play_sfx("boss_explode")
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position
		get_parent().add_child(exp_node)
	if powerup_scene != null:
		var item = powerup_scene.instantiate()
		item.weapon_type = weapon_type
		item.global_position = global_position + Vector2(0.0, -10.0)
		get_parent().add_child(item)
	queue_free()

func _draw() -> void:
	if sensor_texture != null:
		var pw := 28.0
		var ph := 34.0
		var col: Color = Color(1.8, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
		draw_texture_rect(sensor_texture, Rect2(-pw * 0.5, -ph + 4.0, pw, ph), false, col)
		
		# Glowing red sensor scanner pulse
		var pulse := 0.5 + 0.5 * sin(anim_timer * 8.0)
		var core_col := Color(1.0, 0.2, 0.1, 0.6 + 0.4 * pulse)
		draw_circle(Vector2(0.0, -ph + 10.0), 3.5, core_col)
		return
	
	# Procedural fallback
	draw_circle(Vector2.ZERO, 12.0, Color(0.4, 0.45, 0.5))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.2, 0.2))
