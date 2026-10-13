extends Control

var score: int = 0
var high_score: int = 20000
var lives: int = 3
var weapon_name: String = "RIFLE"
var weapon_letter: String = "R"
var weapon_color: Color = Color(0.35, 0.90, 0.55)
var boss_health: float = 0.0
var boss_max_health: float = 35.0
var show_boss_bar: bool = false
var victory_displayed: bool = false
var anim_timer: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	Global.score_changed.connect(_on_score_changed)
	Global.lives_changed.connect(_on_lives_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	Global.boss_health_changed.connect(_on_boss_health_changed)
	Global.boss_defeated.connect(_on_boss_defeated)
	Global.map_toggled.connect(_on_map_toggled)
	_update_hud()
	queue_redraw()

func _on_map_toggled(_is_open: bool) -> void:
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _on_score_changed(new_score: int) -> void:
	score = new_score
	if score > high_score:
		high_score = score
	queue_redraw()

func _on_lives_changed(new_lives: int) -> void:
	lives = new_lives
	queue_redraw()

func _on_weapon_changed(wtype: Global.WeaponType) -> void:
	match wtype:
		Global.WeaponType.RIFLE:
			weapon_name = "STD RIFLE"
			weapon_letter = "R"
			weapon_color = Color(0.35, 0.90, 0.55)
		Global.WeaponType.SPREAD:
			weapon_name = "SPREAD GUN"
			weapon_letter = "S"
			weapon_color = Color(1.0, 0.45, 0.15)
		Global.WeaponType.MACHINE:
			weapon_name = "MACHINE GUN"
			weapon_letter = "M"
			weapon_color = Color(1.0, 0.80, 0.15)
		Global.WeaponType.LASER:
			weapon_name = "LASER BEAM"
			weapon_letter = "L"
			weapon_color = Color(0.20, 0.85, 1.0)
	queue_redraw()

func _on_boss_health_changed(current: float, max_val: float) -> void:
	show_boss_bar = true
	boss_health = current
	boss_max_health = max_val
	queue_redraw()

func _on_boss_defeated() -> void:
	victory_displayed = true
	queue_redraw()

func _update_hud() -> void:
	score = Global.score
	high_score = Global.high_score
	lives = Global.lives
	_on_weapon_changed(Global.current_weapon)

func _draw() -> void:
	# =========================================================================
	# CLEAN FLOATING RETRO ARCADE HUD (NO STRIPE BACKGROUND)
	# =========================================================================
	var screen_w: float = maxf(960.0, get_viewport_rect().size.x)
	var base_y: float = 18.0
	
	# -------------------------------------------------------------------------
	# MODULE 1: 1P SCORE
	# -------------------------------------------------------------------------
	var cur_x: float = 16.0
	_draw_pixel_text("1P", Vector2(cur_x, base_y), Color(1.0, 0.85, 0.20), 12)
	cur_x += 22.0
	var score_str := "%06d" % score
	_draw_pixel_text(score_str, Vector2(cur_x, base_y), Color(1.0, 1.0, 1.0), 13)
	cur_x += 65.0
	
	# -------------------------------------------------------------------------
	# MODULE 2: HI-SCORE
	# -------------------------------------------------------------------------
	_draw_pixel_text("HI", Vector2(cur_x, base_y), Color(1.0, 0.35, 0.35), 12)
	cur_x += 22.0
	var hi_str := "%06d" % high_score
	_draw_pixel_text(hi_str, Vector2(cur_x, base_y), Color(0.95, 0.95, 1.0), 13)
	cur_x += 65.0
	
	# -------------------------------------------------------------------------
	# MODULE 3: STAGE & MISSION
	# -------------------------------------------------------------------------
	var stage_tag := "STAGE " + str(Global.current_stage)
	_draw_pixel_text(stage_tag, Vector2(cur_x, base_y), Color(0.30, 0.85, 1.0), 11)
	cur_x += 58.0
	
	var stage_name := Global.get_stage_name()
	_draw_pixel_text(stage_name, Vector2(cur_x, base_y), Color(0.85, 0.95, 1.0), 11)
	cur_x += 70.0
	
	# -------------------------------------------------------------------------
	# MODULE 4: REST (COMMANDO LIVES)
	# -------------------------------------------------------------------------
	_draw_pixel_text("REST", Vector2(cur_x, base_y), Color(0.35, 0.95, 0.55), 11)
	cur_x += 38.0
	
	var shown_lives := mini(lives, 3)
	for i in range(shown_lives):
		var lx: float = cur_x + float(i) * 14.0
		# Mini commando torso
		draw_rect(Rect2(lx, 11.0, 7.0, 8.0), Color(0.18, 0.40, 0.90))
		# Soldier face
		draw_circle(Vector2(lx + 3.5, 9.0), 2.5, Color(0.96, 0.78, 0.62))
		# Red bandana
		draw_rect(Rect2(lx + 0.5, 7.5, 6.0, 2.0), Color(0.95, 0.20, 0.20))
	cur_x += float(shown_lives) * 14.0 + 4.0
	
	var lives_str := "x" + str(lives)
	_draw_pixel_text(lives_str, Vector2(cur_x, base_y), Color(1.0, 0.85, 0.25), 12)
	cur_x += 32.0
	
	# -------------------------------------------------------------------------
	# MODULE 5: WEAPON
	# -------------------------------------------------------------------------
	var coin_x: float = cur_x + 8.0
	var coin_y: float = base_y - 4.5
	draw_circle(Vector2(coin_x, coin_y), 7.0, Color(0.12, 0.16, 0.22, 0.90))
	draw_circle(Vector2(coin_x, coin_y), 7.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.25))
	draw_arc(Vector2(coin_x, coin_y), 7.0, 0.0, TAU, 16, weapon_color, 1.2)
	_draw_pixel_text(weapon_letter, Vector2(coin_x - 3.5, base_y - 0.5), Color.WHITE, 10)
	cur_x += 20.0
	
	_draw_pixel_text(weapon_name, Vector2(cur_x, base_y), weapon_color, 11)
	
	# -------------------------------------------------------------------------
	# MODULE 6: TACTICAL LEVEL MINIMAP BAR (REAL-TIME SECTOR RADAR)
	# -------------------------------------------------------------------------
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var player_x: float = player_node.global_position.x if (player_node != null and is_instance_valid(player_node)) else 0.0
	
	var minimap_x: float = 600.0
	var minimap_y: float = 7.0
	var minimap_w: float = 230.0
	var minimap_h: float = 16.0
	var minimap_rect := Rect2(minimap_x, minimap_y, minimap_w, minimap_h)
	
	LevelMaps.draw_level_map(self, Global.current_stage, minimap_rect, player_x, false, anim_timer)
	
	var meters := int(player_x)
	var telemetry_str := "MAP: %dm / 5800m" % meters
	_draw_pixel_text(telemetry_str, Vector2(minimap_x + 2.0, minimap_y + minimap_h + 10.0), Color(0.35, 0.85, 1.0), 9)
	_draw_pixel_text("[TAP / PRESS M]", Vector2(minimap_x + minimap_w - 74.0, minimap_y + minimap_h + 10.0), Color(0.60, 0.75, 0.90), 8)
	
	# -------------------------------------------------------------------------
	# MODULE 7: CONTRA MAKER LEVEL EDITOR BUTTON
	# -------------------------------------------------------------------------
	var maker_btn_rect := Rect2(848.0, 7.0, 100.0, 26.0)
	draw_rect(maker_btn_rect, Color(0.10, 0.16, 0.25, 0.90))
	draw_rect(maker_btn_rect, Color(0.25, 0.75, 1.0, 0.85), false, 1.2)
	_draw_pixel_text("★ MAKER", Vector2(856.0, 24.0), Color(0.35, 0.95, 1.0), 10)
	_draw_pixel_text("[F1]", Vector2(922.0, 24.0), Color(1.0, 0.85, 0.3), 8)
	
	# =========================================================================
	# BOSS CORE HEALTH BAR
	# =========================================================================
	if show_boss_bar and boss_health > 0.0:
		var bar_w := 240.0
		var bar_x := (screen_w - bar_w) * 0.5
		var bar_y := 24.0
		var bar_h := 8.0
		
		# Boss bar housing
		draw_rect(Rect2(bar_x - 2.0, bar_y - 1.0, bar_w + 4.0, bar_h + 2.0), Color(0.04, 0.06, 0.09, 0.92))
		draw_rect(Rect2(bar_x - 2.0, bar_y - 1.0, bar_w + 4.0, bar_h + 2.0), Color(0.90, 0.25, 0.25, 0.80), false, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.12, 0.04, 0.04, 0.95))
		
		var pct := clampf(boss_health / boss_max_health, 0.0, 1.0)
		var fill_w := bar_w * pct
		if fill_w > 0.0:
			var pulse := 0.85 + 0.15 * sin(anim_timer * 8.0)
			draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), Color(0.95 * pulse, 0.18, 0.18))
			draw_line(Vector2(bar_x, bar_y + 0.5), Vector2(bar_x + fill_w, bar_y + 0.5), Color(1.0, 0.65, 0.65, 0.7), 1.0)
		
		var boss_tag := Global.get_boss_name()
		_draw_pixel_text(boss_tag, Vector2(bar_x - 84.0, bar_y + 7.0), Color(1.0, 0.35, 0.35), 9)
	
	# =========================================================================
	# FULL TACTICAL LEVEL MAP OVERLAY (PAUSE & INTEL SCHEMATIC)
	# =========================================================================
	if Global.is_map_open:
		_draw_tactical_map_overlay(screen_w, player_x)
	
	# =========================================================================
	# GAME OVER & VICTORY OVERLAYS
	# =========================================================================
	if Global.is_game_over:
		draw_rect(Rect2(0.0, 160.0, screen_w, 160.0), Color(0.02, 0.02, 0.04, 0.92))
		draw_line(Vector2(0.0, 160.0), Vector2(screen_w, 160.0), Color(0.95, 0.20, 0.20, 0.9), 2.0)
		draw_line(Vector2(0.0, 320.0), Vector2(screen_w, 320.0), Color(0.95, 0.20, 0.20, 0.9), 2.0)
		_draw_pixel_text("GAME OVER", Vector2(screen_w * 0.5 - 110.0, 230.0), Color(1.0, 0.25, 0.25), 32)
		_draw_pixel_text("PRESS RESTART OR TAP SCREEN TO RETRY", Vector2(screen_w * 0.5 - 190.0, 275.0), Color(1.0, 0.90, 0.30), 16)
	elif victory_displayed:
		draw_rect(Rect2(0.0, 140.0, screen_w, 210.0), Color(0.02, 0.04, 0.08, 0.94))
		draw_line(Vector2(0.0, 140.0), Vector2(screen_w, 140.0), Color(0.20, 0.95, 0.40, 0.9), 2.0)
		draw_line(Vector2(0.0, 350.0), Vector2(screen_w, 350.0), Color(0.20, 0.95, 0.40, 0.9), 2.0)
		if Global.current_stage < Global.MAX_STAGES:
			_draw_pixel_text("STAGE " + str(Global.current_stage) + " CLEAR!", Vector2(screen_w * 0.5 - 130.0, 195.0), Color(0.25, 1.0, 0.45), 32)
			_draw_pixel_text("MISSION OBJECTIVE COMPLETED!", Vector2(screen_w * 0.5 - 150.0, 235.0), Color(1.0, 1.0, 1.0), 18)
			_draw_pixel_text("STAGE SCORE: " + str(score), Vector2(screen_w * 0.5 - 85.0, 270.0), Color(1.0, 0.85, 0.20), 16)
			_draw_pixel_text("► TAP SCREEN / PRESS JUMP TO PROCEED TO STAGE " + str(Global.current_stage + 1) + " ◄", Vector2(screen_w * 0.5 - 235.0, 305.0), Color(0.30, 0.85, 1.0), 14)
			_draw_pixel_text("[ OR TAP MENU FOR LEVEL SELECT ]", Vector2(screen_w * 0.5 - 130.0, 332.0), Color(0.70, 0.75, 0.85), 12)
		else:
			_draw_pixel_text("OPERATION CONTRA COMPLETE!", Vector2(screen_w * 0.5 - 240.0, 195.0), Color(1.0, 0.85, 0.20), 30)
			_draw_pixel_text("ALL 8 STAGES CLEARED • EARTH IS SAVED!", Vector2(screen_w * 0.5 - 190.0, 235.0), Color(0.30, 1.0, 0.50), 18)
			_draw_pixel_text("FINAL SCORE: " + str(score), Vector2(screen_w * 0.5 - 85.0, 270.0), Color(1.0, 1.0, 1.0), 16)
			_draw_pixel_text("CONGRATULATIONS, ULTIMATE COMMANDO!", Vector2(screen_w * 0.5 - 180.0, 305.0), Color(0.95, 0.35, 0.35), 15)
			_draw_pixel_text("[ TAP SCREEN / MENU TO RETURN TO TITLE ]", Vector2(screen_w * 0.5 - 165.0, 332.0), Color(0.30, 0.85, 1.0), 12)

func _draw_tactical_map_overlay(screen_w: float, player_x: float) -> void:
	var font := ThemeDB.fallback_font
	var m := LevelMaps.get_map_data(Global.current_stage)
	var p_col: Color = m["primary_color"]
	
	# Dark tactical backdrop
	draw_rect(Rect2(0.0, 0.0, screen_w, 540.0), Color(0.02, 0.04, 0.08, 0.95))
	
	# Top Header
	var title_str: String = "TACTICAL THEATER LEVEL MAP // STAGE " + str(Global.current_stage) + ": " + m["name"]
	draw_string(font, Vector2(36.0, 38.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.88, 0.25))
	draw_string(font, Vector2(36.0, 56.0), m["sector"] + " • THEME: " + m["theme"] + " • THREAT: " + m["diff"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 0.85, 1.0))
	draw_line(Vector2(36.0, 64.0), Vector2(screen_w - 36.0, 64.0), p_col, 1.5)
	
	# Close button on top-right
	draw_rect(Rect2(screen_w - 180.0, 22.0, 144.0, 32.0), Color(0.12, 0.16, 0.24, 0.90))
	draw_rect(Rect2(screen_w - 180.0, 22.0, 144.0, 32.0), Color(0.40, 0.65, 0.95), false, 1.2)
	draw_string(font, Vector2(screen_w - 165.0, 43.0), "◄ RESUME COMBAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	
	# Panoramic blueprint schematic
	var schematic_rect := Rect2(36.0, 76.0, screen_w - 72.0, 240.0)
	LevelMaps.draw_level_map(self, Global.current_stage, schematic_rect, player_x, true, anim_timer)
	
	# Tactical Telemetry & Briefing Card below
	var intel_rect := Rect2(36.0, 330.0, screen_w - 72.0, 140.0)
	draw_rect(intel_rect, Color(0.05, 0.08, 0.13, 0.95))
	draw_rect(intel_rect, Color(0.20, 0.35, 0.50), false, 1.2)
	
	draw_string(font, Vector2(52.0, 354.0), "► CURRENT COMMANDO TELEMETRY:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.25, 1.0, 0.45))
	draw_string(font, Vector2(285.0, 354.0), "POSITION: %d METERS  (SECTOR PROGRESS: %d%%)" % [int(player_x), int(clampf(player_x / 5800.0 * 100.0, 0.0, 100.0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	draw_string(font, Vector2(52.0, 382.0), "MISSION OBJECTIVE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.20))
	draw_string(font, Vector2(285.0, 382.0), "BREACH ENEMY DEFENSES AND ANNIHILATE " + m["boss"] + " AT 5800 METERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.90, 0.90))
	
	draw_string(font, Vector2(52.0, 410.0), "TERRAIN HAZARDS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.40, 0.40))
	draw_string(font, Vector2(285.0, 410.0), m["hazard"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.70, 0.70))
	
	draw_string(font, Vector2(52.0, 436.0), "INTELLIGENCE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.85, 1.0))
	draw_string(font, Vector2(285.0, 436.0), m["intel"], HORIZONTAL_ALIGNMENT_LEFT, screen_w - 360.0, 11, Color(0.85, 0.92, 1.0))
	
	# Bottom Hint
	draw_string(font, Vector2(screen_w * 0.5 - 145.0, 502.0), "[ TAP SCREEN OR PRESS M / MAP BUTTON TO RETURN ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.50, 0.70, 0.90))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			Global.toggle_map()
			Global.play_sfx("menu_cursor")
			queue_redraw()
		elif event.keycode == KEY_F1:
			Global.toggle_maker_mode()
			Global.play_sfx("menu_cursor")
			queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position)

func _handle_touch(pos: Vector2) -> void:
	if Global.is_map_open:
		Global.toggle_map()
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	# Tap on top-right minimap bar to open full tactical map
	var minimap_tap_rect := Rect2(600.0, 4.0, 235.0, 32.0)
	if minimap_tap_rect.has_point(pos):
		Global.toggle_map()
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return
	
	# Tap on MAKER button
	var maker_tap_rect := Rect2(846.0, 4.0, 106.0, 32.0)
	if maker_tap_rect.has_point(pos):
		Global.toggle_maker_mode()
		Global.play_sfx("menu_cursor")
		queue_redraw()
		return

func _draw_pixel_text(text: String, pos: Vector2, col: Color, font_size: int = 14) -> void:
	var font := ThemeDB.fallback_font
	# 4-way outline shadow for crisp visibility on top of any background
	draw_string(font, pos + Vector2(-1.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos + Vector2(1.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos + Vector2(0.0, -1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos + Vector2(0.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
