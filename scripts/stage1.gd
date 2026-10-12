extends Node2D

@export var soldier_scene: PackedScene = preload("res://scenes/enemy_soldier.tscn")
@export var turret_scene: PackedScene = preload("res://scenes/enemy_turret.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/enemy_sniper.tscn")
@export var blimp_scene: PackedScene = preload("res://scenes/powerup_blimp.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var boss: Node2D = $Boss
@onready var world_colliders: StaticBody2D = $WorldColliders

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var soldier_spawn_timer: float = 2.0
var blimp_spawn_timer: float = 7.0
var blimp_index: int = 0
var anim_timer: float = 0.0

const LEVEL_MIN_X: float = 0.0
const LEVEL_MAX_X: float = 6700.0
const BOSS_TRIGGER_X: float = 5800.0

var bg_texture: Texture2D = null
var ground_tile_texture: Texture2D = null
var water_tile_texture: Texture2D = null

# 7 major ground sectors across the 6700px expanded mission
var ground_segments: Array[Rect2] = [
	Rect2(0.0, 440.0, 800.0, 80.0),       # Sector 1: Jungle Landing Beach
	Rect2(900.0, 440.0, 800.0, 80.0),     # Sector 2: Outer Fortress Perimeter
	Rect2(1800.0, 440.0, 800.0, 80.0),    # Sector 3: Jungle Ravine Catwalks
	Rect2(2720.0, 440.0, 880.0, 80.0),    # Sector 4: Mid-Stage Heavy Battery
	Rect2(3720.0, 440.0, 880.0, 80.0),    # Sector 5: Waterfall Cliffside
	Rect2(4720.0, 440.0, 880.0, 80.0),    # Sector 6: Alien Hive Perimeter
	Rect2(5720.0, 440.0, 980.0, 80.0)     # Sector 7: Wall Defense Boss Arena
]

# 12 distinct, non-overlapping bridges & tactical catwalks
var bridge_platforms: Array[Rect2] = [
	Rect2(350.0, 360.0, 300.0, 16.0),     # 1: Intro elevated ledge
	Rect2(750.0, 360.0, 270.0, 16.0),     # 2: Spans Water Gap 1 (800-900)
	Rect2(1200.0, 360.0, 350.0, 16.0),    # 3: Sector 2 elevated catwalk
	Rect2(1650.0, 360.0, 270.0, 16.0),    # 4: Spans Water Gap 2 (1700-1800)
	Rect2(2100.0, 360.0, 350.0, 16.0),    # 5: Sector 3 elevated platform
	Rect2(2550.0, 360.0, 270.0, 16.0),    # 6: Spans Water Gap 3 (2600-2720)
	Rect2(3000.0, 360.0, 450.0, 16.0),    # 7: Sector 4 fortress battery
	Rect2(3550.0, 360.0, 270.0, 16.0),    # 8: Spans Water Gap 4 (3600-3720)
	Rect2(4000.0, 360.0, 450.0, 16.0),    # 9: Sector 5 waterfall ridge
	Rect2(4550.0, 360.0, 270.0, 16.0),    # 10: Spans Water Gap 5 (4600-4720)
	Rect2(5000.0, 360.0, 450.0, 16.0),    # 11: Sector 6 alien rampart
	Rect2(5550.0, 360.0, 270.0, 16.0)     # 12: Spans Water Gap 6 (5600-5720) into Boss Arena
]

func _ready() -> void:
	Global.screen_shake_requested.connect(_on_screen_shake)
	if ResourceLoader.exists("res://assets/tiles/ground_tile.png"):
		ground_tile_texture = load("res://assets/tiles/ground_tile.png")
	elif ResourceLoader.exists("res://assets/tiles/ground_tile.jpg"):
		ground_tile_texture = load("res://assets/tiles/ground_tile.jpg")
	if ResourceLoader.exists("res://assets/tiles/water_tile.jpg"):
		water_tile_texture = load("res://assets/tiles/water_tile.jpg")
	_setup_background()
	_setup_colliders()
	_setup_static_enemies()
	queue_redraw()

func _setup_background() -> void:
	var bg_path := "res://assets/backgrounds/stage1_jungle.jpg"
	if Global.current_stage == 2:
		bg_path = "res://assets/backgrounds/stage2_waterfall.jpg"
	elif Global.current_stage == 3:
		bg_path = "res://assets/backgrounds/stage3_alien_hive.jpg"
	
	if ResourceLoader.exists(bg_path):
		bg_texture = load(bg_path)
		
		var p_bg := ParallaxBackground.new()
		p_bg.layer = -10
		add_child(p_bg)
		
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

func _setup_colliders() -> void:
	if world_colliders == null:
		return
	
	for g in ground_segments:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = g.size
		c.shape = s
		c.position = g.position + g.size * 0.5
		world_colliders.add_child(c)
	
	for b in bridge_platforms:
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
	# Screen Shake
	if shake_duration > 0.0:
		shake_duration -= delta
		var offset := Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO
	
	# Camera horizontal tracking (arcade side-scrolling style)
	if player != null and is_instance_valid(player):
		var target_cam_x := clampf(player.global_position.x + 120.0, 480.0, 5800.0)
		camera.global_position.x = maxf(camera.global_position.x, target_cam_x)
		
		# Boss trigger check
		if camera.global_position.x >= BOSS_TRIGGER_X and boss != null and is_instance_valid(boss):
			boss.activate()
	
	# Soldier Wave Spawner (before boss arena)
	if camera.global_position.x < BOSS_TRIGGER_X:
		soldier_spawn_timer -= delta
		if soldier_spawn_timer <= 0.0:
			var min_interval := 2.6
			var max_interval := 4.8
			if Global.current_stage == 2:
				min_interval = 1.8
				max_interval = 3.4
			elif Global.current_stage == 3:
				min_interval = 1.3
				max_interval = 2.4
			soldier_spawn_timer = randf_range(min_interval, max_interval)
			_spawn_soldier_wave()
		
		# Flying Powerup Blimp Spawner
		blimp_spawn_timer -= delta
		if blimp_spawn_timer <= 0.0:
			blimp_spawn_timer = 9.0
			_spawn_flying_blimp()

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _setup_static_enemies() -> void:
	# 8 Turrets placed along ground & fortress platforms
	var turret_positions: Array[Vector2] = [
		Vector2(700.0, 435.0),
		Vector2(1375.0, 345.0),
		Vector2(2020.0, 435.0),
		Vector2(2275.0, 345.0),
		Vector2(3225.0, 345.0),
		Vector2(3920.0, 435.0),
		Vector2(4225.0, 345.0),
		Vector2(5225.0, 345.0)
	]
	for pos in turret_positions:
		if turret_scene != null:
			var t = turret_scene.instantiate()
			t.global_position = pos
			add_child(t)
	
	# 8 Snipers placed on elevated bridges
	var sniper_positions: Array[Vector2] = [
		Vector2(500.0, 345.0),
		Vector2(885.0, 345.0),
		Vector2(1785.0, 345.0),
		Vector2(2685.0, 345.0),
		Vector2(3500.0, 435.0),
		Vector2(3685.0, 345.0),
		Vector2(4685.0, 345.0),
		Vector2(5685.0, 345.0)
	]
	for pos in sniper_positions:
		if sniper_scene != null:
			var s = sniper_scene.instantiate()
			s.global_position = pos
			add_child(s)

func _spawn_soldier_wave() -> void:
	if soldier_scene == null:
		return
	var cam_x := camera.global_position.x
	# Spawn ahead of camera
	var spawn_x := cam_x + 520.0
	var s = soldier_scene.instantiate()
	s.global_position = Vector2(spawn_x, 420.0)
	add_child(s)

func _spawn_flying_blimp() -> void:
	if blimp_scene == null:
		return
	var cam_x := camera.global_position.x
	var spawn_x := cam_x - 300.0
	var b = blimp_scene.instantiate()
	b.global_position = Vector2(spawn_x, randf_range(160.0, 240.0))
	
	# Cycle through Spread, Machine, Laser
	var weapons = [Global.WeaponType.SPREAD, Global.WeaponType.MACHINE, Global.WeaponType.LASER]
	b.weapon_type = weapons[blimp_index % weapons.size()]
	blimp_index += 1
	add_child(b)

func _draw() -> void:
	var cam_x: float = camera.global_position.x if camera != null else 480.0
	var view_left: float = cam_x - 560.0
	var view_right: float = cam_x + 560.0
	_draw_backdrop(view_left, view_right)
	_draw_platforms(view_left, view_right)

func _draw_backdrop(view_left: float, view_right: float) -> void:
	if water_tile_texture != null:
		# Draw animated textured water with flowing currents and wave undulation
		var water_w: float = 160.0
		var tex_src := Rect2(0.0, 0.0, float(water_tile_texture.get_width()), float(water_tile_texture.get_height()))
		var w_tint := Color.WHITE
		if Global.current_stage == 2:
			w_tint = Color(0.85, 0.95, 1.1)
		elif Global.current_stage == 3:
			w_tint = Color(1.3, 0.45, 0.35)
		
		# Flowing current offset
		var flow_speed: float = 32.0 if Global.current_stage != 2 else 65.0
		var flow_offset: float = fmod(anim_timer * flow_speed, water_w)
		
		var start_k: int = int(floor((view_left - flow_offset) / water_w)) - 1
		var end_k: int = int(ceil((view_right - flow_offset) / water_w)) + 1
		
		for k in range(start_k, end_k):
			var wx: float = float(k) * water_w + flow_offset
			var wave_bob: float = sin(anim_timer * 3.6 + float(k) * 0.9) * 2.8
			var w_rect := Rect2(wx, 442.0 + wave_bob, water_w, 100.0 - wave_bob)
			draw_texture_rect_region(water_tile_texture, w_rect, tex_src, w_tint)
		
		# Animated dynamic surface foam ripples
		_draw_water_surface_foam(view_left, view_right)
		
		# Player swimming ripples & splash interaction
		_draw_player_water_interaction()
		return

	if bg_texture != null:
		# Fallback parallax background with water plane
		if Global.current_stage == 2:
			draw_rect(Rect2(view_left, 450.0, view_right - view_left, 150.0), Color(0.1, 0.35, 0.6, 0.88))
			for fl in range(12):
				var wfx := view_left + float(fl) * 110.0 + fmod(anim_timer * 60.0, 110.0)
				draw_line(Vector2(wfx, 465.0), Vector2(wfx + 70.0, 465.0), Color.WHITE, 2.0)
		elif Global.current_stage == 3:
			draw_rect(Rect2(view_left, 450.0, view_right - view_left, 150.0), Color(0.35, 0.08, 0.05, 0.88))
			for w in range(16):
				var wx := view_left + float(w) * 80.0
				var wy := 470.0 + sin(anim_timer * 4.0 + float(w)) * 3.0
				draw_line(Vector2(wx, wy), Vector2(wx + 40.0, wy), Color(1.0, 0.3, 0.1), 2.5)
		else:
			draw_rect(Rect2(view_left, 450.0, view_right - view_left, 150.0), Color(0.05, 0.20, 0.35, 0.88))
			for w in range(16):
				var wx := view_left + float(w) * 80.0 + fmod(anim_timer * 30.0, 80.0)
				draw_line(Vector2(wx, 470.0), Vector2(wx + 40.0, 470.0), Color(0.1, 0.35, 0.55), 2.0)
		_draw_water_surface_foam(view_left, view_right)
		_draw_player_water_interaction()
		return

func _draw_water_surface_foam(v_left: float, v_right: float) -> void:
	var step := 28.0
	var num_pts := int((v_right - v_left) / step) + 3
	var foam_pts := PackedVector2Array()
	
	for i in range(num_pts):
		var px: float = v_left + float(i) * step
		var wave_y: float = 444.0 + sin(anim_timer * 4.2 + px * 0.035) * 2.5 + cos(anim_timer * 2.1 + px * 0.015) * 1.5
		foam_pts.append(Vector2(px, wave_y))
	
	for i in range(foam_pts.size() - 1):
		var p1 := foam_pts[i]
		var p2 := foam_pts[i + 1]
		var foam_alpha := 0.6 + 0.35 * sin(anim_timer * 5.0 + p1.x * 0.05)
		var foam_col := Color(1.0, 1.0, 1.0, foam_alpha)
		if Global.current_stage == 3:
			foam_col = Color(1.0, 0.45, 0.2, foam_alpha)
		draw_line(p1, p2, foam_col, 2.2)
		var shimmer_offset := Vector2(0.0, 5.0 + sin(anim_timer * 3.0 + p1.x * 0.08) * 1.5)
		draw_line(p1 + shimmer_offset, p2 + shimmer_offset, Color(foam_col.r, foam_col.g, foam_col.b, foam_alpha * 0.4), 1.5)

func _draw_player_water_interaction() -> void:
	if player == null or not is_instance_valid(player):
		return
	var py: float = player.global_position.y
	var px: float = player.global_position.x
	if py >= 435.0 and py <= 525.0:
		var ripple_r1: float = fmod(anim_timer * 26.0, 22.0) + 4.0
		var ripple_alpha1: float = 1.0 - (ripple_r1 / 26.0)
		var ripple_r2: float = fmod(anim_timer * 26.0 + 11.0, 22.0) + 4.0
		var ripple_alpha2: float = 1.0 - (ripple_r2 / 26.0)
		
		var rip_center := Vector2(px, 448.0)
		draw_arc(rip_center, ripple_r1, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, ripple_alpha1 * 0.7), 2.0)
		draw_arc(rip_center, ripple_r2, 0.0, TAU, 16, Color(0.7, 0.9, 1.0, ripple_alpha2 * 0.5), 1.5)
		
		if abs(player.velocity.x) > 10.0:
			for d in range(4):
				var splash_dir := -1.0 if player.velocity.x > 0.0 else 1.0
				var splash_x: float = px + splash_dir * (float(d) * 6.0 + 4.0)
				var splash_y: float = 446.0 - absf(sin(anim_timer * 14.0 + float(d))) * 7.0
				draw_circle(Vector2(splash_x, splash_y), 2.0, Color(1.0, 1.0, 1.0, 0.85))

func _draw_platforms(view_left: float, view_right: float) -> void:
	var col_grass := Color(0.2, 0.55, 0.25)
	var col_dirt := Color(0.35, 0.25, 0.18)
	var col_girder := Color(0.4, 0.42, 0.48)
	var col_rivet := Color(0.2, 0.22, 0.26)
	
	if Global.current_stage == 2:
		col_grass = Color(0.2, 0.45, 0.6)
		col_dirt = Color(0.18, 0.22, 0.3)
		col_girder = Color(0.32, 0.38, 0.48)
	elif Global.current_stage == 3:
		col_grass = Color(0.7, 0.2, 0.25)
		col_dirt = Color(0.25, 0.1, 0.12)
		col_girder = Color(0.45, 0.2, 0.25)
		col_rivet = Color(0.2, 0.05, 0.08)
	
	# Main Ground segments with frustum culling
	for g in ground_segments:
		if g.end.x < view_left - 50.0 or g.position.x > view_right + 50.0:
			continue
		
		if ground_tile_texture != null:
			var tile_w: float = 128.0
			var num_tiles: int = int(ceil(g.size.x / tile_w))
			var g_src := Rect2(0.0, 0.0, float(ground_tile_texture.get_width()), float(ground_tile_texture.get_height()))
			var g_tint := Color.WHITE
			if Global.current_stage == 2:
				g_tint = Color(0.8, 0.9, 1.05)
			elif Global.current_stage == 3:
				g_tint = Color(1.15, 0.65, 0.65)
			
			for j in range(num_tiles):
				var tx: float = g.position.x + float(j) * tile_w
				var tw: float = minf(tile_w, g.end.x - tx)
				var trect := Rect2(tx, g.position.y - 16.0, tw, g.size.y + 16.0)
				var src_partial := Rect2(0.0, 0.0, g_src.size.x * (tw / tile_w), g_src.size.y)
				draw_texture_rect_region(ground_tile_texture, trect, src_partial, g_tint)
		else:
			draw_rect(g, col_dirt)
			draw_rect(Rect2(g.position.x, g.position.y, g.size.x, 8.0), col_grass)
			for j in range(int(g.size.x / 40.0)):
				var fx: float = g.position.x + float(j) * 40.0 + 10.0
				draw_circle(Vector2(fx, g.position.y - 2.0), 4.0, col_grass)
	
	# Elevated Girder & Rock Bridges with frustum culling
	for b in bridge_platforms:
		if b.end.x < view_left - 50.0 or b.position.x > view_right + 50.0:
			continue
		
		draw_rect(b, col_girder)
		draw_line(Vector2(b.position.x, b.position.y), Vector2(b.position.x + b.size.x, b.position.y), Color(0.6, 0.65, 0.7), 2.0)
		for k in range(int(b.size.x / 24.0)):
			var kx: float = b.position.x + float(k) * 24.0
			draw_line(Vector2(kx, b.position.y), Vector2(kx + 24.0, b.position.y + 16.0), col_rivet, 2.0)
			draw_line(Vector2(kx + 24.0, b.position.y), Vector2(kx, b.position.y + 16.0), col_rivet, 2.0)
