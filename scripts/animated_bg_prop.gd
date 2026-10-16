class_name AnimatedBgProp
extends Node2D

@export var prop_data: BgItemData = null

var current_frame: int = 0
var anim_timer: float = 0.0
var vfx_timer: float = 0.0

func _ready() -> void:
	z_index = -1 # Render in background behind player and enemies
	if prop_data == null and ResourceLoader.exists("res://resources/bg_props/radar_dish.tres"):
		prop_data = load("res://resources/bg_props/radar_dish.tres")
	queue_redraw()

func _process(delta: float) -> void:
	if prop_data == null:
		return
	
	anim_timer += delta * prop_data.fps
	var old_frame := current_frame
	if prop_data.frame_count > 0:
		current_frame = int(anim_timer) % prop_data.frame_count
	
	if current_frame != old_frame or prop_data.has_light_glow:
		queue_redraw()
	
	# Ambient subtle particle effects
	if prop_data.vfx_type != "none" and prop_data.vfx_interval > 0.0:
		vfx_timer += delta
		if vfx_timer >= prop_data.vfx_interval:
			vfx_timer = 0.0
			_emit_ambient_vfx()

func _emit_ambient_vfx() -> void:
	if not is_inside_tree() or not has_node("/root/VFX"):
		return
	
	# Only emit if within screen vicinity
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		if absf(global_position.x - cam.global_position.x) > 600.0:
			return
	
	var spawn_pos: Vector2 = global_position + prop_data.offset
	match prop_data.vfx_type:
		"steam":
			VFX.spawn_dust_puff(spawn_pos + Vector2(0.0, -12.0), 2, Color(0.9, 0.95, 1.0, 0.4))
		"sparks":
			var spk_col := Color(0.35, 0.95, 1.0) if (prop_data.item_id == "electric_arc" or prop_data.item_id == "alien_core") else Color(1.0, 0.8, 0.3)
			VFX.spawn_hit_sparks(spawn_pos, Vector2.UP, spk_col)
		"spores":
			VFX.spawn_blood_splatter(spawn_pos, Vector2.UP, true)
		"splash":
			VFX.spawn_water_splash(spawn_pos)

func _draw() -> void:
	if prop_data == null:
		return
	
	# 1. Ambient lighting glow halo
	if prop_data.has_light_glow and prop_data.light_color.a > 0.0:
		var is_reddish := (prop_data.light_color.r > 0.5 and prop_data.light_color.g < 0.4)
		if not is_reddish:
			var pulse: float = 0.85 + 0.15 * sin(anim_timer * 4.0)
			var halo_col: Color = prop_data.light_color
			halo_col.a *= pulse
			draw_circle(prop_data.offset, prop_data.light_radius * pulse, halo_col)
	
	# 2. Draw current frame texture
	var cur_tex: Texture2D = null
	if prop_data.frames.size() > current_frame:
		cur_tex = prop_data.frames[current_frame]
	elif prop_data.spritesheet != null:
		cur_tex = prop_data.spritesheet
	
	if cur_tex != null:
		var s := prop_data.size
		var draw_pos := prop_data.offset - s * 0.5
		draw_texture_rect(cur_tex, Rect2(draw_pos, s), false, prop_data.color_tint)
	else:
		# Fallback indicator
		draw_circle(prop_data.offset, 12.0, Color(0.2, 0.7, 0.9, 0.5))
