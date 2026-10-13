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
		p_layer.motion_mirroring = Vector2(960.0, 0.0)
		p_bg.add_child(p_layer)
		
		var spr := Sprite2D.new()
		spr.texture = bg_texture
		var tex_size := bg_texture.get_size()
		spr.scale = Vector2(960.0 / tex_size.x, 540.0 / tex_size.y)
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
	
	if player != null and is_instance_valid(player):
		var target_cam_x := clampf(player.global_position.x + 120.0, 480.0, 5800.0)
		camera.global_position.x = maxf(camera.global_position.x, target_cam_x)
		
		if camera.global_position.x >= BOSS_TRIGGER_X and boss != null and is_instance_valid(boss):
			boss.activate()
	
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
	# Handcrafted tactical placements matching classic Contra pacing
	
	# 1. Fortified Ground & Deck Turrets
	var turret_positions: Array[Vector2] = [
		Vector2(720.0, 435.0),    # Sector 1: Landing Beach defense bunker
		Vector2(1380.0, 435.0),   # Sector 2: Fortress Perimeter ground pillbox
		Vector2(2650.0, 435.0),   # Sector 3: Ravine choke point
		Vector2(3480.0, 280.0),   # Sector 4: Heavy battery elevated deck
		Vector2(4750.0, 435.0),   # Sector 5: Waterfall ridge approach
		Vector2(5420.0, 435.0)    # Sector 6: Outer fortress gateway bunker
	]
	for pos in turret_positions:
		if turret_scene != null and pos.x < BOSS_TRIGGER_X - 100.0:
			var t = turret_scene.instantiate()
			t.global_position = pos
			add_child(t)
	
	# 2. Elevated Snipers on Lookout Perches and Rope Bridges
	var sniper_positions: Array[Vector2] = [
		Vector2(530.0, 270.0),    # Sector 1: High observation perch
		Vector2(890.0, 330.0),    # Chasm 1: Guarding Rope Bridge 1
		Vector2(1550.0, 215.0),   # Sector 2: High fortress observation spire
		Vector2(1890.0, 320.0),   # Chasm 2: Overlooking Waterfall Gorge
		Vector2(2930.0, 330.0),   # Chasm 3: Guarding River Bridge 3
		Vector2(3750.0, 200.0),   # Sector 4: Watchtower spire
		Vector2(4710.0, 205.0)    # Sector 5: High cliff lookout
	]
	for pos in sniper_positions:
		if sniper_scene != null and pos.x < BOSS_TRIGGER_X - 100.0:
			var s = sniper_scene.instantiate()
			s.global_position = pos
			add_child(s)
	
	# 3. Heavy Grenadiers - Tactical Mini-Guardians at key strongpoints
	var grenadier_positions: Array[Vector2] = [
		Vector2(3620.0, 275.0),   # Sector 4: Heavy Battery mortar post
		Vector2(5640.0, 250.0)    # Sector 6: Fortress Gatekeeper
	]
	for pos in grenadier_positions:
		if grenadier_scene != null and pos.x < BOSS_TRIGGER_X - 120.0:
			var gr = grenadier_scene.instantiate()
			gr.global_position = pos
			add_child(gr)
	
	# 4. Ambush Crawlers - Surprise ambushes in the jungle ravine
	var crawler_positions: Array[Vector2] = [
		Vector2(2220.0, 420.0),   # Sector 3: Ambush in the ravine undergrowth
		Vector2(2440.0, 420.0),   # Sector 3: Second crawler pack
		Vector2(4380.0, 420.0),   # Sector 5: Ambush along waterfall cliff
		Vector2(4580.0, 420.0)    # Sector 5: Ambush before fortress moat
	]
	for pos in crawler_positions:
		if crawler_scene != null and pos.x < BOSS_TRIGGER_X - 150.0:
			var cr = crawler_scene.instantiate()
			cr.global_position = pos
			add_child(cr)
	
	# 5. Handcrafted Powerup Sensor Pods (Classic rewarding weapon progression)
	var sensor_pods: Array[Dictionary] = [
		{"pos": Vector2(330.0, 370.0), "weapon": Global.WeaponType.SPREAD},    # Sector 1: Spread gun
		{"pos": Vector2(1280.0, 295.0), "weapon": Global.WeaponType.MACHINE},  # Sector 2: Machine gun
		{"pos": Vector2(2380.0, 275.0), "weapon": Global.WeaponType.LASER},    # Sector 3: Laser gun
		{"pos": Vector2(4480.0, 285.0), "weapon": Global.WeaponType.SPREAD}   # Sector 5: Spread gun
	]
	for pod_info in sensor_pods:
		if sensor_scene != null and pod_info["pos"].x < BOSS_TRIGGER_X - 150.0:
			var pod = sensor_scene.instantiate()
			pod.global_position = pod_info["pos"]
			pod.weapon_type = pod_info["weapon"]
			add_child(pod)

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
				if p_type == PlatformType.HIGH_PERCH and res_beacon != null:
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
	
	var s = soldier_scene.instantiate()
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
	
	var count: int = 1 if Global.current_stage <= 2 else (2 if randf() < 0.6 else 1)
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
	_draw_platforms(view_left, view_right)
	_draw_weather_particles(view_left, view_right)

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
		
		# Gorge canyon rock shadow behind cliff overhangs
		draw_rect(Rect2(pit_left - 36.0, 440.0, pit_w + 72.0, 200.0), Color(0.03, 0.04, 0.06, 0.96))
		draw_rect(Rect2(pit_left - 24.0, 475.0, pit_w + 48.0, 165.0), Color(0.015, 0.02, 0.03, 1.0))

		if Global.current_stage == 1 or Global.current_stage == 2:
			# Natural organic tropical river basin
			var water_base_y: float = 484.0
			var water_bottom_y: float = 560.0
			var num_pts := int(ceil(pit_w / 6.0)) + 1
			var surface_pts := PackedVector2Array()
			
			for p in range(num_pts):
				var px := minf(pit_left + float(p) * 6.0, pit_right)
				# Gentle natural river swell (smooth calm wave oscillation)
				var wave := sin(px * 0.016 + anim_timer * 1.3) * 2.2 + sin(px * 0.042 - anim_timer * 0.8) * 1.1
				surface_pts.append(Vector2(px, water_base_y + wave))
			
			# Water body fill polygon
			var poly_pts := PackedVector2Array()
			poly_pts.append_array(surface_pts)
			poly_pts.append(Vector2(pit_right, water_bottom_y))
			poly_pts.append(Vector2(pit_left, water_bottom_y))
			
			var c_river_surf := Color(0.06, 0.26, 0.38, 0.94) if Global.current_stage == 1 else Color(0.08, 0.32, 0.52, 0.94)
			draw_colored_polygon(poly_pts, c_river_surf)
			
			# Deep riverbed shadow
			draw_rect(Rect2(pit_left, water_base_y + 14.0, pit_w, water_bottom_y - water_base_y - 14.0), Color(0.01, 0.04, 0.12, 0.65))
			
			# Subtle sub-surface caustics drifting calmly
			for b in range(3):
				var band_y := water_base_y + 8.0 + float(b) * 11.0
				var band_drift := sin(anim_timer * 1.1 + float(b) * 1.4) * 8.0
				var c_caustic := Color(0.30, 0.70, 0.85, 0.18)
				draw_line(Vector2(pit_left + 12.0 + band_drift, band_y), Vector2(pit_right - 12.0 + band_drift, band_y), c_caustic, 1.5)
			
			# Soft translucent surface foam crest highlight
			for p in range(surface_pts.size() - 1):
				var pt1 := surface_pts[p]
				var pt2 := surface_pts[p + 1]
				draw_line(pt1, pt2, Color(0.68, 0.94, 0.98, 0.65), 1.8)
				draw_line(Vector2(pt1.x, pt1.y + 2.0), Vector2(pt2.x, pt2.y + 2.0), Color(0.22, 0.60, 0.78, 0.35), 1.0)
		elif Global.current_stage == 5:
			# Molten lava pool at bottom of refinery pits
			draw_rect(Rect2(pit_left - 20.0, 460.0, pit_w + 40.0, 180.0), Color(0.08, 0.03, 0.02, 0.95))
			var lava_pulse := 0.8 + 0.2 * sin(anim_timer * 6.0 + float(i))
			draw_rect(Rect2(pit_left, 500.0, pit_w, 40.0), Color(1.0 * lava_pulse, 0.35, 0.05))
		elif Global.current_stage == 6:
			# Electric surge sparks at bottom of dynamo voids
			draw_rect(Rect2(pit_left - 20.0, 460.0, pit_w + 40.0, 180.0), Color(0.02, 0.04, 0.08, 0.95))
			draw_line(Vector2(pit_left, 510.0), Vector2(pit_right, 510.0), Color(0.2, 0.8, 1.0, 0.8), 2.5)
		else:
			# Bottomless pit abyss for space/hangar/alien chasms
			draw_rect(Rect2(pit_left - 30.0, 440.0, pit_w + 60.0, 200.0), Color(0.02, 0.02, 0.04, 0.98))

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
				if platform_bridge_texture != null:
					draw_texture_rect(platform_bridge_texture, Rect2(b.position.x, b.position.y - 28.0, b.size.x, 52.0), false, p_tint)
				else:
					var plank_w := 14.0
					for pl in range(int(b.size.x / plank_w)):
						var px := b.position.x + float(pl) * plank_w
						var c_plank := Color(0.55, 0.38, 0.22) if (pl % 2 == 0) else Color(0.46, 0.30, 0.16)
						draw_rect(Rect2(px + 1.0, b.position.y + 3.0, plank_w - 2.0, 11.0), c_plank)
					draw_line(Vector2(b.position.x, b.position.y - 6.0), Vector2(b.end.x, b.position.y - 6.0), Color(0.75, 0.60, 0.35), 2.5)
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
