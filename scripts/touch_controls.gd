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

var btn_restart_pos: Vector2 = Vector2(880.0, 40.0)
var btn_restart_radius: float = 24.0

var btn_menu_pos: Vector2 = Vector2(810.0, 40.0)
var btn_menu_radius: float = 24.0

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
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta * 5.0
	# Smoothly return dpad to resting position when released
	if not dpad_active:
		dpad_center = dpad_center.lerp(default_dpad_center, 12.0 * delta)
		current_thumb_pos = current_thumb_pos.lerp(default_dpad_center, 14.0 * delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
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
	# Menu / Title Button
	if pos.distance_to(btn_menu_pos) <= btn_menu_radius * 1.3:
		Global.play_sfx("menu_cursor")
		Global.go_to_level_select()
		return
	
	# Restart Button
	if pos.distance_to(btn_restart_pos) <= btn_restart_radius * 1.3:
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
	
	# Restart Button
	draw_circle(btn_restart_pos, btn_restart_radius, Color(0.25, 0.2, 0.15, 0.7))
	draw_arc(btn_restart_pos, btn_restart_radius, 0.0, TAU, 18, Color(0.9, 0.7, 0.3, 0.6), 1.5)
	draw_arc(btn_restart_pos, 8.0, 0.5, 5.5, 16, Color.WHITE, 2.0)
	
	# Menu Button
	draw_circle(btn_menu_pos, btn_menu_radius, Color(0.15, 0.2, 0.3, 0.7))
	draw_arc(btn_menu_pos, btn_menu_radius, 0.0, TAU, 18, Color(0.3, 0.7, 1.0, 0.6), 1.5)
	draw_line(btn_menu_pos + Vector2(-7.0, -5.0), btn_menu_pos + Vector2(7.0, -5.0), Color.WHITE, 2.0)
	draw_line(btn_menu_pos + Vector2(-7.0, 0.0), btn_menu_pos + Vector2(7.0, 0.0), Color.WHITE, 2.0)
	draw_line(btn_menu_pos + Vector2(-7.0, 5.0), btn_menu_pos + Vector2(7.0, 5.0), Color.WHITE, 2.0)
