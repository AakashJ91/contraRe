extends Control

# Cinematic Prologue Sequence for Contra Re
# 16-bit arcade intro with CRT scanlines, camera drift, typing teletype, and Red Falcon lore

var current_slide_idx: int = 0
var slide_timer: float = 0.0
var typewriter_chars: int = 0
var total_chars_in_slide: int = 0
var is_typing: bool = true
var sfx_char_counter: int = 0
var transition_alpha: float = 1.0
var is_transitioning: bool = false
var next_slide_idx: int = 0

const TYPE_SPEED: float = 40.0 # Characters per second
const AUTO_ADVANCE_DELAY: float = 4.5 # Seconds to wait after typing finishes

var slides: Array[Dictionary] = [
	{
		"image_path": "res://assets/prologue/prologue_1_meteor.jpg",
		"header": "FEDERATION DEFENSE COMMAND // ARCHIVE 2636-AD",
		"category": "INCIDENT REPORT: METEOR DELTA-9",
		"category_color": Color(0.2, 0.85, 1.0),
		"lines": [
			"YEAR 2636 A.D.  A MASSIVE COSMIC IMPACT STRUCK THE REMOTE GALUGA ARCHIPELAGO.",
			"THE CATACLYSMIC SHOCKWAVE TRIGGERED TIDAL DISTURBANCES ACROSS THE ENTIRE PACIFIC.",
			"MINUTES AFTER IMPACT, ALL SATELLITE COMMUNICATIONS WENT DEAD SILENT."
		]
	},
	{
		"image_path": "res://assets/prologue/prologue_2_threat.jpg",
		"header": "BIO-HAZARD DETECTED // SECTOR Z-4",
		"category": "PRIORITY RED ALERT: RED FALCON SYNDICATE",
		"category_color": Color(1.0, 0.25, 0.2),
		"lines": [
			"DEEP SATELLITE RECONNAISSANCE REVEALED A NIGHTMARISH TRUTH.",
			"THE ANCIENT ALIEN ENTITY KNOWN AS 'RED FALCON' HAS AWOKEN BENEATH THE CRATER.",
			"AN ARMY OF BIOMECHANICAL WAR MACHINES HAS FORTIFIED 8 LETHAL DEFENSE SECTORS."
		]
	},
	{
		"image_path": "res://assets/prologue/prologue_3_drop.jpg",
		"header": "SPECIAL FORCES DIRECTIVE // OPERATION: BLACK PANTHER",
		"category": "DEPLOYMENT ORDER: OPERATION BLACK PANTHER",
		"category_color": Color(1.0, 0.85, 0.2),
		"lines": [
			"EARTH'S FINAL DEFENSE PROTOCOL IS NOW OFFICIALLY AUTHORIZED.",
			"OPERATION BLACK PANTHER: DEPLOYING ELITE GUERRILLA COMMANDO CALLSIGN 'BILL RIZER'.",
			"MISSION DIRECTIVE: INFILTRATE THE JUNGLE, BREACH ALL 8 DEFENSE SECTORS, AND ELIMINATE THE ALIEN CORE. NO RETREAT!"
		]
	}
]

var slide_textures: Array[Texture2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	slide_textures.clear()
	for s in slides:
		var tex: Texture2D = null
		if ResourceLoader.exists(s["image_path"]):
			tex = load(s["image_path"])
		slide_textures.append(tex)
	
	_load_slide(0)
	Global.play_sfx("menu_start")

func _load_slide(idx: int) -> void:
	current_slide_idx = idx
	slide_timer = 0.0
	typewriter_chars = 0
	is_typing = true
	transition_alpha = 1.0
	
	# Calculate total character count for this slide
	total_chars_in_slide = 0
	var lines: Array = slides[current_slide_idx]["lines"]
	for l in lines:
		total_chars_in_slide += String(l).length()
	
	queue_redraw()

func _process(delta: float) -> void:
	slide_timer += delta
	
	# Fade in from transition
	if transition_alpha > 0.0:
		transition_alpha = maxf(0.0, transition_alpha - delta * 3.0)
	
	# Typewriter advancement
	if is_typing:
		var prev_chars := typewriter_chars
		typewriter_chars = mini(total_chars_in_slide, int(slide_timer * TYPE_SPEED))
		
		# Play typing blip sound
		if typewriter_chars > prev_chars:
			sfx_char_counter += (typewriter_chars - prev_chars)
			if sfx_char_counter >= 3:
				sfx_char_counter = 0
				Global.play_sfx("menu_cursor")
		
		if typewriter_chars >= total_chars_in_slide:
			is_typing = false
			slide_timer = 0.0 # Reset to count auto-advance
	else:
		# Auto-advance after delay
		if slide_timer >= AUTO_ADVANCE_DELAY:
			_advance_slide()
	
	queue_redraw()

func _advance_slide() -> void:
	if current_slide_idx < slides.size() - 1:
		Global.play_sfx("menu_cursor")
		_load_slide(current_slide_idx + 1)
	else:
		_finish_prologue()

func _finish_prologue() -> void:
	Global.play_sfx("menu_start")
	Global.start_game(1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_finish_prologue()
		return
	
	if event.is_action_pressed("jump") or event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		if is_typing:
			# Fast-forward typing to end of current slide
			typewriter_chars = total_chars_in_slide
			is_typing = false
			slide_timer = 0.0
			Global.play_sfx("menu_cursor")
			queue_redraw()
		else:
			_advance_slide()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(pos: Vector2) -> void:
	var screen_w := _get_screen_w()
	# Check if clicked on [SKIP >>] button in top right
	var skip_rect := Rect2(screen_w - 140.0, 14.0, 120.0, 36.0)
	if skip_rect.has_point(pos):
		_finish_prologue()
		return
	
	if is_typing:
		typewriter_chars = total_chars_in_slide
		is_typing = false
		slide_timer = 0.0
		Global.play_sfx("menu_cursor")
		queue_redraw()
	else:
		_advance_slide()

func _get_screen_w() -> float:
	return maxf(960.0, get_viewport_rect().size.x)

func _get_offset_x() -> float:
	return (_get_screen_w() - 960.0) * 0.5

func _draw() -> void:
	var screen_w := _get_screen_w()
	var ox := _get_offset_x()
	var font := ThemeDB.fallback_font
	var is_mob := Global.is_mobile_device()
	
	# 1. Background image with slow camera pan & subtle scale drift (Ken Burns effect)
	var tex: Texture2D = slide_textures[current_slide_idx] if current_slide_idx < slide_textures.size() else null
	if tex != null:
		var drift_scale := 1.04 + 0.02 * sin(slide_timer * 0.4)
		var drift_x := sin(slide_timer * 0.3) * 12.0
		var drift_y := cos(slide_timer * 0.25) * 8.0
		
		var draw_w := screen_w * drift_scale
		var draw_h := 540.0 * drift_scale
		var draw_x := (screen_w - draw_w) * 0.5 + drift_x
		var draw_y := (540.0 - draw_h) * 0.5 + drift_y
		
		draw_texture_rect(tex, Rect2(draw_x, draw_y, draw_w, draw_h), false)
		
		# Atmospheric dark gradient overlay so text remains razor sharp
		draw_rect(Rect2(0.0, 0.0, screen_w, 540.0), Color(0.02, 0.04, 0.08, 0.45))
	else:
		draw_rect(Rect2(0.0, 0.0, screen_w, 540.0), Color(0.05, 0.07, 0.12))
	
	# 2. Cinematic Letterbox Borders
	var bar_top_h := 50.0
	var bar_bot_h := 50.0
	draw_rect(Rect2(0.0, 0.0, screen_w, bar_top_h), Color(0.02, 0.02, 0.04, 0.95))
	draw_rect(Rect2(0.0, 540.0 - bar_bot_h, screen_w, bar_bot_h), Color(0.02, 0.02, 0.04, 0.95))
	# Thin tech divider lines
	draw_line(Vector2(0.0, bar_top_h), Vector2(screen_w, bar_top_h), Color(0.2, 0.5, 0.8, 0.6), 1.5)
	draw_line(Vector2(0.0, 540.0 - bar_bot_h), Vector2(screen_w, 540.0 - bar_bot_h), Color(0.2, 0.5, 0.8, 0.6), 1.5)
	
	# 3. Top Header: Title & Skip Button
	var slide_data: Dictionary = slides[current_slide_idx]
	var header_str: String = slide_data["header"]
	draw_circle(Vector2(25.0 + ox * 0.2, 26.0), 4.5, Color(0.2, 1.0, 0.4))
	draw_string(font, Vector2(40.0 + ox * 0.2, 31.0), header_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.9, 1.0))
	
	# Slide Indicator Dots (1 of 3)
	for i in range(slides.size()):
		var dot_x := screen_w * 0.5 + float(i - 1) * 22.0
		var is_cur := (i == current_slide_idx)
		var dot_col := Color(1.0, 0.85, 0.2) if is_cur else Color(0.3, 0.4, 0.5, 0.6)
		draw_circle(Vector2(dot_x, 26.0), 4.0 if is_cur else 2.5, dot_col)
	
	# [ SKIP >> ] Button
	var skip_box := Rect2(screen_w - 135.0, 10.0, 115.0, 32.0)
	draw_rect(skip_box, Color(0.12, 0.16, 0.24, 0.8))
	draw_rect(skip_box, Color(1.0, 0.85, 0.2, 0.85), false, 1.5)
	draw_string(font, Vector2(screen_w - 118.0, 31.0), "SKIP >>", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.9, 0.4))
	
	# 4. Cinematic Text Card at Lower Center
	var box_w := minf(screen_w - 60.0, 880.0)
	var box_h := 132.0
	var box_x := (screen_w - box_w) * 0.5
	var box_y := 345.0
	var text_box_rect := Rect2(box_x, box_y, box_w, box_h)
	
	# Cybernetic card background
	draw_rect(text_box_rect, Color(0.04, 0.07, 0.12, 0.88))
	draw_rect(text_box_rect, Color(0.2, 0.55, 0.9, 0.75), false, 2.0)
	# Corner accent bevels
	var corner_len := 12.0
	draw_line(Vector2(box_x, box_y + corner_len), Vector2(box_x + corner_len, box_y), Color(1.0, 0.85, 0.2), 3.0)
	draw_line(Vector2(box_x + box_w - corner_len, box_y), Vector2(box_x + box_w, box_y + corner_len), Color(1.0, 0.85, 0.2), 3.0)
	
	# Category Badge
	var cat_text: String = slide_data["category"]
	var cat_col: Color = slide_data["category_color"]
	draw_rect(Rect2(box_x + 18.0, box_y - 12.0, 360.0, 22.0), Color(0.02, 0.05, 0.1, 0.95))
	draw_rect(Rect2(box_x + 18.0, box_y - 12.0, 360.0, 22.0), cat_col, false, 1.5)
	draw_string(font, Vector2(box_x + 28.0, box_y + 4.0), "[ " + cat_text + " ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, cat_col)
	
	# 5. Typewriter Text Rendering
	var lines: Array = slide_data["lines"]
	var remaining_chars := typewriter_chars
	var font_size: int = 16 if is_mob else 15
	var line_spacing: float = 28.0
	var text_start_y := box_y + 36.0
	
	for row in range(lines.size()):
		var line_str := String(lines[row])
		var chars_to_take := mini(remaining_chars, line_str.length())
		var visible_part := line_str.substr(0, chars_to_take)
		
		# Draw line text
		var line_pos := Vector2(box_x + 26.0, text_start_y + float(row) * line_spacing)
		draw_string(font, line_pos, visible_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.98, 1.0))
		
		# Blinking cursor if this is the active writing line
		if remaining_chars <= line_str.length() and is_typing:
			var cursor_w := font.get_string_size(visible_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var cursor_pulse := (sin(slide_timer * 14.0) + 1.0) * 0.5
			if cursor_pulse > 0.3:
				draw_rect(Rect2(line_pos.x + cursor_w + 3.0, line_pos.y - 13.0, 8.0, 15.0), Color(0.2, 0.9, 1.0, 0.9))
		
		remaining_chars = maxi(0, remaining_chars - line_str.length())
	
	# 6. Bottom Prompt
	var is_last_slide := (current_slide_idx == slides.size() - 1)
	var prompt_text: String
	var prompt_col: Color
	if is_typing:
		prompt_text = "[ TAP OR PRESS SPACE TO SPEED UP ]"
		prompt_col = Color(0.5, 0.65, 0.8, 0.7)
	elif is_last_slide:
		var pulse := (sin(slide_timer * 6.0) + 1.0) * 0.5
		prompt_text = "►► PRESS ANY KEY OR TAP TO COMMENCE MISSION ◄◄"
		prompt_col = Color(1.0, 0.85, 0.2, 0.7 + pulse * 0.3)
	else:
		var pulse := (sin(slide_timer * 5.0) + 1.0) * 0.5
		prompt_text = "► PRESS ANY KEY OR TAP TO CONTINUE ◄"
		prompt_col = Color(0.3, 1.0, 0.5, 0.65 + pulse * 0.35)
	
	var prompt_w := font.get_string_size(prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2((screen_w - prompt_w) * 0.5, 518.0), prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, prompt_col)
	
	# 7. Subtle Retro CRT Scanlines
	for y in range(0, 540, 4):
		draw_line(Vector2(0.0, float(y)), Vector2(screen_w, float(y)), Color(0.0, 0.0, 0.0, 0.09), 1.0)
	
	# 8. Fade Transition Wash
	if transition_alpha > 0.0:
		draw_rect(Rect2(0.0, 0.0, screen_w, 540.0), Color(0.0, 0.0, 0.0, transition_alpha))
