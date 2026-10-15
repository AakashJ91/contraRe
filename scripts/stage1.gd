extends Node2D

@export var soldier_scene: PackedScene = preload("res://scenes/enemy_soldier.tscn")
@export var turret_scene: PackedScene = preload("res://scenes/enemy_turret.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/enemy_sniper.tscn")
@export var blimp_scene: PackedScene = preload("res://scenes/powerup_blimp.tscn")
@export var sensor_scene: PackedScene = preload("res://scenes/powerup_sensor.tscn")
@export var drone_scene: PackedScene = preload("res://scenes/enemy_drone.tscn")
@export var grenadier_scene: PackedScene = preload("res://scenes/enemy_grenadier.tscn")
@export var crawler_scene: PackedScene = preload("res://scenes/enemy_crawler.tscn")
@export var contra_maker_scene: PackedScene = preload("res://scenes/contra_maker.tscn")
@export var spore_pod_script: GDScript = preload("res://scripts/hazard_spore_pod.gd")
@export var bio_eye_script: GDScript = preload("res://scripts/hazard_bio_eye.gd")

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var boss: Node2D = $Boss
@onready var world_colliders: StaticBody2D = $WorldColliders

var contra_maker: ContraMaker = null

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var soldier_spawn_timer: float = 2.0
var drone_spawn_timer: float = 5.0
var blimp_spawn_timer: float = 7.0
var blimp_index: int = 0
var anim_timer: float = 0.0

# Dynamic Stage Hazard States
var rope_bridge_states: Array[Dictionary] = []
var hydraulic_lifts: Array[Dictionary] = []
var falling_icicles: Array[Dictionary] = []
var flame_vents: Array[Dictionary] = []
var tesla_arcs: Array[Dictionary] = []
var security_tripwires: Array[Dictionary] = []
var psychic_pulse_timer: float = 8.5
var psychic_pulse_active: float = 0.0

const LEVEL_MIN_X: float = 0.0
const LEVEL_MAX_X: float = 6700.0
const BOSS_TRIGGER_X: float = 5800.0

var bg_texture: Texture2D = null
var ground_tile_texture: Texture2D = null
var ground_textures_by_stage: Dictionary = {}
var platform_girder_texture: Texture2D = null
var platform_bridge_texture: Texture2D = null
var platform_turf_texture: Texture2D = null
var platform_tech_texture: Texture2D = null
var platform_chain_texture: Texture2D = null
var platform_chain_hook_texture: Texture2D = null
var ground_edge_right_texture: Texture2D = null
var ground_edge_left_texture: Texture2D = null
var ground_edge_left_textures_by_stage: Dictionary = {}
var ground_edge_right_textures_by_stage: Dictionary = {}
var water_surface_frames: Array[Texture2D] = []
var water_deep_texture: Texture2D = null

enum PlatformType {
	TURF,
	GIRDER,
	ROPE_BRIDGE,
	HIGH_PERCH,
	ICE_SLAB,
	LAVA_GRATE,
	ENERGY_BARRIER,
	TECH_CATWALK,
	BIO_RIB
}

var ground_segments: Array[Rect2] = []
var platforms: Array[Dictionary] = []

func _ready() -> void:
	Global.screen_shake_requested.connect(_on_screen_shake)
	Global.maker_mode_toggled.connect(_on_maker_mode_toggled)
	_load_textures()
	_init_stage_geometry()
	_setup_background()
	_setup_colliders()
	_setup_static_enemies()
	_setup_animated_bg_props()
	
	if contra_maker_scene != null:
		contra_maker = contra_maker_scene.instantiate()
		add_child(contra_maker)
		contra_maker.setup(self, camera)
		if Global.is_maker_mode:
			contra_maker.open_editor()
	
	if camera != null:
		var is_mob: bool = Global.is_mobile_device()
		var entry_zoom := Vector2(1.75, 1.75) if is_mob else Vector2(1.60, 1.60)
		camera.zoom = entry_zoom
		var cur_half_w: float = (960.0 / entry_zoom.x) * 0.5
		var cur_half_h: float = (540.0 / entry_zoom.y) * 0.5
		var p_x: float = player.global_position.x if (player != null and is_instance_valid(player)) else 100.0
		var p_y: float = player.global_position.y if (player != null and is_instance_valid(player)) else 410.0
		camera.global_position = Vector2(clampf(p_x + 80.0, cur_half_w, 5800.0), clampf(p_y - 30.0, cur_half_h, 540.0 - cur_half_h))
	
	queue_redraw()

func _load_textures() -> void:
	if ResourceLoader.exists("res://assets/tiles/ground_tile.png"):
		ground_tile_texture = load("res://assets/tiles/ground_tile.png")
	
	ground_textures_by_stage.clear()
	ground_textures_by_stage[1] = ground_tile_texture
	if ResourceLoader.exists("res://assets/tiles/ground_waterfall.png"):
		ground_textures_by_stage[2] = load("res://assets/tiles/ground_waterfall.png")
	if ResourceLoader.exists("res://assets/tiles/ground_hive.png"):
		ground_textures_by_stage[3] = load("res://assets/tiles/ground_hive.png")
		ground_textures_by_stage[8] = ground_textures_by_stage[3]
	if ResourceLoader.exists("res://assets/tiles/ground_tundra.png"):
		ground_textures_by_stage[4] = load("res://assets/tiles/ground_tundra.png")
	if ResourceLoader.exists("res://assets/tiles/ground_refinery.png"):
		ground_textures_by_stage[5] = load("res://assets/tiles/ground_refinery.png")
	if ResourceLoader.exists("res://assets/tiles/ground_dynamo.png"):
		ground_textures_by_stage[6] = load("res://assets/tiles/ground_dynamo.png")
	if ResourceLoader.exists("res://assets/tiles/ground_hangar.png"):
		ground_textures_by_stage[7] = load("res://assets/tiles/ground_hangar.png")
	if ResourceLoader.exists("res://assets/tiles/platform_girder.png"):
		platform_girder_texture = load("res://assets/tiles/platform_girder.png")
	if ResourceLoader.exists("res://assets/tiles/platform_bridge.png"):
		platform_bridge_texture = load("res://assets/tiles/platform_bridge.png")
	if ResourceLoader.exists("res://assets/tiles/platform_turf.png"):
		platform_turf_texture = load("res://assets/tiles/platform_turf.png")
	if ResourceLoader.exists("res://assets/tiles/platform_tech.png"):
		platform_tech_texture = load("res://assets/tiles/platform_tech.png")
	if ResourceLoader.exists("res://assets/tiles/platform_chain.png"):
		platform_chain_texture = load("res://assets/tiles/platform_chain.png")
	if ResourceLoader.exists("res://assets/tiles/platform_chain_hook.png"):
		platform_chain_hook_texture = load("res://assets/tiles/platform_chain_hook.png")
	ground_edge_left_textures_by_stage.clear()
	ground_edge_right_textures_by_stage.clear()
	if ResourceLoader.exists("res://assets/tiles/ground_edge_left.png"):
		ground_edge_left_texture = load("res://assets/tiles/ground_edge_left.png")
		ground_edge_left_textures_by_stage[1] = ground_edge_left_texture
	if ResourceLoader.exists("res://assets/tiles/ground_edge_right.png"):
		ground_edge_right_texture = load("res://assets/tiles/ground_edge_right.png")
		ground_edge_right_textures_by_stage[1] = ground_edge_right_texture

	var edge_stage_names: Dictionary = {
		2: "waterfall",
		3: "hive",
		4: "tundra",
		5: "refinery",
		6: "dynamo",
		7: "hangar",
	}
	for st_id in edge_stage_names:
		var sname: String = edge_stage_names[st_id]
		var l_path := "res://assets/tiles/ground_%s_edge_left.png" % sname
		var r_path := "res://assets/tiles/ground_%s_edge_right.png" % sname
		if ResourceLoader.exists(l_path):
			ground_edge_left_textures_by_stage[st_id] = load(l_path)
		if ResourceLoader.exists(r_path):
			ground_edge_right_textures_by_stage[st_id] = load(r_path)
	
	if ground_edge_left_textures_by_stage.has(3):
		ground_edge_left_textures_by_stage[8] = ground_edge_left_textures_by_stage[3]
	if ground_edge_right_textures_by_stage.has(3):
		ground_edge_right_textures_by_stage[8] = ground_edge_right_textures_by_stage[3]
	
	water_surface_frames.clear()
	for i in range(4):
		var wp := "res://assets/tiles/water_surface_%d.png" % i
		if ResourceLoader.exists(wp):
			water_surface_frames.append(load(wp))
	if ResourceLoader.exists("res://assets/tiles/water_body_deep.png"):
		water_deep_texture = load("res://assets/tiles/water_body_deep.png")

func _init_stage_geometry() -> void:
	ground_segments.clear()
	platforms.clear()
	var map_data: Dictionary = LevelMaps.get_map_data(Global.current_stage)
	for g in map_data.get("ground_segments", []):
		ground_segments.append(g)
	for p in map_data.get("platforms", []):
		platforms.append(p)
	_init_stage_hazards()

func _init_stage_hazards() -> void:
	rope_bridge_states.clear()
	hydraulic_lifts.clear()
	falling_icicles.clear()
	flame_vents.clear()
	tesla_arcs.clear()
	security_tripwires.clear()
	psychic_pulse_timer = 8.5
	psychic_pulse_active = 0.0
	
	match Global.current_stage:
		1: # JUNGLE: Track rope bridges for collapsing mechanic
			for i in range(platforms.size()):
				if platforms[i]["type"] == PlatformType.ROPE_BRIDGE:
					rope_bridge_states.append({
						"platform_index": i,
						"shake_timer": 0.0,
						"is_collapsed": false,
						"rebuild_timer": 0.0,
						"shake_offset": 0.0
					})
		4: # TUNDRA: Hanging sharp icicles under ice platforms
			for p in platforms:
				if p["type"] == PlatformType.ICE_SLAB:
					var pr: Rect2 = p["rect"]
					falling_icicles.append({
						"pos": Vector2(pr.position.x + pr.size.x * 0.32, pr.position.y + 20.0),
						"initial_pos": Vector2(pr.position.x + pr.size.x * 0.32, pr.position.y + 20.0),
						"vel_y": 0.0,
						"state": 0, # 0=HANGING, 1=TREMBLING, 2=FALLING, 3=SHATTERED
						"timer": 0.0
					})
					falling_icicles.append({
						"pos": Vector2(pr.position.x + pr.size.x * 0.68, pr.position.y + 20.0),
						"initial_pos": Vector2(pr.position.x + pr.size.x * 0.68, pr.position.y + 20.0),
						"vel_y": 0.0,
						"state": 0,
						"timer": 0.0
					})
		5: # REFINERY: Molten flame geysers in foundry chasms
			var vent_xs := [730.0, 1530.0, 2330.0, 3230.0, 4130.0, 5030.0]
			for vx in vent_xs:
				flame_vents.append({
					"pos": Vector2(vx, 455.0),
					"state": 0, # 0=Dormant, 1=Warning, 2=Erupting
					"timer": randf_range(1.5, 3.8)
				})
		6: # DYNAMO: High-voltage tesla lightning coils across chasms
			for i in range(ground_segments.size() - 1):
				var pit_l := ground_segments[i].end.x
				var pit_r := ground_segments[i + 1].position.x
				if (i % 2 == 1):
					tesla_arcs.append({
						"start": Vector2(pit_l - 10.0, 375.0),
						"end": Vector2(pit_r + 10.0, 375.0),
						"cycle": randf_range(0.0, 3.0),
						"active_dur": 0.85,
						"period": 3.0
					})
		7: # HANGAR: Moving hydraulic elevator lifts and laser tripwires
			for idx in [2, 5, 8, 11, 14]:
				if idx < platforms.size():
					var pr: Rect2 = platforms[idx]["rect"]
					hydraulic_lifts.append({
						"platform_index": idx,
						"base_y": pr.position.y,
						"amp": 68.0,
						"speed": 1.5,
						"phase": float(idx) * 1.2
					})
			for tw_x in [1350.0, 2600.0, 4100.0]:
				security_tripwires.append({
					"x": tw_x,
					"top_y": 140.0,
					"bottom_y": 440.0,
					"triggered": false
				})


func _setup_background() -> void:
	for c in get_children():
		if c is ParallaxBackground or c.name == "SkyFleetCanvas" or c.is_in_group("sky_fleet"):
			c.queue_free()
	
	var bg_names: Array[String] = [
		"stage1_jungle.jpg",
		"stage2_waterfall.jpg",
		"stage3_alien_hive.jpg",
		"stage4_tundra.jpg",
		"stage5_refinery.jpg",
		"stage6_dynamo.jpg",
		"stage7_hangar.jpg",
		"stage8_sanctum.jpg"
	]
	var idx := clampi(Global.current_stage - 1, 0, bg_names.size() - 1)
	var bg_path := "res://assets/backgrounds/" + bg_names[idx]
	
	var p_bg := ParallaxBackground.new()
	p_bg.layer = -10
	add_child(p_bg)
	
	if ResourceLoader.exists(bg_path):
		bg_texture = load(bg_path)
		var p_layer := ParallaxLayer.new()
		p_layer.motion_scale = Vector2(0.3, 0.0)
		var tile_w: float = 960.0
		var tile_h: float = 540.0
		p_layer.motion_mirroring = Vector2(tile_w, 0.0)
		p_bg.add_child(p_layer)
		
		var tex_size := bg_texture.get_size()
		var spr_scale := Vector2(tile_w / tex_size.x, tile_h / tex_size.y)
		
		# Tile contiguous sprites inside the ParallaxLayer so that on any screen aspect ratio
		# (16:9, ultrawide, mobile 20:9), the background spans seamlessly with zero gaps
		for s_idx in range(3):
			var spr := Sprite2D.new()
			spr.texture = bg_texture
			spr.scale = spr_scale
			spr.position = Vector2(float(s_idx) * tile_w, 0.0)
			spr.centered = false
			p_layer.add_child(spr)
	else:
		# Procedural Atmospheric Parallax Layers fallback
		var p_sky := ParallaxLayer.new()
		p_sky.motion_scale = Vector2(0.15, 0.0)
		p_sky.motion_mirroring = Vector2(960.0, 0.0)
		p_bg.add_child(p_sky)
		
		var sky_node := ProceduralSkyLayer.new()
		sky_node.stage_idx = Global.current_stage
		p_sky.add_child(sky_node)
	
	# Dynamic Ambient Sky Fleet (Birds, Bats, Supersonic Jets, Recon Blimps & VTOLs)
	var sky_canvas := CanvasLayer.new()
	sky_canvas.layer = -9
	sky_canvas.name = "SkyFleetCanvas"
	add_child(sky_canvas)
	
	var sky_script: GDScript = preload("res://scripts/background_sky_fleet.gd")
	if sky_script != null:
		var sky_fleet = sky_script.new()
		sky_fleet.stage_theme = Global.current_stage
		sky_fleet.add_to_group("sky_fleet")
		sky_canvas.add_child(sky_fleet)

class ProceduralSkyLayer extends Node2D:
	var stage_idx: int = 4
	
	func _draw() -> void:
		match stage_idx:
			4: # Arctic Tundra Blizzard
				draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.10, 0.16, 0.26))
				for i in range(5):
					var mx := float(i) * 220.0 - 50.0
					var pts := PackedVector2Array([Vector2(mx, 540.0), Vector2(mx + 110.0, 160.0), Vector2(mx + 220.0, 540.0)])
					draw_colored_polygon(pts, Color(0.25, 0.38, 0.55))
			5: # Refinery Smelting Skyline
				draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.14, 0.06, 0.04))
				draw_rect(Rect2(0.0, 240.0, 960.0, 300.0), Color(0.35, 0.12, 0.04))
				for i in range(8):
					var sx := float(i) * 130.0 + 30.0
					draw_rect(Rect2(sx, 120.0, 24.0, 220.0), Color(0.22, 0.15, 0.15))
			6: # Electric Dynamo Grid
				draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.04, 0.08, 0.16))
				for i in range(6):
					var tx := float(i) * 170.0 + 40.0
					draw_line(Vector2(tx, 540.0), Vector2(tx + 40.0, 120.0), Color(0.2, 0.5, 0.8, 0.4), 3.0)
					draw_line(Vector2(tx + 80.0, 540.0), Vector2(tx + 40.0, 120.0), Color(0.2, 0.5, 0.8, 0.4), 3.0)
			7: # Starport Outer Space
				draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.02, 0.03, 0.06))
				draw_circle(Vector2(750.0, 140.0), 55.0, Color(0.65, 0.35, 0.85, 0.7))
				for s in range(30):
					var spx := fmod(float(s) * 87.0 + 23.0, 960.0)
					var spy := fmod(float(s) * 53.0 + 17.0, 420.0)
					draw_circle(Vector2(spx, spy), 1.5, Color.WHITE)
			8: # Mother Brain Bio-Chamber
				draw_rect(Rect2(0.0, 0.0, 960.0, 540.0), Color(0.12, 0.03, 0.08))
				for a in range(8):
					var ax := float(a) * 140.0
					draw_line(Vector2(ax, 0.0), Vector2(ax + 40.0, 540.0), Color(0.45, 0.10, 0.20, 0.35), 14.0)

func _setup_colliders() -> void:
	if world_colliders == null:
		return
	for c in world_colliders.get_children():
		c.queue_free()
	
	for g in ground_segments:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = g.size
		c.shape = s
		c.position = g.position + g.size * 0.5
		world_colliders.add_child(c)
	
	for p in platforms:
		var b: Rect2 = p["rect"]
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = b.size
		c.shape = s
		c.position = b.position + b.size * 0.5
		c.one_way_collision = true
		world_colliders.add_child(c)
		p["collider"] = c

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _physics_process(delta: float) -> void:
	if contra_maker != null and contra_maker.is_active and not contra_maker.is_test_playing:
		if player != null and is_instance_valid(player):
			player.velocity = Vector2.ZERO
		return
	
	if shake_duration > 0.0:
		shake_duration -= delta
		var offset := Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO
	
	if player != null and is_instance_valid(player) and camera != null:
		var is_mob: bool = Global.is_mobile_device()
		var target_zoom: Vector2 = Vector2(1.18, 1.18) if is_mob else Vector2(1.0, 1.0)
		var entry_zoom: Vector2 = Vector2(1.75, 1.75) if is_mob else Vector2(1.60, 1.60)
		
		var t_elapsed: float = Global.STAGE_INTRO_DURATION - Global.stage_intro_timer
		var zoom_anim_dur: float = 1.6
		
		if Global.is_stage_intro_active() and t_elapsed < zoom_anim_dur and not Global.is_maker_mode:
			var zoom_p: float = clampf(t_elapsed / zoom_anim_dur, 0.0, 1.0)
			var zoom_ease: float = 1.0 - pow(1.0 - zoom_p, 3.0)
			camera.zoom = entry_zoom.lerp(target_zoom, zoom_ease)
			
			var cur_half_w: float = (960.0 / camera.zoom.x) * 0.5
			var cur_half_h: float = (540.0 / camera.zoom.y) * 0.5
			var min_y: float = cur_half_h
			var max_y: float = 540.0 - cur_half_h
			
			var entry_cam_x: float = clampf(player.global_position.x + 80.0, cur_half_w, 5800.0)
			var entry_cam_y: float = clampf(player.global_position.y - 30.0, min_y, max_y)
			
			var game_cam_x: float = clampf(player.global_position.x + 120.0, cur_half_w, 5800.0)
			var game_cam_y: float = clampf(280.0 if is_mob else 270.0, min_y, max_y)
			
			camera.global_position.x = lerpf(entry_cam_x, game_cam_x, zoom_ease)
			camera.global_position.y = lerpf(entry_cam_y, game_cam_y, zoom_ease)
		else:
			camera.zoom = target_zoom
			var half_w: float = (960.0 / camera.zoom.x) * 0.5
			var target_cam_x := clampf(player.global_position.x + 120.0, half_w, 5800.0)
			camera.global_position.x = maxf(camera.global_position.x, target_cam_x)
			camera.global_position.y = 280.0 if is_mob else 270.0
		
		if camera.global_position.x >= BOSS_TRIGGER_X and boss != null and is_instance_valid(boss):
			boss.activate()
	
	_process_stage_mechanics(delta)
	
	if camera.global_position.x < BOSS_TRIGGER_X:
		soldier_spawn_timer -= delta
		if soldier_spawn_timer <= 0.0:
			var min_interval := maxf(2.6, 4.2 - float(Global.current_stage) * 0.2)
			var max_interval := maxf(4.2, 6.4 - float(Global.current_stage) * 0.3)
			soldier_spawn_timer = randf_range(min_interval, max_interval)
			_spawn_soldier_wave()
		
		# Rare ambient aerial drone scouts (measured pacing, not constant swarm)
		drone_spawn_timer -= delta
		if drone_spawn_timer <= 0.0:
			drone_spawn_timer = randf_range(30.0, 52.0)
			_spawn_drone_wave()
		
		blimp_spawn_timer -= delta
		if blimp_spawn_timer <= 0.0:
			blimp_spawn_timer = 14.0
			_spawn_flying_blimp()

func _process_stage_mechanics(delta: float) -> void:
	if player == null or not is_instance_valid(player) or player.state == player.PlayerState.DEAD:
		return
	
	var p_pos := player.global_position
	var p_on_floor := player.is_on_floor()
	var cur_stage := Global.current_stage

	match cur_stage:
		1: # JUNGLE: Collapsing rope bridges
			for b in rope_bridge_states:
				var p_idx: int = b["platform_index"]
				if p_idx < platforms.size():
					var p = platforms[p_idx]
					var r: Rect2 = p["rect"]
					var col: CollisionShape2D = p.get("collider", null)
					
					# Detect player standing on this bridge
					if p_on_floor and not b["is_collapsed"] and b["shake_timer"] <= 0.0:
						if p_pos.x >= r.position.x - 6.0 and p_pos.x <= r.end.x + 6.0 and abs(p_pos.y - r.position.y) < 18.0:
							b["shake_timer"] = 0.85
							Global.play_sfx("hit")
							VFX.spawn_dust_puff(Vector2(p_pos.x, r.position.y), 3, Color(0.65, 0.50, 0.35, 0.7))
					
					# Shake countdown
					if b["shake_timer"] > 0.0:
						b["shake_timer"] -= delta
						b["shake_offset"] = sin(b["shake_timer"] * 40.0) * 3.5
						if b["shake_timer"] <= 0.0:
							# Collapse!
							b["is_collapsed"] = true
							b["rebuild_timer"] = 3.6
							b["shake_offset"] = 0.0
							if col != null:
								col.disabled = true
							Global.play_sfx("hit")
							VFX.spawn_dust_puff(Vector2(r.position.x + r.size.x * 0.5, r.position.y + 10.0), 6, Color(0.65, 0.50, 0.35, 0.8))
					
					# Rebuild countdown
					if b["is_collapsed"]:
						b["rebuild_timer"] -= delta
						if b["rebuild_timer"] <= 0.0:
							b["is_collapsed"] = false
							if col != null:
								col.disabled = false
							VFX.spawn_dust_puff(Vector2(r.position.x + r.size.x * 0.5, r.position.y), 4, Color(0.7, 0.7, 0.7, 0.6))

		2: # WATERFALL: Thermal Updrafts over river chasms
			for i in range(ground_segments.size() - 1):
				var pit_l := ground_segments[i].end.x
				var pit_r := ground_segments[i + 1].position.x
				if p_pos.x >= pit_l - 20.0 and p_pos.x <= pit_r + 20.0:
					if not p_on_floor and p_pos.y >= 240.0 and p_pos.y <= 520.0:
						player.in_updraft = true
						if randf() < 0.15:
							VFX.spawn_dust_puff(Vector2(p_pos.x + randf_range(-15.0, 15.0), 485.0), 3, Color(0.8, 0.9, 1.0, 0.5))

		4: # TUNDRA: Low-friction ice sliding + falling stalactite icicles
			if p_on_floor:
				player.is_on_ice = true
			
			for ic in falling_icicles:
				match ic["state"]:
					0: # HANGING
						if abs(p_pos.x - ic["pos"].x) < 42.0 and p_pos.y > ic["pos"].y and p_pos.y < ic["pos"].y + 280.0:
							ic["state"] = 1 # TREMBLING
							ic["timer"] = 0.38
							Global.play_sfx("hit")
							VFX.spawn_dust_puff(ic["pos"], 2, Color(0.85, 0.95, 1.0, 0.6))
					1: # TREMBLING
						ic["timer"] -= delta
						if ic["timer"] <= 0.0:
							ic["state"] = 2 # FALLING
							ic["vel_y"] = 120.0
					2: # FALLING
						ic["vel_y"] += 1250.0 * delta
						ic["pos"].y += ic["vel_y"] * delta
						
						# Player hit check
						if ic["pos"].distance_to(p_pos) < 22.0:
							player.take_damage(1.0)
							ic["state"] = 3 # SHATTERED
							VFX.spawn_hit_sparks(ic["pos"], Vector2.UP, Color(0.7, 0.95, 1.0))
						elif ic["pos"].y >= 435.0:
							ic["state"] = 3 # SHATTERED
							VFX.spawn_dust_puff(ic["pos"], 3, Color(0.8, 0.95, 1.0, 0.8))

		5: # REFINERY: Conveyor Catwalks & Flame Geysers
			# Conveyors
			if p_on_floor:
				for i in range(platforms.size()):
					var p = platforms[i]
					if p["type"] == PlatformType.LAVA_GRATE or p["type"] == PlatformType.TECH_CATWALK:
						var r: Rect2 = p["rect"]
						if p_pos.x >= r.position.x and p_pos.x <= r.end.x and abs(p_pos.y - r.position.y) < 14.0:
							var dir: float = 1.0 if (i % 2 == 0) else -1.0
							player.conveyor_push = dir * 90.0 * delta * 60.0
							break
			
			# Flame vents
			for v in flame_vents:
				v["timer"] -= delta
				if v["timer"] <= 0.0:
					match v["state"]:
						0: # DORMANT -> WARNING
							v["state"] = 1
							v["timer"] = 0.6
						1: # WARNING -> ERUPTING
							v["state"] = 2
							v["timer"] = 1.15
							Global.play_sfx("shoot_spread")
							Global.screen_shake_requested.emit(2.5, 0.3)
						2: # ERUPTING -> DORMANT
							v["state"] = 0
							v["timer"] = randf_range(2.0, 3.8)
				
				# Active flame damage check
				if v["state"] == 2:
					if abs(p_pos.x - v["pos"].x) < 28.0 and p_pos.y <= v["pos"].y + 10.0 and p_pos.y >= v["pos"].y - 170.0:
						player.take_damage(1.0)

		6: # DYNAMO: High-voltage surge barrier cycle & tesla coils
			var surge_phase := fmod(anim_timer, 2.8)
			var is_surging := (surge_phase >= 1.8)
			if is_surging and p_on_floor:
				for p in platforms:
					if p["type"] == PlatformType.ENERGY_BARRIER:
						var r: Rect2 = p["rect"]
						if p_pos.x >= r.position.x and p_pos.x <= r.end.x and abs(p_pos.y - r.position.y) < 14.0:
							player.take_damage(1.0)
							Global.play_sfx("hit")
							VFX.spawn_explosion(p_pos, 0.85, true, false)
							break
			
			# Tesla coils across chasms
			for t in tesla_arcs:
				var t_cycle: float = t["cycle"]
				var t_period: float = t["period"]
				var t_active_dur: float = t["active_dur"]
				var t_phase: float = fmod(anim_timer + t_cycle, t_period)
				var arc_active: bool = (t_phase < t_active_dur)
				if arc_active:
					var t_start: Vector2 = t["start"]
					var t_end: Vector2 = t["end"]
					if p_pos.x >= t_start.x and p_pos.x <= t_end.x and abs(p_pos.y - t_start.y) < 26.0:
						player.take_damage(1.0)
						Global.play_sfx("hit")
						VFX.spawn_explosion(p_pos, 0.9, true, false)

		7: # HANGAR: Hydraulic elevator lifts & security laser tripwires
			for lift in hydraulic_lifts:
				var p_idx: int = lift["platform_index"]
				if p_idx < platforms.size():
					var p = platforms[p_idx]
					var lift_base_y: float = lift["base_y"]
					var lift_speed: float = lift["speed"]
					var lift_phase: float = lift["phase"]
					var lift_amp: float = lift["amp"]
					var new_y: float = lift_base_y + sin(anim_timer * lift_speed + lift_phase) * lift_amp
					var old_y: float = p["rect"].position.y
					var diff_y: float = new_y - old_y
					p["rect"].position.y = new_y
					
					var col: CollisionShape2D = p.get("collider", null)
					if col != null:
						col.position.y = new_y + p["rect"].size.y * 0.5
					
					if p_on_floor:
						var r: Rect2 = p["rect"]
						if p_pos.x >= r.position.x and p_pos.x <= r.end.x and abs(p_pos.y - old_y) < 18.0:
							player.global_position.y += diff_y
			
			# Security tripwires
			for tw in security_tripwires:
				if not tw["triggered"]:
					if abs(p_pos.x - tw["x"]) < 20.0 and p_pos.y >= tw["top_y"] and p_pos.y <= tw["bottom_y"]:
						tw["triggered"] = true
						Global.play_sfx("hit")
						Global.screen_shake_requested.emit(4.0, 0.5)
						if drone_scene != null:
							for d_i in range(2):
								var d = drone_scene.instantiate()
								d.global_position = Vector2(tw["x"] + (180.0 if d_i == 0 else -180.0), 160.0 + float(d_i) * 30.0)
								d.facing_dir = -1 if d_i == 0 else 1
								add_child(d)

		8: # SANCTUM: Psychic Gravitational Distortion Wave
			psychic_pulse_timer -= delta
			if psychic_pulse_timer <= 0.0:
				psychic_pulse_timer = 9.2
				psychic_pulse_active = 2.4
				Global.screen_shake_requested.emit(3.5, 0.9)
				Global.play_sfx("jump")
			
			if psychic_pulse_active > 0.0:
				psychic_pulse_active -= delta
				var distort := sin(anim_timer * 8.0)
				player.stage_gravity_scale = 0.50 if distort > 0.0 else 1.35
			else:
				player.stage_gravity_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	# Advance to next stage when stage clear victory is displayed
	if Global.is_victory:
		if event.is_action_pressed("jump") or event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
			Global.advance_to_next_stage()
		elif (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			if event.position.y > 60.0:
				Global.advance_to_next_stage()

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _on_maker_mode_toggled(is_maker: bool) -> void:
	if contra_maker != null:
		if is_maker:
			contra_maker.open_editor()
		else:
			contra_maker.close_editor()

func _setup_static_enemies() -> void:
	match Global.current_stage:
		1: # JUNGLE PERIMETER
			# Classic fortified bunkers, high lookouts & river gorge bridges
			_spawn_turrets([Vector2(720.0, 435.0), Vector2(1380.0, 435.0), Vector2(2650.0, 435.0), Vector2(3480.0, 280.0), Vector2(4750.0, 435.0), Vector2(5420.0, 435.0)])
			_spawn_snipers([Vector2(530.0, 270.0), Vector2(890.0, 330.0), Vector2(1550.0, 215.0), Vector2(1890.0, 320.0), Vector2(2930.0, 330.0), Vector2(3750.0, 200.0), Vector2(4710.0, 205.0)])
			_spawn_grenadiers([Vector2(3620.0, 275.0), Vector2(5640.0, 250.0)])
			_spawn_crawlers([Vector2(2220.0, 420.0), Vector2(2440.0, 420.0), Vector2(4380.0, 420.0)])
			_spawn_sensors([
				{"pos": Vector2(330.0, 370.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(1280.0, 295.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(2380.0, 275.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(4480.0, 285.0), "weapon": Global.WeaponType.SPREAD}
			])

		2: # WATERFALL FORTRESS
			# Cliffside snipers overlooking waterfall chasms + escarpment turrets
			_spawn_turrets([Vector2(1050.0, 435.0), Vector2(2850.0, 435.0), Vector2(3850.0, 340.0), Vector2(4950.0, 435.0), Vector2(5550.0, 320.0)])
			_spawn_snipers([Vector2(380.0, 270.0), Vector2(710.0, 435.0), Vector2(1280.0, 280.0), Vector2(1610.0, 435.0), Vector2(2200.0, 260.0), Vector2(2510.0, 435.0), Vector2(3150.0, 270.0), Vector2(4150.0, 260.0), Vector2(5250.0, 270.0)])
			_spawn_grenadiers([Vector2(2000.0, 435.0), Vector2(3460.0, 435.0), Vector2(5600.0, 435.0)])
			_spawn_crawlers([Vector2(1400.0, 420.0), Vector2(2950.0, 420.0), Vector2(4350.0, 420.0)])
			_spawn_sensors([
				{"pos": Vector2(300.0, 350.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(1600.0, 430.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(3100.0, 270.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(4800.0, 350.0), "weapon": Global.WeaponType.MACHINE}
			])

		3: # ALIEN HIVE BIO-CAVERN
			# Living spore egg pods + swarming crawlers & bio-snipers
			_spawn_spore_pods([Vector2(400.0, 270.0), Vector2(980.0, 350.0), Vector2(1520.0, 320.0), Vector2(2120.0, 260.0), Vector2(2750.0, 350.0), Vector2(3400.0, 320.0), Vector2(4100.0, 260.0), Vector2(5100.0, 270.0)])
			_spawn_turrets([Vector2(690.0, 320.0), Vector2(1850.0, 350.0), Vector2(3750.0, 350.0), Vector2(4750.0, 435.0), Vector2(5480.0, 320.0)])
			_spawn_snipers([Vector2(220.0, 350.0), Vector2(1200.0, 280.0), Vector2(2420.0, 320.0), Vector2(3050.0, 270.0), Vector2(4400.0, 320.0), Vector2(5300.0, 435.0)])
			_spawn_crawlers([Vector2(550.0, 420.0), Vector2(1100.0, 420.0), Vector2(1950.0, 420.0), Vector2(2850.0, 420.0), Vector2(3800.0, 420.0), Vector2(4800.0, 420.0)])
			_spawn_sensors([
				{"pos": Vector2(260.0, 350.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(1800.0, 340.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(3300.0, 320.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(4900.0, 350.0), "weapon": Global.WeaponType.LASER}
			])

		4: # SNOWFIELD TUNDRA
			# Fortified mortar grenadiers & frost snipers
			_spawn_turrets([Vector2(1320.0, 270.0), Vector2(2640.0, 320.0), Vector2(4000.0, 350.0), Vector2(5040.0, 340.0)])
			_spawn_snipers([Vector2(450.0, 270.0), Vector2(1080.0, 350.0), Vector2(1680.0, 320.0), Vector2(2300.0, 260.0), Vector2(2980.0, 350.0), Vector2(3660.0, 320.0), Vector2(4300.0, 260.0), Vector2(5380.0, 260.0)])
			_spawn_grenadiers([Vector2(760.0, 320.0), Vector2(2020.0, 350.0), Vector2(3300.0, 260.0), Vector2(4660.0, 320.0), Vector2(5500.0, 435.0)])
			_spawn_sensors([
				{"pos": Vector2(320.0, 350.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(1900.0, 350.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(3200.0, 260.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(4500.0, 260.0), "weapon": Global.WeaponType.LASER}
			])

		5: # STEEL REFINERY
			# Conveyor rush, molten foundry turrets & upper mortar posts
			_spawn_turrets([Vector2(420.0, 270.0), Vector2(1450.0, 320.0), Vector2(2520.0, 340.0), Vector2(3750.0, 260.0), Vector2(4980.0, 320.0), Vector2(5650.0, 260.0)])
			_spawn_snipers([Vector2(650.0, 320.0), Vector2(1740.0, 340.0), Vector2(2850.0, 260.0), Vector2(4050.0, 320.0), Vector2(5300.0, 340.0)])
			_spawn_grenadiers([Vector2(920.0, 340.0), Vector2(2000.0, 260.0), Vector2(3150.0, 320.0), Vector2(4350.0, 340.0), Vector2(5200.0, 435.0)])
			_spawn_sensors([
				{"pos": Vector2(280.0, 350.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(1600.0, 340.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(3000.0, 260.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(4800.0, 260.0), "weapon": Global.WeaponType.LASER}
			])

		6: # ELECTRIC DYNAMO
			# High-voltage surge grid, tesla coils & dielectric snipers
			_spawn_turrets([Vector2(440.0, 270.0), Vector2(1580.0, 320.0), Vector2(2800.0, 340.0), Vector2(4150.0, 260.0), Vector2(5520.0, 320.0)])
			_spawn_snipers([Vector2(720.0, 320.0), Vector2(1260.0, 260.0), Vector2(1880.0, 340.0), Vector2(2480.0, 320.0), Vector2(3100.0, 260.0), Vector2(3800.0, 340.0), Vector2(4480.0, 320.0), Vector2(5200.0, 260.0)])
			_spawn_grenadiers([Vector2(1000.0, 340.0), Vector2(2180.0, 260.0), Vector2(3480.0, 320.0), Vector2(4800.0, 340.0)])
			_spawn_sensors([
				{"pos": Vector2(300.0, 350.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(1700.0, 320.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(3300.0, 320.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(4700.0, 340.0), "weapon": Global.WeaponType.SPREAD}
			])

		7: # ALIEN AEROSPACE HANGAR
			# Moving hydraulic elevators, security lasers, orbital gantry turrets
			_spawn_turrets([Vector2(480.0, 270.0), Vector2(1400.0, 260.0), Vector2(2450.0, 260.0), Vector2(3500.0, 260.0), Vector2(4650.0, 260.0), Vector2(5380.0, 340.0)])
			_spawn_snipers([Vector2(250.0, 350.0), Vector2(1100.0, 350.0), Vector2(2120.0, 340.0), Vector2(3150.0, 340.0), Vector2(4250.0, 340.0), Vector2(5200.0, 435.0)])
			_spawn_grenadiers([Vector2(1600.0, 435.0), Vector2(3800.0, 435.0), Vector2(4900.0, 435.0)])
			_spawn_sensors([
				{"pos": Vector2(290.0, 350.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(1900.0, 340.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(3300.0, 340.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(4800.0, 260.0), "weapon": Global.WeaponType.MACHINE}
			])

		8: # MOTHER BRAIN SANCTUM
			# Living bio-eye sentries, egg sacs, heavy crawler packs, final powerups
			_spawn_bio_eyes([Vector2(400.0, 260.0), Vector2(1220.0, 250.0), Vector2(2100.0, 250.0), Vector2(3050.0, 250.0), Vector2(4050.0, 250.0), Vector2(5100.0, 250.0)])
			_spawn_spore_pods([Vector2(200.0, 350.0), Vector2(680.0, 320.0), Vector2(1500.0, 320.0), Vector2(2400.0, 320.0), Vector2(3380.0, 320.0), Vector2(4380.0, 320.0), Vector2(5420.0, 320.0)])
			_spawn_turrets([Vector2(950.0, 340.0), Vector2(1800.0, 340.0), Vector2(2720.0, 340.0), Vector2(3700.0, 340.0), Vector2(4700.0, 340.0)])
			_spawn_crawlers([Vector2(1100.0, 420.0), Vector2(1950.0, 420.0), Vector2(2850.0, 420.0), Vector2(3850.0, 420.0), Vector2(4900.0, 420.0)])
			_spawn_grenadiers([Vector2(2200.0, 435.0), Vector2(4500.0, 435.0), Vector2(5600.0, 435.0)])
			_spawn_sensors([
				{"pos": Vector2(250.0, 350.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(1400.0, 320.0), "weapon": Global.WeaponType.MACHINE},
				{"pos": Vector2(2600.0, 340.0), "weapon": Global.WeaponType.LASER},
				{"pos": Vector2(3900.0, 340.0), "weapon": Global.WeaponType.SPREAD},
				{"pos": Vector2(5200.0, 250.0), "weapon": Global.WeaponType.LASER}
			])

func _spawn_turrets(positions: Array[Vector2]) -> void:
	if turret_scene == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 100.0:
			var t = turret_scene.instantiate()
			t.global_position = pos
			add_child(t)

func _spawn_snipers(positions: Array[Vector2]) -> void:
	if sniper_scene == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 100.0:
			var s = sniper_scene.instantiate()
			s.global_position = pos
			add_child(s)

func _spawn_grenadiers(positions: Array[Vector2]) -> void:
	if grenadier_scene == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 120.0:
			var gr = grenadier_scene.instantiate()
			gr.global_position = pos
			add_child(gr)

func _spawn_crawlers(positions: Array[Vector2]) -> void:
	if crawler_scene == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 150.0:
			var cr = crawler_scene.instantiate()
			cr.global_position = pos
			add_child(cr)

func _spawn_sensors(sensor_pods: Array[Dictionary]) -> void:
	if sensor_scene == null: return
	for pod_info in sensor_pods:
		if pod_info["pos"].x < BOSS_TRIGGER_X - 150.0:
			var pod = sensor_scene.instantiate()
			pod.global_position = pod_info["pos"]
			pod.weapon_type = pod_info["weapon"]
			add_child(pod)

func _spawn_spore_pods(positions: Array[Vector2]) -> void:
	if spore_pod_script == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 120.0:
			var pod = spore_pod_script.new()
			pod.global_position = pos
			add_child(pod)

func _spawn_bio_eyes(positions: Array[Vector2]) -> void:
	if bio_eye_script == null: return
	for pos in positions:
		if pos.x < BOSS_TRIGGER_X - 120.0:
			var eye = bio_eye_script.new()
			eye.global_position = pos
			add_child(eye)

func _setup_animated_bg_props() -> void:
	for c in get_children():
		if c is AnimatedBgProp or c.is_in_group("bg_props"):
			c.queue_free()
	
	var prop_scene: PackedScene = preload("res://scenes/animated_bg_prop.tscn")
	if prop_scene == null:
		return
	
	var res_radar: BgItemData = load("res://resources/bg_props/radar_dish.tres") if ResourceLoader.exists("res://resources/bg_props/radar_dish.tres") else null
	var res_fan: BgItemData = load("res://resources/bg_props/industrial_fan.tres") if ResourceLoader.exists("res://resources/bg_props/industrial_fan.tres") else null
	var res_beacon: BgItemData = load("res://resources/bg_props/warning_beacon.tres") if ResourceLoader.exists("res://resources/bg_props/warning_beacon.tres") else null
	var res_steam: BgItemData = load("res://resources/bg_props/steam_vent.tres") if ResourceLoader.exists("res://resources/bg_props/steam_vent.tres") else null
	var res_term: BgItemData = load("res://resources/bg_props/flickering_terminal.tres") if ResourceLoader.exists("res://resources/bg_props/flickering_terminal.tres") else null
	var res_core: BgItemData = load("res://resources/bg_props/alien_core.tres") if ResourceLoader.exists("res://resources/bg_props/alien_core.tres") else null
	var res_arc: BgItemData = load("res://resources/bg_props/electric_arc.tres") if ResourceLoader.exists("res://resources/bg_props/electric_arc.tres") else null
	var res_waterfall: BgItemData = load("res://resources/bg_props/waterfall_cascade.tres") if ResourceLoader.exists("res://resources/bg_props/waterfall_cascade.tres") else null

	var stage_num := Global.current_stage
	
	for i in range(platforms.size()):
		var p_rect: Rect2 = platforms[i]["rect"]
		var p_type: int = platforms[i]["type"]
		if p_rect.position.x > BOSS_TRIGGER_X - 150.0:
			continue
		
		var chosen_data: BgItemData = null
		var prop_pos := Vector2(p_rect.position.x + p_rect.size.x * 0.5, p_rect.position.y)
		
		# Only place props on suitable platform types (high perches and tech decks, never bridges!)
		if p_type == PlatformType.ROPE_BRIDGE:
			continue
		
		match stage_num:
			1: # Jungle Military Outpost
				if p_type == PlatformType.HIGH_PERCH and res_radar != null and i % 2 == 0:
					chosen_data = res_radar
				elif res_beacon != null and i % 3 == 1:
					chosen_data = res_beacon
			2: # Waterfall & River Basin
				if p_type == PlatformType.HIGH_PERCH and res_waterfall != null and i % 2 == 0:
					chosen_data = res_waterfall
				elif res_beacon != null:
					chosen_data = res_beacon
			3, 8: # Alien Bio-Hive / Sanctum
				if i % 2 == 0 and res_core != null: chosen_data = res_core
				elif res_arc != null: chosen_data = res_arc
			4: # Arctic Tundra
				if i % 3 == 0 and res_steam != null: chosen_data = res_steam
				elif i % 3 == 1 and res_term != null: chosen_data = res_term
				elif res_beacon != null: chosen_data = res_beacon
			5: # Industrial Refinery
				if i % 3 == 0 and res_fan != null: chosen_data = res_fan
				elif i % 3 == 1 and res_steam != null: chosen_data = res_steam
				elif res_beacon != null: chosen_data = res_beacon
			6: # High-Voltage Dynamo
				if i % 3 == 0 and res_arc != null: chosen_data = res_arc
				elif i % 3 == 1 and res_fan != null: chosen_data = res_fan
				elif res_beacon != null: chosen_data = res_beacon
			7: # Military Hangar
				if i % 3 == 0 and res_radar != null: chosen_data = res_radar
				elif i % 3 == 1 and res_term != null: chosen_data = res_term
				elif res_beacon != null: chosen_data = res_beacon
			_:
				chosen_data = res_radar
		
		if chosen_data != null:
			var prop: AnimatedBgProp = prop_scene.instantiate() as AnimatedBgProp
			prop.prop_data = chosen_data
			prop.global_position = prop_pos
			add_child(prop)


func get_safe_respawn_position(target_x: float) -> Vector2:
	for g in ground_segments:
		if target_x >= g.position.x + 40.0 and target_x <= g.end.x - 40.0:
			return Vector2(target_x, 80.0)
	var best_x: float = 200.0
	var min_dist: float = 999999.0
	for g in ground_segments:
		var safe_left := g.position.x + 60.0
		var safe_right := g.end.x - 60.0
		var d_left := absf(target_x - safe_left)
		var d_right := absf(target_x - safe_right)
		if d_left < min_dist:
			min_dist = d_left
			best_x = safe_left
		if d_right < min_dist:
			min_dist = d_right
			best_x = safe_right
	return Vector2(best_x, 80.0)

func is_position_over_ground(pos_x: float) -> bool:
	for g in ground_segments:
		if pos_x >= g.position.x and pos_x <= g.end.x:
			return true
	return false

func _spawn_soldier_wave() -> void:
	if soldier_scene == null or camera == null or player == null or not is_instance_valid(player):
		return
	
	# Cap maximum simultaneous active foot soldiers to 4
	var active_soldiers: int = 0
	for node in get_tree().get_nodes_in_group("foot_soldiers"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			active_soldiers += 1
	if active_soldiers >= 4:
		soldier_spawn_timer = 1.0
		return
	
	var cam_x := camera.global_position.x
	var player_x := player.global_position.x
	if ground_segments.is_empty():
		return
	var cur_seg: Rect2 = ground_segments[0]
	for g in ground_segments:
		if player_x >= g.position.x - 80.0 and player_x <= g.end.x + 80.0:
			cur_seg = g
			break
	
	# 85% spawn ahead running left, 15% spawn behind running right
	var spawn_from_right: bool = randf() > 0.15
	var spawn_x: float
	var initial_facing: int
	
	if spawn_from_right:
		var target_x := minf(cam_x + 460.0, cur_seg.end.x - 40.0)
		if target_x <= player_x + 100.0:
			target_x = cam_x + 460.0
		spawn_x = target_x
		initial_facing = -1
	else:
		var target_x := maxf(cam_x - 460.0, cur_seg.position.x + 40.0)
		if target_x >= player_x - 100.0:
			target_x = cam_x - 460.0
		spawn_x = target_x
		initial_facing = 1
	
	for i in range(ground_segments.size() - 1):
		var pit_start := ground_segments[i].end.x
		var pit_end := ground_segments[i + 1].position.x
		if spawn_x >= pit_start - 20.0 and spawn_x <= pit_end + 20.0:
			spawn_x = pit_end + 40.0 if initial_facing == -1 else pit_start - 40.0
			break
	
	var s: Node2D
	if Global.current_stage == 3 and crawler_scene != null:
		s = crawler_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, 420.0)
		s.add_to_group("foot_soldiers")
	elif Global.current_stage == 8 and crawler_scene != null and randf() < 0.65:
		s = crawler_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, 420.0)
		s.add_to_group("foot_soldiers")
	else:
		s = soldier_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, 420.0)
	add_child(s)

func _spawn_drone_wave() -> void:
	if drone_scene == null or camera == null or player == null or not is_instance_valid(player):
		return
	var cam_x := camera.global_position.x
	var spawn_from_right: bool = randf() > 0.35
	var spawn_x: float = cam_x + 520.0 if spawn_from_right else cam_x - 520.0
	var altitude: float = randf_range(130.0, 210.0)
	
	var count: int = 1
	if Global.current_stage == 6 or Global.current_stage == 7:
		count = 2 if randf() < 0.75 else 3
	elif Global.current_stage >= 3:
		count = 2 if randf() < 0.55 else 1
	for i in range(count):
		var d = drone_scene.instantiate()
		var x_offset := float(i) * 55.0 * (1.0 if spawn_from_right else -1.0)
		var y_offset := float(i) * 28.0
		d.global_position = Vector2(spawn_x + x_offset, altitude + y_offset)
		d.facing_dir = -1 if spawn_from_right else 1
		add_child(d)

func _spawn_flying_blimp() -> void:
	if blimp_scene == null:
		return
	var cam_x := camera.global_position.x
	var spawn_x := cam_x - 300.0
	var b = blimp_scene.instantiate()
	b.global_position = Vector2(spawn_x, randf_range(160.0, 240.0))
	var weapons = [Global.WeaponType.SPREAD, Global.WeaponType.MACHINE, Global.WeaponType.LASER]
	b.weapon_type = weapons[blimp_index % weapons.size()]
	blimp_index += 1
	add_child(b)

func _draw() -> void:
	var cam_x: float = camera.global_position.x if camera != null else 480.0
	var view_left: float = cam_x - 560.0
	var view_right: float = cam_x + 560.0
	_draw_stage_mechanics_background(view_left, view_right)
	_draw_platforms(view_left, view_right)
	_draw_stage_mechanics_foreground(view_left, view_right, cam_x)
	_draw_weather_particles(view_left, view_right)

func _draw_stage_mechanics_background(view_left: float, view_right: float) -> void:
	match Global.current_stage:
		2: # WATERFALL: Buoyant thermal updraft mist columns over chasms
			for i in range(ground_segments.size() - 1):
				var pit_l := ground_segments[i].end.x
				var pit_r := ground_segments[i + 1].position.x
				var pit_w := pit_r - pit_l
				if pit_r >= view_left - 40.0 and pit_l <= view_right + 40.0:
					for m in range(5):
						var mx := pit_l + float(m + 1) * (pit_w / 6.0)
						var my := 480.0 - fmod(anim_timer * 135.0 + float(m) * 55.0, 240.0)
						var alpha := clampf((480.0 - my) / 240.0, 0.0, 1.0) * 0.38
						draw_circle(Vector2(mx + sin(anim_timer * 2.5 + float(m)) * 12.0, my), 16.0, Color(0.75, 0.92, 1.0, alpha))
		3, 8: # ALIEN HIVE & SANCTUM: Bubbling corrosive acid chasms
			for i in range(ground_segments.size() - 1):
				var pit_l := ground_segments[i].end.x
				var pit_r := ground_segments[i + 1].position.x
				var pit_w := pit_r - pit_l
				if pit_r >= view_left - 40.0 and pit_l <= view_right + 40.0:
					draw_rect(Rect2(pit_l, 490.0, pit_w, 50.0), Color(0.85, 0.15, 0.35, 0.9))
					for b in range(5):
						var bx := pit_l + fmod(float(b) * 45.0 + anim_timer * 22.0, pit_w)
						var by := 490.0 - sin(anim_timer * 5.0 + float(b)) * 5.0
						draw_circle(Vector2(bx, by), 3.5, Color(1.0, 0.45, 0.65, 0.8))
		5: # REFINERY: Molten flame geysers
			for v in flame_vents:
				if v["pos"].x >= view_left - 50.0 and v["pos"].x <= view_right + 50.0:
					draw_rect(Rect2(v["pos"].x - 16.0, v["pos"].y, 32.0, 16.0), Color(0.18, 0.12, 0.10))
					draw_rect(Rect2(v["pos"].x - 12.0, v["pos"].y + 2.0, 24.0, 6.0), Color(0.95, 0.35, 0.05))
					if v["state"] == 1:
						for s in range(3):
							var sy: float = v["pos"].y - float(s) * 12.0 - fmod(anim_timer * 40.0, 30.0)
							draw_circle(Vector2(v["pos"].x + randf_range(-6.0, 6.0), sy), 2.5, Color(1.0, 0.7, 0.2, 0.75))
					elif v["state"] == 2:
						var flame_h := 160.0 + sin(anim_timer * 25.0) * 15.0
						var pts := PackedVector2Array([
							Vector2(v["pos"].x - 18.0, v["pos"].y),
							Vector2(v["pos"].x - 12.0, v["pos"].y - flame_h * 0.6),
							Vector2(v["pos"].x, v["pos"].y - flame_h),
							Vector2(v["pos"].x + 12.0, v["pos"].y - flame_h * 0.6),
							Vector2(v["pos"].x + 18.0, v["pos"].y)
						])
						draw_colored_polygon(pts, Color(1.0, 0.35, 0.05, 0.95))
						var core_pts := PackedVector2Array([
							Vector2(v["pos"].x - 8.0, v["pos"].y),
							Vector2(v["pos"].x, v["pos"].y - flame_h * 0.75),
							Vector2(v["pos"].x + 8.0, v["pos"].y)
						])
						draw_colored_polygon(core_pts, Color(1.0, 0.95, 0.7, 0.95))
		6: # DYNAMO: Tesla coils across chasms
			for t in tesla_arcs:
				var t_start: Vector2 = t["start"]
				var t_end: Vector2 = t["end"]
				if t_end.x >= view_left - 40.0 and t_start.x <= view_right + 40.0:
					draw_rect(Rect2(t_start.x - 4.0, t_start.y - 12.0, 8.0, 24.0), Color(0.2, 0.3, 0.45))
					draw_rect(Rect2(t_end.x - 4.0, t_end.y - 12.0, 8.0, 24.0), Color(0.2, 0.3, 0.45))
					draw_circle(t_start, 6.0, Color(0.4, 0.85, 1.0))
					draw_circle(t_end, 6.0, Color(0.4, 0.85, 1.0))
					var t_phase: float = fmod(anim_timer + float(t["cycle"]), float(t["period"]))
					if t_phase < float(t["active_dur"]):
						var segs := 6
						var seg_w: float = (t_end.x - t_start.x) / float(segs)
						var prev_pt: Vector2 = t_start
						for s in range(1, segs):
							var cur_x: float = t_start.x + float(s) * seg_w
							var cur_y: float = t_start.y + sin(anim_timer * 35.0 + float(s)) * 14.0
							var cur_pt := Vector2(cur_x, cur_y)
							draw_line(prev_pt, cur_pt, Color(0.85, 0.95, 1.0), 3.0)
							draw_line(prev_pt, cur_pt, Color(0.2, 0.8, 1.0, 0.6), 6.0)
							prev_pt = cur_pt
						draw_line(prev_pt, t_end, Color(0.85, 0.95, 1.0), 3.0)
		7: # HANGAR: Hydraulic elevator chrome pistons
			for lift in hydraulic_lifts:
				var p_idx: int = lift["platform_index"]
				if p_idx < platforms.size():
					var p = platforms[p_idx]
					var r: Rect2 = p["rect"]
					if r.end.x >= view_left and r.position.x <= view_right:
						var piston_offsets: Array[float] = [0.25, 0.75]
						for c_i: float in piston_offsets:
							var cx: float = r.position.x + r.size.x * c_i
							var top_p := Vector2(cx, r.position.y + 24.0)
							var bot_p := Vector2(cx, 440.0)
							draw_line(top_p, bot_p, Color(0.32, 0.40, 0.50), 7.0)
							draw_line(top_p, bot_p, Color(0.85, 0.92, 1.0), 2.5)

func _draw_stage_mechanics_foreground(view_left: float, view_right: float, cam_x: float) -> void:
	match Global.current_stage:
		4: # TUNDRA: Falling icicles
			for ic in falling_icicles:
				if ic["state"] == 2: # FALLING
					var ip: Vector2 = ic["pos"]
					if ip.x >= view_left - 20.0 and ip.x <= view_right + 20.0:
						var pts := PackedVector2Array([
							Vector2(ip.x - 4.0, ip.y - 18.0),
							Vector2(ip.x + 4.0, ip.y - 18.0),
							Vector2(ip.x, ip.y)
						])
						draw_colored_polygon(pts, Color(0.70, 0.92, 1.0, 0.95))
						draw_line(Vector2(ip.x, ip.y - 18.0), Vector2(ip.x, ip.y), Color.WHITE, 1.2)
		7: # HANGAR: Security laser tripwires
			for tw in security_tripwires:
				if tw["x"] >= view_left - 30.0 and tw["x"] <= view_right + 30.0:
					draw_rect(Rect2(tw["x"] - 6.0, tw["top_y"] - 8.0, 12.0, 16.0), Color(0.2, 0.2, 0.25))
					draw_rect(Rect2(tw["x"] - 6.0, tw["bottom_y"] - 8.0, 12.0, 16.0), Color(0.2, 0.2, 0.25))
					if not tw["triggered"]:
						var pulse := 0.7 + 0.3 * sin(anim_timer * 12.0)
						draw_line(Vector2(tw["x"], tw["top_y"]), Vector2(tw["x"], tw["bottom_y"]), Color(1.0, 0.1, 0.1, 0.85 * pulse), 2.0)
						draw_line(Vector2(tw["x"], tw["top_y"]), Vector2(tw["x"], tw["bottom_y"]), Color(1.0, 0.6, 0.6, 0.45 * pulse), 4.5)
					else:
						if sin(anim_timer * 20.0) > 0.0:
							draw_circle(Vector2(tw["x"], tw["top_y"]), 8.0, Color(1.0, 0.2, 0.2, 0.8))
							draw_circle(Vector2(tw["x"], tw["bottom_y"]), 8.0, Color(1.0, 0.2, 0.2, 0.8))
		8: # SANCTUM: Full-screen psychic distortion wave overlay
			if psychic_pulse_active > 0.0:
				var pulse_alpha := (psychic_pulse_active / 2.4) * 0.30 * (0.6 + 0.4 * sin(anim_timer * 14.0))
				var vp_rect := Rect2(view_left, 0.0, view_right - view_left, 540.0)
				draw_rect(vp_rect, Color(0.9, 0.15, 0.65, pulse_alpha))
				for ring in range(3):
					var r_radius := fmod(anim_timer * 220.0 + float(ring) * 90.0, 480.0)
					draw_arc(Vector2(cam_x, 270.0), r_radius, 0.0, TAU, 32, Color(1.0, 0.4, 0.8, pulse_alpha * 0.6), 2.5)

func _draw_platforms(view_left: float, view_right: float) -> void:
	var g_tint := Color.WHITE
	var p_tint := Color.WHITE
	var col_dirt := Color(0.35, 0.25, 0.18)
	var col_top := Color(0.2, 0.55, 0.25)
	
	match Global.current_stage:
		1: # Jungle
			g_tint = Color.WHITE
			p_tint = Color.WHITE
			col_dirt = Color(0.35, 0.25, 0.18)
			col_top = Color(0.2, 0.55, 0.25)
		2: # Waterfall
			g_tint = Color(0.75, 0.90, 1.10)
			p_tint = Color(0.85, 0.95, 1.05)
			col_dirt = Color(0.18, 0.25, 0.35)
			col_top = Color(0.20, 0.55, 0.65)
		3: # Hive
			g_tint = Color(1.15, 0.65, 0.70)
			p_tint = Color(1.10, 0.70, 0.75)
			col_dirt = Color(0.25, 0.10, 0.15)
			col_top = Color(0.75, 0.20, 0.30)
		4: # Tundra
			g_tint = Color(0.80, 0.95, 1.15)
			p_tint = Color(0.85, 0.98, 1.10)
			col_dirt = Color(0.25, 0.38, 0.52)
			col_top = Color(0.92, 0.95, 1.0)
		5: # Refinery
			g_tint = Color(1.20, 0.75, 0.50)
			p_tint = Color(1.15, 0.80, 0.60)
			col_dirt = Color(0.18, 0.15, 0.16)
			col_top = Color(0.95, 0.45, 0.10)
		6: # Dynamo
			g_tint = Color(0.60, 0.90, 1.20)
			p_tint = Color(0.70, 0.95, 1.15)
			col_dirt = Color(0.12, 0.15, 0.24)
			col_top = Color(0.20, 0.85, 1.0)
		7: # Hangar
			g_tint = Color(0.85, 0.85, 0.95)
			p_tint = Color(0.90, 0.90, 1.0)
			col_dirt = Color(0.16, 0.18, 0.24)
			col_top = Color(0.45, 0.50, 0.65)
		8: # Sanctum
			g_tint = Color(1.15, 0.55, 0.90)
			p_tint = Color(1.10, 0.60, 0.85)
			col_dirt = Color(0.18, 0.08, 0.15)
			col_top = Color(0.85, 0.18, 0.45)
	
	# Chasms between ground segments
	for i in range(ground_segments.size() - 1):
		var pit_left := ground_segments[i].end.x
		var pit_right := ground_segments[i + 1].position.x
		var pit_w := pit_right - pit_left
		if pit_right < view_left - 80.0 or pit_left > view_right + 80.0:
			continue
		
		if Global.current_stage == 5:
			# Molten lava pool at bottom of refinery pits
			var lava_pulse := 0.8 + 0.2 * sin(anim_timer * 6.0 + float(i))
			draw_rect(Rect2(pit_left, 500.0, pit_w, 40.0), Color(1.0 * lava_pulse, 0.35, 0.05, 0.85))
		elif Global.current_stage == 6:
			# Electric surge sparks at bottom of dynamo voids
			draw_line(Vector2(pit_left, 510.0), Vector2(pit_right, 510.0), Color(0.2, 0.8, 1.0, 0.8), 2.5)

	# Ground segments
	var edge_w: float = 96.0
	for g in ground_segments:
		if g.end.x < view_left - 50.0 or g.position.x > view_right + 50.0:
			continue
		
		var has_left_edge: bool = (g.position.x > 0.0)
		var has_right_edge: bool = (g.end.x < LEVEL_MAX_X)
		var active_edge_left_tex: Texture2D = ground_edge_left_textures_by_stage.get(Global.current_stage, ground_edge_left_texture)
		var active_edge_right_tex: Texture2D = ground_edge_right_textures_by_stage.get(Global.current_stage, ground_edge_right_texture)
		var actual_left_w: float = edge_w if (has_left_edge and active_edge_left_tex != null) else 0.0
		var actual_right_w: float = edge_w if (has_right_edge and active_edge_right_tex != null) else 0.0
		
		var mid_start_x: float = g.position.x + actual_left_w
		var mid_end_x: float = g.end.x - actual_right_w
		var mid_width: float = maxf(0.0, mid_end_x - mid_start_x)
		var ground_draw_y: float = g.position.y - 30.0
		var ground_draw_h: float = g.size.y + 30.0
		
		var active_ground_tex: Texture2D = ground_textures_by_stage.get(Global.current_stage, ground_tile_texture)
		if active_ground_tex == null:
			active_ground_tex = ground_tile_texture

		if active_ground_tex != null:
			var gw: float = float(active_ground_tex.get_width())
			var gh: float = float(active_ground_tex.get_height())
			var tile_w: float = 128.0 if gh > 100.0 else gw
			var num_tiles: int = int(ceil(mid_width / tile_w))
			
			for j in range(num_tiles):
				var tx: float = mid_start_x + float(j) * tile_w
				var tw: float = minf(tile_w, mid_end_x - tx)
				var ratio_w: float = tw / tile_w
				var trect := Rect2(tx, ground_draw_y, tw, ground_draw_h)
				var src_partial := Rect2(0.0, 0.0, gw * ratio_w, gh)
				var draw_tint := Color.WHITE if active_ground_tex != ground_tile_texture else g_tint
				draw_texture_rect_region(active_ground_tex, trect, src_partial, draw_tint)
		else:
			draw_rect(Rect2(mid_start_x, g.position.y, mid_width, g.size.y), col_dirt)
			draw_rect(Rect2(mid_start_x, g.position.y, mid_width, 8.0), col_top)
		
		if has_left_edge and active_edge_left_tex != null:
			var left_rect := Rect2(g.position.x, ground_draw_y, actual_left_w, ground_draw_h)
			var left_tint := Color.WHITE if active_edge_left_tex != ground_edge_left_texture else g_tint
			draw_texture_rect(active_edge_left_tex, left_rect, false, left_tint)
		
		if has_right_edge and active_edge_right_tex != null:
			var right_rect := Rect2(g.end.x - actual_right_w, ground_draw_y, actual_right_w, ground_draw_h)
			var right_tint := Color.WHITE if active_edge_right_tex != ground_edge_right_texture else g_tint
			draw_texture_rect(active_edge_right_tex, right_rect, false, right_tint)

	# Elevated Platforms
	for p in platforms:
		var b: Rect2 = p["rect"]
		var ptype: int = p["type"]
		if b.end.x < view_left - 50.0 or b.position.x > view_right + 50.0:
			continue
		
		match ptype:
			PlatformType.TURF:
				if platform_turf_texture != null:
					draw_texture_rect(platform_turf_texture, Rect2(b.position.x, b.position.y - 6.0, b.size.x, 46.0), false, p_tint)
				else:
					draw_rect(b, col_dirt)
					draw_rect(Rect2(b.position.x, b.position.y - 3.0, b.size.x, 6.0), col_top)
				# Grass blades top fringe
				for g in range(int(b.size.x / 14.0)):
					var gx := b.position.x + float(g) * 14.0 + 4.0
					draw_line(Vector2(gx, b.position.y - 1.0), Vector2(gx + 2.0, b.position.y - 5.0), col_top, 1.5)
			PlatformType.GIRDER:
				var chain_lx: float = b.position.x + 16.0
				var chain_rx: float = b.end.x - 20.0
				_draw_vertical_chain(Vector2(chain_lx, -12.0), Vector2(chain_lx, b.position.y + 4.0), 12.0, p_tint)
				_draw_vertical_chain(Vector2(chain_rx, -12.0), Vector2(chain_rx, b.position.y + 4.0), 12.0, p_tint)
				if b.size.x >= 90.0:
					_draw_hanging_chain_hook(Vector2(b.position.x + b.size.x * 0.5, b.position.y + 24.0), 52.0, p_tint)
				if platform_girder_texture != null:
					draw_texture_rect(platform_girder_texture, Rect2(b.position.x, b.position.y, b.size.x, 36.0), false, p_tint)
				else:
					draw_rect(b, Color(0.35, 0.38, 0.44))
					draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 4.0), Color(0.92, 0.80, 0.15))
			PlatformType.ROPE_BRIDGE:
				var bridge_b: Rect2 = b
				var is_col: bool = false
				for br in rope_bridge_states:
					if br["platform_index"] < platforms.size() and platforms[br["platform_index"]]["rect"].position == b.position:
						bridge_b.position.y += br["shake_offset"]
						is_col = br["is_collapsed"]
						break
				
				if is_col:
					# Snapped hanging rope ends and fallen bridge gap
					draw_line(Vector2(b.position.x, b.position.y - 6.0), Vector2(b.position.x + 28.0, b.position.y + 26.0), Color(0.65, 0.48, 0.30), 2.5)
					draw_line(Vector2(b.end.x, b.position.y - 6.0), Vector2(b.end.x - 28.0, b.position.y + 26.0), Color(0.65, 0.48, 0.30), 2.5)
				elif platform_bridge_texture != null:
					draw_texture_rect(platform_bridge_texture, Rect2(bridge_b.position.x, bridge_b.position.y - 28.0, bridge_b.size.x, 52.0), false, p_tint)
				else:
					var plank_w := 14.0
					for pl in range(int(bridge_b.size.x / plank_w)):
						var px := bridge_b.position.x + float(pl) * plank_w
						var c_plank := Color(0.55, 0.38, 0.22) if (pl % 2 == 0) else Color(0.46, 0.30, 0.16)
						draw_rect(Rect2(px + 1.0, bridge_b.position.y + 3.0, plank_w - 2.0, 11.0), c_plank)
					draw_line(Vector2(bridge_b.position.x, bridge_b.position.y - 6.0), Vector2(bridge_b.end.x, bridge_b.position.y - 6.0), Color(0.75, 0.60, 0.35), 2.5)
			PlatformType.HIGH_PERCH:
				var perch_lx: float = b.position.x + 12.0
				var perch_rx: float = b.end.x - 12.0
				_draw_vertical_chain(Vector2(perch_lx, -12.0), Vector2(perch_lx, b.position.y), 12.0, p_tint)
				_draw_vertical_chain(Vector2(perch_rx, -12.0), Vector2(perch_rx, b.position.y), 12.0, p_tint)
				if platform_tech_texture != null:
					draw_texture_rect(platform_tech_texture, Rect2(b.position.x, b.position.y - 16.0, b.size.x, 56.0), false, p_tint)
				else:
					draw_rect(b, Color(0.20, 0.25, 0.35))
					draw_line(Vector2(b.position.x, b.position.y), Vector2(b.end.x, b.position.y), Color(0.4, 0.7, 1.0), 2.0)
				# Lookout Antenna & Blinking Beacon
				var mast_x := b.end.x - 14.0
				draw_line(Vector2(mast_x, b.position.y), Vector2(mast_x, b.position.y - 22.0), Color(0.7, 0.8, 0.9), 1.5)
				var beacon_flash := sin(anim_timer * 8.0) > 0.0
				var beacon_col := Color(1.0, 0.20, 0.20) if beacon_flash else Color(0.3, 0.08, 0.08)
				draw_circle(Vector2(mast_x, b.position.y - 23.0), 3.0, beacon_col)
			PlatformType.ICE_SLAB:
				_draw_platform_ice_slab(b, p_tint)
			PlatformType.LAVA_GRATE:
				_draw_platform_lava_grate(b, p_tint)
			PlatformType.ENERGY_BARRIER:
				_draw_platform_energy_barrier(b, p_tint)
			PlatformType.TECH_CATWALK:
				_draw_platform_tech_catwalk(b, p_tint)
			PlatformType.BIO_RIB:
				_draw_platform_bio_rib(b, p_tint)

func _draw_platform_ice_slab(b: Rect2, p_tint: Color) -> void:
	# Crystalline translucent glacier ice core
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 20.0), Color(0.22, 0.46, 0.68, 0.90) * p_tint)
	draw_rect(Rect2(b.position.x + 2.0, b.position.y + 3.0, b.size.x - 4.0, 14.0), Color(0.45, 0.78, 0.95, 0.75) * p_tint)
	
	# Powder snow mantle layer on top
	draw_rect(Rect2(b.position.x - 2.0, b.position.y - 2.0, b.size.x + 4.0, 6.0), Color(0.95, 0.98, 1.0) * p_tint)
	draw_line(Vector2(b.position.x + 8.0, b.position.y + 4.0), Vector2(b.end.x - 8.0, b.position.y + 4.0), Color(1.0, 1.0, 1.0, 0.85), 1.5)
	
	# Sharp crystalline icicles hanging below
	var icicle_spacing := 16.0
	var count := int(b.size.x / icicle_spacing)
	for i in range(count):
		var ix := b.position.x + float(i) * icicle_spacing + 8.0
		var hash_val := fmod(ix * 0.17 + 23.0, 1.0)
		var icicle_len := 8.0 + hash_val * 16.0 + 2.0 * sin(anim_timer * 2.0 + float(i))
		var w := 4.0
		var pts := PackedVector2Array([
			Vector2(ix - w, b.position.y + 20.0),
			Vector2(ix + w, b.position.y + 20.0),
			Vector2(ix, b.position.y + 20.0 + icicle_len)
		])
		draw_colored_polygon(pts, Color(0.60, 0.88, 1.0, 0.85) * p_tint)
		draw_line(Vector2(ix, b.position.y + 20.0), Vector2(ix, b.position.y + 20.0 + icicle_len), Color(1.0, 1.0, 1.0, 0.90), 1.0)

func _draw_platform_lava_grate(b: Rect2, p_tint: Color) -> void:
	# Heavy cast-iron blast furnace framework
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 24.0), Color(0.14, 0.11, 0.11))
	draw_rect(Rect2(b.position.x + 2.0, b.position.y + 2.0, b.size.x - 4.0, 20.0), Color(0.08, 0.06, 0.06))
	
	# Molten thermal exhaust vents pulsing with superheated magma
	var vent_w := 14.0
	var vent_gap := 8.0
	var total_step := vent_w + vent_gap
	var num_vents := int((b.size.x - 12.0) / total_step)
	for v in range(num_vents):
		var vx := b.position.x + 8.0 + float(v) * total_step
		var pulse := 0.75 + 0.25 * sin(anim_timer * 6.0 + float(v) * 0.8)
		var magma_col := Color(1.0 * pulse, 0.42 * pulse, 0.08)
		draw_rect(Rect2(vx, b.position.y + 4.0, vent_w, 15.0), magma_col)
		draw_line(Vector2(vx + vent_w * 0.5, b.position.y + 6.0), Vector2(vx + vent_w * 0.5, b.position.y + 17.0), Color(1.0, 0.95, 0.60, pulse), 2.0)
	
	# Heavy iron top border and rivet studs
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 4.0), Color(0.45, 0.35, 0.30))
	for r in range(int(b.size.x / 24.0)):
		draw_circle(Vector2(b.position.x + 12.0 + float(r) * 24.0, b.position.y + 2.0), 1.5, Color(0.75, 0.65, 0.55))
	
	# Animated conveyor chevrons in Stage 5 Refinery
	if Global.current_stage == 5:
		var c_dir: float = 1.0 if (int(b.position.x) % 2 == 0) else -1.0
		var scroll := fmod(anim_timer * 45.0 * c_dir, 20.0)
		var num_ch := int(b.size.x / 20.0)
		for ch in range(num_ch):
			var ch_x := b.position.x + float(ch) * 20.0 + scroll
			if ch_x >= b.position.x + 4.0 and ch_x <= b.end.x - 12.0:
				var tip_x := ch_x + (6.0 * c_dir)
				draw_line(Vector2(ch_x, b.position.y + 3.0), Vector2(tip_x, b.position.y + 7.0), Color(1.0, 0.85, 0.2, 0.85), 2.0)
				draw_line(Vector2(ch_x, b.position.y + 11.0), Vector2(tip_x, b.position.y + 7.0), Color(1.0, 0.85, 0.2, 0.85), 2.0)

	# Hanging fiery slag chains underneath
	var chain_lx: float = b.position.x + 18.0
	var chain_rx: float = b.end.x - 18.0
	_draw_vertical_chain(Vector2(chain_lx, -12.0), Vector2(chain_lx, b.position.y + 4.0), 12.0, Color(1.2, 0.8, 0.5))
	_draw_vertical_chain(Vector2(chain_rx, -12.0), Vector2(chain_rx, b.position.y + 4.0), 12.0, Color(1.2, 0.8, 0.5))

func _draw_platform_energy_barrier(b: Rect2, p_tint: Color) -> void:
	# High-voltage busbar chassis
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 22.0), Color(0.08, 0.12, 0.18))
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 5.0), Color(0.85, 0.65, 0.20))
	
	# Central plasma core conduit
	var plasma_glow := 0.80 + 0.20 * sin(anim_timer * 9.0)
	var plasma_col := Color(0.15, 0.85 * plasma_glow, 1.0 * plasma_glow, 0.9)
	draw_rect(Rect2(b.position.x + 4.0, b.position.y + 8.0, b.size.x - 8.0, 8.0), plasma_col)
	draw_line(Vector2(b.position.x + 6.0, b.position.y + 12.0), Vector2(b.end.x - 6.0, b.position.y + 12.0), Color.WHITE, 1.5)
	
	# Dynamic electric arc lightning discharges crackling across the surface
	var arc_phase := int(anim_timer * 15.0)
	for a in range(3):
		var arc_seed := float((arc_phase + a * 7) % 19) / 19.0
		var ax1 := b.position.x + arc_seed * (b.size.x - 40.0)
		var ax2 := ax1 + 25.0
		var ay_mid := b.position.y - 4.0 - 3.0 * sin(anim_timer * 20.0 + float(a))
		draw_line(Vector2(ax1, b.position.y), Vector2((ax1 + ax2) * 0.5, ay_mid), Color(0.7, 0.95, 1.0), 1.5)
		draw_line(Vector2((ax1 + ax2) * 0.5, ay_mid), Vector2(ax2, b.position.y), Color(0.7, 0.95, 1.0), 1.5)
	
	# Blinding high-voltage yellow lightning arcs when surging in Stage 6 Dynamo
	if Global.current_stage == 6:
		var surge_phase := fmod(anim_timer, 2.8)
		if surge_phase >= 1.8:
			for a in range(4):
				var ax1 := b.position.x + fmod(float(a) * 55.0 + anim_timer * 95.0, b.size.x - 30.0)
				var ax2 := ax1 + 25.0
				var ay_top := b.position.y - 12.0 - sin(anim_timer * 32.0 + float(a)) * 8.0
				draw_line(Vector2(ax1, b.position.y), Vector2((ax1 + ax2) * 0.5, ay_top), Color(1.0, 0.95, 0.35), 2.5)
				draw_line(Vector2((ax1 + ax2) * 0.5, ay_top), Vector2(ax2, b.position.y), Color(1.0, 0.95, 0.35), 2.5)
				draw_line(Vector2(ax1, b.position.y), Vector2((ax1 + ax2) * 0.5, ay_top), Color(1.0, 0.6, 0.1, 0.4), 4.5)

	# Ceramic high-voltage disc insulators beneath
	for ins in range(int(b.size.x / 40.0)):
		var inx := b.position.x + 20.0 + float(ins) * 40.0
		draw_circle(Vector2(inx, b.position.y + 25.0), 4.5, Color(0.25, 0.40, 0.55))
		draw_circle(Vector2(inx, b.position.y + 30.0), 3.5, Color(0.18, 0.28, 0.40))
		draw_line(Vector2(inx, b.position.y + 22.0), Vector2(inx, b.position.y + 34.0), Color.WHITE, 1.0)

func _draw_platform_tech_catwalk(b: Rect2, p_tint: Color) -> void:
	# Spaceport dark carbon-composite launch deck
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 24.0), Color(0.12, 0.14, 0.18))
	draw_rect(Rect2(b.position.x, b.position.y + 20.0, b.size.x, 4.0), Color(0.22, 0.28, 0.38))
	
	# Hazard warning chevron stripe border (Yellow & Black angled stripes)
	var stripe_w := 14.0
	var num_stripes := int(b.size.x / stripe_w)
	for s in range(num_stripes):
		var sx := b.position.x + float(s) * stripe_w
		var col_st := Color(0.95, 0.80, 0.15) if (s % 2 == 0) else Color(0.10, 0.10, 0.12)
		var pts := PackedVector2Array([
			Vector2(sx, b.position.y),
			Vector2(sx + stripe_w, b.position.y),
			Vector2(sx + stripe_w - 4.0, b.position.y + 6.0),
			Vector2(sx - 4.0, b.position.y + 6.0)
		])
		draw_colored_polygon(pts, col_st)
	
	# Runway LED navigation beacon lights (flashing amber & green)
	for led in range(int(b.size.x / 36.0)):
		var lx := b.position.x + 18.0 + float(led) * 36.0
		var is_amber := (led % 2 == 0)
		var flash := sin(anim_timer * 6.0 + float(led) * 1.5) > 0.0
		var l_col := (Color(1.0, 0.75, 0.15) if is_amber else Color(0.25, 1.0, 0.45)) if flash else Color(0.15, 0.20, 0.22)
		draw_circle(Vector2(lx, b.position.y + 13.0), 3.0, l_col)
		if flash:
			draw_circle(Vector2(lx, b.position.y + 13.0), 5.5, Color(l_col.r, l_col.g, l_col.b, 0.3))
	
	# Under-slung pneumatic support struts
	draw_line(Vector2(b.position.x + 16.0, b.position.y + 24.0), Vector2(b.position.x + 8.0, b.position.y + 44.0), Color(0.35, 0.42, 0.52), 2.5)
	draw_line(Vector2(b.end.x - 16.0, b.position.y + 24.0), Vector2(b.end.x - 8.0, b.position.y + 44.0), Color(0.35, 0.42, 0.52), 2.5)

	# Animated conveyor chevrons in Stage 5 Refinery
	if Global.current_stage == 5:
		var c_dir: float = 1.0 if (int(b.position.x) % 2 == 0) else -1.0
		var scroll := fmod(anim_timer * 45.0 * c_dir, 20.0)
		var num_ch := int(b.size.x / 20.0)
		for ch in range(num_ch):
			var ch_x := b.position.x + float(ch) * 20.0 + scroll
			if ch_x >= b.position.x + 4.0 and ch_x <= b.end.x - 12.0:
				var tip_x := ch_x + (6.0 * c_dir)
				draw_line(Vector2(ch_x, b.position.y + 6.0), Vector2(tip_x, b.position.y + 10.0), Color(1.0, 0.85, 0.2, 0.85), 2.0)
				draw_line(Vector2(ch_x, b.position.y + 14.0), Vector2(tip_x, b.position.y + 10.0), Color(1.0, 0.85, 0.2, 0.85), 2.0)

func _draw_platform_bio_rib(b: Rect2, p_tint: Color) -> void:
	var pulse := 0.85 + 0.15 * sin(anim_timer * 4.0)
	var col_flesh := Color(0.60 * pulse, 0.10, 0.22)
	var col_chitin := Color(0.88, 0.82, 0.70)
	
	# Throbbing organic flesh foundation
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 24.0), col_flesh)
	
	# Glowing bio-luminescent neural capillaries running through flesh
	draw_line(Vector2(b.position.x + 6.0, b.position.y + 8.0), Vector2(b.end.x - 6.0, b.position.y + 8.0), Color(1.0, 0.40, 0.65, 0.8), 2.0)
	draw_line(Vector2(b.position.x + 12.0, b.position.y + 15.0), Vector2(b.end.x - 12.0, b.position.y + 15.0), Color(0.80, 0.25, 0.45, 0.6), 1.5)
	
	# Curving skeletal chitin rib cages wrapping around the platform
	var rib_spacing := 28.0
	var num_ribs := int(b.size.x / rib_spacing)
	for r in range(num_ribs):
		var rx := b.position.x + 14.0 + float(r) * rib_spacing
		var pts := PackedVector2Array([
			Vector2(rx - 5.0, b.position.y + 24.0),
			Vector2(rx - 2.0, b.position.y),
			Vector2(rx + 2.0, b.position.y),
			Vector2(rx + 5.0, b.position.y + 24.0)
		])
		draw_colored_polygon(pts, col_chitin)
		draw_circle(Vector2(rx, b.position.y - 1.0), 3.0, Color.WHITE)
	
	# Hanging organic slime stalactites and venom droplets
	for s in range(int(b.size.x / 32.0)):
		var sx := b.position.x + 16.0 + float(s) * 32.0
		var s_len := 10.0 + 4.0 * sin(anim_timer * 3.0 + float(s))
		draw_line(Vector2(sx, b.position.y + 24.0), Vector2(sx, b.position.y + 24.0 + s_len), Color(0.65, 0.15, 0.30), 2.0)
		draw_circle(Vector2(sx, b.position.y + 24.0 + s_len), 2.5, Color(0.55, 1.0, 0.25, 0.85))

func _draw_vertical_chain(top_pos: Vector2, bottom_pos: Vector2, chain_w: float = 12.0, tint: Color = Color.WHITE) -> void:
	if platform_chain_texture == null:
		draw_line(top_pos, bottom_pos, Color(0.45, 0.50, 0.55, 0.8), 2.0)
		return
	var chain_h: float = chain_w * 2.0
	var total_len: float = bottom_pos.y - top_pos.y
	if total_len <= 0.0:
		return
	var x: float = top_pos.x - chain_w * 0.5
	var tex_w: float = float(platform_chain_texture.get_width())
	var tex_h: float = float(platform_chain_texture.get_height())
	var cur_y: float = bottom_pos.y - chain_h
	while cur_y >= top_pos.y - chain_h:
		var crect := Rect2(x, cur_y, chain_w, chain_h)
		var csrc := Rect2(0.0, 0.0, tex_w, tex_h)
		draw_texture_rect_region(platform_chain_texture, crect, csrc, tint)
		cur_y -= chain_h

func _draw_hanging_chain_hook(attach_pos: Vector2, chain_len: float = 54.0, tint: Color = Color.WHITE) -> void:
	if platform_chain_hook_texture == null:
		return
	var hook_w: float = 16.0
	var full_h: float = hook_w * (float(platform_chain_hook_texture.get_height()) / float(platform_chain_hook_texture.get_width()))
	var hook_h: float = minf(full_h, chain_len)
	var hrect := Rect2(attach_pos.x - hook_w * 0.5, attach_pos.y, hook_w, hook_h)
	var src_ratio: float = hook_h / full_h
	var tex_w: float = float(platform_chain_hook_texture.get_width())
	var tex_h: float = float(platform_chain_hook_texture.get_height())
	var hsrc := Rect2(0.0, tex_h * (1.0 - src_ratio), tex_w, tex_h * src_ratio)
	draw_texture_rect_region(platform_chain_hook_texture, hrect, hsrc, tint)

func _draw_weather_particles(view_left: float, view_right: float) -> void:
	match Global.current_stage:
		2: # Rushing waterfall mist & ambient spray particles
			for m in range(24):
				var mx := fmod(float(m) * 88.0 + anim_timer * 75.0 + sin(anim_timer * 1.8 + float(m)) * 22.0, 1050.0) + view_left - 30.0
				var my := fmod(float(m) * 36.0 + anim_timer * 170.0, 550.0)
				var m_alpha := 0.22 + 0.18 * sin(anim_timer * 3.0 + float(m))
				draw_circle(Vector2(mx, my), 1.8, Color(0.85, 0.95, 1.0, m_alpha))
		4: # Falling blizzard snow
			for s in range(25):
				var sx := fmod(float(s) * 95.0 + anim_timer * 180.0, 1000.0) + view_left
				var sy := fmod(float(s) * 43.0 + anim_timer * 140.0, 540.0)
				draw_circle(Vector2(sx, sy), 2.2, Color(1.0, 1.0, 1.0, 0.75))
		5: # Rising magma embers
			for e in range(20):
				var ex := fmod(float(e) * 110.0 + sin(anim_timer * 2.0 + float(e)) * 40.0, 1000.0) + view_left
				var ey := 540.0 - fmod(float(e) * 48.0 + anim_timer * 110.0, 480.0)
				draw_circle(Vector2(ex, ey), 2.0, Color(1.0, 0.45, 0.10, 0.8))
		6: # Electric sparks
			if fmod(anim_timer, 0.3) < 0.1:
				var px := view_left + randf_range(100.0, 900.0)
				var py := randf_range(120.0, 480.0)
				draw_circle(Vector2(px, py), 3.0, Color(0.3, 0.85, 1.0, 0.9))
				draw_line(Vector2(px, py), Vector2(px + randf_range(-15.0, 15.0), py + randf_range(-15.0, 15.0)), Color(1.0, 1.0, 1.0), 1.5)
