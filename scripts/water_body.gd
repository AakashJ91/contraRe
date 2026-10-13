class_name WaterBody
extends Node2D

@export var water_size: Vector2 = Vector2(320.0, 120.0):
	set(val):
		water_size = val
		_update_collision()
		queue_redraw()

@export var is_hazard: bool = false
@export var surface_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var deep_color: Color = Color(0.9, 0.95, 1.0, 0.9)
@export var anim_fps: float = 6.0
@export var ambient_splashes: bool = true

var surface_frames: Array[Texture2D] = []
var deep_texture: Texture2D = null
var ripple_frames: Array[Texture2D] = []

var anim_timer: float = 0.0
var current_frame: int = 0
var ambient_timer: float = 0.0

var area: Area2D = null
var col_shape: CollisionShape2D = null
var rect_shape: RectangleShape2D = null

func _ready() -> void:
	z_index = -1
	_load_textures()
	_setup_area()
	queue_redraw()

func _load_textures() -> void:
	surface_frames.clear()
	for i in range(4):
		var p := "res://assets/tiles/water_surface_%d.png" % i
		if ResourceLoader.exists(p):
			surface_frames.append(load(p))
	
	if ResourceLoader.exists("res://assets/tiles/water_body_deep.png"):
		deep_texture = load("res://assets/tiles/water_body_deep.png")
	
	ripple_frames.clear()
	for i in range(4):
		var rp := "res://assets/tiles/water_ripple_%d.png" % i
		if ResourceLoader.exists(rp):
			ripple_frames.append(load(rp))

func _setup_area() -> void:
	area = Area2D.new()
	area.name = "WaterArea"
	area.collision_layer = 0
	area.collision_mask = 1 | 2 | 4 | 8 | 16
	
	col_shape = CollisionShape2D.new()
	rect_shape = RectangleShape2D.new()
	col_shape.shape = rect_shape
	area.add_child(col_shape)
	add_child(area)
	
	_update_collision()
	
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)

func _update_collision() -> void:
	if rect_shape != null and col_shape != null:
		rect_shape.size = water_size
		col_shape.position = water_size * 0.5

func _process(delta: float) -> void:
	anim_timer += delta * anim_fps
	var old_frame := current_frame
	if surface_frames.size() > 0:
		current_frame = int(anim_timer) % surface_frames.size()
	
	if current_frame != old_frame:
		queue_redraw()
	
	if ambient_splashes and is_inside_tree() and has_node("/root/VFX"):
		ambient_timer += delta
		if ambient_timer >= 2.0:
			ambient_timer = randf_range(0.0, 0.8)
			var rx := randf_range(16.0, maxf(16.0, water_size.x - 16.0))
			var splash_pos := global_position + Vector2(rx, 2.0)
			# Only trigger if near camera
			var cam := get_viewport().get_camera_2d()
			if cam == null or absf(cam.global_position.x - splash_pos.x) < 520.0:
				VFX.spawn_water_splash(splash_pos)

func _on_body_entered(body: Node2D) -> void:
	_trigger_splash(body.global_position)
	if is_hazard and body.has_method("take_damage"):
		body.take_damage(999.0)

func _on_area_entered(other_area: Area2D) -> void:
	_trigger_splash(other_area.global_position)

func _trigger_splash(target_pos: Vector2) -> void:
	if not is_inside_tree() or not has_node("/root/VFX"):
		return
	
	var splash_x := clampf(target_pos.x, global_position.x, global_position.x + water_size.x)
	var splash_pos := Vector2(splash_x, global_position.y)
	VFX.spawn_water_splash(splash_pos)

func _draw() -> void:
	var w: float = water_size.x
	var h: float = water_size.y
	if w <= 0.0 or h <= 0.0:
		return
	
	# 1. Under-layer deep water body
	var body_top: float = 12.0
	var body_h: float = maxf(0.0, h - body_top)
	if deep_texture != null and body_h > 0.0:
		var tex_w: float = float(deep_texture.get_width())
		var tex_h: float = float(deep_texture.get_height())
		var x_cursor: float = 0.0
		while x_cursor < w:
			var step_w: float = minf(tex_w, w - x_cursor)
			var y_cursor: float = body_top
			while y_cursor < h:
				var step_h: float = minf(tex_h, h - y_cursor)
				var src_rect := Rect2(0.0, 0.0, step_w, step_h)
				var dst_rect := Rect2(x_cursor, y_cursor, step_w, step_h)
				draw_texture_rect_region(deep_texture, dst_rect, src_rect, deep_color)
				y_cursor += step_h
			x_cursor += step_w
	else:
		draw_rect(Rect2(0.0, body_top, w, body_h), Color(0.05, 0.2, 0.45, 0.9))
	
	# 2. Surface animated waves
	var cur_surface_tex: Texture2D = null
	if surface_frames.size() > current_frame:
		cur_surface_tex = surface_frames[current_frame]
	
	if cur_surface_tex != null:
		var tile_w: float = float(cur_surface_tex.get_width())
		var tile_h: float = float(cur_surface_tex.get_height())
		var x_cursor: float = 0.0
		while x_cursor < w:
			var step_w: float = minf(tile_w, w - x_cursor)
			var src_rect := Rect2(0.0, 0.0, step_w, tile_h)
			var dst_rect := Rect2(x_cursor, 0.0, step_w, tile_h)
			draw_texture_rect_region(cur_surface_tex, dst_rect, src_rect, surface_color)
			x_cursor += step_w
	else:
		draw_rect(Rect2(0.0, 0.0, w, 16.0), Color(0.2, 0.6, 0.9, 0.85))
	
	# 3. Translucent water shimmer crest highlight
	draw_line(Vector2(0.0, 1.0), Vector2(w, 1.0), Color(0.8, 0.95, 1.0, 0.4), 1.0)
