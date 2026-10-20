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

var health_pip_full: Texture2D = null
var health_pip_warning: Texture2D = null
var health_pip_critical: Texture2D = null
var health_pip_empty: Texture2D = null
var medal_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	Global.score_changed.connect(_on_score_changed)
	Global.lives_changed.connect(_on_lives_changed)
	Global.player_health_changed.connect(_on_player_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	Global.boss_health_changed.connect(_on_boss_health_changed)
	Global.boss_defeated.connect(_on_boss_defeated)
	Global.mini_boss_defeated.connect(_on_mini_boss_defeated)
	Global.stage_started.connect(_on_stage_started)
	
	if ResourceLoader.exists("res://assets/ui/medal_life.png"):
		medal_texture = load("res://assets/ui/medal_life.png")
	if ResourceLoader.exists("res://assets/ui/health_pip_full.png"):
		health_pip_full = load("res://assets/ui/health_pip_full.png")
	if ResourceLoader.exists("res://assets/ui/health_pip_warning.png"):
		health_pip_warning = load("res://assets/ui/health_pip_warning.png")
	if ResourceLoader.exists("res://assets/ui/health_pip_critical.png"):
		health_pip_critical = load("res://assets/ui/health_pip_critical.png")
	if ResourceLoader.exists("res://assets/ui/health_pip_empty.png"):
		health_pip_empty = load("res://assets/ui/health_pip_empty.png")
	
	_update_hud()
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func trigger_stage_intro() -> void:
	Global.start_stage_intro()
	Global.play_sfx("menu_start")
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
		Global.WeaponType.FIRE:
			weapon_name = "TWIST FIRE"
			weapon_letter = "F"
			weapon_color = Color(1.0, 0.35, 0.1)
	queue_redraw()

func _on_boss_health_changed(current: float, max_val: float) -> void:
	if max_val <= 0.0 or current <= 0.0:
		show_boss_bar = false
	else:
		show_boss_bar = true
		boss_health = current
		boss_max_health = max_val
	queue_redraw()

func _on_mini_boss_defeated() -> void:
	show_boss_bar = false
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
	var medal_w: float = 12.0 if is_mob else 10.0
	var medal_h: float = 16.0 if is_mob else 14.0
	var icon_step: float = medal_w + (4.0 if is_mob else 3.0)
	var my: float = base_y - (13.0 if is_mob else 11.5)
	
	for i in range(shown_lives):
		var lx: float = cur_x + float(i) * icon_step
		if medal_texture != null:
			draw_texture_rect(medal_texture, Rect2(lx, my, medal_w, medal_h), false)
		else:
			# Fallback: Mini commando torso
			draw_rect(Rect2(lx, 13.0 if is_mob else 11.0, 8.5 if is_mob else 7.0, 10.0 if is_mob else 8.0), Color(0.18, 0.40, 0.90))
			draw_circle(Vector2(lx + (4.2 if is_mob else 3.5), 11.0 if is_mob else 9.0), 3.0 if is_mob else 2.5, Color(0.96, 0.78, 0.62))
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
	var pip_w: float = 11.0 if is_mob else 9.0
	var pip_h: float = 15.0 if is_mob else 13.0
	var pip_step: float = pip_w + (4.0 if is_mob else 3.0)
	var hy: float = base_y - (12.0 if is_mob else 10.5)
	
	for i in range(player_max_health):
		var hx: float = cur_x + float(i) * pip_step
		var pip_rect := Rect2(hx, hy, pip_w, pip_h)
		
		var chosen_tex: Texture2D = health_pip_empty
		if i < player_health:
			if player_health == 3:
				chosen_tex = health_pip_full
			elif player_health == 2:
				chosen_tex = health_pip_warning
			else:
				# 1 HP: Critical Flashing
				if fmod(anim_timer * 6.0, 1.0) > 0.45:
					chosen_tex = health_pip_critical
				else:
					chosen_tex = health_pip_empty
		else:
			chosen_tex = health_pip_empty
		
		if chosen_tex != null:
			draw_texture_rect(chosen_tex, pip_rect, false)
		else:
			# Fallback procedural rendering
			draw_rect(pip_rect, Color(0.06, 0.09, 0.14, 0.92))
			draw_rect(pip_rect, Color(0.30, 0.42, 0.55, 0.85), false, 1.0)
			if i < player_health:
				var hp_col := Color(0.20, 0.95, 0.40)
				if player_health == 2:
					hp_col = Color(1.0, 0.82, 0.20)
				elif player_health <= 1:
					hp_col = Color(1.0, 0.22, 0.22)
				draw_rect(Rect2(hx + 1.5, hy + 1.5, pip_w - 3.0, pip_h - 3.0), hp_col)
	cur_x += float(player_max_health) * pip_step + 12.0
	
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
	# BOSS ENCOUNTER CINEMATIC CUTSCENE (LETTERBOX BARS, WARNING, DOSSIER CARD)
	# =========================================================================
	if Global.is_boss_cutscene_active:
		_draw_boss_cutscene(screen_w)
	
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
	if Global.is_boss_cutscene_active and event.is_pressed():
		Global.skip_boss_cutscene()
		return
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
	if Global.is_boss_cutscene_active:
		Global.skip_boss_cutscene()
		return
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
	var t_elapsed: float = Global.STAGE_INTRO_DURATION - timer
	
	if timer <= 0.0 or timer > Global.STAGE_INTRO_DURATION:
		return

	var cx: float = screen_w * 0.5
	var cy: float = screen_h * 0.35
	
	var enter_dur: float = 0.92
	var exit_dur: float = 0.85
	
	var is_entering := (t_elapsed < enter_dur)
	var is_exiting := (timer < exit_dur)
	var t_exit := (exit_dur - timer) if is_exiting else 0.0
	
	var flash_intensity: float = 0.0
	if is_entering and t_elapsed >= 0.80:
		var flash_t := clampf((t_elapsed - 0.80) / 0.18, 0.0, 1.0)
		flash_intensity = (1.0 - flash_t) * 0.95
	
	# Gentle hover breathing during presentation hold
	if not is_entering and not is_exiting:
		cy += sin(anim_timer * 4.0) * 2.5
	
	var stage_badge := "STAGE " + str(Global.current_stage)
	var stage_title := Global.get_stage_full_title()
	
	var badge_font_size: int = 22 if is_mob else 20
	var title_font_size: int = 36 if is_mob else 32
	
	var pos1_y: float = cy - (18.0 if not is_mob else 20.0)
	var pos2_y: float = cy + (22.0 if not is_mob else 26.0)
	
	# Shimmer & Pulse base colors
	var pulse := 0.92 + 0.08 * sin(anim_timer * 7.0)
	var badge_base := Color(1.0, 0.85, 0.25, 1.0)
	var title_base := Color(0.45 * pulse, 0.95 * pulse, 1.0, 1.0)
	
	if flash_intensity > 0.01:
		badge_base = badge_base.lerp(Color.WHITE, flash_intensity)
		title_base = title_base.lerp(Color.WHITE, flash_intensity)
		
		# Center impact laser streak upon full text completion
		var streak_w: float = lerpf(80.0, screen_w * 0.45, 1.0 - flash_intensity)
		var streak_col_inner := Color(1.0, 1.0, 1.0, flash_intensity * 0.9)
		var streak_col_outer := Color(0.25, 0.90, 1.0, flash_intensity * 0.5)
		draw_line(Vector2(cx - streak_w, cy), Vector2(cx + streak_w, cy), streak_col_outer, 5.0)
		draw_line(Vector2(cx - streak_w * 0.8, cy), Vector2(cx + streak_w * 0.8, cy), streak_col_inner, 2.0)
	
	# Decorative wings flanking STAGE X
	var font := ThemeDB.fallback_font
	var badge_w := font.get_string_size(stage_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_font_size).x
	var badge_finish: float = 0.0 + float(stage_badge.length()) * 0.045 + 0.15
	
	var wing_progress: float = 1.0
	if is_entering:
		wing_progress = clampf((t_elapsed - 0.20) / (badge_finish - 0.20), 0.0, 1.0)
	elif is_exiting:
		wing_progress = clampf(1.0 - t_exit / 0.35, 0.0, 1.0)
	
	if wing_progress > 0.02:
		var wing_pad: float = 16.0
		var max_wing_len: float = 38.0
		var wing_len: float = max_wing_len * wing_progress
		var wing_alpha: float = wing_progress * 0.85
		var wing_col := Color(1.0, 0.82, 0.20, wing_alpha)
		var lx1 := cx - (badge_w * 0.5) - wing_pad - wing_len
		var lx2 := cx - (badge_w * 0.5) - wing_pad
		draw_line(Vector2(lx1, pos1_y), Vector2(lx2, pos1_y), wing_col, 2.0)
		draw_line(Vector2(lx1, pos1_y - 4.0), Vector2(lx1, pos1_y + 4.0), wing_col, 2.0)
		var rx1 := cx + (badge_w * 0.5) + wing_pad
		var rx2 := cx + (badge_w * 0.5) + wing_pad + wing_len
		draw_line(Vector2(rx1, pos1_y), Vector2(rx2, pos1_y), wing_col, 2.0)
		draw_line(Vector2(rx2, pos1_y - 4.0), Vector2(rx2, pos1_y + 4.0), wing_col, 2.0)

	# Letter-by-letter rendering for Line 1 (Badge) & Line 2 (Full Title)
	_draw_letter_by_letter_line(
		stage_badge,
		Vector2(cx, pos1_y),
		badge_base,
		badge_font_size,
		0.0,      # line_enter_delay
		0.0,      # line_exit_delay
		t_elapsed,
		t_exit,
		is_entering,
		is_exiting,
		0.045,    # enter_stagger
		0.032,    # exit_stagger
		0.20,     # enter_char_dur
		0.28,     # exit_char_dur
		false,    # show_cursor
		-1.0      # fan_bias
	)
	_draw_letter_by_letter_line(
		stage_title,
		Vector2(cx, pos2_y),
		title_base,
		title_font_size,
		0.16,     # line_enter_delay
		0.10,     # line_exit_delay
		t_elapsed,
		t_exit,
		is_entering,
		is_exiting,
		0.038,    # enter_stagger
		0.032,    # exit_stagger
		0.20,     # enter_char_dur
		0.28,     # exit_char_dur
		true,     # show_cursor
		1.0       # fan_bias
	)

func _draw_letter_by_letter_line(
	text: String,
	center_pos: Vector2,
	base_color: Color,
	font_size: int,
	line_enter_delay: float,
	line_exit_delay: float,
	t_elapsed: float,
	t_exit: float,
	is_entering: bool,
	is_exiting: bool,
	enter_stagger: float,
	exit_stagger: float,
	enter_char_dur: float,
	exit_char_dur: float,
	show_cursor: bool,
	fan_bias: float
) -> void:
	if text.is_empty():
		return
		
	var font := ThemeDB.fallback_font
	var total_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var start_x := center_pos.x - (total_w * 0.5)
	var base_y := center_pos.y
	
	var enter_finish := line_enter_delay + float(text.length()) * enter_stagger + enter_char_dur
	var is_line_entering := (is_entering and t_elapsed < enter_finish)
	var latest_active_x: float = start_x
	
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var pref_w := font.get_string_size(text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var char_w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var char_cx := start_x + pref_w + char_w * 0.5
		
		# If line is entering and character hasn't started its entrance yet, omit it
		if is_line_entering:
			var char_enter_start := line_enter_delay + float(i) * enter_stagger
			if t_elapsed < char_enter_start:
				continue
		
		var char_pos := Vector2(char_cx, base_y)
		var char_scale := Vector2.ONE
		var char_alpha: float = 1.0
		var char_col := base_color
		
		if is_line_entering:
			var char_enter_start := line_enter_delay + float(i) * enter_stagger
			var char_t := clampf((t_elapsed - char_enter_start) / enter_char_dur, 0.0, 1.0)
			if char_t < 1.0:
				var e := _ease_out_back(char_t)
				var drop_y := (1.0 - e) * -26.0
				char_pos.y += drop_y
				char_scale = Vector2.ONE * lerpf(2.0, 1.0, e)
				char_alpha = clampf(char_t / 0.20, 0.0, 1.0)
				
				var flash := clampf((0.35 - char_t) / 0.35, 0.0, 1.0)
				char_col = char_col.lerp(Color.WHITE, flash)
				latest_active_x = start_x + pref_w + char_w + 3.0
		elif is_exiting:
			var char_exit_start := line_exit_delay + float(i) * exit_stagger
			var char_exit_t := clampf((t_exit - char_exit_start) / exit_char_dur, 0.0, 1.0)
			
			# If character has completed its flight, do not draw
			if char_exit_t >= 1.0:
				continue
				
			if t_exit >= char_exit_start:
				# Active supersonic liftoff per letter
				var e_exit := pow(char_exit_t, 2.2)
				var lift_y: float = -e_exit * 190.0
				var fan_x: float = fan_bias * 25.0 * e_exit + (float(i) - float(text.length() - 1) * 0.5) * char_exit_t * 10.0
				
				char_pos.y += lift_y
				char_pos.x += fan_x
				
				# Vertical hyper-warp elongation
				char_scale.x = maxf(0.1, 1.0 - char_exit_t * 0.35)
				char_scale.y = 1.0 + char_exit_t * 1.6
				char_alpha = clampf(1.0 - pow(char_exit_t, 1.6), 0.0, 1.0)
				
				# Initial ignition white flash
				if char_exit_t < 0.28:
					var blast := (0.28 - char_exit_t) / 0.28
					char_col = char_col.lerp(Color.WHITE, blast * 0.9)
				
				# Speed blur afterimage ghost
				if char_exit_t > 0.08 and char_exit_t < 0.85:
					var g_pos := Vector2(char_cx + fan_x * 0.55, base_y + lift_y * 0.55)
					var g_col := char_col
					g_col.a = char_alpha * 0.35
					if ch != " ":
						_draw_transformed_pixel_text(ch, g_pos, char_scale, g_col, font_size)
		else:
			# Traveling shimmer wave across settled letters during hold
			var shimmer_center := start_x + fmod(anim_timer * 340.0, total_w + 140.0) - 70.0
			var dist := absf(char_cx - shimmer_center)
			var gleam := clampf(1.0 - dist / 36.0, 0.0, 1.0)
			char_col = char_col.lerp(Color.WHITE, gleam * 0.6)
		
		char_col.a = char_alpha
		
		if ch != " " and char_alpha > 0.001:
			_draw_transformed_pixel_text(ch, char_pos, char_scale, char_col, font_size)
	
	# High-tech cyber typing cursor at leading edge during entrance
	if show_cursor and is_line_entering and t_elapsed >= line_enter_delay:
		var cur_blink := 0.65 + 0.35 * sin(anim_timer * 22.0)
		var cur_col := Color(0.40, 0.95, 1.0, cur_blink)
		var cur_h: float = float(font_size) * 0.70
		draw_line(Vector2(latest_active_x, base_y - cur_h * 0.5), Vector2(latest_active_x, base_y + cur_h * 0.5), cur_col, 2.5)

static func _ease_out_back(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	var p := clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + c3 * p * p * p + c1 * p * p

static func _ease_in_back(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	var p := clampf(t, 0.0, 1.0)
	return c3 * p * p * p - c1 * p * p

func _draw_transformed_pixel_text(text: String, center: Vector2, scale_vec: Vector2, col: Color, font_size: int = 14) -> void:
	if col.a <= 0.001 or scale_vec.x <= 0.001 or scale_vec.y <= 0.001:
		return
	var font := ThemeDB.fallback_font
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var baseline_offset_y := (ascent - descent) * 0.5
	var local_pos := Vector2(-text_w * 0.5, baseline_offset_y)
	
	draw_set_transform(center, 0.0, scale_vec)
	var shadow_col := Color(0.0, 0.0, 0.0, col.a * 0.95)
	# 8-way outline for supreme floating contrast
	for ox in [-2.0, 0.0, 2.0]:
		for oy in [-2.0, 0.0, 2.0]:
			if ox != 0.0 or oy != 0.0:
				draw_string(font, local_pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_col)
	draw_string(font, local_pos + Vector2(3.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, col.a * 0.85))
	draw_string(font, local_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_boss_cutscene(screen_w: float) -> void:
	var screen_h: float = maxf(540.0, get_viewport_rect().size.y)
	var is_mob: bool = Global.is_mobile_device()
	var timer: float = Global.boss_cutscene_timer
	var t_elapsed: float = Global.BOSS_CUTSCENE_DURATION - timer
	
	if timer <= 0.0 or timer > Global.BOSS_CUTSCENE_DURATION:
		return
	
	var font := ThemeDB.fallback_font
	
	# -------------------------------------------------------------------------
	# 1. WIDESCREEN CINEMATIC LETTERBOX BARS (TOP & BOTTOM)
	# -------------------------------------------------------------------------
	var max_bar_h: float = 64.0 if not is_mob else 54.0
	var bar_in_t := clampf(t_elapsed / 0.35, 0.0, 1.0)
	var bar_h := max_bar_h * clampf(_ease_out_back(bar_in_t), 0.0, 1.05)
	
	# Top letterbox bar
	draw_rect(Rect2(0.0, 0.0, screen_w, bar_h), Color(0.02, 0.03, 0.05, 0.96))
	# Bottom letterbox bar
	draw_rect(Rect2(0.0, screen_h - bar_h, screen_w, bar_h), Color(0.02, 0.03, 0.05, 0.96))
	
	# Neon hazard border lines
	var hazard_pulse := 0.75 + 0.25 * sin(anim_timer * 10.0)
	var border_col := Color(1.0, 0.22, 0.22, 0.90 * hazard_pulse)
	draw_line(Vector2(0.0, bar_h), Vector2(screen_w, bar_h), border_col, 2.0)
	draw_line(Vector2(0.0, screen_h - bar_h), Vector2(screen_w, screen_h - bar_h), border_col, 2.0)
	
	# Tactical micro telemetry in letterbox bars
	if bar_in_t >= 0.75:
		var tech_pulse := 0.85 + 0.15 * sin(anim_timer * 6.0)
		_draw_pixel_text("▶ COMBAT SENSORS // APEX SENSOR LOCK", Vector2(16.0, bar_h - 14.0), Color(0.35, 0.88, 1.0, tech_pulse), 11 if is_mob else 10)
		var right_tag := "SECTOR " + str(Global.current_stage) + " // BOSS ENCOUNTER"
		var rtag_w := font.get_string_size(right_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_draw_pixel_text(right_tag, Vector2(screen_w - rtag_w - 16.0, bar_h - 14.0), Color(1.0, 0.85, 0.30, tech_pulse), 11 if is_mob else 10)
		
		# Skip instruction prompt in bottom bar
		var skip_txt := "[ TAP SCREEN OR PRESS ANY BUTTON TO SKIP ]"
		var skip_sz := 12 if is_mob else 11
		var skip_w := font.get_string_size(skip_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, skip_sz).x
		var skip_col := Color(0.85, 0.92, 1.0, 0.65 + 0.35 * sin(anim_timer * 5.0))
		_draw_pixel_text(skip_txt, Vector2((screen_w - skip_w) * 0.5, screen_h - (bar_h * 0.5) + 4.0), skip_col, skip_sz)
	
	# -------------------------------------------------------------------------
	# 2. EMERGENCY RED KLAXON WASH (AMBIENT SIREN PULSE)
	# -------------------------------------------------------------------------
	if t_elapsed < 2.5:
		var siren_f: float = 0.5 + 0.5 * sin(t_elapsed * 14.0)
		draw_rect(Rect2(0.0, bar_h, screen_w, screen_h - 2.0 * bar_h), Color(0.95, 0.08, 0.08, 0.07 * siren_f))
	
	# -------------------------------------------------------------------------
	# 3. TACTICAL HAZARD WARNING BANNER (UPPER THIRD)
	# -------------------------------------------------------------------------
	if t_elapsed >= 0.15:
		var ban_t := clampf((t_elapsed - 0.15) / 0.30, 0.0, 1.0)
		var ban_y := bar_h + (24.0 if not is_mob else 16.0)
		var ban_h: float = 34.0 if not is_mob else 28.0
		var max_ban_w := screen_w * 0.88
		var ban_w := max_ban_w * clampf(_ease_out_back(ban_t), 0.0, 1.0)
		var ban_x := (screen_w - ban_w) * 0.5
		var ban_rect := Rect2(ban_x, ban_y, ban_w, ban_h)
		
		# Crimson warning banner fill & border
		draw_rect(ban_rect, Color(0.35, 0.04, 0.04, 0.92))
		draw_rect(ban_rect, Color(1.0, 0.82, 0.20, 0.90), false, 1.5)
		
		# Caution diagonal hazard stripes
		if ban_t >= 0.7:
			var stripe_spacing: float = 24.0
			var stripe_count := int(ban_w / stripe_spacing)
			for s in range(stripe_count):
				var sx := ban_x + float(s) * stripe_spacing
				draw_line(Vector2(sx, ban_y + ban_h), Vector2(sx + 12.0, ban_y), Color(1.0, 0.82, 0.20, 0.22), 1.5)
		
		# Flashing Warning Text
		if ban_t >= 0.6:
			var warn_pulse := fmod(anim_timer * 10.0, 1.0)
			var warn_col := Color(1.0, 0.95, 0.30) if warn_pulse < 0.5 else Color(1.0, 0.25, 0.25)
			var warn_txt := "▲ WARNING : CRITICAL THREAT LEVEL SSS DETECTED ▲"
			var warn_fs: int = 15 if not is_mob else 13
			var warn_w := font.get_string_size(warn_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, warn_fs).x
			_draw_pixel_text(warn_txt, Vector2((screen_w - warn_w) * 0.5, ban_y + (ban_h * 0.5) + 5.0), warn_col, warn_fs)
	
	# -------------------------------------------------------------------------
	# 4. TARGET DOSSIER / BOSS IDENTIFICATION CARD (CENTER)
	# -------------------------------------------------------------------------
	if t_elapsed >= 0.45:
		var card_t := clampf((t_elapsed - 0.45) / 0.35, 0.0, 1.0)
		var card_w: float = minf(screen_w - 32.0, 580.0 if not is_mob else 480.0)
		var card_h: float = 124.0 if not is_mob else 108.0
		var card_cx := screen_w * 0.5
		var card_cy := screen_h * 0.48
		var card_scale := Vector2.ONE * _ease_out_back(card_t)
		
		draw_set_transform(Vector2(card_cx, card_cy), 0.0, card_scale)
		
		var lx := -card_w * 0.5
		var ly := -card_h * 0.5
		var card_rect := Rect2(lx, ly, card_w, card_h)
		
		# Dark glass panel fill
		draw_rect(card_rect, Color(0.03, 0.06, 0.12, 0.90))
		draw_rect(card_rect, Color(0.25, 0.75, 1.0, 0.70), false, 1.2)
		
		# Sci-Fi Corner Brackets
		var bracket_len: float = 16.0
		var bracket_col := Color(0.35, 0.95, 1.0, 0.95)
		# Top-Left
		draw_line(Vector2(lx, ly), Vector2(lx + bracket_len, ly), bracket_col, 2.5)
		draw_line(Vector2(lx, ly), Vector2(lx, ly + bracket_len), bracket_col, 2.5)
		# Top-Right
		draw_line(Vector2(lx + card_w, ly), Vector2(lx + card_w - bracket_len, ly), bracket_col, 2.5)
		draw_line(Vector2(lx + card_w, ly), Vector2(lx + card_w, ly + bracket_len), bracket_col, 2.5)
		# Bottom-Left
		draw_line(Vector2(lx, ly + card_h), Vector2(lx + bracket_len, ly + card_h), bracket_col, 2.5)
		draw_line(Vector2(lx, ly + card_h), Vector2(lx, ly + card_h - bracket_len), bracket_col, 2.5)
		# Bottom-Right
		draw_line(Vector2(lx + card_w, ly + card_h), Vector2(lx + card_w - bracket_len, ly + card_h), bracket_col, 2.5)
		draw_line(Vector2(lx + card_w, ly + card_h), Vector2(lx + card_w, ly + card_h - bracket_len), bracket_col, 2.5)
		
		# Internal horizontal tech grid lines
		for g in range(1, 4):
			var gy := ly + float(g) * (card_h / 4.0)
			draw_line(Vector2(lx + 8.0, gy), Vector2(lx + card_w - 8.0, gy), Color(0.2, 0.5, 0.8, 0.12), 1.0)
		
		# Header Tag: [ APEX HOSTILE TARGET IDENTIFIED ]
		var h_txt := "[ APEX HOSTILE TARGET IDENTIFIED ]"
		var h_w := font.get_string_size(h_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_draw_pixel_text(h_txt, Vector2(-h_w * 0.5, ly + 20.0), Color(0.35, 0.90, 1.0, 0.90), 10)
		
		# Boss Full Name: Golden / Amber title
		var b_name := Global.boss_cutscene_name
		if b_name.is_empty():
			b_name = "RED FALCON DEFENSE WALL"
		var b_size: int = 24 if not is_mob else 20
		var b_w := font.get_string_size(b_name, HORIZONTAL_ALIGNMENT_LEFT, -1, b_size).x
		var name_pulse := 0.90 + 0.10 * sin(anim_timer * 8.0)
		var name_col := Color(1.0 * name_pulse, 0.85 * name_pulse, 0.25)
		_draw_pixel_text(b_name, Vector2(-b_w * 0.5, ly + 54.0), name_col, b_size)
		
		# Sector / Subtitle
		var sub_txt := Global.boss_cutscene_subtitle
		if sub_txt.is_empty():
			sub_txt = "STAGE " + str(Global.current_stage) + " // FORTIFIED DEFENSE CORE"
		var sub_size: int = 12 if not is_mob else 11
		var sub_w := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
		_draw_pixel_text(sub_txt, Vector2(-sub_w * 0.5, ly + 78.0), Color(0.85, 0.88, 0.95), sub_size)
		
		# Specs / Objective
		var spec_txt := "STATUS: CHARGING WEAPONS • VULCAN GATLINGS ONLINE"
		var spec_w := font.get_string_size(spec_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_draw_pixel_text(spec_txt, Vector2(-spec_w * 0.5, ly + 100.0), Color(1.0, 0.40, 0.40), 10)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# -------------------------------------------------------------------------
	# 5. PHASE 3 CLIMAX: "►►► ENGAGE! ◄◄◄" STROBE PROMPT
	# -------------------------------------------------------------------------
	if t_elapsed >= 2.2:
		var engage_t := t_elapsed - 2.2
		var pulse_scale := 1.0 + 0.12 * sin(engage_t * 22.0)
		var engage_txt := "►►► ENGAGE! ◄◄◄"
		var fs: int = 28 if not is_mob else 24
		var engage_pos := Vector2(screen_w * 0.5, screen_h * 0.72)
		var flash_col := Color.WHITE if fmod(anim_timer * 14.0, 1.0) < 0.5 else Color(1.0, 0.25, 0.25)
		_draw_transformed_pixel_text(engage_txt, engage_pos, Vector2.ONE * pulse_scale, flash_col, fs)
