extends Control

# Dynamic Floating Multi-Touch Movement Controller & Action Buttons for Mobile

var default_dpad_center: Vector2 = Vector2(140.0, 410.0)
var dpad_center: Vector2 = default_dpad_center
var current_thumb_pos: Vector2 = default_dpad_center
var dpad_radius: float = 75.0
var dpad_touch_id: int = -1
var dpad_vector: Vector2 = Vector2.ZERO
var dpad_active: bool = false

var btn_shoot_pos: Vector2 = Vector2(850.0, 430.0)
var btn_shoot_radius: float = 48.0
var btn_shoot_touch_id: int = -1
var shoot_active: bool = false

var btn_jump_pos: Vector2 = Vector2(740.0, 450.0)
var btn_jump_radius: float = 45.0
var btn_jump_touch_id: int = -1
var jump_active: bool = false

var btn_map_pos: Vector2 = Vector2(848.0, 14.0)
var btn_map_size: Vector2 = Vector2(34.0, 22.0)

var btn_menu_pos: Vector2 = Vector2(890.0, 14.0)
var btn_menu_size: Vector2 = Vector2(34.0, 22.0)
var btn_menu_radius: float = 18.0

var btn_restart_pos: Vector2 = Vector2(932.0, 14.0)
var btn_restart_size: Vector2 = Vector2(34.0, 22.0)
var btn_restart_radius: float = 18.0

var style_map_btn: StyleBoxFlat
var style_menu_btn: StyleBoxFlat
var style_restart_btn: StyleBoxFlat

var last_actions: Dictionary = {
	"move_left": false,
	"move_right": false,
	"move_up": false,
	"move_down": false
}

var pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process_input(true)
	
	style_map_btn = StyleBoxFlat.new()
	style_map_btn.bg_color = Color(0.04, 0.08, 0.14, 0.60)
	style_map_btn.border_color = Color(0.25, 0.85, 0.55, 0.40)
	style_map_btn.set_border_width_all(1)
	style_map_btn.set_corner_radius_all(6)
	style_map_btn.anti_aliasing = true
	
	style_menu_btn = StyleBoxFlat.new()
	style_menu_btn.bg_color = Color(0.06, 0.09, 0.14, 0.60)
	style_menu_btn.border_color = Color(0.35, 0.65, 0.95, 0.35)
	style_menu_btn.set_border_width_all(1)
	style_menu_btn.set_corner_radius_all(6)
	style_menu_btn.anti_aliasing = true

	style_restart_btn = StyleBoxFlat.new()
	style_restart_btn.bg_color = Color(0.08, 0.07, 0.06, 0.60)
	style_restart_btn.border_color = Color(0.95, 0.70, 0.25, 0.35)
	style_restart_btn.set_border_width_all(1)
	style_restart_btn.set_corner_radius_all(6)
	style_restart_btn.anti_aliasing = true

	queue_redraw()
	if Global.has_signal("maker_mode_toggled"):
		Global.maker_mode_toggled.connect(_on_maker_mode_toggled)

func _on_maker_mode_toggled(maker_active: bool) -> void:
	if maker_active:
		visible = false
		_reset_all_inputs()
	else:
		visible = true
	queue_redraw()

func _reset_all_inputs() -> void:
	dpad_active = false
	dpad_touch_id = -1
	dpad_vector = Vector2.ZERO
	shoot_active = false
	btn_shoot_touch_id = -1
	jump_active = false
	btn_jump_touch_id = -1
	_release_all_dpad_actions()
	Input.action_release("shoot")
	Input.action_release("jump")

func _process(delta: float) -> void:
	if Global.is_maker_mode:
		if visible:
			visible = false
			_reset_all_inputs()
		return
	elif not visible:
		visible = true
	
	pulse_time += delta * 5.0
	# Smoothly return dpad to resting position when released
	if not dpad_active:
		dpad_center = dpad_center.lerp(default_dpad_center, 12.0 * delta)
		current_thumb_pos = current_thumb_pos.lerp(default_dpad_center, 14.0 * delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if Global.is_maker_mode:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)
	# Mouse simulation for PC preview
	elif event is InputEventMouseButton:
		if event.pressed:
			_handle_touch_down(99, event.position)
		else:
			_handle_touch_up(99)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_handle_touch_drag(99, event.position)

func _handle_touch_down(idx: int, pos: Vector2) -> void:
	# Tactical Map, Level Selector & Restart on top-right (aligned with scoreboard)
	if pos.y <= 32.0:
		if pos.x >= 828.0 and pos.x < 868.0:
			Global.play_sfx("menu_cursor")
			Global.toggle_map()
			return
		elif pos.x >= 868.0 and pos.x < 911.0:
			Global.play_sfx("menu_cursor")
			Global.go_to_level_select()
			return
		elif pos.x >= 911.0 and pos.x <= 958.0:
			Global.reset_game()
			get_tree().reload_current_scene()
			return
	
	# Jump Button
	if pos.distance_to(btn_jump_pos) <= btn_jump_radius * 1.3:
		btn_jump_touch_id = idx
		jump_active = true
		Input.action_press("jump")
		queue_redraw()
		return
	
	# Shoot Button
	if pos.distance_to(btn_shoot_pos) <= btn_shoot_radius * 1.3:
		btn_shoot_touch_id = idx
		shoot_active = true
		Input.action_press("shoot")
		queue_redraw()
		return
	
	# DYNAMIC MOVEMENT CONTROLLER: Left half of screen (below top status bar)
	if pos.x < 480.0 and pos.y > 80.0:
		dpad_touch_id = idx
		dpad_active = true
		# Anchor the dynamic joystick origin right under the user's thumb!
		dpad_center = pos
		current_thumb_pos = pos
		dpad_vector = Vector2.ZERO
		_update_dpad(pos)
		queue_redraw()

func _handle_touch_drag(idx: int, pos: Vector2) -> void:
	if idx == dpad_touch_id:
		_update_dpad(pos)
		queue_redraw()

func _handle_touch_up(idx: int) -> void:
	if idx == dpad_touch_id:
		dpad_touch_id = -1
		dpad_active = false
		dpad_vector = Vector2.ZERO
		_release_all_dpad_actions()
		queue_redraw()
	
	if idx == btn_jump_touch_id:
		btn_jump_touch_id = -1
		jump_active = false
		Input.action_release("jump")
		queue_redraw()
	
	if idx == btn_shoot_touch_id:
		btn_shoot_touch_id = -1
		shoot_active = false
		Input.action_release("shoot")
		queue_redraw()

func _update_dpad(pos: Vector2) -> void:
	var offset: Vector2 = pos - dpad_center
	var dist: float = offset.length()
	
	if dist > dpad_radius:
		# Floating origin follow: smoothly pull center if thumb moves beyond radius
		var dir := offset.normalized()
		dpad_center = pos - dir * dpad_radius
		current_thumb_pos = pos
		dpad_vector = dir
	else:
		current_thumb_pos = pos
		dpad_vector = offset / dpad_radius
	
	var deadzone: float = 0.22
	var cur_left: bool = false
	var cur_right: bool = false
	var cur_up: bool = false
	var cur_down: bool = false
	
	# 8-Directional angular sector calculation
	if dpad_vector.length() >= deadzone:
		var angle := dpad_vector.angle() # Range: -PI to +PI
		var step := PI / 8.0 # 22.5 degrees
		
		if angle >= -step and angle < step:
			cur_right = true
		elif angle >= step and angle < 3.0 * step:
			cur_right = true
			cur_down = true
		elif angle >= 3.0 * step and angle < 5.0 * step:
			cur_down = true
		elif angle >= 5.0 * step and angle < 7.0 * step:
			cur_left = true
			cur_down = true
		elif angle >= 7.0 * step or angle < -7.0 * step:
			cur_left = true
		elif angle >= -7.0 * step and angle < -5.0 * step:
			cur_left = true
			cur_up = true
		elif angle >= -5.0 * step and angle < -3.0 * step:
			cur_up = true
		elif angle >= -3.0 * step and angle < -step:
			cur_right = true
			cur_up = true
	
	_set_action_state("move_left", cur_left)
	_set_action_state("move_right", cur_right)
	_set_action_state("move_up", cur_up)
	_set_action_state("move_down", cur_down)

func _set_action_state(action: String, is_active: bool) -> void:
	if last_actions[action] != is_active:
		last_actions[action] = is_active
		if is_active:
			Input.action_press(action)
		else:
			Input.action_release(action)

func _release_all_dpad_actions() -> void:
	for action in last_actions.keys():
		if last_actions[action]:
			last_actions[action] = false
			Input.action_release(action)

func _draw() -> void:
	if Global.is_maker_mode:
		return
	
	var bg_alpha := 0.28
	var fg_alpha := 0.65
	
	# --- DYNAMIC JOYSTICK BASE ---
	var base_ring_col := Color(0.2, 0.7, 1.0, 0.85) if dpad_active else Color(0.8, 0.85, 0.95, 0.35)
	var base_bg_col := Color(0.04, 0.1, 0.2, 0.5) if dpad_active else Color(0.06, 0.08, 0.12, bg_alpha)
	
	# Outer Area Fill & Ring
	draw_circle(dpad_center, dpad_radius, base_bg_col)
	draw_arc(dpad_center, dpad_radius, 0.0, TAU, 36, base_ring_col, 2.5)
	
	# Dynamic Pulse Ring when active
	if dpad_active:
		var pulse_radius := dpad_radius + sin(pulse_time) * 4.0
		draw_arc(dpad_center, pulse_radius, 0.0, TAU, 32, Color(0.3, 0.8, 1.0, 0.35), 1.5)
		# Tether line from center to thumb
		draw_line(dpad_center, current_thumb_pos, Color(0.4, 0.8, 1.0, 0.6), 3.0)
	
	# Center anchor pip
	draw_circle(dpad_center, 6.0, Color(0.4, 0.8, 1.0, 0.5 if dpad_active else 0.25))
	
	# 8-Way Directional Notches & Indicators
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		var dir := Vector2(cos(a), sin(a))
		var notch_start := dpad_center + dir * (dpad_radius - 12.0)
		var notch_end := dpad_center + dir * dpad_radius
		var is_highlighted := false
		
		# Check if this notch is currently active
		if dpad_active and dpad_vector.length() > 0.2:
			var angle_diff: float = absf(fposmod(dir.angle() - dpad_vector.angle() + PI, TAU) - PI)
			if angle_diff < PI / 8.0:
				is_highlighted = true
		
		var notch_col := Color(1.0, 0.85, 0.2, 0.95) if is_highlighted else Color(0.7, 0.8, 0.9, 0.3)
		draw_line(notch_start, notch_end, notch_col, 3.5 if is_highlighted else 2.0)
		if is_highlighted:
			# Directional arrowhead
			var arrow_pt := dpad_center + dir * (dpad_radius + 8.0)
			draw_circle(arrow_pt, 4.0, Color(1.0, 0.85, 0.2))
	
	# --- THUMB KNOB ---
	var knob_radius := 26.0
	var knob_bg := Color(0.1, 0.45, 0.9, 0.9) if dpad_active else Color(0.45, 0.5, 0.6, 0.5)
	draw_circle(current_thumb_pos, knob_radius, Color(0.02, 0.05, 0.1, 0.6))
	draw_circle(current_thumb_pos, knob_radius * 0.85, knob_bg)
	draw_arc(current_thumb_pos, knob_radius * 0.85, 0.0, TAU, 24, Color(0.8, 0.95, 1.0, 0.8), 2.0)
	draw_circle(current_thumb_pos, 8.0, Color.WHITE)
	
	# --- ACTION BUTTONS (RIGHT SIDE) ---
	# Jump Button (A)
	var jump_col := Color(0.1, 0.55, 0.9, 0.9) if jump_active else Color(0.1, 0.4, 0.8, fg_alpha)
	draw_circle(btn_jump_pos, btn_jump_radius, Color(0.05, 0.1, 0.2, bg_alpha))
	draw_circle(btn_jump_pos, btn_jump_radius * 0.85, jump_col)
	draw_arc(btn_jump_pos, btn_jump_radius, 0.0, TAU, 28, Color(0.4, 0.8, 1.0, 0.6), 2.5)
	
	# Jump Label 'A'
	draw_line(btn_jump_pos + Vector2(-8.0, 8.0), btn_jump_pos + Vector2(0.0, -9.0), Color.WHITE, 3.0)
	draw_line(btn_jump_pos + Vector2(8.0, 8.0), btn_jump_pos + Vector2(0.0, -9.0), Color.WHITE, 3.0)
	draw_line(btn_jump_pos + Vector2(-5.0, 0.0), btn_jump_pos + Vector2(5.0, 0.0), Color.WHITE, 3.0)
	
	# Shoot Button (B)
	var shoot_col := Color(0.95, 0.2, 0.15, 0.95) if shoot_active else Color(0.8, 0.2, 0.2, fg_alpha)
	draw_circle(btn_shoot_pos, btn_shoot_radius, Color(0.2, 0.05, 0.05, bg_alpha))
	draw_circle(btn_shoot_pos, btn_shoot_radius * 0.85, shoot_col)
	draw_arc(btn_shoot_pos, btn_shoot_radius, 0.0, TAU, 28, Color(1.0, 0.5, 0.4, 0.6), 2.5)
	
	# Shoot Label 'B'
	draw_line(btn_shoot_pos + Vector2(-7.0, -9.0), btn_shoot_pos + Vector2(-7.0, 9.0), Color.WHITE, 3.0)
	draw_arc(btn_shoot_pos + Vector2(-5.0, -4.5), 5.5, -PI*0.5, PI*0.5, 12, Color.WHITE, 2.5)
	draw_arc(btn_shoot_pos + Vector2(-5.0, 4.5), 5.5, -PI*0.5, PI*0.5, 12, Color.WHITE, 2.5)
	
	# --- SLEEK FLAT TACTICAL MAP BUTTON ---
	var map_rect := Rect2(btn_map_pos.x - btn_map_size.x * 0.5, btn_map_pos.y - btn_map_size.y * 0.5, btn_map_size.x, btn_map_size.y)
	draw_style_box(style_map_btn, map_rect)
	
	# Flat tactical map fold / radar icon
	var map_col := Color(0.40, 0.95, 0.70, 0.95)
	var mx := btn_map_pos.x - 7.0
	var my := btn_map_pos.y - 5.5
	draw_line(Vector2(mx, my), Vector2(mx, my + 11.0), map_col, 1.6)
	draw_line(Vector2(mx, my), Vector2(mx + 4.5, my + 2.0), map_col, 1.4)
	draw_line(Vector2(mx + 4.5, my + 2.0), Vector2(mx + 4.5, my + 13.0), map_col, 1.6)
	draw_line(Vector2(mx + 4.5, my + 2.0), Vector2(mx + 9.5, my), map_col, 1.4)
	draw_line(Vector2(mx + 9.5, my), Vector2(mx + 9.5, my + 11.0), map_col, 1.6)
	draw_line(Vector2(mx + 9.5, my), Vector2(mx + 14.0, my + 2.0), map_col, 1.4)
	draw_line(Vector2(mx + 14.0, my + 2.0), Vector2(mx + 14.0, my + 13.0), map_col, 1.6)
	draw_line(Vector2(mx, my + 11.0), Vector2(mx + 4.5, my + 13.0), map_col, 1.4)
	draw_line(Vector2(mx + 4.5, my + 13.0), Vector2(mx + 9.5, my + 11.0), map_col, 1.4)
	draw_line(Vector2(mx + 9.5, my + 11.0), Vector2(mx + 14.0, my + 13.0), map_col, 1.4)
	
	# --- SLEEK FLAT LEVEL SELECTOR (MENU) BUTTON ---
	var menu_rect := Rect2(btn_menu_pos.x - btn_menu_size.x * 0.5, btn_menu_pos.y - btn_menu_size.y * 0.5, btn_menu_size.x, btn_menu_size.y)
	draw_style_box(style_menu_btn, menu_rect)
	
	# Flat 4-tile stage select icon [::]
	var grid_col := Color(0.92, 0.95, 1.0, 0.90)
	var tile_sz: float = 3.5
	var tile_gap: float = 2.5
	var hg: float = tile_sz + tile_gap * 0.5
	draw_rect(Rect2(btn_menu_pos.x - hg, btn_menu_pos.y - hg, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x + tile_gap * 0.5, btn_menu_pos.y - hg, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x - hg, btn_menu_pos.y + tile_gap * 0.5, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x + tile_gap * 0.5, btn_menu_pos.y + tile_gap * 0.5, tile_sz, tile_sz), grid_col)
	
	# --- SLEEK FLAT RESTART BUTTON ---
	var restart_rect := Rect2(btn_restart_pos.x - btn_restart_size.x * 0.5, btn_restart_pos.y - btn_restart_size.y * 0.5, btn_restart_size.x, btn_restart_size.y)
	draw_style_box(style_restart_btn, restart_rect)
	
	# Flat reload circular arrow
	var restart_col := Color(1.0, 0.92, 0.75, 0.90)
	var r_rad: float = 5.5
	draw_arc(btn_restart_pos, r_rad, 0.5, 5.5, 20, restart_col, 1.8)
	var tip := btn_restart_pos + Vector2(cos(5.5), sin(5.5)) * r_rad
	var dir := Vector2(0.706, 0.708)
	var arrow_pts := PackedVector2Array([
		tip + dir * 3.2,
		tip - dir * 1.5 + Vector2(-dir.y, dir.x) * 2.8,
		tip - dir * 1.5 - Vector2(-dir.y, dir.x) * 2.8
	])
	draw_colored_polygon(arrow_pts, restart_col)

func _is_point_in_btn(point: Vector2, btn_center: Vector2, btn_size: Vector2) -> bool:
	var pad: float = 6.0
	var r := Rect2(btn_center.x - btn_size.x * 0.5 - pad, btn_center.y - btn_size.y * 0.5 - pad, btn_size.x + pad * 2.0, btn_size.y + pad * 2.0)
	return r.has_point(point)
