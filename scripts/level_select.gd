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
var bg_texture: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/backgrounds/title_bg.jpg"):
		bg_texture = load("res://assets/backgrounds/title_bg.jpg")
	if ResourceLoader.exists("res://assets/backgrounds/stage1_jungle.jpg"):
		stage_thumbnails[1] = load("res://assets/backgrounds/stage1_jungle.jpg")
	if ResourceLoader.exists("res://assets/backgrounds/stage2_waterfall.jpg"):
		stage_thumbnails[2] = load("res://assets/backgrounds/stage2_waterfall.jpg")
	if ResourceLoader.exists("res://assets/backgrounds/stage3_alien_hive.jpg"):
		stage_thumbnails[3] = load("res://assets/backgrounds/stage3_alien_hive.jpg")
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
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
			selected_stage = 8 if selected_stage == 1 else selected_stage - 1
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		elif event.is_action_pressed("move_right"):
			selected_stage = 1 if selected_stage == 8 else selected_stage + 1
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return

	if event.is_action_pressed("move_left"):
		selected_stage = 8 if selected_stage == 1 else selected_stage - 1
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("move_right"):
		selected_stage = 1 if selected_stage == 8 else selected_stage + 1
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("move_up"):
		selected_stage = selected_stage - 4 if selected_stage > 4 else selected_stage + 4
		Global.play_sfx("menu_cursor")
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		selected_stage = selected_stage + 4 if selected_stage <= 4 else selected_stage - 4
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
	if show_full_map:
		# Close Map Button at bottom left
		var close_rect := Rect2(32.0, 485.0, 200.0, 36.0)
		if close_rect.has_point(pos):
			show_full_map = false
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		
		# Deploy Button at bottom right
		var deploy_rect := Rect2(700.0, 485.0, 228.0, 36.0)
		if deploy_rect.has_point(pos):
			_deploy(selected_stage)
			return
		
		# Stage switcher arrows in header
		if Rect2(20.0, 15.0, 60.0, 35.0).has_point(pos):
			selected_stage = 8 if selected_stage == 1 else selected_stage - 1
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		elif Rect2(880.0, 15.0, 60.0, 35.0).has_point(pos):
			selected_stage = 1 if selected_stage == 8 else selected_stage + 1
			Global.play_sfx("menu_cursor")
			queue_redraw()
			return
		return

	# Return to Title Button at bottom left
	var back_rect := Rect2(32.0, 485.0, 140.0, 36.0)
	if back_rect.has_point(pos):
		Global.play_sfx("menu_cursor")
		Global.go_to_title()
		return
	
	# Center Tactical Blueprint Map Inspector Button
	var map_btn_rect := Rect2(182.0, 485.0, 320.0, 36.0)
	if map_btn_rect.has_point(pos):
		show_full_map = true
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	# Contra Maker Button
	var maker_btn_rect := Rect2(512.0, 485.0, 185.0, 36.0)
	if maker_btn_rect.has_point(pos):
		Global.play_sfx("menu_start")
		Global.current_stage = selected_stage
		Global.is_maker_mode = true
		get_tree().create_timer(0.2).timeout.connect(func(): Global.start_game(selected_stage))
		return
	
	# Deploy Selected Button at bottom right
	var deploy_bar := Rect2(706.0, 485.0, 222.0, 36.0)
	if deploy_bar.has_point(pos):
		_deploy(selected_stage)
		return
	
	# Check 8 Stage Cards (4 columns x 2 rows)
	var card_w := 205.0
	var card_h := 172.0
	var start_x := 32.0
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
			var btn_rect := Rect2(cx + 10.0, cy + 134.0, card_w - 20.0, 26.0)
			if btn_rect.has_point(pos):
				# Directly clicked Deploy/Select button on the card
				selected_stage = stage_num
				_deploy(stage_num)
				return
			elif selected_stage == stage_num:
				# Tapping already selected card deploys to this stage
				_deploy(stage_num)
				return
			else:
				# Select the clicked card
				selected_stage = stage_num
				Global.play_sfx("menu_cursor")
				queue_redraw()
				return

func _deploy(stage_id: int) -> void:
	if is_deploying:
		return
	is_deploying = true
	Global.play_sfx("menu_start")
	get_tree().create_timer(0.20).timeout.connect(func(): Global.start_game(stage_id))

func _draw() -> void:
	# Background Wallpaper & Wash
	if bg_texture != null:
		draw_texture_rect(bg_texture, Rect2(0.0, 0.0, 960.0, 540.0), false)
		draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.04, 0.07, 0.12, 0.88))
	else:
		draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.05, 0.07, 0.11))
	
	# Tactical Tech Grid Lines
	for i in range(11):
		var y := float(i) * 52.0
		draw_line(Vector2(0.0, y), Vector2(960.0, y), Color(0.12, 0.22, 0.38, 0.25), 1.0)
	
	var font := ThemeDB.fallback_font
	
	# If full map mode is active, draw the full-screen tactical blueprint map
	if show_full_map:
		_draw_full_level_map_view(font)
		return
	
	# Top Header
	draw_string(font, Vector2(350.0, 44.0), "MISSION SELECT", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.85, 0.20))
	draw_string(font, Vector2(285.0, 72.0), "OPERATION CONTRA • 8 TACTICAL LEVEL MAPS & BOSS STRONGHOLDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.85, 1.0))
	draw_line(Vector2(32.0, 84.0), Vector2(928.0, 84.0), Color(0.25, 0.45, 0.75, 0.60), 1.5)
	
	# 8 Stage Cards (4 columns x 2 rows)
	var card_w := 205.0
	var card_h := 172.0
	var start_x := 32.0
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
		
		# Card Background Plate
		var bg_col := Color(0.10, 0.16, 0.26, 0.95) if is_sel else Color(0.06, 0.08, 0.13, 0.90)
		draw_rect(card_rect, bg_col)
		
		# Glowing border when selected
		var border_col: Color = s["color"] if is_sel else Color(0.20, 0.28, 0.38, 0.70)
		var border_w: float = 2.5 if is_sel else 1.0
		draw_rect(card_rect, border_col, false, border_w)
		
		# Top pulsing accent bar on selected card
		if is_sel:
			var pulse := 0.7 + 0.3 * sin(anim_timer * 8.0)
			draw_rect(Rect2(cx, cy, card_w, 3.0), Color(s["color"].r, s["color"].g, s["color"].b, pulse))
		
		# Authentic Level Map schematic inside thumbnail box
		var thumb_rect := Rect2(cx + 8.0, cy + 8.0, card_w - 16.0, 68.0)
		LevelMaps.draw_level_map(self, stage_id, thumb_rect, -1.0, false, anim_timer)
		
		# Stage Number & Title
		var title_col := Color(1.0, 0.95, 0.40) if is_sel else Color(0.92, 0.94, 0.98)
		var title_short: String = "STAGE " + str(stage_id) + ": " + s["theme"]
		draw_string(font, Vector2(cx + 10.0, cy + 96.0), title_short, HORIZONTAL_ALIGNMENT_LEFT, card_w - 20.0, 10, title_col)
		
		# Difficulty badge + Boss readout
		draw_rect(Rect2(cx + 10.0, cy + 106.0, 68.0, 16.0), Color(0.08, 0.10, 0.14))
		draw_rect(Rect2(cx + 10.0, cy + 106.0, 68.0, 16.0), s["color"], false, 1.0)
		draw_string(font, Vector2(cx + 14.0, cy + 118.0), s["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, s["color"])
		
		# Boss target tag
		draw_string(font, Vector2(cx + 84.0, cy + 118.0), "BOSS: " + s["boss"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 92.0, 9, Color(1.0, 0.40, 0.40))
		
		# Deploy Button at bottom of card
		var btn_rect := Rect2(cx + 10.0, cy + 134.0, card_w - 20.0, 26.0)
		var btn_bg: Color = s["color"] if is_sel else Color(0.12, 0.18, 0.25)
		draw_rect(btn_rect, btn_bg)
		draw_rect(btn_rect, Color.WHITE if is_sel else Color(0.30, 0.45, 0.60), false, 1.0)
		
		var deploy_label := "► DEPLOY ◄" if is_sel else "SELECT"
		var label_col := Color.WHITE if is_sel else Color(0.70, 0.80, 0.90)
		draw_string(font, Vector2(cx + card_w * 0.5 - 34.0, cy + 151.0), deploy_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_col)
	
	# Bottom Return Button
	var back_rect := Rect2(32.0, 485.0, 140.0, 36.0)
	draw_rect(back_rect, Color(0.12, 0.16, 0.24, 0.90))
	draw_rect(back_rect, Color(0.40, 0.55, 0.75, 0.80), false, 1.5)
	draw_string(font, Vector2(52.0, 508.0), "◄ TITLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.90, 0.95, 1.0))
	
	# Center Tactical Blueprint Map Inspector Button
	var map_btn_rect := Rect2(182.0, 485.0, 320.0, 36.0)
	draw_rect(map_btn_rect, Color(0.08, 0.14, 0.22, 0.92))
	draw_rect(map_btn_rect, Color(0.30, 0.70, 0.95), false, 1.5)
	draw_string(font, Vector2(204.0, 508.0), "☵ VIEW MAP INTEL [M] ☵", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.40, 0.90, 1.0))
	
	# Contra Maker Level Editor Button
	var maker_btn_rect := Rect2(512.0, 485.0, 185.0, 36.0)
	draw_rect(maker_btn_rect, Color(0.08, 0.22, 0.28, 0.94))
	draw_rect(maker_btn_rect, Color(0.20, 0.85, 1.0), false, 1.8)
	draw_string(font, Vector2(526.0, 508.0), "★ CONTRA MAKER ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 1.0, 0.90))
	
	# Bottom Deploy Selected Button
	var dep_rect := Rect2(706.0, 485.0, 222.0, 36.0)
	var sel_color: Color = stages_info[selected_stage - 1]["color"]
	draw_rect(dep_rect, Color(sel_color.r * 0.4, sel_color.g * 0.4, sel_color.b * 0.4, 0.95))
	draw_rect(dep_rect, sel_color, false, 1.8)
	draw_string(font, Vector2(722.0, 508.0), "START STAGE " + str(selected_stage) + " ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_full_level_map_view(font: Font) -> void:
	var m := LevelMaps.get_map_data(selected_stage)
	var p_col: Color = m["primary_color"]
	
	# Dark tech wash
	draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.02, 0.04, 0.08, 0.96))
	
	# Top Header with Stage Switcher hints
	draw_string(font, Vector2(32.0, 42.0), "◄ [Q]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.6, 0.8))
	draw_string(font, Vector2(900.0, 42.0), "[E] ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.6, 0.8))
	
	var header_title: String = "TACTICAL THEATER LEVEL MAP // STAGE " + str(selected_stage) + ": " + m["name"]
	draw_string(font, Vector2(100.0, 36.0), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.88, 0.25))
	draw_string(font, Vector2(100.0, 56.0), m["sector"] + " • THEME: " + m["theme"] + " • THREAT: " + m["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.85, 1.0))
	draw_line(Vector2(32.0, 66.0), Vector2(928.0, 66.0), p_col, 1.5)
	
	# Large Panoramic Terrain Blueprint Schematic Canvas
	var schematic_rect := Rect2(32.0, 78.0, 896.0, 230.0)
	LevelMaps.draw_level_map(self, selected_stage, schematic_rect, -1.0, true, anim_timer)
	
	# Tactical Briefing Intel Card
	var intel_rect := Rect2(32.0, 322.0, 896.0, 145.0)
	draw_rect(intel_rect, Color(0.06, 0.09, 0.15, 0.95))
	draw_rect(intel_rect, Color(0.25, 0.38, 0.55), false, 1.2)
	
	draw_string(font, Vector2(48.0, 346.0), "► OPERATIONAL INTELLIGENCE BRIEFING:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.20))
	draw_string(font, Vector2(48.0, 372.0), m["intel"], HORIZONTAL_ALIGNMENT_LEFT, 860.0, 12, Color(0.92, 0.95, 1.0))
	
	# Hazard and Boss specs
	draw_string(font, Vector2(48.0, 412.0), "TERRAIN HAZARDS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.45, 0.45))
	draw_string(font, Vector2(190.0, 412.0), m["hazard"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.75, 0.75))
	
	draw_string(font, Vector2(48.0, 436.0), "PRIMARY OBJECTIVE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.40, 0.85, 1.0))
	draw_string(font, Vector2(190.0, 436.0), "DESTROY " + m["boss"] + " AT 5800 METERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	draw_string(font, Vector2(620.0, 436.0), "PLATFORMS: " + str(m["platforms"].size()) + " • CHASMS: " + str(m["ground_segments"].size() - 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.8, 1.0))
	
	# Bottom Action Buttons
	var close_rect := Rect2(32.0, 485.0, 200.0, 36.0)
	draw_rect(close_rect, Color(0.12, 0.16, 0.24, 0.90))
	draw_rect(close_rect, Color(0.40, 0.55, 0.75, 0.80), false, 1.5)
	draw_string(font, Vector2(48.0, 508.0), "◄ RETURN TO LEVEL GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.90, 0.95, 1.0))
	
	var dep_rect := Rect2(700.0, 485.0, 228.0, 36.0)
	draw_rect(dep_rect, Color(p_col.r * 0.4, p_col.g * 0.4, p_col.b * 0.4, 0.95))
	draw_rect(dep_rect, p_col, false, 1.8)
	draw_string(font, Vector2(722.0, 508.0), "DEPLOY TO THIS LEVEL ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
