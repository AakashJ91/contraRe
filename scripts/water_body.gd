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
@export var anim_fps: float = 1.0
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
		var p := "res://assets/tiles/common/water_surface_%d.png" % i
		if not ResourceLoader.exists(p):
			p = "res://assets/tiles/water_surface_%d.png" % i
		if ResourceLoader.exists(p):
			surface_frames.append(load(p))
	
	var deep_path := "res://assets/tiles/common/water_body_deep.png"
	if not ResourceLoader.exists(deep_path):
		deep_path = "res://assets/tiles/water_body_deep.png"
	if ResourceLoader.exists(deep_path):
		deep_texture = load(deep_path)
	
	ripple_frames.clear()
	for i in range(4):
		var rp := "res://assets/tiles/common/water_ripple_%d.png" % i
		if not ResourceLoader.exists(rp):
			rp = "res://assets/tiles/water_ripple_%d.png" % i
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
	queue_redraw()
	
	if ambient_splashes and is_inside_tree() and has_node("/root/VFX"):
		ambient_timer += delta
		if ambient_timer >= 3.0:
			ambient_timer = randf_range(0.0, 1.0)
			var rx := randf_range(16.0, maxf(16.0, water_size.x - 16.0))
			var splash_pos := global_position + Vector2(rx, 2.0)
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
	
	var num_pts := int(ceil(w / 6.0)) + 1
	var surface_pts := PackedVector2Array()
	for p in range(num_pts):
		var px := minf(float(p) * 6.0, w)
		var wave := sin(px * 0.018 + anim_timer * 1.3) * 2.2 + sin(px * 0.045 - anim_timer * 0.8) * 1.1
		surface_pts.append(Vector2(px, wave))
	
	var poly_pts := PackedVector2Array()
	poly_pts.append_array(surface_pts)
	poly_pts.append(Vector2(w, h))
	poly_pts.append(Vector2(0.0, h))
	
	var c_surf := Color(0.06, 0.28, 0.40, 0.94) * surface_color
	draw_colored_polygon(poly_pts, c_surf)
	
	# Deep waterbed shadow
	if h > 18.0:
		draw_rect(Rect2(0.0, 14.0, w, h - 14.0), Color(0.01, 0.05, 0.14, 0.65) * deep_color)
	
	# Sub-surface caustics drifting gently
	for b in range(min(3, int(h / 20.0))):
		var band_y := 8.0 + float(b) * 12.0
		var band_drift := sin(anim_timer * 1.1 + float(b) * 1.4) * 6.0
		draw_line(Vector2(10.0 + band_drift, band_y), Vector2(w - 10.0 + band_drift, band_y), Color(0.30, 0.75, 0.90, 0.18), 1.5)
	
	# Soft translucent wave crest foam highlight
	for p in range(surface_pts.size() - 1):
		var pt1 := surface_pts[p]
		var pt2 := surface_pts[p + 1]
		draw_line(pt1, pt2, Color(0.70, 0.95, 1.0, 0.65), 1.8)
		draw_line(Vector2(pt1.x, pt1.y + 2.0), Vector2(pt2.x, pt2.y + 2.0), Color(0.25, 0.65, 0.82, 0.35), 1.0)
