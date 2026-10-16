extends Control

# Dynamic Floating Multi-Touch Movement Controller & Action Buttons for Mobile

var default_dpad_center: Vector2 = Vector2(140.0, 410.0)
var dpad_center: Vector2 = default_dpad_center
var current_thumb_pos: Vector2 = default_dpad_center
var dpad_radius: float = 75.0
var dpad_touch_id: int = -1
var dpad_vector: Vector2 = Vector2.ZERO
var dpad_active: bool = false

# Large, highly responsive Shoot Button (Fire / B)
var btn_shoot_pos: Vector2 = Vector2(850.0, 415.0)
var btn_shoot_radius: float = 68.0
var btn_shoot_touch_id: int = -1
var shoot_active: bool = false

# Jump Button (A) & Universal Right-Side Jump Zone
var btn_jump_pos: Vector2 = Vector2(715.0, 435.0)
var btn_jump_radius: float = 60.0
var jump_touch_ids: Array[int] = []
var jump_active: bool = false
var last_jump_tap_pos: Vector2 = Vector2.ZERO
var jump_tap_anim: float = 0.0
@export var show_jump_button: bool = true

var btn_menu_pos: Vector2 = Vector2(890.0, 14.0)
var btn_menu_size: Vector2 = Vector2(34.0, 22.0)
var btn_menu_radius: float = 18.0

var btn_restart_pos: Vector2 = Vector2(932.0, 14.0)
var btn_restart_size: Vector2 = Vector2(34.0, 22.0)
var btn_restart_radius: float = 18.0

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
	
	show_jump_button = true
	if Global.is_mobile_device():
		dpad_radius = 85.0
		btn_shoot_radius = 68.0
		btn_jump_radius = 60.0
		default_dpad_center = Vector2(145.0, 405.0)
		dpad_center = default_dpad_center
		current_thumb_pos = default_dpad_center
		btn_menu_size = Vector2(44.0, 30.0)
		btn_menu_radius = 22.0
		btn_restart_size = Vector2(44.0, 30.0)
		btn_restart_radius = 22.0
	
	style_menu_btn = StyleBoxFlat.new()
	style_menu_btn.bg_color = Color(0.06, 0.12, 0.22, 0.38)
	style_menu_btn.border_color = Color(0.45, 0.80, 1.0, 0.40)
	style_menu_btn.set_border_width_all(1)
	style_menu_btn.set_corner_radius_all(8)
	style_menu_btn.anti_aliasing = true

	style_restart_btn = StyleBoxFlat.new()
	style_restart_btn.bg_color = Color(0.18, 0.12, 0.06, 0.38)
	style_restart_btn.border_color = Color(1.0, 0.75, 0.35, 0.40)
	style_restart_btn.set_border_width_all(1)
	style_restart_btn.set_corner_radius_all(8)
	style_restart_btn.anti_aliasing = true

	_update_layout_positions()
	queue_redraw()
	if Global.has_signal("maker_mode_toggled"):
		Global.maker_mode_toggled.connect(_on_maker_mode_toggled)

func _get_screen_w() -> float:
	return maxf(960.0, get_viewport_rect().size.x)

func _update_layout_positions() -> void:
	var w := _get_screen_w()
	if Global.is_mobile_device():
		btn_shoot_pos = Vector2(w - 110.0, 415.0)
		btn_jump_pos = Vector2(w - 245.0, 435.0)
		btn_menu_pos = Vector2(w - 82.0, 18.0)
		btn_restart_pos = Vector2(w - 28.0, 18.0)
	else:
		btn_shoot_pos = Vector2(w - 110.0, 415.0)
		btn_jump_pos = Vector2(w - 245.0, 435.0)
		btn_menu_pos = Vector2(w - 70.0, 14.0)
		btn_restart_pos = Vector2(w - 28.0, 14.0)

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
	jump_touch_ids.clear()
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
	if jump_tap_anim > 0.0:
		jump_tap_anim = maxf(0.0, jump_tap_anim - delta)

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
	_update_layout_positions()
	var w := _get_screen_w()
	var half_w := w * 0.5

	# Level Selector & Restart on top-right (aligned with scoreboard)
	var top_touch_h: float = 46.0 if Global.is_mobile_device() else 36.0
	if pos.y <= top_touch_h:
		if pos.x >= w - 110.0 and pos.x < w - 55.0:
			Global.play_sfx("menu_cursor")
			Global.go_to_level_select()
			return
		elif pos.x >= w - 55.0:
			Global.reset_game()
			get_tree().reload_current_scene()
			return
	
	# Shoot Button (B): Primary firing action
	if pos.distance_to(btn_shoot_pos) <= btn_shoot_radius * 1.15:
		btn_shoot_touch_id = idx
		shoot_active = true
		Input.action_press("shoot")
		queue_redraw()
		return
	
	# Jump Button (A) or Right-Half Screen Tap
	if pos.distance_to(btn_jump_pos) <= btn_jump_radius * 1.25 or (pos.x >= half_w and pos.y > 36.0):
		if not jump_touch_ids.has(idx):
			jump_touch_ids.append(idx)
		jump_active = true
		Input.action_press("jump")
		last_jump_tap_pos = pos
		jump_tap_anim = 0.35
		queue_redraw()
		return
	
	# DYNAMIC MOVEMENT CONTROLLER: Left half of screen (below top status bar)
	if pos.x < half_w and pos.y > 60.0:
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
	elif jump_touch_ids.has(idx):
		# If sliding into the shoot button from jump area
		if btn_shoot_touch_id == -1 and pos.distance_to(btn_shoot_pos) <= btn_shoot_radius * 1.15:
			jump_touch_ids.erase(idx)
			if jump_touch_ids.is_empty():
				jump_active = false
				Input.action_release("jump")
			btn_shoot_touch_id = idx
			shoot_active = true
			Input.action_press("shoot")
			queue_redraw()
	elif idx == btn_shoot_touch_id:
		# If sliding from shoot button into jump button area
		if pos.distance_to(btn_jump_pos) <= btn_jump_radius * 1.15:
			btn_shoot_touch_id = -1
			shoot_active = false
			Input.action_release("shoot")
			if not jump_touch_ids.has(idx):
				jump_touch_ids.append(idx)
			jump_active = true
			Input.action_press("jump")
			queue_redraw()

func _handle_touch_up(idx: int) -> void:
	if idx == dpad_touch_id:
		dpad_touch_id = -1
		dpad_active = false
		dpad_vector = Vector2.ZERO
		_release_all_dpad_actions()
		queue_redraw()
	
	if idx == btn_shoot_touch_id:
		btn_shoot_touch_id = -1
		shoot_active = false
		Input.action_release("shoot")
		queue_redraw()
	
	if jump_touch_ids.has(idx):
		jump_touch_ids.erase(idx)
		if jump_touch_ids.is_empty():
			jump_active = false
			Input.action_release("jump")
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

func _draw_glass_disc(pos: Vector2, radius: float, is_active: bool, base_tint: Color, glow_tint: Color, border_tint: Color, pulse_radius: float = 0.0) -> void:
	# 1. Soft elevation ambient shadow
	draw_circle(pos + Vector2(0.0, 4.0), radius * 0.98, Color(0.0, 0.0, 0.0, 0.28))
	
	# 2. Translucent frosted glass tint fill
	draw_circle(pos, radius, base_tint)
	
	# 3. Soft internal refraction glow
	var glow_a: float = 0.24 if is_active else 0.06
	draw_circle(pos, radius * 0.82, Color(glow_tint.r, glow_tint.g, glow_tint.b, glow_a))
	
	# 4. Off-center specular surface sheen / light reflection (top-left glare)
	var sheen_offset := Vector2(-radius * 0.24, -radius * 0.26)
	draw_circle(pos + sheen_offset, radius * 0.44, Color(1.0, 1.0, 1.0, 0.09 if is_active else 0.05))
	
	# 5. Inner refraction bevel ring (depth to the glass lens)
	var inner_rim_col := Color(border_tint.r, border_tint.g, border_tint.b, 0.28 if is_active else 0.16)
	draw_arc(pos, radius - 3.5, 0.0, TAU, 36, inner_rim_col, 1.2)
	
	# 6. Outer polished glass perimeter ring
	draw_arc(pos, radius, 0.0, TAU, 36, border_tint, 2.4 if is_active else 1.8)
	
	# 7. Upper rim specular highlight arc (light catching curved glass edge)
	var spec_col := Color(1.0, 1.0, 1.0, 0.65 if is_active else 0.42)
	draw_arc(pos, radius - 1.2, -PI * 0.82, -PI * 0.18, 28, spec_col, 1.8)
	
	# 8. Counter-reflection ambient bounce on lower rim
	var bounce_col := Color(border_tint.r, border_tint.g, border_tint.b, 0.25 if is_active else 0.12)
	draw_arc(pos, radius - 2.0, PI * 0.28, PI * 0.72, 24, bounce_col, 1.2)
	
	# 9. Bright specular point glint on top-left edge
	var glint_pos := pos + Vector2(-radius * 0.48, -radius * 0.48)
	draw_circle(glint_pos, 2.5, Color(1.0, 1.0, 1.0, 0.75 if is_active else 0.45))
	
	# 10. Active dynamic pulse ring
	if is_active and pulse_radius > 0.0:
		draw_arc(pos, pulse_radius, 0.0, TAU, 36, Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.35), 1.6)

func _draw() -> void:
	if Global.is_maker_mode:
		return
	
	_update_layout_positions()
	
	# --- DYNAMIC JOYSTICK BASE (LEFT SIDE) ---
	var base_fill := Color(0.06, 0.14, 0.26, 0.34) if dpad_active else Color(0.04, 0.08, 0.14, 0.14)
	var base_glow := Color(0.20, 0.75, 1.0)
	var base_border := Color(0.40, 0.85, 1.0, 0.80) if dpad_active else Color(0.65, 0.80, 0.95, 0.30)
	var base_pulse := dpad_radius + sin(pulse_time) * 4.0 if dpad_active else 0.0
	_draw_glass_disc(dpad_center, dpad_radius, dpad_active, base_fill, base_glow, base_border, base_pulse)
	
	# Glowing tether line from center to thumb
	if dpad_active:
		draw_line(dpad_center, current_thumb_pos, Color(0.2, 0.7, 1.0, 0.35), 4.5)
		draw_line(dpad_center, current_thumb_pos, Color(0.5, 0.9, 1.0, 0.80), 2.2)
		draw_line(dpad_center, current_thumb_pos, Color(1.0, 1.0, 1.0, 0.95), 1.0)
	
	# Center anchor glass pip
	draw_circle(dpad_center, 6.5, Color(0.3, 0.8, 1.0, 0.55 if dpad_active else 0.22))
	draw_circle(dpad_center, 3.0, Color.WHITE if dpad_active else Color(0.8, 0.9, 1.0, 0.4))
	
	# 8-Way Directional Notches & Indicators (Etched Glass Grooves)
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		var dir := Vector2(cos(a), sin(a))
		var notch_start := dpad_center + dir * (dpad_radius - 12.0)
		var notch_end := dpad_center + dir * (dpad_radius - 2.0)
		var is_highlighted := false
		
		# Check if this notch is currently active
		if dpad_active and dpad_vector.length() > 0.2:
			var angle_diff: float = absf(fposmod(dir.angle() - dpad_vector.angle() + PI, TAU) - PI)
			if angle_diff < PI / 8.0:
				is_highlighted = true
		
		var notch_col := Color(1.0, 0.88, 0.30, 0.95) if is_highlighted else Color(0.75, 0.88, 1.0, 0.28)
		# Subtle etched groove shadow
		draw_line(notch_start + Vector2(0.5, 1.0), notch_end + Vector2(0.5, 1.0), Color(0.0, 0.0, 0.0, 0.25), 2.0)
		draw_line(notch_start, notch_end, notch_col, 3.2 if is_highlighted else 1.8)
		if is_highlighted:
			var arrow_pt := dpad_center + dir * (dpad_radius + 8.0)
			draw_circle(arrow_pt + Vector2(0.0, 1.0), 4.5, Color(0.0, 0.0, 0.0, 0.35))
			draw_circle(arrow_pt, 4.0, Color(1.0, 0.88, 0.30))
			draw_circle(arrow_pt, 2.0, Color.WHITE)
	
	# --- THUMB KNOB (FLOATING GLASS ORB / LENS) ---
	var knob_radius: float = 32.0 if Global.is_mobile_device() else 26.0
	# 1. Soft floating drop shadow
	draw_circle(current_thumb_pos + Vector2(0.0, 4.5), knob_radius * 0.95, Color(0.0, 0.0, 0.0, 0.38))
	# 2. Translucent crystal body
	var knob_core_col := Color(0.12, 0.40, 0.85, 0.65) if dpad_active else Color(0.14, 0.20, 0.30, 0.38)
	draw_circle(current_thumb_pos, knob_radius * 0.88, knob_core_col)
	# 3. Glass dome specular curved reflection
	var knob_sheen_pos := current_thumb_pos + Vector2(-knob_radius * 0.24, -knob_radius * 0.26)
	draw_circle(knob_sheen_pos, knob_radius * 0.40, Color(1.0, 1.0, 1.0, 0.18 if dpad_active else 0.10))
	# 4. Outer polished crystal bezel ring
	var knob_bezel_col := Color(0.85, 0.95, 1.0, 0.85 if dpad_active else 0.50)
	draw_arc(current_thumb_pos, knob_radius * 0.88, 0.0, TAU, 28, knob_bezel_col, 2.0 if Global.is_mobile_device() else 1.8)
	# 5. Upper rim specular arc
	draw_arc(current_thumb_pos, knob_radius * 0.88 - 1.2, -PI * 0.80, -PI * 0.20, 20, Color(1.0, 1.0, 1.0, 0.80), 1.6)
	# 6. Center glowing crystal iris
	var iris_radius: float = 7.5 if Global.is_mobile_device() else 6.0
	draw_circle(current_thumb_pos, iris_radius + 2.0, Color(0.2, 0.7, 1.0, 0.3 if dpad_active else 0.1))
	draw_circle(current_thumb_pos, iris_radius, Color(0.40, 0.92, 1.0, 0.95) if dpad_active else Color(1.0, 1.0, 1.0, 0.45))
	draw_circle(current_thumb_pos, iris_radius * 0.45, Color.WHITE)
	# 7. Bright specular point shine
	var knob_glint_pos := current_thumb_pos + Vector2(-knob_radius * 0.36, -knob_radius * 0.36)
	draw_circle(knob_glint_pos, 2.2, Color(1.0, 1.0, 1.0, 0.90))
	
	# --- JUMP TAP SHOCKWAVE / RIPPLE FEEDBACK (ANYWHERE ON RIGHT SIDE) ---
	if jump_tap_anim > 0.0 and last_jump_tap_pos != Vector2.ZERO:
		var prog: float = 1.0 - (jump_tap_anim / 0.35)
		var rip_r: float = 14.0 + prog * 44.0
		var rip_a: float = (1.0 - prog) * 0.85
		draw_arc(last_jump_tap_pos, rip_r, 0.0, TAU, 28, Color(0.25, 0.85, 1.0, rip_a), 2.5)
		draw_circle(last_jump_tap_pos, 7.0 * (1.0 - prog), Color(0.50, 0.95, 1.0, rip_a * 0.7))

	# --- JUMP BUTTON (A / JUMP) ---
	if show_jump_button:
		var jump_base := Color(0.08, 0.24, 0.48, 0.38) if jump_active else Color(0.04, 0.14, 0.30, 0.16)
		var jump_glow := Color(0.20, 0.75, 1.0)
		var jump_border := Color(0.50, 0.92, 1.0, 0.85) if jump_active else Color(0.40, 0.78, 1.0, 0.42)
		var jump_pulse := btn_jump_radius + 4.0 + sin(pulse_time * 2.0) * 2.5 if jump_active else 0.0
		_draw_glass_disc(btn_jump_pos, btn_jump_radius, jump_active, jump_base, jump_glow, jump_border, jump_pulse)
		
		# Letter 'A' (Etched Glass Typography with Soft Shadow)
		var a_shadow := Vector2(1.2, 1.5)
		draw_line(btn_jump_pos + a_shadow + Vector2(-12.0, 14.0), btn_jump_pos + a_shadow + Vector2(0.0, -14.0), Color(0.0, 0.0, 0.0, 0.35), 3.6)
		draw_line(btn_jump_pos + a_shadow + Vector2(12.0, 14.0), btn_jump_pos + a_shadow + Vector2(0.0, -14.0), Color(0.0, 0.0, 0.0, 0.35), 3.6)
		draw_line(btn_jump_pos + a_shadow + Vector2(-7.5, 2.0), btn_jump_pos + a_shadow + Vector2(7.5, 2.0), Color(0.0, 0.0, 0.0, 0.35), 3.0)
		
		if jump_active:
			# Electric cyan neon underglow
			draw_line(btn_jump_pos + Vector2(-12.0, 14.0), btn_jump_pos + Vector2(0.0, -14.0), Color(0.3, 0.85, 1.0, 0.45), 6.0)
			draw_line(btn_jump_pos + Vector2(12.0, 14.0), btn_jump_pos + Vector2(0.0, -14.0), Color(0.3, 0.85, 1.0, 0.45), 6.0)
			draw_line(btn_jump_pos + Vector2(-7.5, 2.0), btn_jump_pos + Vector2(7.5, 2.0), Color(0.3, 0.85, 1.0, 0.45), 5.0)
		
		var a_col := Color(1.0, 1.0, 1.0, 0.95 if jump_active else 0.65)
		draw_line(btn_jump_pos + Vector2(-12.0, 14.0), btn_jump_pos + Vector2(0.0, -14.0), a_col, 3.6)
		draw_line(btn_jump_pos + Vector2(12.0, 14.0), btn_jump_pos + Vector2(0.0, -14.0), a_col, 3.6)
		draw_line(btn_jump_pos + Vector2(-7.5, 2.0), btn_jump_pos + Vector2(7.5, 2.0), a_col, 3.0)

	# --- SHOOT BUTTON (B / FIRE) ---
	var shoot_base := Color(0.45, 0.10, 0.14, 0.38) if shoot_active else Color(0.22, 0.06, 0.08, 0.16)
	var shoot_glow := Color(1.0, 0.35, 0.30)
	var shoot_border := Color(1.0, 0.65, 0.55, 0.85) if shoot_active else Color(1.0, 0.45, 0.40, 0.42)
	var shoot_pulse := btn_shoot_radius + 4.0 + sin(pulse_time * 2.0) * 2.5 if shoot_active else 0.0
	_draw_glass_disc(btn_shoot_pos, btn_shoot_radius, shoot_active, shoot_base, shoot_glow, shoot_border, shoot_pulse)
	
	# Reticle etched tick marks on B perimeter
	for rdir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tick_col := Color(1.0, 0.70, 0.60, 0.75 if shoot_active else 0.30)
		draw_line(btn_shoot_pos + rdir * (btn_shoot_radius - 7.0), btn_shoot_pos + rdir * (btn_shoot_radius + 4.0), tick_col, 1.8)

	# Letter 'B' (Etched Glass Typography with Soft Shadow)
	var b_offset := Vector2(3.0, 0.0)
	var b_shadow := b_offset + Vector2(1.2, 1.5)
	draw_line(btn_shoot_pos + b_shadow + Vector2(-12.0, -15.0), btn_shoot_pos + b_shadow + Vector2(-12.0, 15.0), Color(0.0, 0.0, 0.0, 0.35), 4.0)
	draw_line(btn_shoot_pos + b_shadow + Vector2(-12.0, -15.0), btn_shoot_pos + b_shadow + Vector2(-2.0, -15.0), Color(0.0, 0.0, 0.0, 0.35), 4.0)
	draw_line(btn_shoot_pos + b_shadow + Vector2(-12.0, 0.0), btn_shoot_pos + b_shadow + Vector2(-2.0, 0.0), Color(0.0, 0.0, 0.0, 0.35), 3.4)
	draw_line(btn_shoot_pos + b_shadow + Vector2(-12.0, 15.0), btn_shoot_pos + b_shadow + Vector2(-2.0, 15.0), Color(0.0, 0.0, 0.0, 0.35), 4.0)
	draw_arc(btn_shoot_pos + b_shadow + Vector2(-2.0, -7.5), 7.5, -PI*0.5, PI*0.5, 14, Color(0.0, 0.0, 0.0, 0.35), 3.4)
	draw_arc(btn_shoot_pos + b_shadow + Vector2(-2.0, 7.5), 7.5, -PI*0.5, PI*0.5, 14, Color(0.0, 0.0, 0.0, 0.35), 3.4)
	
	if shoot_active:
		# Crimson ruby neon underglow
		draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, -15.0), btn_shoot_pos + b_offset + Vector2(-12.0, 15.0), Color(1.0, 0.3, 0.25, 0.45), 6.5)
		draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, -15.0), btn_shoot_pos + b_offset + Vector2(-2.0, -15.0), Color(1.0, 0.3, 0.25, 0.45), 6.5)
		draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, 0.0), btn_shoot_pos + b_offset + Vector2(-2.0, 0.0), Color(1.0, 0.3, 0.25, 0.45), 5.5)
		draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, 15.0), btn_shoot_pos + b_offset + Vector2(-2.0, 15.0), Color(1.0, 0.3, 0.25, 0.45), 6.5)
		draw_arc(btn_shoot_pos + b_offset + Vector2(-2.0, -7.5), 7.5, -PI*0.5, PI*0.5, 14, Color(1.0, 0.3, 0.25, 0.45), 5.5)
		draw_arc(btn_shoot_pos + b_offset + Vector2(-2.0, 7.5), 7.5, -PI*0.5, PI*0.5, 14, Color(1.0, 0.3, 0.25, 0.45), 5.5)
	
	var b_col := Color(1.0, 1.0, 1.0, 0.95 if shoot_active else 0.65)
	draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, -15.0), btn_shoot_pos + b_offset + Vector2(-12.0, 15.0), b_col, 4.0)
	draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, -15.0), btn_shoot_pos + b_offset + Vector2(-2.0, -15.0), b_col, 4.0)
	draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, 0.0), btn_shoot_pos + b_offset + Vector2(-2.0, 0.0), b_col, 3.4)
	draw_line(btn_shoot_pos + b_offset + Vector2(-12.0, 15.0), btn_shoot_pos + b_offset + Vector2(-2.0, 15.0), b_col, 4.0)
	draw_arc(btn_shoot_pos + b_offset + Vector2(-2.0, -7.5), 7.5, -PI*0.5, PI*0.5, 14, b_col, 3.4)
	draw_arc(btn_shoot_pos + b_offset + Vector2(-2.0, 7.5), 7.5, -PI*0.5, PI*0.5, 14, b_col, 3.4)
	
	# --- SLEEK GLASS LEVEL SELECTOR (MENU) BUTTON (HEADER) ---
	var menu_rect := Rect2(btn_menu_pos.x - btn_menu_size.x * 0.5, btn_menu_pos.y - btn_menu_size.y * 0.5, btn_menu_size.x, btn_menu_size.y)
	# Soft elevation drop shadow
	draw_rect(Rect2(menu_rect.position.x, menu_rect.position.y + 2.0, menu_rect.size.x, menu_rect.size.y), Color(0.0, 0.0, 0.0, 0.25))
	draw_style_box(style_menu_btn, menu_rect)
	# Upper glass specular edge line
	draw_line(Vector2(menu_rect.position.x + 3.0, menu_rect.position.y + 1.2), Vector2(menu_rect.end.x - 3.0, menu_rect.position.y + 1.2), Color(1.0, 1.0, 1.0, 0.45), 1.0)
	
	var is_mob: bool = Global.is_mobile_device()
	var grid_col := Color(0.92, 0.96, 1.0, 0.90)
	var tile_sz: float = 4.4 if is_mob else 3.5
	var tile_gap: float = 3.0 if is_mob else 2.5
	var hg: float = tile_sz + tile_gap * 0.5
	draw_rect(Rect2(btn_menu_pos.x - hg, btn_menu_pos.y - hg, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x + tile_gap * 0.5, btn_menu_pos.y - hg, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x - hg, btn_menu_pos.y + tile_gap * 0.5, tile_sz, tile_sz), grid_col)
	draw_rect(Rect2(btn_menu_pos.x + tile_gap * 0.5, btn_menu_pos.y + tile_gap * 0.5, tile_sz, tile_sz), grid_col)
	
	# --- SLEEK GLASS RESTART BUTTON (HEADER) ---
	var restart_rect := Rect2(btn_restart_pos.x - btn_restart_size.x * 0.5, btn_restart_pos.y - btn_restart_size.y * 0.5, btn_restart_size.x, btn_restart_size.y)
	# Soft elevation drop shadow
	draw_rect(Rect2(restart_rect.position.x, restart_rect.position.y + 2.0, restart_rect.size.x, restart_rect.size.y), Color(0.0, 0.0, 0.0, 0.25))
	draw_style_box(style_restart_btn, restart_rect)
	# Upper glass specular edge line
	draw_line(Vector2(restart_rect.position.x + 3.0, restart_rect.position.y + 1.2), Vector2(restart_rect.end.x - 3.0, restart_rect.position.y + 1.2), Color(1.0, 1.0, 1.0, 0.45), 1.0)
	
	var restart_col := Color(1.0, 0.92, 0.75, 0.90)
	var r_rad: float = 7.0 if is_mob else 5.5
	draw_arc(btn_restart_pos, r_rad, 0.5, 5.5, 20, restart_col, 2.0 if is_mob else 1.8)
	var tip := btn_restart_pos + Vector2(cos(5.5), sin(5.5)) * r_rad
	var dir := Vector2(0.706, 0.708)
	var arrow_sz: float = 4.2 if is_mob else 3.2
	var arrow_pts := PackedVector2Array([
		tip + dir * arrow_sz,
		tip - dir * 1.8 + Vector2(-dir.y, dir.x) * (3.6 if is_mob else 2.8),
		tip - dir * 1.8 - Vector2(-dir.y, dir.x) * (3.6 if is_mob else 2.8)
	])
	draw_colored_polygon(arrow_pts, restart_col)

func _draw_btn_text(text: String, pos: Vector2, col: Color, font_size: int = 11) -> void:
	var font := ThemeDB.fallback_font
	var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(pos.x - string_size.x * 0.5, pos.y + string_size.y * 0.35)
	# Soft translucent drop shadow that respects text opacity
	draw_string(font, text_pos + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, col.a * 0.55))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
