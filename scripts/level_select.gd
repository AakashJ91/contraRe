extends Control

var selected_stage: int = 1
var anim_timer: float = 0.0

var stages_info: Array[Dictionary] = [
	{
		"id": 1,
		"name": "STAGE 1: JUNGLE PERIMETER",
		"theme": "JUNGLE & FORTRESS",
		"diff": "NORMAL",
		"boss": "WALL CORE",
		"desc": "Infiltrate tropical canopy, cross rope bridges, and eliminate the armored Wall Defense Core.",
		"color": Color(0.2, 0.7, 0.3)
	},
	{
		"id": 2,
		"name": "STAGE 2: WATERFALL FORTRESS",
		"theme": "TORRENTIAL CLIFFSIDE",
		"diff": "HARD",
		"boss": "HYDRO MECH",
		"desc": "Ascend cascading waterfalls, leap river chasms, and destroy the dual-cannon Hydro Walker.",
		"color": Color(0.2, 0.55, 0.9)
	},
	{
		"id": 3,
		"name": "STAGE 3: ALIEN HIVE BIO-CAVERN",
		"theme": "SUBTERRANEAN HIVE",
		"diff": "HARD",
		"boss": "BIO-HEART",
		"desc": "Penetrate subterranean flesh caverns, dodge alien swarms, and eradicate the Giga Bio-Heart.",
		"color": Color(0.85, 0.25, 0.35)
	},
	{
		"id": 4,
		"name": "STAGE 4: SNOWFIELD TUNDRA",
		"theme": "ARCTIC GLACIER",
		"diff": "EXPERT",
		"boss": "SIEGE TANK",
		"desc": "Navigate sub-zero blizzards across slippery ice floes and demolish the armored heavy Siege Tank.",
		"color": Color(0.40, 0.85, 1.0)
	},
	{
		"id": 5,
		"name": "STAGE 5: STEEL REFINERY",
		"theme": "INDUSTRIAL SMELTER",
		"diff": "EXPERT",
		"boss": "MAGMA FORGE",
		"desc": "Fight above molten metal cauldrons on high-heat factory catwalks to crush the flaming Magma Golem.",
		"color": Color(1.0, 0.55, 0.15)
	},
	{
		"id": 6,
		"name": "STAGE 6: ELECTRIC DYNAMO",
		"theme": "HIGH-VOLTAGE SUBSTATION",
		"diff": "EXPERT",
		"boss": "THUNDER DYNAMO",
		"desc": "Scale electrifying transformer towers and bypass high-voltage conduits to overload the Tesla Dynamo.",
		"color": Color(0.95, 0.85, 0.2)
	},
	{
		"id": 7,
		"name": "STAGE 7: ALIEN AEROSPACE HANGAR",
		"theme": "ORBITAL STARPORT",
		"diff": "NIGHTMARE",
		"boss": "STAR CRUISER",
		"desc": "Infiltrate the orbital starship launch bays and shoot down the hovering alien Vanguard Dreadnought.",
		"color": Color(0.70, 0.40, 0.95)
	},
	{
		"id": 8,
		"name": "STAGE 8: MOTHER BRAIN SANCTUM",
		"theme": "LIVING BIO-SANCTUM",
		"diff": "APOCALYPSE",
		"boss": "MOTHER BRAIN",
		"desc": "Enter the living heart of the alien empire to destroy Emperor Mother Brain and save Earth!",
		"color": Color(1.0, 0.25, 0.25)
	}
]

var stage_thumbnails: Dictionary = {}
var stage_backgrounds: Dictionary = {}
var bg_texture: Texture2D = null
var prev_bg_stage: int = 1
var bg_fade: float = 1.0

func _ready() -> void:
	if ResourceLoader.exists("res://assets/backgrounds/title_bg.jpg"):
		bg_texture = load("res://assets/backgrounds/title_bg.jpg")
	
	var stage_bg_files := {
		1: "stage1_jungle.jpg",
		2: "stage2_waterfall.jpg",
		3: "stage3_alien_hive.jpg",
		4: "stage4_tundra.jpg",
		5: "stage5_refinery.jpg",
		6: "stage6_dynamo.jpg",
		7: "stage7_hangar.jpg",
		8: "stage8_sanctum.jpg"
	}
	for sid in stage_bg_files:
		var path: String = "res://assets/backgrounds/" + str(stage_bg_files[sid])
		if ResourceLoader.exists(path):
			stage_backgrounds[sid] = load(path)
			stage_thumbnails[sid] = stage_backgrounds[sid]
	
	if Global.current_stage >= 1 and Global.current_stage <= 8:
		selected_stage = Global.current_stage
	prev_bg_stage = selected_stage
	bg_fade = 1.0
	queue_redraw()

func _set_selected_stage(new_stage: int) -> void:
	if new_stage == selected_stage:
		return
	prev_bg_stage = selected_stage
	selected_stage = new_stage
	bg_fade = 0.0
	Global.play_sfx("menu_cursor")
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	if bg_fade < 1.0:
		bg_fade = minf(1.0, bg_fade + delta * 3.5)
	queue_redraw()

var show_full_map: bool = false
var is_deploying: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		show_full_map = not show_full_map
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	if show_full_map:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE):
			show_full_map = false
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		elif event.is_action_pressed("jump") or event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
			_deploy(selected_stage)
			return
		elif event.is_action_pressed("move_left"):
			_set_selected_stage(8 if selected_stage == 1 else selected_stage - 1)
			return
		elif event.is_action_pressed("move_right"):
			_set_selected_stage(1 if selected_stage == 8 else selected_stage + 1)
			return

	if event.is_action_pressed("move_left"):
		_set_selected_stage(8 if selected_stage == 1 else selected_stage - 1)
	elif event.is_action_pressed("move_right"):
		_set_selected_stage(1 if selected_stage == 8 else selected_stage + 1)
	elif event.is_action_pressed("move_up"):
		_set_selected_stage(selected_stage - 4 if selected_stage > 4 else selected_stage + 4)
	elif event.is_action_pressed("move_down"):
		_set_selected_stage(selected_stage + 4 if selected_stage <= 4 else selected_stage - 4)
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

func _get_screen_w() -> float:
	return maxf(960.0, get_viewport_rect().size.x)

func _get_offset_x() -> float:
	return (_get_screen_w() - 960.0) * 0.5

func _handle_click(pos: Vector2) -> void:
	var ox := _get_offset_x()
	var w := _get_screen_w()

	if show_full_map:
		# Close Map Button at bottom left
		var close_rect := Rect2(32.0 + ox, 485.0, 200.0, 36.0)
		if close_rect.has_point(pos):
			show_full_map = false
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		
		# Deploy Button at bottom right
		var deploy_rect := Rect2(700.0 + ox, 485.0, 228.0, 36.0)
		if deploy_rect.has_point(pos):
			_deploy(selected_stage)
			return
		
		# Stage switcher arrows in header
		if Rect2(20.0 + ox, 15.0, 60.0, 35.0).has_point(pos):
			_set_selected_stage(8 if selected_stage == 1 else selected_stage - 1)
			return
		elif Rect2(880.0 + ox, 15.0, 60.0, 35.0).has_point(pos):
			_set_selected_stage(1 if selected_stage == 8 else selected_stage + 1)
			return
		return

	# Return to Title Button at bottom left
	var back_rect := Rect2(32.0 + ox, 485.0, 140.0, 36.0)
	if back_rect.has_point(pos):
		Global.play_sfx("menu_cursor")
		Global.go_to_title()
		return
	
	# Center Tactical Blueprint Map Inspector Button
	var map_btn_rect := Rect2(182.0 + ox, 485.0, 320.0, 36.0)
	if map_btn_rect.has_point(pos):
		show_full_map = true
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	# Contra Maker Button
	var maker_btn_rect := Rect2(512.0 + ox, 485.0, 185.0, 36.0)
	if maker_btn_rect.has_point(pos):
		Global.play_sfx("menu_start")
		Global.current_stage = selected_stage
		Global.is_maker_mode = true
		get_tree().create_timer(0.2).timeout.connect(func(): Global.start_game(selected_stage))
		return
	
	# Deploy Selected Button at bottom right
	var deploy_bar := Rect2(706.0 + ox, 485.0, 222.0, 36.0)
	if deploy_bar.has_point(pos):
		_deploy(selected_stage)
		return
	
	# Check 8 Stage Cards (4 columns x 2 rows)
	var card_w := 205.0
	var card_h := 172.0
	var start_x := 32.0 + ox
	var col_gap := 25.0
	var start_y := 100.0
	var row_gap := 18.0
	
	for i in range(stages_info.size()):
		var col := i % 4
		var row := i / 4
		var cx := start_x + float(col) * (card_w + col_gap)
		var cy := start_y + float(row) * (card_h + row_gap)
		var crect := Rect2(cx, cy, card_w, card_h)
		if crect.has_point(pos):
			var stage_num := i + 1
			var btn_rect := Rect2(cx + 8.0, cy + 132.0, card_w - 16.0, 28.0)
			if btn_rect.has_point(pos):
				# Directly clicked Deploy/Select button on the card
				_set_selected_stage(stage_num)
				_deploy(stage_num)
				return
			elif selected_stage == stage_num:
				# Tapping already selected card deploys to this stage
				_deploy(stage_num)
				return
			else:
				# Select the clicked card
				_set_selected_stage(stage_num)
				return

func _deploy(stage_id: int) -> void:
	if is_deploying:
		return
	is_deploying = true
	Global.play_sfx("menu_start")
	get_tree().create_timer(0.20).timeout.connect(func(): Global.start_game(stage_id))

func _draw() -> void:
	var w := _get_screen_w()
	var ox := _get_offset_x()

	# Background Wallpaper & Dynamic Cross-Fade between Stage Backgrounds
	var cur_bg: Texture2D = stage_backgrounds.get(selected_stage, bg_texture)
	var prev_bg: Texture2D = stage_backgrounds.get(prev_bg_stage, bg_texture)
	var screen_rect := Rect2(0.0, 0.0, w, 540.0)
	
	if cur_bg != null:
		if bg_fade < 1.0 and prev_bg != null and prev_bg != cur_bg:
			draw_texture_rect(prev_bg, screen_rect, false)
			draw_texture_rect(cur_bg, screen_rect, false, Color(1.0, 1.0, 1.0, bg_fade))
		else:
			draw_texture_rect(cur_bg, screen_rect, false)
		
		# Tactical wash tuned for rich aesthetics while ensuring maximum text readability
		var sel_color: Color = stages_info[selected_stage - 1]["color"]
		draw_rect(screen_rect, Color(0.03, 0.05, 0.09, 0.62))
		draw_rect(screen_rect, Color(sel_color.r * 0.12, sel_color.g * 0.12, sel_color.b * 0.18, 0.22))
		# Header & footer contrast bands
		draw_rect(Rect2(0.0, 0.0, w, 86.0), Color(0.02, 0.03, 0.06, 0.60))
		draw_rect(Rect2(0.0, 474.0, w, 66.0), Color(0.02, 0.03, 0.06, 0.70))
	elif bg_texture != null:
		draw_texture_rect(bg_texture, screen_rect, false)
		draw_rect(screen_rect, Color(0.04, 0.07, 0.12, 0.88))
	else:
		draw_rect(screen_rect, Color(0.05, 0.07, 0.11))
	
	# Tactical Tech Grid Lines
	for i in range(11):
		var y := float(i) * 52.0
		draw_line(Vector2(0.0, y), Vector2(w, y), Color(0.12, 0.22, 0.38, 0.25), 1.0)
	
	var font := ThemeDB.fallback_font
	
	# If full map mode is active, draw the full-screen tactical blueprint map
	if show_full_map:
		_draw_full_level_map_view(font, w, ox)
		return
	
	# Top Header
	draw_string(font, Vector2(350.0 + ox, 44.0), "MISSION SELECT", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.85, 0.20))
	draw_string(font, Vector2(285.0 + ox, 72.0), "OPERATION CONTRA • 8 TACTICAL LEVEL MAPS & BOSS STRONGHOLDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.85, 1.0))
	draw_line(Vector2(32.0 + ox, 84.0), Vector2(928.0 + ox, 84.0), Color(0.25, 0.45, 0.75, 0.60), 1.5)
	
	# 8 Stage Cards (4 columns x 2 rows)
	var card_w := 205.0
	var card_h := 172.0
	var start_x := 32.0 + ox
	var col_gap := 25.0
	var start_y := 100.0
	var row_gap := 18.0
	
	for i in range(stages_info.size()):
		var s: Dictionary = stages_info[i]
		var stage_id: int = int(s["id"])
		var is_sel: bool = (selected_stage == stage_id)
		var col := i % 4
		var row := i / 4
		var cx := start_x + float(col) * (card_w + col_gap)
		var cy := start_y + float(row) * (card_h + row_gap)
		var card_rect := Rect2(cx, cy, card_w, card_h)
		
		# Drop Shadow for floating card depth
		draw_rect(Rect2(cx + 3.0, cy + 4.0, card_w, card_h), Color(0.0, 0.0, 0.0, 0.52))
		
		# Glassmorphism Base Plate
		var bg_col := Color(0.07, 0.11, 0.18, 0.96) if is_sel else Color(0.04, 0.06, 0.10, 0.90)
		draw_rect(card_rect, bg_col)
		
		# Subtle top-half glass reflection sheen
		draw_rect(Rect2(cx, cy, card_w, 42.0), Color(1.0, 1.0, 1.0, 0.05 if is_sel else 0.025))
		
		# Inset chamfer line for glass border effect
		draw_rect(Rect2(cx + 1.0, cy + 1.0, card_w - 2.0, card_h - 2.0), Color(1.0, 1.0, 1.0, 0.08 if is_sel else 0.04), false, 1.0)
		
		# Outer Glow & Glowing border when selected
		if is_sel:
			var glow_pulse := 0.22 + 0.10 * sin(anim_timer * 6.0)
			draw_rect(Rect2(cx - 2.0, cy - 2.0, card_w + 4.0, card_h + 4.0), Color(s["color"].r, s["color"].g, s["color"].b, glow_pulse), false, 2.0)
			draw_rect(card_rect, s["color"], false, 1.8)
			
			# Top pulsating energy accent bar
			var pulse := 0.75 + 0.25 * sin(anim_timer * 8.0)
			draw_rect(Rect2(cx, cy, card_w, 3.0), Color(s["color"].r, s["color"].g, s["color"].b, pulse))
			
			# Tech corner brackets (6px L-accents)
			var b_len := 7.0
			var b_col: Color = Color.WHITE
			draw_line(Vector2(cx, cy), Vector2(cx + b_len, cy), b_col, 1.5)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + b_len), b_col, 1.5)
			draw_line(Vector2(cx + card_w, cy), Vector2(cx + card_w - b_len, cy), b_col, 1.5)
			draw_line(Vector2(cx + card_w, cy), Vector2(cx + card_w, cy + b_len), b_col, 1.5)
			draw_line(Vector2(cx, cy + card_h), Vector2(cx + b_len, cy + card_h), b_col, 1.5)
			draw_line(Vector2(cx, cy + card_h), Vector2(cx, cy + card_h - b_len), b_col, 1.5)
			draw_line(Vector2(cx + card_w, cy + card_h), Vector2(cx + card_w - b_len, cy + card_h), b_col, 1.5)
			draw_line(Vector2(cx + card_w, cy + card_h), Vector2(cx + card_w, cy + card_h - b_len), b_col, 1.5)
		else:
			draw_rect(card_rect, Color(0.18, 0.25, 0.36, 0.65), false, 1.0)
			# Subtle corner ticks
			var b_len := 4.0
			var b_col := Color(0.30, 0.42, 0.58, 0.40)
			draw_line(Vector2(cx, cy), Vector2(cx + b_len, cy), b_col, 1.0)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + b_len), b_col, 1.0)
			draw_line(Vector2(cx + card_w, cy), Vector2(cx + card_w - b_len, cy), b_col, 1.0)
			draw_line(Vector2(cx + card_w, cy), Vector2(cx + card_w, cy + b_len), b_col, 1.0)
			draw_line(Vector2(cx, cy + card_h), Vector2(cx + b_len, cy + card_h), b_col, 1.0)
			draw_line(Vector2(cx, cy + card_h), Vector2(cx, cy + card_h - b_len), b_col, 1.0)
			draw_line(Vector2(cx + card_w, cy + card_h), Vector2(cx + card_w - b_len, cy + card_h), b_col, 1.0)
			draw_line(Vector2(cx + card_w, cy + card_h), Vector2(cx + card_w, cy + card_h - b_len), b_col, 1.0)

		# Stage Background Preview Monitor (Sleek 16:6 widescreen viewport)
		var thumb_rect := Rect2(cx + 6.0, cy + 6.0, card_w - 12.0, 72.0)
		var thumb_bg: Texture2D = stage_backgrounds.get(stage_id, null)
		if thumb_bg != null:
			var thumb_mod: Color = Color.WHITE if is_sel else Color(0.86, 0.89, 0.94, 0.88)
			draw_texture_rect(thumb_bg, thumb_rect, false, thumb_mod)
			if is_sel:
				draw_rect(thumb_rect, Color(s["color"].r * 0.12, s["color"].g * 0.12, s["color"].b * 0.18, 0.15))
			# Vignette bands on top & bottom of monitor
			draw_rect(Rect2(thumb_rect.position.x, thumb_rect.position.y, thumb_rect.size.x, 14.0), Color(0.02, 0.03, 0.06, 0.45))
			draw_rect(Rect2(thumb_rect.position.x, thumb_rect.end.y - 14.0, thumb_rect.size.x, 14.0), Color(0.02, 0.04, 0.08, 0.55))
		else:
			draw_rect(thumb_rect, Color(0.08, 0.12, 0.18))
		
		# Monitor Bezel / Frame
		var frame_col: Color = s["color"] if is_sel else Color(0.24, 0.33, 0.45, 0.75)
		draw_rect(thumb_rect, frame_col, false, 1.2 if is_sel else 1.0)
		
		# Monitor Tactical Overlays:
		# Top-Left: Stage ID pill badge
		var badge_rect := Rect2(cx + 10.0, cy + 10.0, 52.0, 15.0)
		draw_rect(badge_rect, Color(0.02, 0.04, 0.07, 0.82))
		draw_rect(badge_rect, s["color"] if is_sel else Color(0.35, 0.45, 0.60, 0.80), false, 1.0)
		draw_string(font, Vector2(cx + 14.0, cy + 21.0), "ST. 0" + str(stage_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		
		# Top-Right: Active Target Telemetry Blip (if selected) or Sector Distance
		if is_sel:
			var blip := 0.65 + 0.35 * sin(anim_timer * 9.0)
			draw_circle(Vector2(cx + card_w - 18.0, cy + 17.5), 3.0, Color(s["color"].r, s["color"].g, s["color"].b, blip))
			draw_string(font, Vector2(cx + card_w - 48.0, cy + 21.0), "ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, s["color"])
		else:
			draw_string(font, Vector2(cx + card_w - 46.0, cy + 21.0), "8800M", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.65, 0.75, 0.90, 0.60))

		# Stage Title
		var title_col := Color(1.0, 0.92, 0.45) if is_sel else Color(0.92, 0.95, 1.0)
		var title_text: String = s["theme"]
		var is_mob: bool = Global.is_mobile_device()
		draw_string(font, Vector2(cx + 8.0, cy + 96.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, card_w - 16.0, 11 if is_mob else 10, title_col)
		
		# Tactical Chips: Difficulty badge & Boss target
		var diff_w: float = 68.0 if is_mob else 65.0
		var chip_y: float = cy + (105.0 if is_mob else 104.0)
		var chip_h: float = 17.0
		
		# Difficulty Chip
		draw_rect(Rect2(cx + 8.0, chip_y, diff_w, chip_h), Color(s["color"].r * 0.16, s["color"].g * 0.16, s["color"].b * 0.22, 0.90))
		draw_rect(Rect2(cx + 8.0, chip_y, diff_w, chip_h), s["color"], false, 1.0)
		draw_string(font, Vector2(cx + 12.0, chip_y + 12.0), "◈ " + s["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, s["color"])
		
		# Boss Target Chip
		var boss_x: float = cx + diff_w + 12.0
		var boss_w: float = card_w - diff_w - 20.0
		draw_rect(Rect2(boss_x, chip_y, boss_w, chip_h), Color(0.12, 0.06, 0.08, 0.85))
		draw_rect(Rect2(boss_x, chip_y, boss_w, chip_h), Color(0.60, 0.22, 0.22, 0.65), false, 1.0)
		draw_string(font, Vector2(boss_x + 5.0, chip_y + 12.0), "BOSS: " + s["boss"], HORIZONTAL_ALIGNMENT_LEFT, boss_w - 8.0, 9, Color(1.0, 0.50, 0.50))
		
		# Deploy / Select Button at bottom of card
		var btn_h: float = 28.0 if is_mob else 26.0
		var btn_y: float = cy + (132.0 if is_mob else 134.0)
		var btn_rect := Rect2(cx + 8.0, btn_y, card_w - 16.0, btn_h)
		
		if is_sel:
			var b_pulse := 0.88 + 0.12 * sin(anim_timer * 6.0)
			var btn_bg := Color(s["color"].r * 0.58 * b_pulse, s["color"].g * 0.58 * b_pulse, s["color"].b * 0.58 * b_pulse, 0.95)
			draw_rect(btn_rect, btn_bg)
			draw_line(Vector2(btn_rect.position.x + 2.0, btn_rect.position.y + 1.0), Vector2(btn_rect.end.x - 2.0, btn_rect.position.y + 1.0), Color(1.0, 1.0, 1.0, 0.50), 1.0)
			draw_rect(btn_rect, Color.WHITE, false, 1.2)
		else:
			draw_rect(btn_rect, Color(0.09, 0.14, 0.22, 0.88))
			draw_line(Vector2(btn_rect.position.x + 2.0, btn_rect.position.y + 1.0), Vector2(btn_rect.end.x - 2.0, btn_rect.position.y + 1.0), Color(1.0, 1.0, 1.0, 0.12), 1.0)
			draw_rect(btn_rect, Color(0.25, 0.38, 0.52, 0.60), false, 1.0)
		
		var deploy_label := "► DEPLOY ◄" if is_sel else "SELECT"
		var label_col := Color.WHITE if is_sel else Color(0.72, 0.82, 0.94)
		var d_size: int = 12 if is_mob else 11
		var d_w := font.get_string_size(deploy_label, HORIZONTAL_ALIGNMENT_LEFT, -1, d_size).x
		draw_string(font, Vector2(cx + (card_w - d_w) * 0.5, cy + (151.0 if not is_mob else 151.0)), deploy_label, HORIZONTAL_ALIGNMENT_LEFT, -1, d_size, label_col)
	
	# Bottom Return Button
	var is_mob_ui: bool = Global.is_mobile_device()
	var back_rect := Rect2(32.0 + ox, 482.0 if is_mob_ui else 485.0, 140.0, 38.0 if is_mob_ui else 36.0)
	draw_rect(back_rect, Color(0.12, 0.16, 0.24, 0.90))
	draw_rect(back_rect, Color(0.40, 0.55, 0.75, 0.80), false, 1.5)
	draw_string(font, Vector2(50.0 + ox, 508.0), "◄ TITLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14 if is_mob_ui else 13, Color(0.90, 0.95, 1.0))
	
	# Center Tactical Blueprint Map Inspector Button
	var map_btn_rect := Rect2(182.0 + ox, 485.0, 320.0, 36.0)
	draw_rect(map_btn_rect, Color(0.08, 0.14, 0.22, 0.92))
	draw_rect(map_btn_rect, Color(0.30, 0.70, 0.95), false, 1.5)
	draw_string(font, Vector2(204.0 + ox, 508.0), "☵ VIEW MAP INTEL [M] ☵", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.40, 0.90, 1.0))
	
	# Contra Maker Level Editor Button
	var maker_btn_rect := Rect2(512.0 + ox, 485.0, 185.0, 36.0)
	draw_rect(maker_btn_rect, Color(0.08, 0.22, 0.28, 0.94))
	draw_rect(maker_btn_rect, Color(0.20, 0.85, 1.0), false, 1.8)
	draw_string(font, Vector2(526.0 + ox, 508.0), "★ CONTRA MAKER ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 1.0, 0.90))
	
	# Bottom Deploy Selected Button
	var dep_rect := Rect2(706.0 + ox, 485.0, 222.0, 36.0)
	var sel_color: Color = stages_info[selected_stage - 1]["color"]
	draw_rect(dep_rect, Color(sel_color.r * 0.4, sel_color.g * 0.4, sel_color.b * 0.4, 0.95))
	draw_rect(dep_rect, sel_color, false, 1.8)
	draw_string(font, Vector2(722.0 + ox, 508.0), "START STAGE " + str(selected_stage) + " ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_full_level_map_view(font: Font, w: float, ox: float) -> void:
	var m := LevelMaps.get_map_data(selected_stage)
	var p_col: Color = m["primary_color"]
	
	# Stage Background & Dark tech wash
	var full_bg: Texture2D = stage_backgrounds.get(selected_stage, bg_texture)
	var screen_rect := Rect2(0.0, 0.0, w, 540.0)
	if full_bg != null:
		draw_texture_rect(full_bg, screen_rect, false, Color(0.7, 0.75, 0.85, 1.0))
	draw_rect(screen_rect, Color(0.02, 0.04, 0.08, 0.88))
	
	# Top Header with Stage Switcher hints
	draw_string(font, Vector2(32.0 + ox, 42.0), "◄ [Q]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.6, 0.8))
	draw_string(font, Vector2(900.0 + ox, 42.0), "[E] ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.6, 0.8))
	
	var header_title: String = "TACTICAL THEATER LEVEL MAP // STAGE " + str(selected_stage) + ": " + m["name"]
	draw_string(font, Vector2(100.0 + ox, 36.0), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.88, 0.25))
	draw_string(font, Vector2(100.0 + ox, 56.0), m["sector"] + " • THEME: " + m["theme"] + " • THREAT: " + m["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.85, 1.0))
	draw_line(Vector2(32.0 + ox, 66.0), Vector2(928.0 + ox, 66.0), p_col, 1.5)
	
	# Large Panoramic Terrain Blueprint Schematic Canvas
	var schematic_rect := Rect2(32.0 + ox, 78.0, 896.0, 230.0)
	if full_bg != null:
		draw_texture_rect(full_bg, schematic_rect, false, Color(0.85, 0.85, 0.95, 0.35))
		draw_rect(schematic_rect, Color(0.01, 0.03, 0.06, 0.45))
	LevelMaps.draw_level_map(self, selected_stage, schematic_rect, -1.0, true, anim_timer)
	
	# Tactical Briefing Intel Card
	var intel_rect := Rect2(32.0 + ox, 322.0, 896.0, 145.0)
	draw_rect(intel_rect, Color(0.06, 0.09, 0.15, 0.95))
	draw_rect(intel_rect, Color(0.25, 0.38, 0.55), false, 1.2)
	
	draw_string(font, Vector2(48.0 + ox, 346.0), "► OPERATIONAL INTELLIGENCE BRIEFING:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.20))
	draw_string(font, Vector2(48.0 + ox, 372.0), m["intel"], HORIZONTAL_ALIGNMENT_LEFT, 860.0, 12, Color(0.92, 0.95, 1.0))
	
	# Hazard and Boss specs
	draw_string(font, Vector2(48.0 + ox, 412.0), "TERRAIN HAZARDS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.45, 0.45))
	draw_string(font, Vector2(190.0 + ox, 412.0), m["hazard"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.75, 0.75))
	
	draw_string(font, Vector2(48.0 + ox, 436.0), "PRIMARY OBJECTIVE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.40, 0.85, 1.0))
	draw_string(font, Vector2(190.0 + ox, 436.0), "DESTROY " + m["boss"] + " AT 8800 METERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	draw_string(font, Vector2(620.0 + ox, 436.0), "PLATFORMS: " + str(m["platforms"].size()) + " • CHASMS: " + str(m["ground_segments"].size() - 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.8, 1.0))
	
	# Bottom Action Buttons
	var close_rect := Rect2(32.0 + ox, 485.0, 200.0, 36.0)
	draw_rect(close_rect, Color(0.12, 0.16, 0.24, 0.90))
	draw_rect(close_rect, Color(0.40, 0.55, 0.75, 0.80), false, 1.5)
	draw_string(font, Vector2(48.0 + ox, 508.0), "◄ RETURN TO LEVEL GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.90, 0.95, 1.0))
	
	var dep_rect := Rect2(700.0 + ox, 485.0, 228.0, 36.0)
	draw_rect(dep_rect, Color(p_col.r * 0.4, p_col.g * 0.4, p_col.b * 0.4, 0.95))
	draw_rect(dep_rect, p_col, false, 1.8)
	draw_string(font, Vector2(722.0 + ox, 508.0), "DEPLOY TO THIS LEVEL ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
