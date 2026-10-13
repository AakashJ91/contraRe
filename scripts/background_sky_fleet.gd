class_name BackgroundSkyFleet
extends Node2D

# =============================================================================
# BACKGROUND SKY FLEET - DYNAMIC FLOCKS & ATMOSPHERIC AIRBORNE OBJECTS
# =============================================================================

@export var stage_theme: int = 1

var flyers: Array[Dictionary] = []
var spawn_timer_flock: float = 2.0
var spawn_timer_vehicle: float = 5.0
var cloud_drift_timer: float = 0.0
var last_cam_x: float = -99999.0

# Preloaded textures for maximum rendering performance
var tex_bird_frames: Array[Texture2D] = []
var tex_bat_frames: Array[Texture2D] = []
var tex_jet_frames: Array[Texture2D] = []
var tex_blimp_frames: Array[Texture2D] = []
var tex_vtol_frames: Array[Texture2D] = []

func _ready() -> void:
	z_index = -3
	_load_textures()
	_initial_sky_population()

func _load_textures() -> void:
	tex_bird_frames.clear()
	tex_bat_frames.clear()
	tex_jet_frames.clear()
	tex_blimp_frames.clear()
	tex_vtol_frames.clear()
	
	for i in range(4):
		var p_bird := "res://assets/bg_sky/bird_flap_%d.png" % i
		if ResourceLoader.exists(p_bird):
			tex_bird_frames.append(load(p_bird))
		
		var p_bat := "res://assets/bg_sky/alien_bat_%d.png" % i
		if ResourceLoader.exists(p_bat):
			tex_bat_frames.append(load(p_bat))
		
		var p_jet := "res://assets/bg_sky/stealth_jet_%d.png" % i
		if ResourceLoader.exists(p_jet):
			tex_jet_frames.append(load(p_jet))
		
		var p_blimp := "res://assets/bg_sky/recon_blimp_%d.png" % i
		if ResourceLoader.exists(p_blimp):
			tex_blimp_frames.append(load(p_blimp))
		
		var p_vtol := "res://assets/bg_sky/sky_vtol_%d.png" % i
		if ResourceLoader.exists(p_vtol):
			tex_vtol_frames.append(load(p_vtol))

func _initial_sky_population() -> void:
	flyers.clear()
	# Pre-populate 1 flock and 1 vehicle in the sky for instant visual spectacle
	_spawn_flock(randf_range(150.0, 750.0))
	_spawn_vehicle(randf_range(200.0, 700.0))

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	
	# Compute camera horizontal delta for parallax scrolling
	var cam_dx: float = 0.0
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		if last_cam_x > -90000.0:
			cam_dx = cam.global_position.x - last_cam_x
		last_cam_x = cam.global_position.x
	
	# Periodic flock spawning (calm ambient interval)
	spawn_timer_flock -= delta
	if spawn_timer_flock <= 0.0:
		spawn_timer_flock = randf_range(25.0, 48.0)
		_spawn_flock(-60.0 if randf() > 0.3 else 1020.0)
	
	# Periodic vehicle / high-altitude craft spawning
	spawn_timer_vehicle -= delta
	if spawn_timer_vehicle <= 0.0:
		spawn_timer_vehicle = randf_range(35.0, 65.0)
		_spawn_vehicle(-80.0 if randf() > 0.4 else 1040.0)
	
	# Update active flyers
	for i in range(flyers.size() - 1, -1, -1):
		var f: Dictionary = flyers[i]
		f["time_alive"] += delta
		f["anim_timer"] += delta * f["anim_fps"]
		
		# Glide vs flap cycle for birds
		if f["type"] == "bird":
			f["glide_timer"] -= delta
			if f["glide_timer"] <= 0.0:
				f["is_gliding"] = not f["is_gliding"]
				f["glide_timer"] = randf_range(1.5, 3.5) if f["is_gliding"] else randf_range(1.2, 2.5)
		
		# Update horizontal position (gentle ambient cruise + subtle camera parallax)
		f["x"] += f["speed"] * f["direction"] * delta - cam_dx * 0.06
		
		# Sinusoidal vertical undulating flight
		var bob: float = sin(t * float(f["bob_freq"]) + float(f["bob_phase"])) * float(f["bob_amp"])
		f["y"] = float(f["base_y"]) + bob
		
		# Vapor trail history for stealth jets
		if f["type"] == "jet":
			f["trail_timer"] += delta
			if f["trail_timer"] >= 0.08:
				f["trail_timer"] = 0.0
				var engine_x: float = float(f["x"]) - float(f["direction"]) * 16.0
				f["trail"].append(Vector2(engine_x, float(f["y"])))
				if f["trail"].size() > 16:
					f["trail"].remove_at(0)
		
		# Cleanup off-screen flyers (past margin)
		if f["direction"] > 0 and f["x"] > 1150.0:
			flyers.remove_at(i)
		elif f["direction"] < 0 and f["x"] < -150.0:
			flyers.remove_at(i)
	
	queue_redraw()

func _spawn_flock(start_x: float) -> void:
	var cur_stage := Global.current_stage
	var is_alien := (cur_stage == 3 or cur_stage == 8)
	var dir := 1.0 if start_x < 500.0 else -1.0
	var flock_size := randi_range(2, 4)
	var base_speed := randf_range(38.0, 58.0)
	var base_alt := randf_range(60.0, 220.0)
	
	# Determine species plumage color
	var tint := Color.WHITE
	match cur_stage:
		1: # Jungle: Tropical emerald or amber toucan
			tint = Color(0.85, 1.0, 0.7) if randf() > 0.5 else Color(1.0, 0.9, 0.6)
		2: # Waterfall: Sea gull (clean crisp white/light sky blue)
			tint = Color(0.95, 0.98, 1.0)
		3, 8: # Alien Hive / Sanctum: Bioluminescent bio-bat (violet/magenta)
			tint = Color(0.9, 0.6, 1.0)
		4: # Arctic Tundra: Snow petrel (pure white with ice sheen)
			tint = Color(0.92, 0.96, 1.0)
		5, 6: # Refinery / Dynamo: Industrial raven (dark soot charcoal)
			tint = Color(0.55, 0.60, 0.68)
		7: # Military Hangar: Recon scout drone
			tint = Color(0.75, 0.85, 0.95)
	
	for j in range(flock_size):
		var lead_offset_x := -float(j) * 22.0 * dir + randf_range(-6.0, 6.0)
		var lead_offset_y := float(abs(j - flock_size / 2)) * 14.0 + randf_range(-5.0, 5.0)
		
		flyers.append({
			"type": "alien_bat" if is_alien else "bird",
			"x": start_x + lead_offset_x,
			"y": base_alt + lead_offset_y,
			"base_y": base_alt + lead_offset_y,
			"speed": base_speed + randf_range(-4.0, 4.0),
			"direction": dir,
			"anim_timer": randf_range(0.0, 4.0),
			"anim_fps": randf_range(3.2, 4.5),
			"is_gliding": false,
			"glide_timer": randf_range(1.5, 3.5),
			"bob_freq": randf_range(1.2, 1.8),
			"bob_amp": randf_range(2.5, 5.0),
			"bob_phase": float(j) * 0.8 + randf_range(0.0, 1.0),
			"scale": Vector2.ONE * randf_range(0.85, 1.15),
			"tint": tint,
			"time_alive": 0.0,
			"trail": [],
			"trail_timer": 0.0
		})

func _spawn_vehicle(start_x: float) -> void:
	var cur_stage := Global.current_stage
	var dir := 1.0 if start_x < 500.0 else -1.0
	
	# Pick vehicle type according to stage theme
	var v_type := "jet"
	var alt := randf_range(50.0, 130.0)
	var spd := 120.0
	var scale_val := randf_range(0.9, 1.1)
	
	match cur_stage:
		1: # Jungle: Occasional distant stealth fighter or VTOL helicopter
			if randf() > 0.5:
				v_type = "jet"
				spd = randf_range(110.0, 140.0)
				alt = randf_range(50.0, 100.0)
			else:
				v_type = "vtol"
				spd = randf_range(35.0, 55.0)
				alt = randf_range(80.0, 160.0)
		2: # Waterfall: Military VTOL or Recon Blimp over the river
			if randf() > 0.5:
				v_type = "vtol"
				spd = randf_range(35.0, 50.0)
				alt = randf_range(90.0, 170.0)
			else:
				v_type = "blimp"
				spd = randf_range(14.0, 24.0)
				alt = randf_range(55.0, 110.0)
		3, 8: # Alien Hive / Sanctum: Heavy Alien Bat Matriarch or bio-flyer
			_spawn_flock(start_x)
			return
		4: # Arctic Tundra: Supersonic Stealth Interceptor
			v_type = "jet"
			spd = randf_range(120.0, 160.0)
			alt = randf_range(45.0, 85.0)
		5, 6: # Refinery / Dynamo: Heavy Recon Surveillance Airship
			if randf() > 0.4:
				v_type = "blimp"
				spd = randf_range(14.0, 22.0)
				alt = randf_range(60.0, 120.0)
			else:
				v_type = "jet"
				spd = randf_range(110.0, 140.0)
				alt = randf_range(50.0, 90.0)
		7: # Starport / Hangar: Twin supersonic stealth fighters
			v_type = "jet"
			spd = randf_range(130.0, 170.0)
			alt = randf_range(40.0, 85.0)
	
	flyers.append({
		"type": v_type,
		"x": start_x,
		"y": alt,
		"base_y": alt,
		"speed": spd,
		"direction": dir,
		"anim_timer": 0.0,
		"anim_fps": 6.0 if v_type == "blimp" else (12.0 if v_type == "vtol" else 10.0),
		"is_gliding": false,
		"glide_timer": 0.0,
		"bob_freq": 1.2 if v_type == "blimp" else 2.2,
		"bob_amp": 3.0 if v_type == "blimp" else 1.5,
		"bob_phase": randf_range(0.0, TAU),
		"scale": Vector2.ONE * scale_val,
		"tint": Color.WHITE,
		"time_alive": 0.0,
		"trail": [],
		"trail_timer": 0.0
	})

func _draw() -> void:
	for f in flyers:
		var pos := Vector2(f["x"], f["y"])
		var dir: float = f["direction"]
		var f_type: String = f["type"]
		
		# Draw jet vapor trails
		if f_type == "jet" and not f["trail"].is_empty():
			var trail_pts: Array = f["trail"]
			for k in range(trail_pts.size() - 1):
				var alpha: float = float(k + 1) / float(trail_pts.size()) * 0.45
				var w: float = 1.0 + float(trail_pts.size() - 1 - k) * 0.15
				draw_line(trail_pts[k], trail_pts[k + 1], Color(0.85, 0.95, 1.0, alpha), w)
		
		# Get animation frame texture
		var tex: Texture2D = null
		match f_type:
			"bird":
				if f["is_gliding"] and not tex_bird_frames.is_empty():
					tex = tex_bird_frames[0]
				elif not tex_bird_frames.is_empty():
					var frame_idx := int(f["anim_timer"]) % tex_bird_frames.size()
					tex = tex_bird_frames[frame_idx]
			"alien_bat":
				if not tex_bat_frames.is_empty():
					var frame_idx := int(f["anim_timer"]) % tex_bat_frames.size()
					tex = tex_bat_frames[frame_idx]
			"jet":
				if not tex_jet_frames.is_empty():
					var frame_idx := int(f["anim_timer"]) % tex_jet_frames.size()
					tex = tex_jet_frames[frame_idx]
			"blimp":
				if not tex_blimp_frames.is_empty():
					var frame_idx := int(f["anim_timer"]) % tex_blimp_frames.size()
					tex = tex_blimp_frames[frame_idx]
			"vtol":
				if not tex_vtol_frames.is_empty():
					var frame_idx := int(f["anim_timer"]) % tex_vtol_frames.size()
					tex = tex_vtol_frames[frame_idx]
		
		if tex != null:
			var ts := tex.get_size()
			var s: Vector2 = f["scale"]
			
			# Draw texture flipped if flying left-to-right (sprites natively face right)
			# If dir < 0, flip horizontally
			if dir < 0.0:
				var dst := Rect2(pos.x + ts.x * s.x * 0.5, pos.y - ts.y * s.y * 0.5, -ts.x * s.x, ts.y * s.y)
				draw_texture_rect(tex, dst, false, f["tint"])
			else:
				var dst := Rect2(pos.x - ts.x * s.x * 0.5, pos.y - ts.y * s.y * 0.5, ts.x * s.x, ts.y * s.y)
				draw_texture_rect(tex, dst, false, f["tint"])
