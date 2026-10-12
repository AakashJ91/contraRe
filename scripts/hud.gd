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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Global.score_changed.connect(_on_score_changed)
	Global.lives_changed.connect(_on_lives_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	Global.boss_health_changed.connect(_on_boss_health_changed)
	Global.boss_defeated.connect(_on_boss_defeated)
	_update_hud()
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
	var w: float = maxf(960.0, get_viewport_rect().size.x)
	var strip_h: float = 38.0
	
	# =========================================================================
	# 1. CLASSIC 16-BIT ARCADE CARBON CHASSIS
	# =========================================================================
	# Base dark carbon chassis with subtle arcade scanlines
	draw_rect(Rect2(0.0, 0.0, w, strip_h), Color(0.07, 0.08, 0.11, 0.96))
	for y in range(0, int(strip_h), 2):
		draw_line(Vector2(0.0, float(y)), Vector2(w, float(y)), Color(0.05, 0.06, 0.08, 0.5), 1.0)
	
	# Top metallic chamfer highlight line
	draw_line(Vector2(0.0, 0.0), Vector2(w, 0.0), Color(0.40, 0.50, 0.62, 0.90), 1.0)
	draw_line(Vector2(0.0, 1.0), Vector2(w, 1.0), Color(0.20, 0.26, 0.34, 0.50), 1.0)
	
	# Bottom chassis border: dark groove + classic arcade crimson pinstripe
	draw_line(Vector2(0.0, strip_h - 2.0), Vector2(w, strip_h - 2.0), Color(0.08, 0.10, 0.14), 1.0)
	draw_line(Vector2(0.0, strip_h - 1.0), Vector2(w, strip_h - 1.0), Color(0.88, 0.18, 0.20, 0.95), 1.5)
	# Soft ambient shadow onto game layer
	draw_rect(Rect2(0.0, strip_h + 1.0, w, 3.0), Color(0.0, 0.0, 0.0, 0.40))
	
	# =========================================================================
	# 2. SEGMENTED ARCADE BEZEL MODULES
	# =========================================================================
	var panel_h := 28.0
	var panel_y := 5.0
	
	# --- MODULE 1: PLAYER 1 SCORE ---
	var p1_rect := Rect2(10.0, panel_y, 175.0, panel_h)
	_draw_arcade_panel(p1_rect, Color(1.0, 0.84, 0.0))
	_draw_pixel_text("1P", Vector2(p1_rect.position.x + 8.0, panel_y + 19.0), Color(1.0, 0.84, 0.0), 13)
	var score_str := "%06d" % score
	_draw_pixel_text(score_str, Vector2(p1_rect.position.x + 40.0, panel_y + 20.0), Color(1.0, 1.0, 1.0), 16)
	
	# --- MODULE 2: HIGH SCORE ---
	var p2_rect := Rect2(195.0, panel_y, 165.0, panel_h)
	_draw_arcade_panel(p2_rect, Color(0.95, 0.22, 0.22))
	_draw_pixel_text("HI", Vector2(p2_rect.position.x + 8.0, panel_y + 19.0), Color(0.95, 0.22, 0.22), 13)
	var hi_str := "%06d" % high_score
	_draw_pixel_text(hi_str, Vector2(p2_rect.position.x + 38.0, panel_y + 20.0), Color(1.0, 1.0, 1.0), 16)
	
	# --- MODULE 3: STAGE MISSION ---
	var p3_rect := Rect2(370.0, panel_y, 175.0, panel_h)
	_draw_arcade_panel(p3_rect, Color(0.25, 0.85, 1.0))
	var stage_tag := "STAGE " + str(Global.current_stage)
	_draw_pixel_text(stage_tag, Vector2(p3_rect.position.x + 8.0, panel_y + 19.0), Color(0.25, 0.85, 1.0), 12)
	# Pulsing radar beacon dot
	var radar_alpha := 0.6 + 0.4 * sin(anim_timer * 6.0)
	draw_circle(Vector2(p3_rect.position.x + 86.0, panel_y + 14.0), 3.0, Color(0.2, 1.0, 0.4, radar_alpha))
	var stage_name := "JUNGLE"
	if Global.current_stage == 2:
		stage_name = "WATERFALL"
	elif Global.current_stage == 3:
		stage_name = "HIVE"
	_draw_pixel_text(stage_name, Vector2(p3_rect.position.x + 96.0, panel_y + 19.0), Color(0.90, 0.95, 1.0), 11)
	
	# --- MODULE 4: COMMANDO LIVES (REST) ---
	var p4_rect := Rect2(555.0, panel_y, 175.0, panel_h)
	_draw_arcade_panel(p4_rect, Color(0.35, 0.95, 0.45))
	_draw_pixel_text("REST", Vector2(p4_rect.position.x + 8.0, panel_y + 19.0), Color(0.35, 0.95, 0.45), 12)
	# Mini Pixel-Art Commando Badges
	var shown_lives := mini(lives, 3)
	for i in range(shown_lives):
		var lx: float = p4_rect.position.x + 56.0 + float(i) * 19.0
		# Torso & Blue Tank Top
		draw_rect(Rect2(lx, panel_y + 11.0, 9.0, 11.0), Color(0.15, 0.35, 0.85))
		# Commando Face / Skin tone
		draw_circle(Vector2(lx + 4.5, panel_y + 9.0), 3.5, Color(0.96, 0.76, 0.60))
		# Red Bandana Headband
		draw_rect(Rect2(lx + 1.0, panel_y + 6.0, 7.0, 3.0), Color(0.95, 0.15, 0.15))
		# Bandana Knot Trailing
		draw_line(Vector2(lx + 7.0, panel_y + 7.0), Vector2(lx + 10.0, panel_y + 10.0), Color(0.95, 0.15, 0.15), 1.5)
	var lives_str := "x" + str(lives)
	_draw_pixel_text(lives_str, Vector2(p4_rect.position.x + 122.0, panel_y + 19.0), Color(1.0, 0.85, 0.20), 14)
	
	# --- MODULE 5: ARSENAL WEAPON ---
	var p5_rect := Rect2(740.0, panel_y, 210.0, panel_h)
	_draw_arcade_panel(p5_rect, weapon_color)
	_draw_pixel_text("GUN", Vector2(p5_rect.position.x + 8.0, panel_y + 19.0), Color(0.70, 0.80, 0.90), 11)
	
	# Circular Arcade Power-Up Coin Badge
	var emb_x := p5_rect.position.x + 48.0
	var emb_y := panel_y + 14.0
	# Outer red arcade bezel
	draw_circle(Vector2(emb_x, emb_y), 9.0, Color(0.85, 0.15, 0.15, 0.95))
	draw_arc(Vector2(emb_x, emb_y), 9.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.20), 1.2)
	# Weapon Initial inside coin
	_draw_pixel_text(weapon_letter, Vector2(emb_x - 4.5, emb_y + 4.5), Color(1.0, 1.0, 1.0), 12)
	
	# Weapon Name in neon arcade accent
	_draw_pixel_text(weapon_name, Vector2(p5_rect.position.x + 66.0, panel_y + 20.0), weapon_color, 12)
	
	# =========================================================================
	# 3. BOSS CORE HEALTH BAR
	# =========================================================================
	if show_boss_bar and boss_health > 0.0:
		var bar_w := 280.0
		var bar_x := (w - bar_w) * 0.5
		var bar_y := 46.0
		var bar_h := 12.0
		
		# Steel bezel casing
		draw_rect(Rect2(bar_x - 3.0, bar_y - 2.0, bar_w + 6.0, bar_h + 4.0), Color(0.08, 0.10, 0.13, 0.95))
		draw_rect(Rect2(bar_x - 3.0, bar_y - 2.0, bar_w + 6.0, bar_h + 4.0), Color(0.85, 0.20, 0.20, 0.85), false, 1.0)
		# Track background
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.12, 0.05, 0.05, 0.95))
		
		# Pulsing health fill
		var pct := clampf(boss_health / boss_max_health, 0.0, 1.0)
		var fill_w := bar_w * pct
		if fill_w > 0.0:
			var pulse := 0.85 + 0.15 * sin(anim_timer * 8.0)
			draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), Color(0.95 * pulse, 0.18, 0.18))
			draw_line(Vector2(bar_x, bar_y + 1.0), Vector2(bar_x + fill_w, bar_y + 1.0), Color(1.0, 0.6, 0.6, 0.6), 1.0)
		
		_draw_pixel_text("BOSS CORE", Vector2(bar_x - 82.0, bar_y + 10.0), Color(1.0, 0.30, 0.30), 11)
	
	# =========================================================================
	# 4. GAME OVER & VICTORY OVERLAYS
	# =========================================================================
	if Global.is_game_over:
		draw_rect(Rect2(0.0, 160.0, w, 160.0), Color(0.02, 0.02, 0.04, 0.92))
		draw_line(Vector2(0.0, 160.0), Vector2(w, 160.0), Color(0.95, 0.20, 0.20, 0.9), 2.0)
		draw_line(Vector2(0.0, 320.0), Vector2(w, 320.0), Color(0.95, 0.20, 0.20, 0.9), 2.0)
		_draw_pixel_text("GAME OVER", Vector2(w * 0.5 - 110.0, 230.0), Color(1.0, 0.25, 0.25), 32)
		_draw_pixel_text("PRESS RESTART OR TAP SCREEN TO RETRY", Vector2(w * 0.5 - 190.0, 275.0), Color(1.0, 0.90, 0.30), 16)
	elif victory_displayed:
		draw_rect(Rect2(0.0, 150.0, w, 190.0), Color(0.02, 0.04, 0.08, 0.94))
		draw_line(Vector2(0.0, 150.0), Vector2(w, 150.0), Color(0.20, 0.95, 0.40, 0.9), 2.0)
		draw_line(Vector2(0.0, 340.0), Vector2(w, 340.0), Color(0.20, 0.95, 0.40, 0.9), 2.0)
		_draw_pixel_text("STAGE " + str(Global.current_stage) + " CLEAR!", Vector2(w * 0.5 - 130.0, 210.0), Color(0.25, 1.0, 0.45), 32)
		_draw_pixel_text("EXCELLENT WORK, COMMANDO!", Vector2(w * 0.5 - 145.0, 250.0), Color(1.0, 1.0, 1.0), 18)
		_draw_pixel_text("STAGE SCORE: " + str(score), Vector2(w * 0.5 - 85.0, 285.0), Color(1.0, 0.85, 0.20), 16)
		_draw_pixel_text("[ TAP MENU BUTTON TO RETURN TO LEVEL SELECT ]", Vector2(w * 0.5 - 180.0, 320.0), Color(0.30, 0.85, 1.0), 14)

func _draw_arcade_panel(rect: Rect2, accent_col: Color) -> void:
	# 1. Recessed dark matte panel background
	draw_rect(rect, Color(0.04, 0.05, 0.08, 0.90))
	
	# 2. Outer 1px chassis border
	draw_rect(rect, Color(0.22, 0.28, 0.36), false, 1.0)
	
	# 3. 16-bit arcade corner brackets (L-shaped pixel brackets on all 4 corners)
	var blen: float = 4.0
	var rx: float = rect.position.x
	var ry: float = rect.position.y
	var rw: float = rect.size.x
	var rh: float = rect.size.y
	
	# Top-left bracket
	draw_line(Vector2(rx, ry), Vector2(rx + blen, ry), accent_col, 2.0)
	draw_line(Vector2(rx, ry), Vector2(rx, ry + blen), accent_col, 2.0)
	# Top-right bracket
	draw_line(Vector2(rx + rw - blen, ry), Vector2(rx + rw, ry), accent_col, 2.0)
	draw_line(Vector2(rx + rw, ry), Vector2(rx + rw, ry + blen), accent_col, 2.0)
	# Bottom-left bracket
	draw_line(Vector2(rx, ry + rh), Vector2(rx + blen, ry + rh), accent_col, 2.0)
	draw_line(Vector2(rx, ry + rh - blen), Vector2(rx, ry + rh), accent_col, 2.0)
	# Bottom-right bracket
	draw_line(Vector2(rx + rw - blen, ry + rh), Vector2(rx + rw, ry + rh), accent_col, 2.0)
	draw_line(Vector2(rx + rw, ry + rh - blen), Vector2(rx + rw, ry + rh), accent_col, 2.0)
	
	# 4. Subtle top interior bevel
	draw_line(Vector2(rx + blen, ry + 1.0), Vector2(rx + rw - blen, ry + 1.0), Color(1.0, 1.0, 1.0, 0.12), 1.0)

func _draw_pixel_text(text: String, pos: Vector2, col: Color, font_size: int = 14) -> void:
	var font := ThemeDB.fallback_font
	# Heavy dark shadow for crisp arcade contrast
	draw_string(font, pos + Vector2(1.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.95))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
