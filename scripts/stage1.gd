extends Node2D

@export var soldier_scene: PackedScene = preload("res://scenes/enemy_soldier.tscn")
@export var turret_scene: PackedScene = preload("res://scenes/enemy_turret.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/enemy_sniper.tscn")
@export var blimp_scene: PackedScene = preload("res://scenes/powerup_blimp.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var boss: Node2D = $Boss

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var soldier_spawn_timer: float = 2.0
var blimp_spawn_timer: float = 8.0
var blimp_index: int = 0

const LEVEL_MIN_X: float = 0.0
const LEVEL_MAX_X: float = 2800.0
const BOSS_TRIGGER_X: float = 2400.0

var bg_texture: Texture2D = null

func _ready() -> void:
	Global.screen_shake_requested.connect(_on_screen_shake)
	_setup_background()
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
		var target_cam_x := clampf(player.global_position.x + 120.0, 480.0, 2400.0)
		camera.global_position.x = maxf(camera.global_position.x, target_cam_x)
		
		# Boss trigger check
		if camera.global_position.x >= BOSS_TRIGGER_X and boss != null and is_instance_valid(boss):
			boss.activate()
	
	# Soldier Wave Spawner (before boss arena)
	if camera.global_position.x < BOSS_TRIGGER_X:
		soldier_spawn_timer -= delta
		if soldier_spawn_timer <= 0.0:
			var min_interval := 2.8
			var max_interval := 5.0
			if Global.current_stage == 2:
				min_interval = 2.0
				max_interval = 3.6
			elif Global.current_stage == 3:
				min_interval = 1.4
				max_interval = 2.6
			soldier_spawn_timer = randf_range(min_interval, max_interval)
			_spawn_soldier_wave()
		
		# Flying Powerup Blimp Spawner
		blimp_spawn_timer -= delta
		if blimp_spawn_timer <= 0.0:
			blimp_spawn_timer = 14.0
			_spawn_flying_blimp()

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _setup_static_enemies() -> void:
	# Turrets placed along jungle fortresses
	var turret_positions: Array[Vector2] = [
		Vector2(650.0, 435.0),
		Vector2(1250.0, 310.0),
		Vector2(1820.0, 435.0),
		Vector2(2150.0, 310.0)
	]
	for pos in turret_positions:
		if turret_scene != null:
			var t = turret_scene.instantiate()
			t.global_position = pos
			add_child(t)
	
	# Snipers placed on high perches
	var sniper_positions: Array[Vector2] = [
		Vector2(450.0, 305.0),
		Vector2(950.0, 215.0),
		Vector2(1580.0, 215.0),
		Vector2(2350.0, 305.0)
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
	# Parallax Jungle & Backdrop scenery drawn across 3000px length
	_draw_backdrop()
	_draw_platforms()

func _draw_backdrop() -> void:
	if bg_texture != null:
		# Parallax background handles sky and landscape above water.
		# Render river, rapids, or magma hazard pool in the foreground water plane:
		if Global.current_stage == 2:
			# Raging rapids river
			draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.1, 0.35, 0.6, 0.88))
			for fl in range(10):
				var wfx := -100.0 + float(fl) * 320.0
				draw_line(Vector2(wfx, 465.0), Vector2(wfx + 180.0, 465.0), Color.WHITE, 2.0)
				draw_line(Vector2(wfx + 60.0, 495.0), Vector2(wfx + 240.0, 495.0), Color(0.7, 0.88, 1.0), 2.0)
		elif Global.current_stage == 3:
			# Toxic alien magma base
			draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.35, 0.08, 0.05, 0.88))
			for w in range(35):
				var wx := -100.0 + float(w) * 95.0
				draw_line(Vector2(wx, 470.0), Vector2(wx + 50.0, 470.0), Color(1.0, 0.3, 0.1), 2.5)
		else:
			# Stage 1: Tropical Jungle River
			draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.05, 0.20, 0.35, 0.88))
			for w in range(40):
				var wx := -100.0 + float(w) * 85.0
				draw_line(Vector2(wx, 470.0), Vector2(wx + 45.0, 470.0), Color(0.1, 0.35, 0.55), 2.0)
				draw_line(Vector2(wx + 20.0, 500.0), Vector2(wx + 65.0, 500.0), Color(0.1, 0.35, 0.55), 2.0)
		return

	if Global.current_stage == 2:
		# Fallback Stage 2: Torrential Waterfall & Blue Cliffs
		draw_rect(Rect2(-200.0, -100.0, 3400.0, 400.0), Color(0.05, 0.1, 0.18))
		for i in range(14):
			var mx := -100.0 + float(i) * 240.0
			draw_rect(Rect2(mx, 120.0, 160.0, 340.0), Color(0.09, 0.15, 0.25))
		for wf in range(7):
			var wfx := 150.0 + float(wf) * 420.0
			draw_rect(Rect2(wfx, 40.0, 75.0, 420.0), Color(0.18, 0.55, 0.85, 0.75))
			for fl in range(12):
				var ly := 60.0 + float(fl) * 32.0 + sin(float(fl) * 2.0) * 10.0
				draw_line(Vector2(wfx + 10.0, ly), Vector2(wfx + 65.0, ly + 8.0), Color.WHITE, 2.0)
		draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.1, 0.35, 0.6))
	elif Global.current_stage == 3:
		# Fallback Stage 3: Subterranean Alien Hive Core
		draw_rect(Rect2(-200.0, -100.0, 3400.0, 400.0), Color(0.12, 0.04, 0.07))
		for i in range(20):
			var ax := -100.0 + float(i) * 160.0
			var ay := 180.0 + sin(float(i) * 1.8) * 35.0
			draw_circle(Vector2(ax, ay), 40.0, Color(0.28, 0.08, 0.12))
			draw_circle(Vector2(ax, ay), 18.0, Color(0.8, 0.2, 0.15, 0.4))
		draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.35, 0.08, 0.05))
		for w in range(35):
			var wx := -100.0 + float(w) * 95.0
			draw_line(Vector2(wx, 470.0), Vector2(wx + 50.0, 470.0), Color(1.0, 0.3, 0.1), 2.5)
	else:
		# Fallback Stage 1: Tropical Jungle Canopy & Calm Blue Water
		draw_rect(Rect2(-200.0, -100.0, 3400.0, 400.0), Color(0.08, 0.12, 0.22))
		for i in range(16):
			var mx := -100.0 + float(i) * 220.0
			var my := 230.0 + sin(float(i) * 1.5) * 40.0
			var mountain_col := Color(0.12, 0.18, 0.28)
			draw_colored_polygon(PackedVector2Array([
				Vector2(mx - 150.0, 420.0),
				Vector2(mx, my),
				Vector2(mx + 150.0, 420.0)
			]), mountain_col)
		for i in range(25):
			var px := -50.0 + float(i) * 135.0
			var py := 150.0 + sin(float(i) * 2.2) * 25.0
			draw_circle(Vector2(px, py), 45.0, Color(0.08, 0.22, 0.15))
			draw_circle(Vector2(px + 20.0, py + 10.0), 38.0, Color(0.12, 0.28, 0.18))
		draw_rect(Rect2(-200.0, 450.0, 3400.0, 150.0), Color(0.05, 0.20, 0.35))
		for w in range(40):
			var wx := -100.0 + float(w) * 85.0
			draw_line(Vector2(wx, 470.0), Vector2(wx + 45.0, 470.0), Color(0.1, 0.35, 0.55), 2.0)
			draw_line(Vector2(wx + 20.0, 500.0), Vector2(wx + 65.0, 500.0), Color(0.1, 0.35, 0.55), 2.0)

func _draw_platforms() -> void:
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
	
	# Main Ground segments
	var ground_segments := [
		Rect2(0.0, 440.0, 700.0, 80.0),
		Rect2(780.0, 440.0, 700.0, 80.0),
		Rect2(1560.0, 440.0, 600.0, 80.0),
		Rect2(2240.0, 440.0, 800.0, 80.0)
	]
	for g in ground_segments:
		draw_rect(g, col_dirt)
		draw_rect(Rect2(g.position.x, g.position.y, g.size.x, 8.0), col_grass)
		for j in range(int(g.size.x / 40.0)):
			var fx: float = g.position.x + float(j) * 40.0 + 10.0
			draw_circle(Vector2(fx, g.position.y - 2.0), 4.0, col_grass)
	
	# Elevated Girder & Rock Bridges (High & Mid platforms)
	var bridge_platforms := [
		Rect2(360.0, 320.0, 220.0, 16.0),
		Rect2(850.0, 230.0, 240.0, 16.0),
		Rect2(1150.0, 330.0, 220.0, 16.0),
		Rect2(1480.0, 230.0, 240.0, 16.0),
		Rect2(1740.0, 330.0, 200.0, 16.0),
		Rect2(2050.0, 330.0, 220.0, 16.0),
		Rect2(2250.0, 320.0, 180.0, 16.0)
	]
	for b in bridge_platforms:
		draw_rect(b, col_girder)
		draw_line(Vector2(b.position.x, b.position.y), Vector2(b.position.x + b.size.x, b.position.y), Color(0.6, 0.65, 0.7), 2.0)
		# Steel cross-trusses
		for k in range(int(b.size.x / 24.0)):
			var kx: float = b.position.x + float(k) * 24.0
			draw_line(Vector2(kx, b.position.y), Vector2(kx + 24.0, b.position.y + 16.0), col_rivet, 2.0)
			draw_line(Vector2(kx + 24.0, b.position.y), Vector2(kx, b.position.y + 16.0), col_rivet, 2.0)
