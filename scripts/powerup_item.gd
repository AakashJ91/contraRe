extends Area2D

@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD
var velocity_y: float = -120.0
var bounce_count: int = 0
var anim_timer: float = 0.0
var is_landed: bool = false
var landed_platform: Dictionary = {}

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
	
	var stage := _get_stage()
	
	# Despawn if camera has scrolled far past this powerup
	if stage != null and "camera" in stage and stage.camera != null and is_instance_valid(stage.camera):
		if stage.camera.global_position.x > 500.0 and global_position.x < stage.camera.global_position.x - 800.0:
			queue_free()
			return
	
	# If already landed, stay firmly planted on the platform or ground surface
	if is_landed:
		if not landed_platform.is_empty():
			var col = landed_platform.get("collider", null)
			if col != null and is_instance_valid(col) and col.disabled:
				# Platform collapsed or dropped away from beneath! Fall down!
				is_landed = false
				bounce_count = 2
				velocity_y = 60.0
				landed_platform = {}
			else:
				var pr: Rect2 = landed_platform.get("rect", Rect2())
				var cur_py: float = pr.position.y
				if col != null and is_instance_valid(col):
					cur_py = col.position.y - pr.size.y * 0.5
				global_position.y = cur_py - 8.0
		queue_redraw()
		return
	
	velocity_y += 500.0 * delta
	var prev_y: float = global_position.y
	var next_y: float = prev_y + velocity_y * delta
	
	if velocity_y <= 0.0:
		# Moving upwards during initial pop arc
		global_position.y = next_y
		queue_redraw()
		return
	
	# Falling downwards: query highest landing surface (platform or ground) directly below
	var surf_info: Dictionary = _find_landing_surface(stage, global_position.x, prev_y)
	if surf_info.get("found", false):
		var target_y: float = float(surf_info.get("landing_y", 422.0))
		if next_y >= target_y:
			global_position.y = target_y
			if bounce_count < 2:
				bounce_count += 1
				velocity_y = -90.0 / float(bounce_count)
			else:
				velocity_y = 0.0
				is_landed = true
				landed_platform = surf_info.get("platform", {})
		else:
			global_position.y = next_y
	else:
		# Over bottomless abyss / chasm
		global_position.y = next_y
		if global_position.y > 650.0:
			queue_free()
			return
	
	queue_redraw()

func _get_stage() -> Node:
	# 1. Direct parent (Stage1 is parent of all spawned items in normal gameplay)
	var p := get_parent()
	if p != null and is_instance_valid(p) and p.has_method("get_landing_surface"):
		return p
	# 2. Stage node in "stage" group
	if is_inside_tree():
		var st := get_tree().get_first_node_in_group("stage")
		if st != null and is_instance_valid(st) and st.has_method("get_landing_surface"):
			return st
		# 3. Current scene or child of current scene (e.g. Main.Stage1)
		var cs := get_tree().current_scene
		if cs != null and is_instance_valid(cs):
			if cs.has_method("get_landing_surface"):
				return cs
			var st_child := cs.get_node_or_null("Stage1")
			if st_child != null and is_instance_valid(st_child) and st_child.has_method("get_landing_surface"):
				return st_child
	return null

func _find_landing_surface(stage: Node, pos_x: float, from_y: float) -> Dictionary:
	if stage != null and is_instance_valid(stage) and stage.has_method("get_landing_surface"):
		return stage.get_landing_surface(pos_x, from_y)
	
	# Self-contained fallback inspection of platforms and ground
	var target_platforms: Array = []
	var target_ground: Array = []
	if stage != null and is_instance_valid(stage):
		if "platforms" in stage and stage.platforms is Array:
			target_platforms = stage.platforms
		if "ground_segments" in stage and stage.ground_segments is Array:
			target_ground = stage.ground_segments
	
	# If stage has no platform data loaded, retrieve directly from LevelMaps!
	if target_platforms.is_empty() and target_ground.is_empty():
		var map_data: Dictionary = LevelMaps.get_map_data(Global.current_stage)
		target_platforms = map_data.get("platforms", [])
		target_ground = map_data.get("ground_segments", [])
	
	var best_surf_y: float = 999999.0
	var found: bool = false
	var is_platform: bool = false
	var best_p: Dictionary = {}
	
	for p in target_platforms:
		var pr: Rect2 = p.get("rect", Rect2())
		if pos_x >= pr.position.x - 6.0 and pos_x <= pr.end.x + 6.0:
			var col = p.get("collider", null)
			if col != null and is_instance_valid(col) and col.disabled:
				continue
			var py: float = pr.position.y
			if col != null and is_instance_valid(col):
				py = col.position.y - pr.size.y * 0.5
			if py >= from_y - 8.0:
				if py < best_surf_y:
					best_surf_y = py
					found = true
					is_platform = true
					best_p = p
	
	for g in target_ground:
		if pos_x >= g.position.x - 6.0 and pos_x <= g.end.x + 6.0:
			var gy: float = g.position.y
			if gy >= from_y - 8.0:
				if gy < best_surf_y:
					best_surf_y = gy
					found = true
					is_platform = false
					best_p = {}
	
	if found:
		return {
			"found": true,
			"surface_y": best_surf_y,
			"landing_y": best_surf_y - 8.0,
			"is_platform": is_platform,
			"platform": best_p
		}
	
	return {"found": false, "surface_y": 0.0, "landing_y": 0.0, "is_platform": false, "platform": {}}


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
		Global.WeaponType.FIRE:
			badge_tex = tex_fire
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
		Global.WeaponType.FIRE:
			letter = "F"
	
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
		"F":
			# F glyph
			draw_line(Vector2(-3.0, 5.0), Vector2(-3.0, -5.0), col_char, 2.0)
			draw_line(Vector2(-3.0, -5.0), Vector2(4.0, -5.0), col_char, 2.0)
			draw_line(Vector2(-3.0, 0.0), Vector2(2.5, 0.0), col_char, 2.0)
