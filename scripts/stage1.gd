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
var platform_girder_texture: Texture2D = null
var platform_bridge_texture: Texture2D = null
var platform_turf_texture: Texture2D = null
var platform_tech_texture: Texture2D = null
var ground_edge_right_texture: Texture2D = null
var ground_edge_left_texture: Texture2D = null

enum PlatformType {
	TURF,
	GIRDER,
	ROPE_BRIDGE,
	HIGH_PERCH
}

# 7 Tactical ground sectors separated by 6 bottomless chasm pits
var ground_segments: Array[Rect2] = [
	Rect2(0.0, 440.0, 800.0, 200.0),       # Sector 1: Jungle Landing Beach (0 - 800)
	Rect2(920.0, 440.0, 780.0, 200.0),     # Sector 2: Outer Fortress Perimeter (920 - 1700)
	Rect2(1820.0, 440.0, 780.0, 200.0),    # Sector 3: Jungle Ravine Catwalks (1820 - 2600)
	Rect2(2740.0, 440.0, 860.0, 200.0),    # Sector 4: Mid-Stage Heavy Battery (2740 - 3600)
	Rect2(3740.0, 440.0, 860.0, 200.0),    # Sector 5: Waterfall Cliffside (3740 - 4600)
	Rect2(4740.0, 440.0, 860.0, 200.0),    # Sector 6: Alien Hive Perimeter (4740 - 5600)
	Rect2(5740.0, 440.0, 960.0, 200.0)     # Sector 7: Final Defense Wall & Boss Arena (5740 - 6700)
]

# Rich multi-tiered tactical platforms with 4 distinct archetypes
var platforms: Array[Dictionary] = [
	# Sector 1: Jungle Landing Beach (0 - 800)
	{"rect": Rect2(250.0, 370.0, 200.0, 16.0), "type": PlatformType.TURF},
	{"rect": Rect2(420.0, 290.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 1 (800 - 920)
	{"rect": Rect2(760.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},

	# Sector 2: Outer Fortress Perimeter (920 - 1700)
	{"rect": Rect2(1050.0, 370.0, 220.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(1250.0, 300.0, 260.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(1480.0, 230.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 2 (1700 - 1820)
	{"rect": Rect2(1660.0, 330.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},

	# Sector 3: Jungle Ravine Catwalks (1820 - 2600)
	{"rect": Rect2(1920.0, 370.0, 200.0, 16.0), "type": PlatformType.TURF},
	{"rect": Rect2(2100.0, 300.0, 240.0, 16.0), "type": PlatformType.TURF},
	{"rect": Rect2(2320.0, 230.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 3 (2600 - 2740)
	{"rect": Rect2(2560.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},

	# Sector 4: Mid-Stage Heavy Battery (2740 - 3600)
	{"rect": Rect2(2880.0, 370.0, 240.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(3100.0, 290.0, 320.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(3400.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 4 (3600 - 3740)
	{"rect": Rect2(3560.0, 330.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},

	# Sector 5: Waterfall Cliffside (3740 - 4600)
	{"rect": Rect2(3860.0, 370.0, 220.0, 16.0), "type": PlatformType.TURF},
	{"rect": Rect2(4060.0, 300.0, 260.0, 16.0), "type": PlatformType.TURF},
	{"rect": Rect2(4300.0, 230.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 5 (4600 - 4740)
	{"rect": Rect2(4560.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},

	# Sector 6: Alien Hive Perimeter (4740 - 5600)
	{"rect": Rect2(4860.0, 370.0, 220.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(5060.0, 300.0, 280.0, 16.0), "type": PlatformType.GIRDER},
	{"rect": Rect2(5320.0, 230.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
	# Pit Chasm 6 (5600 - 5740) into Boss Arena
	{"rect": Rect2(5560.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE}
]

func _ready() -> void:
	Global.screen_shake_requested.connect(_on_screen_shake)
	if ResourceLoader.exists("res://assets/tiles/ground_tile.png"):
		ground_tile_texture = load("res://assets/tiles/ground_tile.png")
	if ResourceLoader.exists("res://assets/tiles/platform_girder.png"):
		platform_girder_texture = load("res://assets/tiles/platform_girder.png")
	if ResourceLoader.exists("res://assets/tiles/platform_bridge.png"):
		platform_bridge_texture = load("res://assets/tiles/platform_bridge.png")
	if ResourceLoader.exists("res://assets/tiles/platform_turf.png"):
		platform_turf_texture = load("res://assets/tiles/platform_turf.png")
	if ResourceLoader.exists("res://assets/tiles/platform_tech.png"):
		platform_tech_texture = load("res://assets/tiles/platform_tech.png")
	if ResourceLoader.exists("res://assets/tiles/ground_edge_right.png"):
		ground_edge_right_texture = load("res://assets/tiles/ground_edge_right.png")
	if ResourceLoader.exists("res://assets/tiles/ground_edge_left.png"):
		ground_edge_left_texture = load("res://assets/tiles/ground_edge_left.png")
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
	# 8 Turrets placed along ground & elevated decks
	var turret_positions: Array[Vector2] = [
		Vector2(700.0, 435.0),    # Sector 1: Ground beach
		Vector2(1380.0, 295.0),   # Sector 2: Fortress Mid Deck (platform at y=300)
		Vector2(2020.0, 435.0),   # Sector 3: Ground ravine
		Vector2(2220.0, 295.0),   # Sector 3: Stepped Turf Mound (platform at y=300)
		Vector2(3260.0, 285.0),   # Sector 4: Heavy Battery Deck (platform at y=290)
		Vector2(3920.0, 435.0),   # Sector 5: Waterfall ground
		Vector2(4190.0, 295.0),   # Sector 5: Waterfall Mid Ridge (platform at y=300)
		Vector2(5200.0, 295.0)    # Sector 6: Alien Hive Mid Deck (platform at y=300)
	]
	for pos in turret_positions:
		if turret_scene != null:
			var t = turret_scene.instantiate()
			t.global_position = pos
			add_child(t)
	
	# 8 Snipers placed strategically on high lookout perches and rope bridges
	var sniper_positions: Array[Vector2] = [
		Vector2(510.0, 285.0),    # Sector 1: High Perch (platform at y=290)
		Vector2(880.0, 335.0),    # Water Gap 1: Rope Bridge (platform at y=340)
		Vector2(1570.0, 225.0),   # Sector 2: High Observation Perch (platform at y=230)
		Vector2(2410.0, 225.0),   # Sector 3: Ravine High Perch (platform at y=230)
		Vector2(2680.0, 335.0),   # Water Gap 3: Rope Bridge (platform at y=340)
		Vector2(3480.0, 215.0),   # Sector 4: Watchtower Perch (platform at y=220)
		Vector2(4400.0, 225.0),   # Sector 5: Waterfall High Lookout (platform at y=230)
		Vector2(5410.0, 225.0)    # Sector 6: Alien Hive High Spire (platform at y=230)
	]
	for pos in sniper_positions:
		if sniper_scene != null:
			var s = sniper_scene.instantiate()
			s.global_position = pos
			add_child(s)

func get_safe_respawn_position(target_x: float) -> Vector2:
	# If target_x is safely over any solid ground segment (with 40px margin from cliff edges)
	for g in ground_segments:
		if target_x >= g.position.x + 40.0 and target_x <= g.end.x - 40.0:
			return Vector2(target_x, 80.0)
	
	# If target_x falls in a pit or too close to an edge, find the closest safe ground position
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
	if soldier_scene == null:
		return
	var cam_x := camera.global_position.x
	# Spawn ahead of camera
	var spawn_x := cam_x + 520.0
	
	# If spawn_x happens to fall over a pit gap, shift onto the next solid ground segment
	for i in range(ground_segments.size() - 1):
		var pit_start := ground_segments[i].end.x
		var pit_end := ground_segments[i + 1].position.x
		if spawn_x >= pit_start - 20.0 and spawn_x <= pit_end + 20.0:
			spawn_x = pit_end + 30.0
			break
	
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
	_draw_platforms(view_left, view_right)

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
	
	# Bottomless Pit Chasms between consecutive ground segments (drawn first so cliff overhangs reveal the abyss)
	for i in range(ground_segments.size() - 1):
		var pit_left := ground_segments[i].end.x
		var pit_right := ground_segments[i + 1].position.x
		var pit_w := pit_right - pit_left
		if pit_right < view_left - 80.0 or pit_left > view_right + 80.0:
			continue
		
		# 1. Abyss darkness void (extends 40px behind cliff overhangs so rock fringes reveal pitch-black void)
		draw_rect(Rect2(pit_left - 40.0, 440.0, pit_w + 80.0, 200.0), Color(0.04, 0.04, 0.06, 0.98))
		draw_rect(Rect2(pit_left - 30.0, 475.0, pit_w + 60.0, 165.0), Color(0.015, 0.015, 0.02, 1.0))
		draw_rect(Rect2(pit_left - 20.0, 505.0, pit_w + 40.0, 135.0), Color(0.0, 0.0, 0.0, 1.0))
		
		# Fallback cliff drop-off lines if edge textures are unavailable
		if ground_edge_right_texture == null or ground_edge_left_texture == null:
			var col_cliff := col_dirt * 0.4
			var col_cliff_hi := col_dirt * 0.65
			draw_line(Vector2(pit_left, 440.0), Vector2(pit_left, 560.0), col_cliff, 3.5)
			draw_line(Vector2(pit_left - 3.0, 440.0), Vector2(pit_left - 3.0, 520.0), col_cliff_hi, 2.0)
			draw_line(Vector2(pit_right, 440.0), Vector2(pit_right, 560.0), col_cliff, 3.5)
			draw_line(Vector2(pit_right + 3.0, 440.0), Vector2(pit_right + 3.0, 520.0), col_cliff_hi, 2.0)

	# Main Ground segments with high-res cliff edges and repeating soil tiles
	var edge_w: float = 96.0
	for g in ground_segments:
		if g.end.x < view_left - 50.0 or g.position.x > view_right + 50.0:
			continue
		
		var g_tint := Color.WHITE
		if Global.current_stage == 2:
			g_tint = Color(0.8, 0.9, 1.05)
		elif Global.current_stage == 3:
			g_tint = Color(1.15, 0.65, 0.65)
		
		var has_left_edge: bool = (g.position.x > 0.0)
		var has_right_edge: bool = (g.end.x < LEVEL_MAX_X)
		var actual_left_edge_w: float = edge_w if (has_left_edge and ground_edge_left_texture != null) else 0.0
		var actual_right_edge_w: float = edge_w if (has_right_edge and ground_edge_right_texture != null) else 0.0
		
		var mid_start_x: float = g.position.x + actual_left_edge_w
		var mid_end_x: float = g.end.x - actual_right_edge_w
		var mid_width: float = maxf(0.0, mid_end_x - mid_start_x)
		
		var ground_draw_y: float = g.position.y - 30.0
		var ground_draw_h: float = g.size.y + 30.0
		
		# Draw middle repeating ground tile
		if ground_tile_texture != null:
			var gw: float = float(ground_tile_texture.get_width())
			var gh: float = float(ground_tile_texture.get_height())
			var tile_w: float = 128.0 if gh > 100.0 else gw
			var num_tiles: int = int(ceil(mid_width / tile_w))
			
			for j in range(num_tiles):
				var tx: float = mid_start_x + float(j) * tile_w
				var tw: float = minf(tile_w, mid_end_x - tx)
				var ratio_w: float = tw / tile_w
				
				if gh > 100.0:
					# High-res seamless ground tile: covers top grass down through bedrock
					var trect := Rect2(tx, ground_draw_y, tw, ground_draw_h)
					var src_partial := Rect2(0.0, 0.0, gw * ratio_w, gh)
					draw_texture_rect_region(ground_tile_texture, trect, src_partial, g_tint)
				else:
					# Low-res sprite backing & slice repetition
					draw_rect(Rect2(tx, g.position.y + 24.0, tw, g.size.y - 24.0), Color(66.0/255.0, 38.0/255.0, 25.0/255.0) * g_tint)
					var cur_y: float = g.position.y - 16.0 + gh
					while cur_y < g.end.y:
						var step_h: float = minf(22.0, g.end.y - cur_y)
						var sub_trect := Rect2(tx, cur_y, tw, step_h)
						var sub_src := Rect2(0.0, 25.0, gw * ratio_w, step_h)
						draw_texture_rect_region(ground_tile_texture, sub_trect, sub_src, g_tint)
						cur_y += 22.0
					var trect := Rect2(tx, g.position.y - 16.0, tw, gh)
					var src_partial := Rect2(0.0, 0.0, gw * ratio_w, gh)
					draw_texture_rect_region(ground_tile_texture, trect, src_partial, g_tint)
		else:
			draw_rect(Rect2(mid_start_x, g.position.y, mid_width, g.size.y), col_dirt)
			draw_rect(Rect2(mid_start_x, g.position.y, mid_width, 8.0), col_grass)
		
		# Draw Left Cliff Edge Tile (facing left into pit chasm)
		if has_left_edge and ground_edge_left_texture != null:
			var left_rect := Rect2(g.position.x, ground_draw_y, actual_left_edge_w, ground_draw_h)
			draw_texture_rect(ground_edge_left_texture, left_rect, false, g_tint)
		
		# Draw Right Cliff Edge Tile (facing right into pit chasm)
		if has_right_edge and ground_edge_right_texture != null:
			var right_rect := Rect2(g.end.x - actual_right_edge_w, ground_draw_y, actual_right_edge_w, ground_draw_h)
			draw_texture_rect(ground_edge_right_texture, right_rect, false, g_tint)
	
	# Elevated Tactical Platforms with Frustum Culling & Archetype Variety
	var p_tint := Color.WHITE
	if Global.current_stage == 2:
		p_tint = Color(0.85, 0.95, 1.05)
	elif Global.current_stage == 3:
		p_tint = Color(1.10, 0.75, 0.75)
		
	for p in platforms:
		var b: Rect2 = p["rect"]
		var ptype: int = p["type"]
		if b.end.x < view_left - 50.0 or b.position.x > view_right + 50.0:
			continue
		
		match ptype:
			PlatformType.TURF:
				# 1. Lush Jungle Turf Ledge with hanging vines
				if platform_turf_texture != null:
					var prect := Rect2(b.position.x, b.position.y - 6.0, b.size.x, 46.0)
					draw_texture_rect(platform_turf_texture, prect, false, p_tint)
				elif ground_tile_texture != null:
					var gw: float = float(ground_tile_texture.get_width())
					var gh: float = float(ground_tile_texture.get_height())
					var p_tile_w: float = 128.0 if gh > 100.0 else gw
					var num_p_tiles: int = int(ceil(b.size.x / p_tile_w))
					for k in range(num_p_tiles):
						var ptx: float = b.position.x + float(k) * p_tile_w
						var ptw: float = minf(p_tile_w, b.end.x - ptx)
						var prect := Rect2(ptx, b.position.y - 10.0, ptw, b.size.y + 10.0)
						var psrc_h: float = minf(gh, (b.size.y + 10.0) * (gh / 216.0) if gh > 100.0 else (b.size.y + 10.0))
						var psrc := Rect2(0.0, 0.0, gw * (ptw / p_tile_w), psrc_h)
						draw_texture_rect_region(ground_tile_texture, prect, psrc, Color.WHITE)
				else:
					draw_rect(b, col_dirt)
					draw_rect(Rect2(b.position.x, b.position.y - 3.0, b.size.x, 7.0), col_grass)
					for v in range(int(b.size.x / 36.0)):
						var vx := b.position.x + float(v) * 36.0 + 12.0
						var v_len: float = 12.0 + sin(anim_timer * 2.0 + vx * 0.05) * 3.0
						draw_line(Vector2(vx, b.end.y), Vector2(vx + sin(anim_timer * 1.5 + float(v)) * 3.0, b.end.y + v_len), Color(0.18, 0.45, 0.2), 1.8)
			
			PlatformType.GIRDER:
				# 2. Industrial Steel Girder with Caution Hazard Warning Edge
				if platform_girder_texture != null:
					var prect := Rect2(b.position.x, b.position.y, b.size.x, 36.0)
					draw_texture_rect(platform_girder_texture, prect, false, p_tint)
				else:
					draw_rect(b, col_girder)
					draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 4.0), Color(0.92, 0.80, 0.15))
					for s in range(int(b.size.x / 16.0)):
						var sx := b.position.x + float(s) * 16.0
						draw_line(Vector2(sx, b.position.y), Vector2(sx + 8.0, b.position.y + 4.0), Color(0.15, 0.15, 0.15), 2.0)
					for k in range(int(b.size.x / 24.0)):
						var kx: float = b.position.x + float(k) * 24.0
						draw_line(Vector2(kx, b.position.y + 4.0), Vector2(kx + 24.0, b.position.y + 16.0), col_rivet, 2.0)
						draw_line(Vector2(kx + 24.0, b.position.y + 4.0), Vector2(kx, b.position.y + 16.0), col_rivet, 2.0)
			
			PlatformType.ROPE_BRIDGE:
				# 3. Jungle Chasm Rope Suspension Bridge
				if platform_bridge_texture != null:
					var prect := Rect2(b.position.x, b.position.y - 28.0, b.size.x, 52.0)
					draw_texture_rect(platform_bridge_texture, prect, false, p_tint)
				else:
					var plank_w := 14.0
					for pl in range(int(b.size.x / plank_w)):
						var px := b.position.x + float(pl) * plank_w
						var col_plank := Color(0.55, 0.38, 0.22) if (pl % 2 == 0) else Color(0.46, 0.30, 0.16)
						draw_rect(Rect2(px + 1.0, b.position.y + 3.0, plank_w - 2.0, 11.0), col_plank)
					draw_line(Vector2(b.position.x, b.position.y - 6.0), Vector2(b.end.x, b.position.y - 6.0), Color(0.75, 0.60, 0.35), 2.5)
					draw_line(Vector2(b.position.x + 2.0, b.position.y - 8.0), Vector2(b.position.x + 2.0, b.position.y + 14.0), Color(0.38, 0.25, 0.14), 3.0)
					draw_line(Vector2(b.end.x - 2.0, b.position.y - 8.0), Vector2(b.end.x - 2.0, b.position.y + 14.0), Color(0.38, 0.25, 0.14), 3.0)
					draw_line(Vector2(b.position.x + b.size.x * 0.5, b.position.y - 8.0), Vector2(b.position.x + b.size.x * 0.5, b.position.y + 14.0), Color(0.38, 0.25, 0.14), 2.5)
			
			PlatformType.HIGH_PERCH:
				# 4. High-Tech Vantage Lookout / Sniper Tower with aviation warning beacon
				if platform_tech_texture != null:
					var prect := Rect2(b.position.x, b.position.y - 16.0, b.size.x, 56.0)
					draw_texture_rect(platform_tech_texture, prect, false, p_tint)
					# Structural suspension cables going upwards
					draw_line(Vector2(b.position.x + 8.0, b.position.y), Vector2(b.position.x + 8.0, b.position.y - 140.0), Color(0.45, 0.50, 0.55, 0.7), 1.5)
					draw_line(Vector2(b.end.x - 8.0, b.position.y), Vector2(b.end.x - 8.0, b.position.y - 140.0), Color(0.45, 0.50, 0.55, 0.7), 1.5)
					# Blinking aviation LED beacon overlay
					var beacon_alpha: float = 0.5 + 0.5 * sin(anim_timer * 6.0)
					var beacon_col := Color(1.0, 0.25, 0.2, beacon_alpha) if Global.current_stage != 2 else Color(0.2, 0.9, 1.0, beacon_alpha)
					draw_circle(Vector2(b.position.x + 12.0, b.position.y - 10.0), 3.5, beacon_col)
					draw_circle(Vector2(b.end.x - 12.0, b.position.y - 10.0), 3.5, beacon_col)
				else:
					draw_rect(b, Color(0.20, 0.24, 0.30))
					draw_line(Vector2(b.position.x, b.position.y), Vector2(b.end.x, b.position.y), Color(0.55, 0.70, 0.85), 2.0)
					for m in range(int(b.size.x / 10.0)):
						var mx := b.position.x + float(m) * 10.0 + 3.0
						draw_rect(Rect2(mx, b.position.y + 4.0, 4.0, 8.0), Color(0.12, 0.14, 0.18))
					# Structural suspension cables going upwards
					draw_line(Vector2(b.position.x + 8.0, b.position.y), Vector2(b.position.x + 8.0, b.position.y - 140.0), Color(0.45, 0.50, 0.55, 0.7), 1.5)
					draw_line(Vector2(b.end.x - 8.0, b.position.y), Vector2(b.end.x - 8.0, b.position.y - 140.0), Color(0.45, 0.50, 0.55, 0.7), 1.5)
					# Blinking aviation LED beacon
					var beacon_alpha: float = 0.5 + 0.5 * sin(anim_timer * 6.0)
					var beacon_col := Color(1.0, 0.25, 0.2, beacon_alpha) if Global.current_stage != 2 else Color(0.2, 0.9, 1.0, beacon_alpha)
					draw_circle(Vector2(b.position.x + 4.0, b.position.y - 4.0), 3.0, beacon_col)
					draw_circle(Vector2(b.end.x - 4.0, b.position.y - 4.0), 3.0, beacon_col)
