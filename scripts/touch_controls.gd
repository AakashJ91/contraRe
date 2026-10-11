extends Control

# Multi-touch virtual D-Pad and Action buttons for Android & Touchscreens

var dpad_center: Vector2 = Vector2(130.0, 420.0)
var dpad_radius: float = 75.0
var dpad_touch_id: int = -1
var dpad_vector: Vector2 = Vector2.ZERO

var btn_shoot_pos: Vector2 = Vector2(850.0, 430.0)
var btn_shoot_radius: float = 48.0
var btn_shoot_touch_id: int = -1

var btn_jump_pos: Vector2 = Vector2(740.0, 450.0)
var btn_jump_radius: float = 45.0
var btn_jump_touch_id: int = -1

var btn_restart_pos: Vector2 = Vector2(880.0, 40.0)
var btn_restart_radius: float = 24.0

var btn_menu_pos: Vector2 = Vector2(810.0, 40.0)
var btn_menu_radius: float = 24.0

var dpad_active: bool = false
var shoot_active: bool = false
var jump_active: bool = false

var last_actions: Dictionary = {
	"move_left": false,
	"move_right": false,
	"move_up": false,
	"move_down": false
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process_input(true)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)
	# Also allow mouse simulation for desktop testing
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
	
	# D-Pad (left half of screen)
	if pos.x < 480.0 and pos.y > 250.0:
		dpad_touch_id = idx
		dpad_active = true
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
		offset = offset.normalized() * dpad_radius
	dpad_vector = offset / dpad_radius
	
	var deadzone: float = 0.25
	var cur_left: bool = dpad_vector.x < -deadzone
	var cur_right: bool = dpad_vector.x > deadzone
	var cur_up: bool = dpad_vector.y < -deadzone
	var cur_down: bool = dpad_vector.y > deadzone
	
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
	
	# D-Pad Outer Ring & Center
	draw_circle(dpad_center, dpad_radius, Color(0.1, 0.1, 0.15, bg_alpha))
	draw_arc(dpad_center, dpad_radius, 0.0, TAU, 32, Color(0.9, 0.9, 1.0, 0.4), 2.5)
	
	# D-Pad Cross Directions
	var cross_col := Color(0.85, 0.85, 0.95, 0.45)
	var arm_len := 38.0
	var arm_w := 14.0
	draw_rect(Rect2(dpad_center.x - arm_w * 0.5, dpad_center.y - arm_len, arm_w, arm_len * 2.0), cross_col)
	draw_rect(Rect2(dpad_center.x - arm_len, dpad_center.y - arm_w * 0.5, arm_len * 2.0, arm_w), cross_col)
	
	# D-Pad Thumb Nub
	var nub_pos: Vector2 = dpad_center + dpad_vector * (dpad_radius * 0.75)
	var nub_color := Color(0.2, 0.6, 1.0, 0.85) if dpad_active else Color(0.7, 0.7, 0.8, 0.5)
	draw_circle(nub_pos, 22.0, nub_color)
	draw_circle(nub_pos, 8.0, Color(1.0, 1.0, 1.0, 0.8))
	
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
	# 3 Menu bars
	draw_line(btn_menu_pos + Vector2(-7.0, -5.0), btn_menu_pos + Vector2(7.0, -5.0), Color.WHITE, 2.0)
	draw_line(btn_menu_pos + Vector2(-7.0, 0.0), btn_menu_pos + Vector2(7.0, 0.0), Color.WHITE, 2.0)
	draw_line(btn_menu_pos + Vector2(-7.0, 5.0), btn_menu_pos + Vector2(7.0, 5.0), Color.WHITE, 2.0)
