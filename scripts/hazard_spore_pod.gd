extends Area2D

# =============================================================================
# CONTRA RE - ALIEN SPORE EGG SAC POD (STAGE 3 & 8 HAZARD)
# =============================================================================
# Pulsating bio-organic egg pods that rupture into leaping alien crawlers
# when approached by the commando or hit by weapon gunfire.

@export var crawler_scene: PackedScene = preload("res://scenes/enemy_crawler.tscn")

var health: float = 2.0
var anim_timer: float = 0.0
var flash_timer: float = 0.0
var is_ruptured: bool = false
var pulse_offset: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	pulse_offset = randf_range(0.0, TAU)
	
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	col_shape.shape = circle
	col_shape.position = Vector2(0.0, -14.0)
	add_child(col_shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_ruptured:
		return
	anim_timer += delta
	if flash_timer > 0.0:
		flash_timer -= delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < 110.0:
			rupture()
			return
	
	queue_redraw()

func take_damage(dmg: float = 1.0) -> void:
	if is_ruptured:
		return
	health -= dmg
	flash_timer = 0.08
	Global.play_sfx("hit")
	if health <= 0.0:
		rupture()

func rupture() -> void:
	if is_ruptured:
		return
	is_ruptured = true
	Global.play_sfx("player_death")
	
	# Massive alien blood splatter and organic rupture blast
	VFX.spawn_blood_splatter(global_position + Vector2(0.0, -14.0), Vector2.UP, true)
	VFX.spawn_explosion(global_position + Vector2(0.0, -14.0), 1.15, false, true)
	
	# Spawn 2 leaping alien crawlers
	if crawler_scene != null:
		var dirs := [-1, 1]
		for d in dirs:
			var c = crawler_scene.instantiate()
			c.global_position = global_position + Vector2(float(d) * 16.0, -18.0)
			c.facing_dir = d
			c.velocity = Vector2(float(d) * 180.0, -280.0)
			get_parent().add_child(c)
	
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + 0.12 * sin(anim_timer * 5.0 + pulse_offset)
	var egg_w: float = 15.0 * pulse
	var egg_h: float = 22.0 * pulse
	
	var col_outer := Color(0.75, 0.18, 0.32) if flash_timer <= 0.0 else Color.WHITE
	var col_inner := Color(0.95, 0.35, 0.50) if flash_timer <= 0.0 else Color.WHITE
	var col_vein := Color(0.45, 0.08, 0.18)
	var col_core := Color(0.55, 1.0, 0.30, 0.85) # Glowing toxic embryo core
	
	# Root chitin tendrils anchoring egg to surface
	for r in range(4):
		var rx := float(r - 2) * 8.0
		var r_end := Vector2(rx * 1.5, 0.0)
		draw_line(Vector2(0.0, -6.0), r_end, col_vein, 2.5)
	
	# Pulsating bulbous egg sac base
	draw_circle(Vector2(0.0, -egg_h * 0.55), egg_w, col_outer)
	draw_circle(Vector2(0.0, -egg_h * 0.55), egg_w * 0.75, col_inner)
	
	# Pulsing green toxic embryo inside
	var core_pulse := 0.6 + 0.4 * sin(anim_timer * 8.0 + pulse_offset)
	draw_circle(Vector2(0.0, -egg_h * 0.55), egg_w * 0.45 * core_pulse, col_core)
	
	# Organic surface veins
	draw_arc(Vector2(0.0, -egg_h * 0.55), egg_w * 0.85, 0.2, 2.8, 12, col_vein, 1.5)
	draw_arc(Vector2(0.0, -egg_h * 0.55), egg_w * 0.65, -2.5, -0.4, 12, col_vein, 1.5)
