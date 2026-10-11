extends Control

var selected_index: int = 0
var menu_items: Array[String] = [
	"START MISSION",
	"SELECT LEVEL",
	"HOW TO PLAY",
	"SOUND: ON"
]

var sound_enabled: bool = true
var show_instructions: bool = false
var anim_timer: float = 0.0
var stars: Array[Vector2] = []
var bg_texture: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/backgrounds/title_bg.jpg"):
		bg_texture = load("res://assets/backgrounds/title_bg.jpg")
	for i in range(50):
		stars.append(Vector2(randf_range(0.0, 960.0), randf_range(0.0, 540.0)))
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if show_instructions:
		if event.is_pressed():
			show_instructions = false
			Global.play_sfx("menu_cursor")
			queue_redraw()
		return
	
	if event.is_action_pressed("move_up"):
		selected_index = (selected_index - 1 + menu_items.size()) % menu_items.size()
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		selected_index = (selected_index + 1) % menu_items.size()
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("jump") or event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		_activate_menu_item(selected_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position)

func _handle_touch(pos: Vector2) -> void:
	if show_instructions:
		show_instructions = false
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	# Check menu item clicks (between y = 300 and y = 470)
	var start_y := 310.0
	var item_height := 42.0
	for i in range(menu_items.size()):
		var item_y := start_y + float(i) * item_height
		var item_rect := Rect2(300.0, item_y - 12.0, 360.0, 34.0)
		if item_rect.has_point(pos):
			selected_index = i
			_activate_menu_item(i)
			return

func _activate_menu_item(index: int) -> void:
	match index:
		0:
			# START MISSION
			Global.play_sfx("menu_start")
			get_tree().create_timer(0.4).timeout.connect(func(): Global.start_game(1))
		1:
			# SELECT LEVEL
			Global.play_sfx("menu_start")
			get_tree().create_timer(0.2).timeout.connect(func(): Global.go_to_level_select())
		2:
			# HOW TO PLAY
			Global.play_sfx("menu_cursor")
			show_instructions = true
			queue_redraw()
		3:
			# TOGGLE SOUND
			sound_enabled = not sound_enabled
			var bus_idx := AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(bus_idx, not sound_enabled)
			menu_items[3] = "SOUND: " + ("ON" if sound_enabled else "OFF")
			Global.play_sfx("menu_cursor")
			queue_redraw()

func _draw() -> void:
	if bg_texture != null:
		draw_texture_rect(bg_texture, Rect2(0.0, 0.0, 960.0, 540.0), false)
		# Cinematic dark gradient wash for menu contrast
		draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.02, 0.04, 0.08, 0.45))
	else:
		draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.04, 0.05, 0.1))
	
	# Twinkling stars
	for i in range(stars.size()):
		var s := stars[i]
		var star_alpha := 0.3 + 0.7 * sin(anim_timer * 3.0 + float(i))
		draw_circle(s, 1.5, Color(0.8, 0.9, 1.0, star_alpha))
	
	# Retro perspective grid at bottom
	var grid_horizon := 360.0
	draw_line(Vector2(0.0, grid_horizon), Vector2(960.0, grid_horizon), Color(0.15, 0.35, 0.7, 0.4), 2.0)
	for i in range(16):
		var x_top := 480.0 + (float(i) - 7.5) * 45.0
		var x_bot := 480.0 + (float(i) - 7.5) * 110.0
		draw_line(Vector2(x_top, grid_horizon), Vector2(x_bot, 540.0), Color(0.1, 0.25, 0.6, 0.25), 1.5)
	
	# Glowing Falcon Emblem in Center-Back
	var emblem_pos := Vector2(480.0, 160.0)
	var glow_pulse := 0.2 + 0.1 * sin(anim_timer * 4.0)
	draw_circle(emblem_pos, 85.0, Color(0.8, 0.2, 0.1, glow_pulse))
	draw_circle(emblem_pos, 70.0, Color(0.9, 0.5, 0.1, glow_pulse * 0.8))
	
	# Title Text: CONTRA RE
	_draw_title_logo()
	
	# Subtitle
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(340.0, 248.0), "--- THE ALIEN WARS REBORN ---", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.85, 1.0))
	
	# Instructions Overlay or Menu Items
	if show_instructions:
		_draw_instructions_card()
	else:
		_draw_menu()
	
	# Bottom Copyright line
	draw_string(font, Vector2(270.0, 520.0), "© 2026 CONTRA RE PROJECT • BUILT FOR ANDROID & PC", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.55, 0.65))

func _draw_title_logo() -> void:
	var font := ThemeDB.fallback_font
	var logo_text := "CONTRA"
	var logo_pos := Vector2(260.0, 190.0)
	
	# Drop shadow
	draw_string(font, logo_pos + Vector2(6.0, 6.0), logo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color(0.1, 0.0, 0.0, 0.9))
	# Crimson bevel
	draw_string(font, logo_pos + Vector2(2.0, 3.0), logo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color(0.7, 0.05, 0.05))
	# Golden glow
	draw_string(font, logo_pos, logo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color(1.0, 0.85, 0.2))
	
	# "RE" Badge
	var re_badge_pos := Vector2(650.0, 150.0)
	draw_rect(Rect2(re_badge_pos.x - 6.0, re_badge_pos.y - 32.0, 72.0, 40.0), Color(0.9, 0.15, 0.15))
	draw_rect(Rect2(re_badge_pos.x - 4.0, re_badge_pos.y - 30.0, 68.0, 36.0), Color(0.1, 0.15, 0.25))
	draw_string(font, re_badge_pos + Vector2(6.0, 0.0), "RE", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(0.2, 0.9, 1.0))

func _draw_menu() -> void:
	var font := ThemeDB.fallback_font
	var start_y := 310.0
	var item_height := 42.0
	
	for i in range(menu_items.size()):
		var item_y := start_y + float(i) * item_height
		var is_sel := (i == selected_index)
		
		# Button Card Background
		var card_rect := Rect2(310.0, item_y - 14.0, 340.0, 32.0)
		var bg_col := Color(0.15, 0.25, 0.45, 0.75) if is_sel else Color(0.08, 0.1, 0.16, 0.5)
		draw_rect(card_rect, bg_col)
		
		var border_col := Color(1.0, 0.85, 0.2) if is_sel else Color(0.25, 0.35, 0.5, 0.5)
		draw_rect(card_rect, border_col, false, 2.0 if is_sel else 1.0)
		
		# Selection pointer indicator (Falcon wing)
		if is_sel:
			var pointer_x: float = 280.0 + sin(anim_timer * 8.0) * 4.0
			draw_polygon(PackedVector2Array([
				Vector2(pointer_x, item_y - 8.0),
				Vector2(pointer_x + 14.0, item_y + 2.0),
				Vector2(pointer_x, item_y + 12.0)
			]), [Color(1.0, 0.85, 0.2)])
		
		var text_col := Color(1.0, 0.95, 0.4) if is_sel else Color(0.8, 0.85, 0.9)
		draw_string(font, Vector2(340.0, item_y + 8.0), menu_items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, text_col)

func _draw_instructions_card() -> void:
	var font := ThemeDB.fallback_font
	# Modal Box
	var box_rect := Rect2(180.0, 180.0, 600.0, 300.0)
	draw_rect(box_rect, Color(0.05, 0.08, 0.15, 0.96))
	draw_rect(box_rect, Color(0.2, 0.7, 1.0), false, 2.5)
	
	draw_string(font, Vector2(360.0, 220.0), "COMMANDO BRIEFING", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.85, 0.2))
	
	# Instructions lines
	var lines := [
		"• 8-WAY AIMING: W/A/S/D or Virtual D-Pad to aim in all 8 directions.",
		"• CROUCH / PRONE: Hold Down on floor to dodge high rifle fire.",
		"• DROP PLATFORMS: Hold Down + Press Jump to fall through bridges.",
		"• WEAPONS: Destroy flying pods for Spread (S), Machine (M), Laser (L).",
		"• OBJECTIVE: Infiltrate the perimeter and destroy the Wall Defense Core."
	]
	
	for j in range(lines.size()):
		draw_string(font, Vector2(210.0, 260.0 + float(j) * 32.0), lines[j], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.95, 1.0))
	
	# Close prompt
	var prompt := "[ TAP ANYWHERE OR PRESS JUMP TO CLOSE ]"
	draw_string(font, Vector2(290.0, 450.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.2, 1.0, 0.5))
