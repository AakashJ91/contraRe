extends Area2D

# =============================================================================
# CONTRA RE - ALIEN SPORE EGG SAC POD (STAGE 3 & 8 HAZARD)
# =============================================================================
# Pulsating bio-organic egg pods that rupture into leaping alien crawlers
# when approached by the commando or hit by weapon gunfire.

@export var crawler_scene: PackedScene = preload("res://scenes/enemy_crawler.tscn")
@export var enemy_data: EnemyData = preload("res://resources/enemies/spore_pod_data.tres")

var health: float = 2.0
var anim_timer: float = 0.0
var flash_timer: float = 0.0
var is_ruptured: bool = false
var pulse_offset: float = 0.0

var pod_texture: Texture2D = null
var pod_frames: Array[Texture2D] = []

func _ready() -> void:
	collision_layer = 1 << 2 # Layer 3: Enemies
	collision_mask = (1 << 3) # Layer 4: PlayerBullets
	if enemy_data != null:
		health = enemy_data.max_health
	pulse_offset = randf_range(0.0, TAU)
	
	if ResourceLoader.exists("res://assets/enemies/hazards/spore_pod.png"):
		pod_texture = load("res://assets/enemies/hazards/spore_pod.png")
	
	pod_frames.clear()
	for i in range(4):
		var p := "res://assets/enemies/hazards/spore_pod_%d.png" % i
		if ResourceLoader.exists(p):
			pod_frames.append(load(p))
	
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
	var score_val := enemy_data.score_reward if enemy_data != null else 300
	Global.add_score(score_val)
	Global.play_sfx("player_death")
	
	# Massive alien blood splatter and organic rupture blast
	VFX.spawn_hit_explosion(global_position + Vector2(0.0, -14.0), 1.2)
	VFX.spawn_explosion(global_position + Vector2(0.0, -14.0), 1.15)
	
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
	var flash_col := Color(2.0, 0.4, 0.4) if flash_timer > 0.0 else Color.WHITE
	var cur_tex: Texture2D = pod_texture
	
	if pod_frames.size() > 0:
		var frame_idx := int(fmod((anim_timer * 4.0) + (pulse_offset * 0.5), float(pod_frames.size())))
		cur_tex = pod_frames[frame_idx]
	
	if cur_tex != null:
		var draw_w := 34.0
		var draw_h := 38.0
		draw_texture_rect(cur_tex, Rect2(-draw_w * 0.5, -draw_h + 4.0, draw_w, draw_h), false, flash_col)
	else:
		# Fallback procedural
		var pulse := 1.0 + 0.12 * sin(anim_timer * 5.0 + pulse_offset)
		var egg_w: float = 15.0 * pulse
		var egg_h: float = 22.0 * pulse
		var col_outer := Color(0.75, 0.18, 0.32) if flash_timer <= 0.0 else Color.WHITE
		draw_circle(Vector2(0.0, -egg_h * 0.55), egg_w, col_outer)
