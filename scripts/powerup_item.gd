extends Area2D

@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD
var velocity_y: float = -120.0
var bounce_count: int = 0
var anim_timer: float = 0.0

var tex_spread: Texture2D = null
var tex_machine: Texture2D = null
var tex_laser: Texture2D = null
var tex_fire: Texture2D = null

func _ready() -> void:
	collision_layer = 1 << 5 # Layer 6: Items
	collision_mask = (1 << 0) | (1 << 1) # Layer 1: Player, Layer 2: World
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if ResourceLoader.exists("res://assets/powerups/powerup_spread.png"):
		tex_spread = load("res://assets/powerups/powerup_spread.png")
	if ResourceLoader.exists("res://assets/powerups/powerup_machine.png"):
		tex_machine = load("res://assets/powerups/powerup_machine.png")
	if ResourceLoader.exists("res://assets/powerups/powerup_laser.png"):
		tex_laser = load("res://assets/powerups/powerup_laser.png")
	if ResourceLoader.exists("res://assets/powerups/powerup_fire.png"):
		tex_fire = load("res://assets/powerups/powerup_fire.png")
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	velocity_y += 500.0 * delta
	global_position.y += velocity_y * delta
	
	var over_ground := true
	var stage = get_tree().current_scene
	if stage != null and stage.has_method("is_position_over_ground"):
		over_ground = stage.is_position_over_ground(global_position.x)
	
	if over_ground:
		# Stop falling when near floor height or bounced
		if velocity_y > 0.0 and bounce_count < 2:
			if global_position.y >= 430.0:
				global_position.y = 430.0
				velocity_y = -100.0
				bounce_count += 1
		elif bounce_count >= 2 and global_position.y > 430.0:
			global_position.y = 430.0
			velocity_y = 0.0
	else:
		# Fall into bottomless pit
		if global_position.y > 550.0:
			queue_free()
			return
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_collect()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.name == "Player":
		_collect()

func _collect() -> void:
	Global.add_score(500)
	Global.set_weapon(weapon_type)
	Global.heal_player(1)
	VFX.spawn_powerup_sparkle(global_position)
	queue_free()

func _draw() -> void:
	var flash := fmod(anim_timer * 8.0, 1.0) > 0.4
	var badge_tex: Texture2D = null
	match weapon_type:
		Global.WeaponType.SPREAD:
			badge_tex = tex_spread
		Global.WeaponType.MACHINE:
			badge_tex = tex_machine
		Global.WeaponType.LASER:
			badge_tex = tex_laser
		_:
			badge_tex = tex_spread
	
	if badge_tex != null:
		var bw: float = 32.0
		var bh: float = 20.0
		var tint: Color = Color(1.3, 1.25, 1.1) if flash else Color.WHITE
		draw_texture_rect(badge_tex, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), false, tint)
		return
	
	var col_badge := Color(0.95, 0.85, 0.2) if flash else Color(0.9, 0.2, 0.2)
	var letter := "S"
	match weapon_type:
		Global.WeaponType.SPREAD:
			letter = "S"
		Global.WeaponType.MACHINE:
			letter = "M"
		Global.WeaponType.LASER:
			letter = "L"
	
	# Red/Golden Falcon Wings badge
	draw_circle(Vector2.ZERO, 10.0, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2.ZERO, 8.5, col_badge)
	
	# Wing tips
	draw_line(Vector2(-12.0, 0.0), Vector2(-6.0, 3.0), col_badge, 3.0)
	draw_line(Vector2(12.0, 0.0), Vector2(6.0, 3.0), col_badge, 3.0)
	
	# Letter rendering via line strokes
	var col_char := Color(1.0, 1.0, 1.0) if flash else Color(0.1, 0.1, 0.1)
	match letter:
		"S":
			# S glyph
			draw_line(Vector2(3.0, -5.0), Vector2(-3.0, -5.0), col_char, 2.0)
			draw_line(Vector2(-3.0, -5.0), Vector2(-3.0, 0.0), col_char, 2.0)
			draw_line(Vector2(-3.0, 0.0), Vector2(3.0, 0.0), col_char, 2.0)
			draw_line(Vector2(3.0, 0.0), Vector2(3.0, 5.0), col_char, 2.0)
			draw_line(Vector2(3.0, 5.0), Vector2(-3.0, 5.0), col_char, 2.0)
		"M":
			# M glyph
			draw_line(Vector2(-4.0, 5.0), Vector2(-4.0, -5.0), col_char, 2.0)
			draw_line(Vector2(-4.0, -5.0), Vector2(0.0, 0.0), col_char, 2.0)
			draw_line(Vector2(0.0, 0.0), Vector2(4.0, -5.0), col_char, 2.0)
			draw_line(Vector2(4.0, -5.0), Vector2(4.0, 5.0), col_char, 2.0)
		"L":
			# L glyph
			draw_line(Vector2(-3.0, -5.0), Vector2(-3.0, 5.0), col_char, 2.0)
			draw_line(Vector2(-3.0, 5.0), Vector2(4.0, 5.0), col_char, 2.0)
