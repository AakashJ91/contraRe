extends Control

var score: int = 0
var high_score: int = 20000
var lives: int = 3
var player_health: int = 3
var player_max_health: int = 3
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
	Global.player_health_changed.connect(_on_player_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	Global.boss_health_changed.connect(_on_boss_health_changed)
	Global.boss_defeated.connect(_on_boss_defeated)
	Global.stage_started.connect(_on_stage_started)
	_update_hud()
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func trigger_stage_intro() -> void:
	Global.start_stage_intro()
	queue_redraw()

func _on_stage_started(_stage_idx: int) -> void:
	trigger_stage_intro()

func _on_score_changed(new_score: int) -> void:
	score = new_score
	if score > high_score:
		high_score = score
	queue_redraw()

func _on_lives_changed(new_lives: int) -> void:
	lives = new_lives
	queue_redraw()

func _on_player_health_changed(current: int, max_val: int) -> void:
	player_health = current
	player_max_health = max_val
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
	player_health = Global.player_health
	player_max_health = Global.PLAYER_MAX_HEALTH
	_on_weapon_changed(Global.current_weapon)

func _draw() -> void:
	# =========================================================================
	# CLEAN FLOATING RETRO ARCADE HUD (NO STRIPE BACKGROUND)
	# =========================================================================
	var screen_w: float = maxf(960.0, get_viewport_rect().size.x)
	var is_mob: bool = Global.is_mobile_device()
	var base_y: float = 22.0 if is_mob else 18.0
	
	# -------------------------------------------------------------------------
	# MODULE 1: REST (COMMANDO LIVES)
	# -------------------------------------------------------------------------
	var cur_x: float = 16.0
	_draw_pixel_text("REST", Vector2(cur_x, base_y), Color(0.35, 0.95, 0.55), 13 if is_mob else 11)
	cur_x += 42.0 if is_mob else 38.0
	
	var shown_lives := mini(lives, 3)
	var icon_step: float = 16.0 if is_mob else 14.0
	for i in range(shown_lives):
		var lx: float = cur_x + float(i) * icon_step
		# Mini commando torso
		draw_rect(Rect2(lx, 13.0 if is_mob else 11.0, 8.5 if is_mob else 7.0, 10.0 if is_mob else 8.0), Color(0.18, 0.40, 0.90))
		# Soldier face
		draw_circle(Vector2(lx + (4.2 if is_mob else 3.5), 11.0 if is_mob else 9.0), 3.0 if is_mob else 2.5, Color(0.96, 0.78, 0.62))
		# Red bandana
		draw_rect(Rect2(lx + 0.5, 9.0 if is_mob else 7.5, 7.5 if is_mob else 6.0, 2.5 if is_mob else 2.0), Color(0.95, 0.20, 0.20))
	cur_x += float(shown_lives) * icon_step + 4.0
	
	var lives_str := "x" + str(lives)
	_draw_pixel_text(lives_str, Vector2(cur_x, base_y), Color(1.0, 0.85, 0.25), 14 if is_mob else 12)
	cur_x += 32.0 if is_mob else 28.0
	
	# -------------------------------------------------------------------------
	# MODULE 2: PLAYER HEALTH (3 HP PIPS)
	# -------------------------------------------------------------------------
	_draw_pixel_text("HP", Vector2(cur_x, base_y), Color(1.0, 0.35, 0.35), 13 if is_mob else 11)
	cur_x += 22.0 if is_mob else 18.0
	var pip_step: float = 13.0 if is_mob else 11.0
	var pip_w: float = 10.0 if is_mob else 8.0
	var pip_h: float = 11.0 if is_mob else 9.0
	var hy: float = base_y - (10.0 if is_mob else 8.5)
	for i in range(player_max_health):
		var hx: float = cur_x + float(i) * pip_step
		# Pip housing
		draw_rect(Rect2(hx, hy, pip_w, pip_h), Color(0.06, 0.09, 0.14, 0.92))
		draw_rect(Rect2(hx, hy, pip_w, pip_h), Color(0.30, 0.42, 0.55, 0.85), false, 1.2 if is_mob else 1.0)
		if i < player_health:
			var hp_col := Color(0.20, 0.95, 0.40) # 3 HP: Green
			if player_health == 2:
				hp_col = Color(1.0, 0.82, 0.20) # 2 HP: Amber
			elif player_health <= 1:
				hp_col = Color(1.0, 0.22, 0.22) # 1 HP: Critical Flashing Red
				if fmod(anim_timer * 6.0, 1.0) > 0.5:
					hp_col = Color(1.0, 0.70, 0.70)
			draw_rect(Rect2(hx + 1.5, hy + 1.5, pip_w - 3.0, pip_h - 3.0), hp_col)
			draw_line(Vector2(hx + 2.0, hy + 2.0), Vector2(hx + pip_w - 2.0, hy + 2.0), Color(1.0, 1.0, 1.0, 0.55), 1.0)
	cur_x += float(player_max_health) * pip_step + 12.0
	
	# -------------------------------------------------------------------------
	# MODULE 3: WEAPON
	# -------------------------------------------------------------------------
	var coin_rad: float = 8.5 if is_mob else 7.0
	var coin_x: float = cur_x + coin_rad + 2.0
	var coin_y: float = base_y - 4.5
	draw_circle(Vector2(coin_x, coin_y), coin_rad, Color(0.12, 0.16, 0.22, 0.90))
	draw_circle(Vector2(coin_x, coin_y), coin_rad, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.25))
	draw_arc(Vector2(coin_x, coin_y), coin_rad, 0.0, TAU, 18, weapon_color, 1.4 if is_mob else 1.2)
	_draw_pixel_text(weapon_letter, Vector2(coin_x - (4.0 if is_mob else 3.5), base_y - 0.5), Color.WHITE, 11 if is_mob else 10)
	cur_x += 24.0 if is_mob else 20.0
	
	_draw_pixel_text(weapon_name, Vector2(cur_x, base_y), weapon_color, 13 if is_mob else 11)
	
	# -------------------------------------------------------------------------
	# MODULE 4: CONTRA MAKER LEVEL EDITOR BUTTON
	# -------------------------------------------------------------------------
	var maker_w: float = 115.0 if is_mob else 100.0
	var maker_h: float = 28.0 if is_mob else 26.0
	var maker_btn_rect := Rect2(screen_w - maker_w - (14.0 if is_mob else 12.0), 6.0, maker_w, maker_h)
	draw_rect(maker_btn_rect, Color(0.10, 0.16, 0.25, 0.90))
	draw_rect(maker_btn_rect, Color(0.25, 0.75, 1.0, 0.85), false, 1.2)
	_draw_pixel_text("★ MAKER", Vector2(maker_btn_rect.position.x + 8.0, 24.0 if not is_mob else 25.0), Color(0.35, 0.95, 1.0), 11 if is_mob else 10)
	_draw_pixel_text("[F1]", Vector2(maker_btn_rect.end.x - 28.0, 24.0 if not is_mob else 25.0), Color(1.0, 0.85, 0.3), 9 if is_mob else 8)
	
	# =========================================================================
	# BOSS CORE HEALTH BAR
	# =========================================================================
	if show_boss_bar and boss_health > 0.0:
		var bar_w: float = 280.0 if is_mob else 240.0
		var bar_x: float = (screen_w - bar_w) * 0.5
		var bar_y: float = 26.0 if is_mob else 24.0
		var bar_h: float = 10.0 if is_mob else 8.0
		
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
		_draw_pixel_text(boss_tag, Vector2(bar_x - (95.0 if is_mob else 84.0), bar_y + (8.0 if is_mob else 7.0)), Color(1.0, 0.35, 0.35), 11 if is_mob else 9)
	
	# =========================================================================
	# STAGE START HIGHLIGHT (FADES & VANISHES AFTER START, NO BACKGROUND)
	# =========================================================================
	if Global.is_stage_intro_active():
		_draw_stage_intro_splash(screen_w)
	
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
			_draw_pixel_text("STAGE " + str(Global.current_stage) + " CLEAR!", Vector2(screen_w * 0.5 - 130.0, 200.0), Color(0.25, 1.0, 0.45), 32)
			_draw_pixel_text("MISSION OBJECTIVE COMPLETED!", Vector2(screen_w * 0.5 - 150.0, 245.0), Color(1.0, 1.0, 1.0), 18)
			_draw_pixel_text("► TAP SCREEN / PRESS JUMP TO PROCEED TO STAGE " + str(Global.current_stage + 1) + " ◄", Vector2(screen_w * 0.5 - 235.0, 285.0), Color(0.30, 0.85, 1.0), 14)
			_draw_pixel_text("[ OR TAP MENU FOR LEVEL SELECT ]", Vector2(screen_w * 0.5 - 130.0, 318.0), Color(0.70, 0.75, 0.85), 12)
		else:
			_draw_pixel_text("OPERATION CONTRA COMPLETE!", Vector2(screen_w * 0.5 - 240.0, 200.0), Color(1.0, 0.85, 0.20), 30)
			_draw_pixel_text("ALL 8 STAGES CLEARED • EARTH IS SAVED!", Vector2(screen_w * 0.5 - 190.0, 245.0), Color(0.30, 1.0, 0.50), 18)
			_draw_pixel_text("CONGRATULATIONS, ULTIMATE COMMANDO!", Vector2(screen_w * 0.5 - 180.0, 285.0), Color(0.95, 0.35, 0.35), 15)
			_draw_pixel_text("[ TAP SCREEN / MENU TO RETURN TO TITLE ]", Vector2(screen_w * 0.5 - 165.0, 318.0), Color(0.30, 0.85, 1.0), 12)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			Global.toggle_maker_mode()
			Global.play_sfx("menu_cursor")
			queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position)

func _handle_touch(pos: Vector2) -> void:
	# Tap on MAKER button
	var screen_w: float = maxf(960.0, get_viewport_rect().size.x)
	var maker_tap_rect := Rect2(screen_w - 114.0, 4.0, 106.0, 32.0)
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

func _draw_stage_intro_splash(screen_w: float) -> void:
	var screen_h: float = maxf(540.0, get_viewport_rect().size.y)
	var is_mob: bool = Global.is_mobile_device()
	var timer: float = Global.stage_intro_timer
	
	# Calculate alpha fade-in, hold, and vanish fade-out
	var alpha: float = 1.0
	if timer > 2.8:
		# Fade in during first 0.4s
		alpha = clampf((Global.STAGE_INTRO_DURATION - timer) / 0.4, 0.0, 1.0)
	elif timer < 0.8:
		# Vanish fade-out during final 0.8s
		alpha = clampf(timer / 0.8, 0.0, 1.0)
	
	if alpha <= 0.001:
		return
	
	var cx: float = screen_w * 0.5
	var cy: float = screen_h * 0.35
	
	# Subtle floating vertical entrance ease
	var entrance_offset: float = 0.0
	if timer > 2.8:
		var t := (Global.STAGE_INTRO_DURATION - timer) / 0.4
		entrance_offset = (1.0 - sin(t * PI * 0.5)) * -12.0
	cy += entrance_offset
	
	# Line 1: STAGE NUMBER (Arcade Gold with multi-pass drop-shadow)
	var stage_badge := "STAGE " + str(Global.current_stage)
	var badge_col := Color(1.0, 0.85, 0.25, alpha)
	_draw_centered_pixel_text(stage_badge, cx, cy - (16.0 if not is_mob else 18.0), badge_col, 20 if not is_mob else 22)
	
	# Line 2: STAGE FULL TITLE (Crisp Glowing Cyan/White with multi-pass drop-shadow)
	var stage_title := Global.get_stage_full_title()
	var pulse := 0.92 + 0.08 * sin(anim_timer * 8.0)
	var title_col := Color(0.50 * pulse, 0.95 * pulse, 1.0, alpha)
	_draw_centered_pixel_text(stage_title, cx, cy + (22.0 if not is_mob else 26.0), title_col, 32 if not is_mob else 36)

func _draw_centered_pixel_text(text: String, center_x: float, y: float, col: Color, font_size: int = 14) -> void:
	var font := ThemeDB.fallback_font
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(center_x - text_w * 0.5, y)
	var shadow_col := Color(0.0, 0.0, 0.0, col.a * 0.95)
	# 8-way outline for supreme legibility on pure floating transparent background
	for ox in [-2.0, 0.0, 2.0]:
		for oy in [-2.0, 0.0, 2.0]:
			if ox != 0.0 or oy != 0.0:
				draw_string(font, pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_col)
	draw_string(font, pos + Vector2(3.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, col.a * 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
