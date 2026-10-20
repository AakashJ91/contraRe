extends Area2D

# =============================================================================
# CONTRA RE - THEMED HOVER DEFENSE SENSOR POD (ANIMATED & LEVITATING)
# =============================================================================
# High-tech anti-gravity hover capsule that levitates in mid-air above platforms.
# Features stage-specific adaptive themes (Military, Aqua, Bio-Alien, Cryo, Magma,
# Tesla, Orbital Stealth, Sanctum Psionic) with animated scanning apertures,
# glowing plasma cores, anti-gravity repulsor exhaust rings, and Falcon powerup drops.

@export var powerup_scene: PackedScene = preload("res://scenes/powerup_item.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var sensor_data: Resource = null
@export var weapon_type: Global.WeaponType = Global.WeaponType.SPREAD

var health: float = 3.0
var max_health: float = 3.0
var flash_timer: float = 0.0
var anim_timer: float = 0.0
var hover_timer: float = 0.0
var frames: Array[Texture2D] = []
var animation_fps: float = 7.0
var sprite_size: Vector2 = Vector2(40.0, 48.0)

var base_position: Vector2 = Vector2.ZERO
var hover_amplitude: float = 6.5
var hover_speed: float = 3.2
var thruster_col: Color = Color(1.0, 0.55, 0.12)
var core_glow_col: Color = Color(1.0, 0.25, 0.15)
var is_hover_initialized: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("powerup_sensors")
	collision_layer = 1 << 2 # Layer 3: Enemies (can be shot by player bullets)
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	
	hover_timer = randf_range(0.0, 10.0)
	
	# Load stage-specific theme resource if not manually specified
	if sensor_data == null:
		var stage_idx := clampi(Global.current_stage, 1, 8)
		var theme_res_path := "res://resources/enemies/powerup_sensor_stage%d.tres" % stage_idx
		if ResourceLoader.exists(theme_res_path):
			sensor_data = load(theme_res_path)
		elif ResourceLoader.exists("res://resources/enemies/powerup_sensor_data.tres"):
			sensor_data = load("res://resources/enemies/powerup_sensor_data.tres")
	
	if sensor_data != null:
		max_health = sensor_data.get("max_health") if sensor_data.get("max_health") != null else 3.0
		health = max_health
		animation_fps = sensor_data.get("animation_fps") if sensor_data.get("animation_fps") != null else 7.0
		sprite_size = sensor_data.get("sprite_size") if sensor_data.get("sprite_size") != null else Vector2(40.0, 48.0)
		hover_amplitude = sensor_data.get("hover_amplitude") if sensor_data.get("hover_amplitude") != null else 6.5
		hover_speed = sensor_data.get("hover_speed") if sensor_data.get("hover_speed") != null else 3.2
		if sensor_data.get("thruster_color") != null:
			thruster_col = sensor_data.get("thruster_color")
		if sensor_data.get("core_color") != null:
			core_glow_col = sensor_data.get("core_color")
		
		var data_frames = sensor_data.get("frame_textures")
		if data_frames != null and data_frames is Array and not data_frames.is_empty():
			frames = (data_frames as Array).duplicate()
	
	# Fallback dynamic theme loading if frames empty
	if frames.is_empty():
		var stage_names: Array[String] = ["military", "aqua", "alien", "cryo", "magma", "tesla", "stealth", "sanctum"]
		var s_idx := clampi(Global.current_stage, 1, 8) - 1
		var t_name: String = stage_names[s_idx]
		for i in range(6):
			var fp := "res://assets/powerups/sensor/themes/%s/frame_%d.png" % [t_name, i]
			if ResourceLoader.exists(fp):
				frames.append(load(fp))
			elif ResourceLoader.exists("res://assets/powerups/sensor/sensor_frame_%d.png" % i):
				frames.append(load("res://assets/powerups/sensor/sensor_frame_%d.png" % i))
	
	if frames.is_empty() and ResourceLoader.exists("res://assets/powerups/powerup_sensor.png"):
		frames.append(load("res://assets/powerups/powerup_sensor.png"))
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_hover_initialized:
		# Elevate base position slightly above ground/platform surface so it hovers gracefully in air
		base_position = global_position + Vector2(0.0, -10.0)
		is_hover_initialized = true
	
	anim_timer += delta
	hover_timer += delta
	
	# Hover oscillation (vertical floating bobbing + gentle horizontal sway & aerodynamic tilt)
	var bob := sin(hover_timer * hover_speed) * hover_amplitude
	var sway := cos(hover_timer * (hover_speed * 0.65)) * 1.8
	var tilt := sin(hover_timer * (hover_speed * 0.8)) * 0.045
	
	global_position = base_position + Vector2(sway, bob)
	rotation = tilt
	
	if flash_timer > 0.0:
		flash_timer -= delta
	
	queue_redraw()

var is_dying: bool = false

func take_damage(dmg: float = 1.0) -> void:
	if is_dying or is_queued_for_deletion():
		return
	health -= dmg
	flash_timer = 0.12
	Global.play_sfx("hit")
	VFX.spawn_hit_sparks(global_position + Vector2(0.0, -14.0), Vector2.UP, Color(1.0, 0.6, 0.2))
	if health <= 0.0:
		_die.call_deferred()

func _die() -> void:
	if is_dying or is_queued_for_deletion():
		return
	is_dying = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var reward := 500
	if sensor_data != null and sensor_data.get("score_reward") != null:
		reward = sensor_data.get("score_reward")
	Global.add_score(reward)
	Global.play_sfx("boss_explode")
	Global.shake_screen(4.0, 0.2)
	
	# Spawn standard multi-frame animated explosion (using explosion.png)
	VFX.spawn_explosion(global_position + Vector2(0.0, -14.0), 1.25)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = global_position + Vector2(0.0, -14.0)
		get_parent().add_child(exp_node)
	
	# Drop Falcon Powerup Weapon Badge
	if powerup_scene != null:
		var item = powerup_scene.instantiate()
		item.weapon_type = weapon_type
		item.global_position = global_position + Vector2(0.0, -12.0)
		get_parent().add_child(item)
	
	queue_free()

func _draw() -> void:
	var cur_tex: Texture2D = null
	if not frames.is_empty():
		var idx := int(anim_timer * animation_fps) % frames.size()
		cur_tex = frames[idx]
	
	var pw: float = sprite_size.x
	var ph: float = sprite_size.y
	# Centered around the collision center (Vector2(0, -14))
	var draw_rect_dest := Rect2(-pw * 0.5, -14.0 - ph * 0.5, pw, ph)
	
	# 1. Anti-Gravity Hover Repulsor Exhaust Rings & Jet Flame
	var nozzle_y := -14.0 + ph * 0.44
	var ring_prog := fposmod(hover_timer * 2.6, 1.0)
	var ring_w := 10.0 + ring_prog * 18.0
	var ring_h := 3.0 + ring_prog * 5.0
	var ring_a := (1.0 - ring_prog) * 0.50
	var ring_col := Color(thruster_col.r, thruster_col.g, thruster_col.b, ring_a)
	
	# Concentric repulsor shockwave ellipse
	draw_arc(Vector2(0.0, nozzle_y + 4.0 + ring_prog * 6.0), ring_w * 0.5, 0.0, TAU, 20, ring_col, 1.2)
	
	# Pulsing anti-grav thruster jet glow
	var jet_pulse := 0.75 + 0.25 * sin(hover_timer * 22.0)
	draw_circle(Vector2(-6.5, nozzle_y + 1.0), 2.8 * jet_pulse, Color(thruster_col.r, thruster_col.g, thruster_col.b, 0.75))
	draw_circle(Vector2(6.5, nozzle_y + 1.0), 2.8 * jet_pulse, Color(thruster_col.r, thruster_col.g, thruster_col.b, 0.75))
	draw_circle(Vector2(-6.5, nozzle_y + 1.0), 1.4 * jet_pulse, Color.WHITE)
	draw_circle(Vector2(6.5, nozzle_y + 1.0), 1.4 * jet_pulse, Color.WHITE)
	
	# 2. Main Themed Sensor Drone Body
	if cur_tex != null:
		var col: Color = Color(2.0, 0.5, 0.5) if flash_timer > 0.0 else Color.WHITE
		draw_texture_rect(cur_tex, draw_rect_dest, false, col)
		
		# Auxiliary dynamic scanning laser bloom
		var pulse := 0.5 + 0.5 * sin(anim_timer * (animation_fps * 1.5))
		var sweep_y := -14.0 + sin(anim_timer * 5.5) * 3.5
		draw_line(Vector2(-pw * 0.28, sweep_y), Vector2(pw * 0.28, sweep_y), Color(core_glow_col.r, core_glow_col.g, core_glow_col.b, 0.40 * pulse), 1.4)
		return
	
	# Procedural fallback if textures missing
	var base_col := Color(0.35, 0.40, 0.50) if flash_timer <= 0.0 else Color(1.0, 0.4, 0.4)
	draw_circle(Vector2(0.0, -14.0), 14.0, Color(0.1, 0.12, 0.16))
	draw_circle(Vector2(0.0, -14.0), 12.0, base_col)
	var glow := 0.5 + 0.5 * sin(anim_timer * 8.0)
	draw_circle(Vector2(0.0, -14.0), 6.5, Color(core_glow_col.r, core_glow_col.g, core_glow_col.b, 0.5 + 0.5 * glow))
	draw_circle(Vector2(0.0, -14.0), 3.0, Color(1.0, 0.9, 0.4))
