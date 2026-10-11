extends Control


var score: int = 0
var high_score: int = 20000
var lives: int = 3
var weapon_name: String = "RIFLE"
var boss_health: float = 0.0
var boss_max_health: float = 35.0
var show_boss_bar: bool = false
var victory_displayed: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Global.score_changed.connect(_on_score_changed)
	Global.lives_changed.connect(_on_lives_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	Global.boss_health_changed.connect(_on_boss_health_changed)
	Global.boss_defeated.connect(_on_boss_defeated)
	_update_hud()
	queue_redraw()

func _process(_delta: float) -> void:
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
			weapon_name = "RIFLE"
		Global.WeaponType.SPREAD:
			weapon_name = "SPREAD (S)"
		Global.WeaponType.MACHINE:
			weapon_name = "MACHINE (M)"
		Global.WeaponType.LASER:
			weapon_name = "LASER (L)"
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
	# Top arcade header bar
	draw_rect(Rect2(0.0, 0.0, 960.0, 36.0), Color(0.06, 0.08, 0.12, 0.85))
	draw_line(Vector2(0.0, 36.0), Vector2(960.0, 36.0), Color(0.2, 0.5, 0.8, 0.6), 2.0)
	
	# Score display
	var score_str := "%06d" % score
	var hi_str := "%06d" % high_score
	
	_draw_text("1P  " + score_str, Vector2(25.0, 24.0), Color(1.0, 0.9, 0.2))
	_draw_text("HI  " + hi_str, Vector2(220.0, 24.0), Color(0.9, 0.3, 0.3))
	
	# Lives remaining
	_draw_text("REST", Vector2(400.0, 24.0), Color(0.8, 0.8, 0.9))
	for i in range(maxi(0, lives)):
		var lx: float = 460.0 + float(i) * 18.0
		# Little commando badge icon
		draw_rect(Rect2(lx, 12.0, 10.0, 14.0), Color(0.15, 0.35, 0.85))
		draw_circle(Vector2(lx + 5.0, 8.0), 4.0, Color(0.96, 0.76, 0.60))
		draw_rect(Rect2(lx + 1.0, 5.0, 8.0, 3.0), Color(0.9, 0.15, 0.15))
	
	# Current Weapon
	_draw_text("GUN: " + weapon_name, Vector2(560.0, 24.0), Color(0.2, 0.9, 0.5))
	
	# Boss health bar
	if show_boss_bar and boss_health > 0.0:
		var bar_w := 260.0
		var bar_x := 350.0
		var bar_y := 48.0
		draw_rect(Rect2(bar_x - 2.0, bar_y - 2.0, bar_w + 4.0, 14.0), Color(0.1, 0.1, 0.15, 0.9))
		var pct := clampf(boss_health / boss_max_health, 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w * pct, 10.0), Color(0.95, 0.2, 0.2))
		_draw_text("CORE", Vector2(bar_x - 60.0, bar_y + 9.0), Color(1.0, 0.3, 0.3), 12)
	
	# Victory / Game Over Overlay
	if Global.is_game_over:
		draw_rect(Rect2(0.0, 160.0, 960.0, 160.0), Color(0.0, 0.0, 0.0, 0.85))
		_draw_text("GAME OVER", Vector2(380.0, 230.0), Color(1.0, 0.2, 0.2), 32)
		_draw_text("PRESS RESTART OR TAP SCREEN TO RETRY", Vector2(280.0, 275.0), Color(1.0, 0.9, 0.3), 18)
	elif victory_displayed:
		draw_rect(Rect2(0.0, 160.0, 960.0, 160.0), Color(0.0, 0.0, 0.0, 0.85))
		_draw_text("STAGE 1 CLEAR!", Vector2(350.0, 220.0), Color(0.2, 1.0, 0.4), 32)
		_draw_text("EXCELLENT WORK, COMMANDO!", Vector2(330.0, 260.0), Color(1.0, 1.0, 1.0), 20)
		_draw_text("STAGE SCORE: " + str(score), Vector2(390.0, 295.0), Color(1.0, 0.85, 0.2), 18)

func _draw_text(text: String, pos: Vector2, col: Color, font_size: int = 14) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
