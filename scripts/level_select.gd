extends Control

var selected_stage: int = 1
var anim_timer: float = 0.0

var stages_info: Array[Dictionary] = [
	{
		"id": 1,
		"name": "STAGE 1: JUNGLE PERIMETER",
		"theme": "JUNGLE & FORTRESS WALL",
		"diff": "NORMAL",
		"desc": "Infiltrate tropical jungle canopy, dodge sniper towers, and destroy the armored Wall Defense Core.",
		"color": Color(0.2, 0.7, 0.3)
	},
	{
		"id": 2,
		"name": "STAGE 2: WATERFALL FORTRESS",
		"theme": "TORRENTIAL CLIFFSIDE",
		"diff": "HARD",
		"desc": "Ascend cascading waterfalls with rapid enemy infantry rushes and intense automated turret crossfire.",
		"color": Color(0.2, 0.5, 0.9)
	},
	{
		"id": 3,
		"name": "STAGE 3: ALIEN HIVE LAIR",
		"theme": "SUBTERRANEAN BIO-CORE",
		"diff": "EXPERT",
		"desc": "Penetrate deep subterranean caverns, face aggressive alien vanguard swarms and the heart core.",
		"color": Color(0.85, 0.25, 0.25)
	}
]

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		selected_stage = 3 if selected_stage == 1 else selected_stage - 1
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("move_right"):
		selected_stage = 1 if selected_stage == 3 else selected_stage + 1
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("jump") or event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		_deploy(selected_stage)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Global.play_sfx("menu_cursor")
		Global.go_to_title()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(pos: Vector2) -> void:
	# Back button at bottom left
	var back_rect := Rect2(40.0, 480.0, 180.0, 36.0)
	if back_rect.has_point(pos):
		Global.play_sfx("menu_cursor")
		Global.go_to_title()
		return
	
	# Check 3 stage cards
	var card_w := 265.0
	var card_h := 330.0
	var spacing := 35.0
	var start_x := 55.0
	var start_y := 115.0
	
	for i in range(stages_info.size()):
		var cx := start_x + float(i) * (card_w + spacing)
		var crect := Rect2(cx, start_y, card_w, card_h)
		if crect.has_point(pos):
			if selected_stage == i + 1:
				_deploy(selected_stage)
			else:
				selected_stage = i + 1
				Global.play_sfx("menu_cursor")
				queue_redraw()
			return

func _deploy(stage_id: int) -> void:
	Global.play_sfx("menu_start")
	get_tree().create_timer(0.4).timeout.connect(func(): Global.start_game(stage_id))

func _draw() -> void:
	# Background
	draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.06, 0.07, 0.12))
	
	# Tech Grid & Scan lines
	for i in range(12):
		var y := float(i) * 50.0
		draw_line(Vector2(0.0, y), Vector2(960.0, y), Color(0.12, 0.16, 0.25, 0.4), 1.0)
	
	var font := ThemeDB.fallback_font
	
	# Top Header
	draw_string(font, Vector2(340.0, 52.0), "SELECT MISSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1.0, 0.85, 0.2))
	draw_string(font, Vector2(325.0, 82.0), "TACTICAL DEPLOYMENT MAP • OPERATION CONRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.8, 1.0))
	draw_line(Vector2(50.0, 95.0), Vector2(910.0, 95.0), Color(0.2, 0.4, 0.7, 0.7), 2.0)
	
	# Stage Cards
	var card_w := 265.0
	var card_h := 340.0
	var spacing := 35.0
	var start_x := 55.0
	var start_y := 115.0
	
	for i in range(stages_info.size()):
		var s: Dictionary = stages_info[i]
		var stage_id: int = int(s["id"])
		var is_sel: bool = (selected_stage == stage_id)
		var cx := start_x + float(i) * (card_w + spacing)
		var card_rect := Rect2(cx, start_y, card_w, card_h)
		
		# Card Background
		var bg_col := Color(0.12, 0.18, 0.32, 0.95) if is_sel else Color(0.07, 0.09, 0.15, 0.85)
		draw_rect(card_rect, bg_col)
		
		# Border with glow if selected
		var border_col: Color = s["color"] if is_sel else Color(0.2, 0.3, 0.45)
		var border_w: float = 3.0 if is_sel else 1.5
		draw_rect(card_rect, border_col, false, border_w)
		
		# Thumbnail Box
		var thumb_rect := Rect2(cx + 12.0, start_y + 14.0, card_w - 24.0, 110.0)
		_draw_thumbnail(thumb_rect, stage_id)
		
		# Stage Title
		var title_col := Color(1.0, 0.95, 0.4) if is_sel else Color(0.9, 0.9, 0.95)
		draw_string(font, Vector2(cx + 14.0, start_y + 150.0), s["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, title_col)
		
		# Difficulty tag
		draw_rect(Rect2(cx + 14.0, start_y + 162.0, 80.0, 18.0), Color(0.1, 0.1, 0.15))
		draw_rect(Rect2(cx + 14.0, start_y + 162.0, 80.0, 18.0), s["color"], false, 1.0)
		draw_string(font, Vector2(cx + 20.0, start_y + 176.0), s["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, s["color"])
		
		# Briefing Text
		_draw_wrapped_text(font, s["desc"], Vector2(cx + 14.0, start_y + 204.0), card_w - 28.0, 12, Color(0.8, 0.85, 0.9))
		
		# Deploy Button at bottom of card
		var btn_rect := Rect2(cx + 20.0, start_y + card_h - 45.0, card_w - 40.0, 32.0)
		var btn_bg: Color = s["color"] if is_sel else Color(0.15, 0.2, 0.3)
		draw_rect(btn_rect, btn_bg)
		draw_rect(btn_rect, Color.WHITE if is_sel else Color(0.4, 0.5, 0.6), false, 1.5)
		
		var deploy_label := "DEPLOY MISSION" if is_sel else "SELECT"
		var label_col := Color.WHITE if is_sel else Color(0.7, 0.8, 0.9)
		draw_string(font, Vector2(cx + 55.0, start_y + card_h - 24.0), deploy_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_col)
	
	# Bottom Return Button
	var back_rect := Rect2(40.0, 480.0, 180.0, 36.0)
	draw_rect(back_rect, Color(0.15, 0.18, 0.25))
	draw_rect(back_rect, Color(0.5, 0.6, 0.8), false, 1.5)
	draw_string(font, Vector2(55.0, 504.0), "◄ RETURN TO TITLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.95, 1.0))
	
	# Bottom Tip
	draw_string(font, Vector2(400.0, 504.0), "[ USE ARROWS OR TAP CARD TO CHOOSE • TAP DEPLOY TO START ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.65, 0.8))

func _draw_thumbnail(rect: Rect2, stage_id: int) -> void:
	draw_rect(rect, Color(0.08, 0.1, 0.15))
	draw_rect(rect, Color(0.3, 0.4, 0.5), false, 1.0)
	
	match stage_id:
		1:
			# Jungle & Wall: green foliage, blue river, wall turret silhouette
			draw_rect(Rect2(rect.position.x, rect.position.y + 70.0, rect.size.x, 40.0), Color(0.1, 0.3, 0.18))
			draw_circle(Vector2(rect.position.x + 50.0, rect.position.y + 60.0), 28.0, Color(0.15, 0.45, 0.22))
			draw_circle(Vector2(rect.position.x + 110.0, rect.position.y + 55.0), 32.0, Color(0.12, 0.4, 0.2))
			draw_rect(Rect2(rect.position.x + 160.0, rect.position.y + 35.0, 60.0, 75.0), Color(0.25, 0.28, 0.32)) # Wall
			draw_circle(Vector2(rect.position.x + 190.0, rect.position.y + 65.0), 9.0, Color(0.2, 0.8, 1.0)) # Alien core
		2:
			# Waterfall: rushing blue cascades and steel girder cliffs
			draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y), Color(0.08, 0.14, 0.26))
			draw_rect(Rect2(rect.position.x + 70.0, rect.position.y, 60.0, rect.size.y), Color(0.2, 0.6, 0.9, 0.8)) # Waterfall stream
			draw_line(Vector2(rect.position.x + 85.0, rect.position.y), Vector2(rect.position.x + 85.0, rect.position.y + rect.size.y), Color.WHITE, 2.0)
			draw_line(Vector2(rect.position.x + 115.0, rect.position.y), Vector2(rect.position.x + 115.0, rect.position.y + rect.size.y), Color.WHITE, 2.0)
			# Steel bridge
			draw_rect(Rect2(rect.position.x + 20.0, rect.position.y + 55.0, rect.size.x - 40.0, 10.0), Color(0.4, 0.45, 0.5))
		3:
			# Alien Hive: biomechanical glowing tentacles and pulsating alien egg
			draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y), Color(0.18, 0.05, 0.08))
			draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 55.0), 34.0, Color(0.65, 0.15, 0.18))
			draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 55.0), 20.0, Color(0.95, 0.3, 0.2))
			draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 55.0), 8.0, Color(1.0, 0.85, 0.4))

func _draw_wrapped_text(font: Font, text: String, pos: Vector2, max_w: float, font_size: int, color: Color) -> void:
	var words := text.split(" ")
	var current_line := ""
	var line_y: float = pos.y
	
	for w in words:
		var test_line: String = current_line + (" " if current_line != "" else "") + w
		var line_size := font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if line_size.x > max_w and current_line != "":
			draw_string(font, Vector2(pos.x, line_y), current_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			current_line = w
			line_y += float(font_size) + 5.0
		else:
			current_line = test_line
	
	if current_line != "":
		draw_string(font, Vector2(pos.x, line_y), current_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
