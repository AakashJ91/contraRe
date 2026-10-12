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
	var strip_h: float = 44.0
	
	# =========================================================================
	# 1. LUXURY GLOSSY GLASS STRIP BACKDROP
	# =========================================================================
	# Base dark obsidian glass fill
	draw_rect(Rect2(0.0, 0.0, w, strip_h), Color(0.04, 0.06, 0.11, 0.92))
	# Subtle cobalt gradient layers
	draw_rect(Rect2(0.0, 0.0, w, strip_h * 0.5), Color(0.08, 0.14, 0.24, 0.22))
	draw_rect(Rect2(0.0, strip_h * 0.5, w, strip_h * 0.5), Color(0.02, 0.03, 0.05, 0.35))
	
	# Signature glossy highlight reflection (curved acrylic sheen)
	var sheen_h := strip_h * 0.48
	draw_rect(Rect2(0.0, 0.0, w, sheen_h), Color(1.0, 1.0, 1.0, 0.12))
	draw_rect(Rect2(0.0, 0.0, w, sheen_h * 0.5), Color(1.0, 1.0, 1.0, 0.06))
	draw_rect(Rect2(0.0, 0.0, w, sheen_h * 0.2), Color(1.0, 1.0, 1.0, 0.08))
	
	# Top specular bevel edge line (gleaming glass rim)
	draw_line(Vector2(0.0, 0.0), Vector2(w, 0.0), Color(0.85, 0.95, 1.0, 0.70), 1.0)
	draw_line(Vector2(0.0, 1.0), Vector2(w, 1.0), Color(0.35, 0.70, 0.95, 0.35), 1.0)
	
	# Animated light shimmer sweep across the strip
	var shimmer_cycle: float = fmod(anim_timer * 0.35, 1.0)
	if shimmer_cycle < 0.32:
		var shim_x: float = (shimmer_cycle / 0.32) * (w + 200.0) - 100.0
		draw_line(Vector2(shim_x, 0.0), Vector2(shim_x + 50.0, strip_h), Color(1.0, 1.0, 1.0, 0.05), 24.0)
		draw_line(Vector2(shim_x + 8.0, 0.0), Vector2(shim_x + 42.0, strip_h), Color(1.0, 1.0, 1.0, 0.08), 8.0)
	
	# Bottom high-tech cyber rim
	draw_line(Vector2(0.0, strip_h - 1.0), Vector2(w, strip_h - 1.0), Color(0.20, 0.70, 1.0, 0.85), 1.5)
	draw_line(Vector2(0.0, strip_h + 0.5), Vector2(w, strip_h + 0.5), Color(0.05, 0.30, 0.65, 0.40), 1.5)
	# Soft ambient shadow beneath the glass strip
	draw_rect(Rect2(0.0, strip_h + 2.0, w, 4.0), Color(0.0, 0.0, 0.0, 0.35))
	
	# =========================================================================
	# 2. SEGMENTED GLASS PODS WITH USER DETAILS
	# =========================================================================
	var pod_h := 32.0
	var pod_y := 6.0
	
	# --- POD 1: PLAYER 1 SCORE ---
	var p1_rect := Rect2(10.0, pod_y, 175.0, pod_h)
	_draw_glass_pod(p1_rect, Color(0.35, 0.50, 0.75, 0.55), Color(1.0, 0.82, 0.20))
	_draw_text_shadow("1P", Vector2(p1_rect.position.x + 10.0, pod_y + 21.0), Color(1.0, 0.82, 0.20), 12)
	var score_str := "%06d" % score
	_draw_text_shadow(score_str, Vector2(p1_rect.position.x + 44.0, pod_y + 22.0), Color(1.0, 0.98, 0.90), 16)
	
	# --- POD 2: HIGH SCORE ---
	var p2_rect := Rect2(195.0, pod_y, 165.0, pod_h)
	_draw_glass_pod(p2_rect, Color(0.55, 0.30, 0.40, 0.55), Color(0.95, 0.25, 0.35))
	_draw_text_shadow("HI", Vector2(p2_rect.position.x + 10.0, pod_y + 21.0), Color(0.95, 0.25, 0.35), 12)
	var hi_str := "%06d" % high_score
	_draw_text_shadow(hi_str, Vector2(p2_rect.position.x + 40.0, pod_y + 22.0), Color(0.96, 0.92, 0.96), 16)
	
	# --- POD 3: MISSION / STAGE INDICATOR ---
	var p3_rect := Rect2(370.0, pod_y, 175.0, pod_h)
	_draw_glass_pod(p3_rect, Color(0.25, 0.55, 0.80, 0.55), Color(0.20, 0.85, 1.0))
	var stage_tag := "STAGE " + str(Global.current_stage)
	_draw_text_shadow(stage_tag, Vector2(p3_rect.position.x + 10.0, pod_y + 21.0), Color(0.20, 0.85, 1.0), 12)
	# Pulsing radar beacon dot
	var radar_alpha := 0.6 + 0.4 * sin(anim_timer * 5.0)
	draw_circle(Vector2(p3_rect.position.x + 88.0, pod_y + 16.0), 3.5, Color(0.2, 1.0, 0.4, radar_alpha))
	var stage_name := "JUNGLE"
	if Global.current_stage == 2:
		stage_name = "WATERFALL"
	elif Global.current_stage == 3:
		stage_name = "HIVE"
	_draw_text_shadow(stage_name, Vector2(p3_rect.position.x + 98.0, pod_y + 21.0), Color(0.85, 0.92, 1.0), 11)
	
	# --- POD 4: COMMANDO LIVES (REST) ---
	var p4_rect := Rect2(555.0, pod_y, 175.0, pod_h)
	_draw_glass_pod(p4_rect, Color(0.30, 0.60, 0.45, 0.55), Color(0.35, 0.90, 0.55))
	_draw_text_shadow("REST", Vector2(p4_rect.position.x + 10.0, pod_y + 21.0), Color(0.35, 0.90, 0.55), 12)
	# Mini Commando Soldier Badges
	var shown_lives := mini(lives, 3)
	for i in range(shown_lives):
		var lx: float = p4_rect.position.x + 58.0 + float(i) * 20.0
		# Torso & Blue Uniform
		draw_rect(Rect2(lx, pod_y + 13.0, 10.0, 12.0), Color(0.18, 0.40, 0.85))
		# Soldier Face / Skin tone
		draw_circle(Vector2(lx + 5.0, pod_y + 10.0), 4.0, Color(0.96, 0.78, 0.62))
		# Red Bandana Headband
		draw_rect(Rect2(lx + 1.0, pod_y + 7.0, 8.0, 3.0), Color(0.95, 0.15, 0.15))
		# Trailing Bandana Knot
		draw_line(Vector2(lx + 8.0, pod_y + 8.0), Vector2(lx + 11.0, pod_y + 11.0), Color(0.95, 0.15, 0.15), 1.5)
	var lives_count_str := "x" + str(lives)
	_draw_text_shadow(lives_count_str, Vector2(p4_rect.position.x + 124.0, pod_y + 22.0), Color(1.0, 0.85, 0.30), 14)
	
	# --- POD 5: TACTICAL ARSENAL (WEAPON) ---
	var p5_rect := Rect2(740.0, pod_y, 210.0, pod_h)
	_draw_glass_pod(p5_rect, Color(weapon_color.r * 0.6, weapon_color.g * 0.6, weapon_color.b * 0.6, 0.65), weapon_color)
	_draw_text_shadow("GUN", Vector2(p5_rect.position.x + 10.0, pod_y + 21.0), Color(0.70, 0.80, 0.90), 11)
	
	# Glowing circular weapon emblem badge [S], [M], [L], [R]
	var emb_x := p5_rect.position.x + 50.0
	var emb_y := pod_y + 16.0
	draw_circle(Vector2(emb_x, emb_y), 9.5, Color(weapon_color.r * 0.25, weapon_color.g * 0.25, weapon_color.b * 0.25, 0.9))
	draw_arc(Vector2(emb_x, emb_y), 9.5, 0.0, TAU, 24, weapon_color, 1.5)
	# Weapon letter inside emblem
	_draw_text_shadow(weapon_letter, Vector2(emb_x - 4.5, emb_y + 4.5), weapon_color, 13)
	
	# Weapon display title
	_draw_text_shadow(weapon_name, Vector2(p5_rect.position.x + 68.0, pod_y + 22.0), weapon_color, 12)
	
	# =========================================================================
	# 3. BOSS HEALTH BAR (GLOSSY TACTICAL HUD CASING)
	# =========================================================================
	if show_boss_bar and boss_health > 0.0:
		var bar_w := 280.0
		var bar_x := (w - bar_w) * 0.5
		var bar_y := 52.0
		var bar_h := 14.0
		
		# Glass container backing
		draw_rect(Rect2(bar_x - 3.0, bar_y - 3.0, bar_w + 6.0, bar_h + 6.0), Color(0.06, 0.08, 0.12, 0.88))
		draw_rect(Rect2(bar_x - 3.0, bar_y - 3.0, bar_w + 6.0, bar_h + 6.0), Color(0.85, 0.25, 0.25, 0.75), false, 1.0)
		# Track background
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.12, 0.08, 0.08, 0.95))
		
		# Health fill with pulse
		var pct := clampf(boss_health / boss_max_health, 0.0, 1.0)
		var fill_w := bar_w * pct
		if fill_w > 0.0:
			var pulse := 0.85 + 0.15 * sin(anim_timer * 8.0)
			draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), Color(0.95 * pulse, 0.18, 0.18))
			# Glossy top reflection on health bar
			draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h * 0.5), Color(1.0, 1.0, 1.0, 0.22))
		
		_draw_text_shadow("BOSS CORE", Vector2(bar_x - 82.0, bar_y + 11.0), Color(1.0, 0.35, 0.35), 11)
	
	# =========================================================================
	# 4. GAME OVER & VICTORY OVERLAYS
	# =========================================================================
	if Global.is_game_over:
		draw_rect(Rect2(0.0, 160.0, w, 160.0), Color(0.02, 0.02, 0.04, 0.90))
		draw_line(Vector2(0.0, 160.0), Vector2(w, 160.0), Color(0.95, 0.2, 0.2, 0.8), 2.0)
		draw_line(Vector2(0.0, 320.0), Vector2(w, 320.0), Color(0.95, 0.2, 0.2, 0.8), 2.0)
		_draw_text_shadow("GAME OVER", Vector2(w * 0.5 - 110.0, 230.0), Color(1.0, 0.25, 0.25), 32)
		_draw_text_shadow("PRESS RESTART OR TAP SCREEN TO RETRY", Vector2(w * 0.5 - 190.0, 275.0), Color(1.0, 0.90, 0.30), 16)
	elif victory_displayed:
		draw_rect(Rect2(0.0, 150.0, w, 190.0), Color(0.02, 0.04, 0.08, 0.92))
		draw_line(Vector2(0.0, 150.0), Vector2(w, 150.0), Color(0.20, 0.95, 0.40, 0.85), 2.0)
		draw_line(Vector2(0.0, 340.0), Vector2(w, 340.0), Color(0.20, 0.95, 0.40, 0.85), 2.0)
		_draw_text_shadow("STAGE " + str(Global.current_stage) + " CLEAR!", Vector2(w * 0.5 - 130.0, 210.0), Color(0.25, 1.0, 0.45), 32)
		_draw_text_shadow("EXCELLENT WORK, COMMANDO!", Vector2(w * 0.5 - 145.0, 250.0), Color(1.0, 1.0, 1.0), 18)
		_draw_text_shadow("STAGE SCORE: " + str(score), Vector2(w * 0.5 - 85.0, 285.0), Color(1.0, 0.85, 0.20), 16)
		_draw_text_shadow("[ TAP MENU BUTTON TO RETURN TO LEVEL SELECT ]", Vector2(w * 0.5 - 180.0, 320.0), Color(0.30, 0.85, 1.0), 14)

func _draw_glass_pod(rect: Rect2, border_col: Color, accent_col: Color) -> void:
	# 1. Dark translucent glass pod body
	draw_rect(rect, Color(0.08, 0.12, 0.18, 0.70))
	
	# 2. Specular Top Sheen inside the pod (gloss effect)
	var sheen_h := rect.size.y * 0.48
	draw_rect(Rect2(rect.position.x + 1.0, rect.position.y + 1.0, rect.size.x - 2.0, sheen_h), Color(1.0, 1.0, 1.0, 0.08))
	draw_rect(Rect2(rect.position.x + 1.0, rect.position.y + 1.0, rect.size.x - 2.0, sheen_h * 0.4), Color(1.0, 1.0, 1.0, 0.05))
	
	# 3. Fine high-tech glass frame (1px outline)
	draw_rect(rect, border_col, false, 1.0)
	
	# 4. Top inner glass glint line
	draw_line(Vector2(rect.position.x + 2.0, rect.position.y + 1.0), Vector2(rect.end.x - 2.0, rect.position.y + 1.0), Color(1.0, 1.0, 1.0, 0.25), 1.0)
	
	# 5. Left tactical accent stripe
	draw_line(Vector2(rect.position.x + 3.0, rect.position.y + 5.0), Vector2(rect.position.x + 3.0, rect.end.y - 5.0), accent_col, 2.5)

func _draw_text_shadow(text: String, pos: Vector2, col: Color, font_size: int = 14) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(1.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
