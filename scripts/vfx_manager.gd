extends Node

# =============================================================================
# CONTRA RE - DYNAMIC VFX & PARTICLE SYSTEM MANAGER
# =============================================================================
# Provides high-impact, retro 16-bit arcade visual effects:
# - Rich bullet hit sparks & wall ricochets
# - Organic alien bio-splatter & human blood droplets
# - Weapon muzzle flashes & dissipated gun smoke
# - Footstep & landing ground dust puffs
# - Heavy tiered fiery explosions with shockwave rings & debris
# - Powerup collection glittering starbursts
# - Water splash plumes & foam ripples
# - High-voltage electric arc bursts
# =============================================================================

var tex_spark: Texture2D = null
var tex_smoke: Texture2D = null
var tex_fire: Texture2D = null
var tex_debris: Texture2D = null
var tex_blood: Texture2D = null
var tex_sparkle: Texture2D = null
var tex_shockwave: Texture2D = null
var tex_explosion_frames: Array[Texture2D] = []
var tex_skull_smoke_frames: Array[Texture2D] = []
var tex_skull_smoke_sheet: Texture2D = null
var explosion_resources: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_textures()

func _load_textures() -> void:
	if ResourceLoader.exists("res://assets/vfx/spark_flare.png"):
		tex_spark = load("res://assets/vfx/spark_flare.png")
	if ResourceLoader.exists("res://assets/vfx/smoke_puff.png"):
		tex_smoke = load("res://assets/vfx/smoke_puff.png")
	if ResourceLoader.exists("res://assets/vfx/fire_particle.png"):
		tex_fire = load("res://assets/vfx/fire_particle.png")
	if ResourceLoader.exists("res://assets/vfx/debris_chunk.png"):
		tex_debris = load("res://assets/vfx/debris_chunk.png")
	if ResourceLoader.exists("res://assets/vfx/blood_splat.png"):
		tex_blood = load("res://assets/vfx/blood_splat.png")
	if ResourceLoader.exists("res://assets/vfx/star_sparkle.png"):
		tex_sparkle = load("res://assets/vfx/star_sparkle.png")
	# Main Arcade Explosion Spritesheet (64x64 frames, 11 frames from explosion.png)
	var tex_explosion_sheet: Texture2D = null
	if ResourceLoader.exists("res://assets/vfx/effect/explosion.png"):
		tex_explosion_sheet = load("res://assets/vfx/effect/explosion.png")
	elif ResourceLoader.exists("res://assets/vfx/explosion.png"):
		tex_explosion_sheet = load("res://assets/vfx/explosion.png")
	
	tex_explosion_frames.clear()
	for i in range(11):
		var ep := "res://assets/vfx/effect/explosion/frame_%d.png" % i
		if ResourceLoader.exists(ep):
			tex_explosion_frames.append(load(ep))
		elif tex_explosion_sheet != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex_explosion_sheet
			atlas.region = Rect2(float(i * 64), 0.0, 64.0, 64.0)
			tex_explosion_frames.append(atlas)
	
	# Skull Smoke Spritesheet (64x64 frames)
	if ResourceLoader.exists("res://assets/vfx/effect/skullsmoke.png"):
		tex_skull_smoke_sheet = load("res://assets/vfx/effect/skullsmoke.png")
	elif ResourceLoader.exists("res://assets/vfx/skullsmoke.png"):
		tex_skull_smoke_sheet = load("res://assets/vfx/skullsmoke.png")
	
	tex_skull_smoke_frames.clear()
	for i in range(12):
		var fp := "res://assets/vfx/effect/skullsmoke/frame_%d.png" % i
		if ResourceLoader.exists(fp):
			tex_skull_smoke_frames.append(load(fp))
		elif tex_skull_smoke_sheet != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex_skull_smoke_sheet
			atlas.region = Rect2(float(i * 64), 0.0, 64.0, 64.0)
			tex_skull_smoke_frames.append(atlas)
	
	_load_explosion_resources()

func _load_explosion_resources() -> void:
	explosion_resources.clear()
	var res_map := {
		"skull": "res://resources/vfx/explosion_skull_smoke.tres",
		"skullsmoke": "res://resources/vfx/explosion_skull_smoke.tres",
		"enemy_death": "res://resources/vfx/explosion_skull_smoke.tres",
		"fiery": "res://resources/vfx/explosion_arcade_fiery.tres",
		"arcade": "res://resources/vfx/explosion_arcade_fiery.tres",
		"electric": "res://resources/vfx/explosion_electric_tesla.tres",
		"tesla": "res://resources/vfx/explosion_electric_tesla.tres",
		"alien": "res://resources/vfx/explosion_alien_bio.tres",
		"bio": "res://resources/vfx/explosion_alien_bio.tres",
		"nuclear": "res://resources/vfx/explosion_nuclear_mega.tres",
		"mega": "res://resources/vfx/explosion_nuclear_mega.tres",
		"cryo": "res://resources/vfx/explosion_cryo_frost.tres",
		"frost": "res://resources/vfx/explosion_cryo_frost.tres",
		"magma": "res://resources/vfx/explosion_magma_volcanic.tres",
		"volcanic": "res://resources/vfx/explosion_magma_volcanic.tres",
		"mini": "res://resources/vfx/explosion_mini_impact.tres",
		"bullet": "res://resources/vfx/explosion_mini_impact.tres",
		"default": "res://resources/vfx/explosion_default.tres"
	}
	for key in res_map:
		var p: String = res_map[key]
		if ResourceLoader.exists(p):
			var res = load(p)
			if res is ExplosionVFXData:
				explosion_resources[key] = res

func _get_vfx_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	var cur := tree.current_scene
	if cur != null:
		var stage = cur.get_node_or_null("Stage1")
		if stage != null:
			return stage
		for child in cur.get_children():
			if child.name.begins_with("Stage"):
				return child
		return cur
	var root := tree.root
	if root != null and root.get_child_count() > 0:
		for i in range(root.get_child_count() - 1, -1, -1):
			var ch = root.get_child(i)
			if ch != self and ch is Node2D:
				return ch
		return root.get_child(root.get_child_count() - 1)
	return self

# -----------------------------------------------------------------------------
# 1. BULLET HIT SPARKS / WALL RICOCHET
# -----------------------------------------------------------------------------
func spawn_hit_sparks(pos: Vector2, normal: Vector2 = Vector2.UP, spark_color: Color = Color(1.0, 0.88, 0.35)) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := HitSparksEffect.new()
	fx.global_position = pos
	fx.spark_normal = normal
	fx.spark_color = spark_color
	fx.tex_spark = tex_spark
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 2. FLESH / ALIEN GOO SPLATTER
# -----------------------------------------------------------------------------
func spawn_blood_splatter(pos: Vector2, dir: Vector2 = Vector2.RIGHT, is_alien: bool = true) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := BloodSplatterEffect.new()
	fx.global_position = pos
	fx.splat_dir = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	fx.is_alien = is_alien
	fx.tex_blood = tex_blood
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 3. GROUND DUST PUFF
# -----------------------------------------------------------------------------
func spawn_dust_puff(pos: Vector2, count: int = 5, dust_color: Color = Color(0.85, 0.85, 0.85, 0.6)) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := DustPuffEffect.new()
	fx.global_position = pos
	fx.particle_count = count
	fx.dust_color = dust_color
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 4. WEAPON MUZZLE FLASH
# -----------------------------------------------------------------------------
func spawn_muzzle_flash(pos: Vector2, dir: Vector2 = Vector2.RIGHT, weapon_type: int = 0) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := MuzzleFlashEffect.new()
	fx.global_position = pos
	fx.aim_dir = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	fx.weapon_type = weapon_type
	fx.tex_spark = tex_spark
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 5. FIERY ARCADE EXPLOSION (ANIMATED & RESOURCE-DRIVEN)
# -----------------------------------------------------------------------------
func get_explosion_resource(name_or_key: String) -> ExplosionVFXData:
	var lk := name_or_key.to_lower()
	if explosion_resources.has(lk):
		return explosion_resources[lk]
	for k in explosion_resources:
		var res: ExplosionVFXData = explosion_resources[k]
		if res != null and (res.explosion_name.to_lower().contains(lk) or res.category.to_lower() == lk):
			return res
	return explosion_resources.get("default", null)

func spawn_explosion_from_resource(pos: Vector2, vfx_data: ExplosionVFXData, scale_override: float = -1.0) -> void:
	if vfx_data == null:
		spawn_explosion(pos, 1.0 if scale_override <= 0.0 else scale_override)
		return
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := AnimatedExplosionEffect.new()
	fx.global_position = pos
	fx.apply_resource(vfx_data, scale_override)
	fx.tex_debris = tex_debris
	fx.tex_spark = tex_spark
	fx.tex_shockwave = tex_shockwave
	fx.tex_fire = tex_fire
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

func spawn_explosion_by_name(pos: Vector2, name_or_key: String, scale_override: float = -1.0) -> void:
	var res := get_explosion_resource(name_or_key)
	if res != null:
		spawn_explosion_from_resource(pos, res, scale_override)
	else:
		spawn_explosion(pos, 1.0 if scale_override <= 0.0 else scale_override)

# -----------------------------------------------------------------------------
# 5B. ENEMY DEATH SKULL SMOKE BURST / EXPLOSION EFFECT (64x64 SPRITESHEET)
# -----------------------------------------------------------------------------
func spawn_enemy_death_explosion(pos: Vector2, scale_mult: float = 1.0) -> void:
	if explosion_resources.has("skullsmoke"):
		spawn_explosion_from_resource(pos, explosion_resources["skullsmoke"], scale_mult)
		return
	
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := AnimatedExplosionEffect.new()
	fx.global_position = pos
	fx.scale_mult = scale_mult
	fx.duration = 0.52
	fx.custom_color = Color.WHITE
	fx.frame_size = Vector2(64.0, 64.0)
	fx.shockwave_color = Color(0.75, 0.9, 1.0, 0.7)
	fx.shockwave_radius = 48.0
	fx.shockwave_ring_count = 1
	fx.shockwave_ring_width = 2.5
	fx.debris_count = 5
	fx.debris_color = Color(0.85, 0.92, 0.95, 1)
	fx.sparks_count = 8
	fx.sparks_color = Color(0.8, 0.95, 1.0, 1)
	fx.smoke_count = 4
	fx.smoke_color = Color(0.45, 0.55, 0.62, 0.55)
	fx.explosion_frames = tex_skull_smoke_frames
	fx.tex_debris = tex_debris
	fx.tex_spark = tex_spark
	fx.tex_shockwave = tex_shockwave
	fx.tex_fire = tex_fire
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

func spawn_explosion(pos: Vector2, scale_mult: float = 1.0, is_electric: bool = false, is_alien: bool = false) -> void:
	var target_key := "fiery"
	if is_electric:
		target_key = "electric"
	elif is_alien:
		target_key = "alien"
	
	if explosion_resources.has(target_key):
		spawn_explosion_from_resource(pos, explosion_resources[target_key], scale_mult)
	elif explosion_resources.has("default"):
		spawn_explosion_from_resource(pos, explosion_resources["default"], scale_mult)
	elif tex_explosion_frames.size() > 0:
		spawn_animated_explosion(pos, scale_mult, is_electric, is_alien)
	else:
		var parent := _get_vfx_parent()
		if parent == null:
			return
		var fx := ExplosionEffect.new()
		fx.global_position = pos
		fx.scale_mult = scale_mult
		fx.is_electric = is_electric
		fx.is_alien = is_alien
		fx.tex_fire = tex_fire
		fx.tex_smoke = tex_smoke
		fx.tex_spark = tex_spark
		fx.tex_debris = tex_debris
		fx.tex_shockwave = tex_shockwave
		parent.add_child(fx)

func spawn_animated_explosion(pos: Vector2, scale_mult: float = 1.0, is_electric: bool = false, is_alien: bool = false, custom_color: Color = Color.WHITE) -> void:
	var target_key := "fiery"
	if is_electric:
		target_key = "electric"
	elif is_alien:
		target_key = "alien"
	
	if explosion_resources.has(target_key) and custom_color == Color.WHITE:
		spawn_explosion_from_resource(pos, explosion_resources[target_key], scale_mult)
		return
	
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := AnimatedExplosionEffect.new()
	fx.global_position = pos
	fx.scale_mult = scale_mult
	fx.is_electric = is_electric
	fx.is_alien = is_alien
	fx.custom_color = custom_color
	fx.frame_size = Vector2(64.0, 64.0)
	fx.explosion_frames = tex_explosion_frames
	fx.tex_debris = tex_debris
	fx.tex_spark = tex_spark
	fx.tex_shockwave = tex_shockwave
	fx.tex_fire = tex_fire
	fx.tex_smoke = tex_smoke
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 6. POWERUP STARBURST SPARKLE
# -----------------------------------------------------------------------------
func spawn_powerup_sparkle(pos: Vector2) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := PowerupSparkleEffect.new()
	fx.global_position = pos
	fx.tex_sparkle = tex_sparkle
	fx.tex_shockwave = tex_shockwave
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 7. WATER SPLASH PLUME
# -----------------------------------------------------------------------------
func spawn_water_splash(pos: Vector2) -> void:
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := WaterSplashEffect.new()
	fx.global_position = pos
	fx.tex_smoke = tex_smoke
	fx.tex_spark = tex_spark
	parent.add_child(fx)

# -----------------------------------------------------------------------------
# 8. LASER IMPACT / HEAT GLOW
# -----------------------------------------------------------------------------
func spawn_laser_hit(pos: Vector2, normal: Vector2 = Vector2.UP) -> void:
	spawn_hit_sparks(pos, normal, Color(0.2, 0.9, 1.0))
	var parent := _get_vfx_parent()
	if parent == null:
		return
	var fx := LaserHitEffect.new()
	fx.global_position = pos
	fx.hit_normal = normal
	fx.tex_spark = tex_spark
	parent.add_child(fx)


# =============================================================================
# EFFECT CLASS IMPLEMENTATIONS
# =============================================================================

# --- HIT SPARKS EFFECT ---
class HitSparksEffect extends Node2D:
	var spark_normal: Vector2 = Vector2.UP
	var spark_color: Color = Color(1.0, 0.88, 0.35)
	var tex_spark: Texture2D = null
	var tex_smoke: Texture2D = null
	var particles: Array[Dictionary] = []
	var elapsed: float = 0.0
	var duration: float = 0.35
	var flash_size: float = 12.0
	
	func _ready() -> void:
		var count := randi_range(6, 11)
		for i in range(count):
			var spread_angle := spark_normal.angle() + randf_range(-1.2, 1.2)
			var spd := randf_range(70.0, 240.0)
			particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(spread_angle), sin(spread_angle)) * spd,
				"size": randf_range(0.6, 1.3),
				"rot": randf_range(0.0, TAU),
				"rot_speed": randf_range(-15.0, 15.0)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for p in particles:
			p["pos"] += p["vel"] * delta
			p["vel"].y += 420.0 * delta # Gravity
			p["vel"].x *= 0.94
			p["rot"] += p["rot_speed"] * delta
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf(1.0 - t, 0.0, 1.0)
		
		# Initial high-intensity flash on frame 0-2
		if t < 0.2:
			var f_alpha: float = (1.0 - t / 0.2) * 0.9
			draw_circle(Vector2.ZERO, flash_size * (1.0 - t * 2.0), Color(1.0, 1.0, 1.0, f_alpha))
		
		for p in particles:
			var p_size: float = p["size"] * (1.0 - t * 0.7)
			var col := spark_color
			col.a = alpha
			if tex_spark != null:
				var s_dim := Vector2(16.0, 16.0) * p_size
				draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
				draw_texture_rect(tex_spark, Rect2(-s_dim * 0.5, s_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(p["pos"], 3.0 * p_size, col)


# --- BLOOD / SLIME SPLATTER EFFECT ---
class BloodSplatterEffect extends Node2D:
	var splat_dir: Vector2 = Vector2.RIGHT
	var is_alien: bool = true
	var tex_blood: Texture2D = null
	var particles: Array[Dictionary] = []
	var elapsed: float = 0.0
	var duration: float = 0.4
	
	func _ready() -> void:
		var count := randi_range(7, 13)
		var base_angle := splat_dir.angle()
		for i in range(count):
			var a := base_angle + randf_range(-0.9, 0.9)
			var spd := randf_range(60.0, 200.0)
			particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"size": randf_range(0.7, 1.4),
				"col_var": randf_range(0.85, 1.15)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for p in particles:
			p["pos"] += p["vel"] * delta
			p["vel"].y += 500.0 * delta # Gravity
			p["vel"].x *= 0.95
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf(1.0 - t * 0.9, 0.0, 1.0)
		
		for p in particles:
			var p_size: float = p["size"] * (1.0 - t * 0.4)
			var col: Color
			if is_alien:
				col = Color(0.25 * p["col_var"], 0.95 * p["col_var"], 0.25, alpha)
			else:
				col = Color(0.85 * p["col_var"], 0.15, 0.15, alpha)
			
			if tex_blood != null:
				var s_dim := Vector2(8.0, 8.0) * p_size
				draw_texture_rect(tex_blood, Rect2(p["pos"] - s_dim * 0.5, s_dim), false, col)
			else:
				draw_circle(p["pos"], 2.5 * p_size, col)


# --- DUST PUFF EFFECT ---
class DustPuffEffect extends Node2D:
	var particle_count: int = 5
	var dust_color: Color = Color(0.85, 0.85, 0.85, 0.6)
	var tex_smoke: Texture2D = null
	var particles: Array[Dictionary] = []
	var elapsed: float = 0.0
	var duration: float = 0.32
	
	func _ready() -> void:
		for i in range(particle_count):
			var spd_x := randf_range(-55.0, 55.0)
			var spd_y := randf_range(-15.0, -45.0)
			particles.append({
				"pos": Vector2(randf_range(-6.0, 6.0), 0.0),
				"vel": Vector2(spd_x, spd_y),
				"scale": randf_range(0.6, 1.1),
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-3.0, 3.0)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for p in particles:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.92
			p["scale"] += 0.8 * delta
			p["rot"] += p["rot_spd"] * delta
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf((1.0 - t) * dust_color.a, 0.0, 1.0)
		var col := Color(dust_color.r, dust_color.g, dust_color.b, alpha)
		
		for p in particles:
			var s_dim: Vector2 = Vector2(16.0, 16.0) * float(p["scale"])
			if tex_smoke != null:
				draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
				draw_texture_rect(tex_smoke, Rect2(-s_dim * 0.5, s_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(p["pos"], s_dim.x * 0.35, col)


# --- WEAPON MUZZLE FLASH EFFECT ---
class MuzzleFlashEffect extends Node2D:
	var aim_dir: Vector2 = Vector2.RIGHT
	var weapon_type: int = 0
	var tex_spark: Texture2D = null
	var tex_smoke: Texture2D = null
	var elapsed: float = 0.0
	var duration: float = 0.12
	var smoke_particles: Array[Dictionary] = []
	
	func _ready() -> void:
		# Small forward gun smoke puffs
		for i in range(3):
			var a := aim_dir.angle() + randf_range(-0.4, 0.4)
			smoke_particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * randf_range(40.0, 110.0),
				"scale": randf_range(0.5, 0.9),
				"rot": randf_range(0.0, TAU)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		for p in smoke_particles:
			p["pos"] += p["vel"] * delta
			p["scale"] += 1.2 * delta
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var flash_alpha: float = clampf(1.0 - t * 3.0, 0.0, 1.0)
		
		# 1. Muzzle Flash Star Flare
		if flash_alpha > 0.05:
			var f_col := Color(1.0, 0.95, 0.4, flash_alpha)
			if weapon_type == 3: # Laser
				f_col = Color(0.2, 0.9, 1.0, flash_alpha)
			elif weapon_type == 1: # Spread
				f_col = Color(1.0, 0.45, 0.2, flash_alpha)
			elif weapon_type == 4: # Fire (Twisting)
				f_col = Color(1.0, 0.32, 0.05, flash_alpha)
			
			var f_size := Vector2(24.0, 24.0) * (1.0 + t)
			if tex_spark != null:
				draw_set_transform(Vector2.ZERO, aim_dir.angle(), Vector2.ONE)
				draw_texture_rect(tex_spark, Rect2(-f_size * 0.5, f_size), false, f_col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(Vector2.ZERO, 10.0 * flash_alpha, f_col)
		
		# 2. Lingering Gun Smoke
		var s_alpha: float = clampf(0.5 * (1.0 - t), 0.0, 0.5)
		for p in smoke_particles:
			var s_dim: Vector2 = Vector2(16.0, 16.0) * float(p["scale"])
			if tex_smoke != null:
				draw_texture_rect(tex_smoke, Rect2(p["pos"] - s_dim * 0.5, s_dim), false, Color(0.9, 0.9, 0.95, s_alpha))


# --- FIERY ARCADE EXPLOSION EFFECT ---
class ExplosionEffect extends Node2D:
	var scale_mult: float = 1.0
	var is_electric: bool = false
	var is_alien: bool = false
	var tex_fire: Texture2D = null
	var tex_smoke: Texture2D = null
	var tex_spark: Texture2D = null
	var tex_debris: Texture2D = null
	var tex_shockwave: Texture2D = null
	
	var elapsed: float = 0.0
	var duration: float = 0.55
	
	var fireball_core: Array[Dictionary] = []
	var smoke_clouds: Array[Dictionary] = []
	var debris_chunks: Array[Dictionary] = []
	var sparks: Array[Dictionary] = []
	
	func _ready() -> void:
		Global.play_sfx("explosion")
		Global.shake_screen(4.0 * scale_mult, 0.22)
		
		# Expanding Fireball clusters
		var fire_count := int(7.0 * scale_mult)
		for i in range(fire_count):
			var a := randf_range(0.0, TAU)
			var dist := randf_range(4.0, 18.0 * scale_mult)
			fireball_core.append({
				"pos": Vector2(cos(a), sin(a)) * dist,
				"vel": Vector2(cos(a), sin(a)) * randf_range(20.0, 70.0 * scale_mult),
				"scale": randf_range(1.2, 2.4) * scale_mult,
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-5.0, 5.0)
			})
		
		# Smoke clouds billow out and rise
		var smoke_count := int(8.0 * scale_mult)
		for i in range(smoke_count):
			var a := randf_range(0.0, TAU)
			smoke_clouds.append({
				"pos": Vector2(cos(a), sin(a)) * randf_range(8.0, 24.0 * scale_mult),
				"vel": Vector2(cos(a), sin(a)) * randf_range(30.0, 90.0 * scale_mult) + Vector2(0, -35.0),
				"scale": randf_range(1.0, 2.2) * scale_mult,
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-3.0, 3.0),
				"shade": randf_range(0.18, 0.45)
			})
		
		# Flying burning shrapnel / debris
		var debris_count := int(6.0 * scale_mult)
		for i in range(debris_count):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(80.0, 220.0 * scale_mult)
			debris_chunks.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-14.0, 14.0),
				"scale": randf_range(0.8, 1.4)
			})
		
		# Glowing spark embers
		var spark_count := int(12.0 * scale_mult)
		for i in range(spark_count):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(70.0, 260.0 * scale_mult)
			sparks.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"scale": randf_range(0.6, 1.2)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for f in fireball_core:
			f["pos"] += f["vel"] * delta
			f["vel"] *= 0.92
			f["scale"] *= 1.02
			f["rot"] += f["rot_spd"] * delta
		
		for s in smoke_clouds:
			s["pos"] += s["vel"] * delta
			s["vel"].y -= 25.0 * delta # Buoyancy rising
			s["scale"] += 1.4 * delta
			s["rot"] += s["rot_spd"] * delta
		
		for d in debris_chunks:
			d["pos"] += d["vel"] * delta
			d["vel"].y += 420.0 * delta # Gravity
			d["vel"].x *= 0.95
			d["rot"] += d["rot_spd"] * delta
		
		for sp in sparks:
			sp["pos"] += sp["vel"] * delta
			sp["vel"] *= 0.93
		
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		
		# 1. Expanding Shockwave Ring
		if t < 0.45:
			var sw_t: float = t / 0.45
			var sw_scale: float = (0.2 + 2.8 * sw_t) * scale_mult
			var sw_alpha: float = clampf(1.0 - sw_t, 0.0, 1.0)
			var sw_dim := Vector2(32.0, 32.0) * sw_scale
			var sw_col := Color(1.0, 0.85, 0.4, sw_alpha * 0.85)
			if is_electric:
				sw_col = Color(0.2, 0.85, 1.0, sw_alpha * 0.85)
			elif is_alien:
				sw_col = Color(0.4, 1.0, 0.3, sw_alpha * 0.85)
			
			if tex_shockwave != null:
				draw_texture_rect(tex_shockwave, Rect2(-sw_dim * 0.5, sw_dim), false, sw_col)
			else:
				draw_arc(Vector2.ZERO, sw_dim.x * 0.5, 0.0, TAU, 28, sw_col, 3.0)
		
		# 2. Billowing Smoke Plumes
		var sm_alpha: float = clampf((1.0 - t) * 0.85, 0.0, 0.85)
		for s in smoke_clouds:
			var s_dim: Vector2 = Vector2(16.0, 16.0) * float(s["scale"])
			var col := Color(s["shade"], s["shade"], s["shade"] + 0.02, sm_alpha)
			if tex_smoke != null:
				draw_set_transform(s["pos"], s["rot"], Vector2.ONE)
				draw_texture_rect(tex_smoke, Rect2(-s_dim * 0.5, s_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(s["pos"], s_dim.x * 0.4, col)
		
		# 3. Blazing Fireball Core (peaks in first half of explosion)
		if t < 0.65:
			var f_alpha: float = clampf(1.0 - t / 0.65, 0.0, 1.0)
			for f in fireball_core:
				var f_dim: Vector2 = Vector2(14.0, 14.0) * float(f["scale"]) * (1.0 - t * 0.3)
				var f_col := Color(1.0, 0.95, 0.4, f_alpha)
				if is_electric:
					f_col = Color(0.3, 0.9, 1.0, f_alpha)
				elif is_alien:
					f_col = Color(0.5, 1.0, 0.3, f_alpha)
				
				if tex_fire != null:
					draw_set_transform(f["pos"], f["rot"], Vector2.ONE)
					draw_texture_rect(tex_fire, Rect2(-f_dim * 0.5, f_dim), false, f_col)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_circle(f["pos"], f_dim.x * 0.45, f_col)
		
		# 4. Outward Flying Hot Shrapnel / Debris
		var deb_alpha: float = clampf(1.0 - t * 0.8, 0.0, 1.0)
		for d in debris_chunks:
			var d_dim: Vector2 = Vector2(8.0, 8.0) * float(d["scale"])
			if tex_debris != null:
				draw_set_transform(d["pos"], d["rot"], Vector2.ONE)
				draw_texture_rect(tex_debris, Rect2(-d_dim * 0.5, d_dim), false, Color(1.0, 1.0, 1.0, deb_alpha))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_rect(Rect2(d["pos"] - d_dim * 0.5, d_dim), Color(0.6, 0.6, 0.65, deb_alpha))
		
		# 5. Flying Spark Embers
		var sp_alpha: float = clampf(1.0 - t, 0.0, 1.0)
		for sp in sparks:
			var sp_dim: Vector2 = Vector2(16.0, 16.0) * float(sp["scale"]) * (1.0 - t * 0.5)
			var sp_col := Color(1.0, 0.85, 0.25, sp_alpha)
			if is_electric:
				sp_col = Color(0.4, 0.9, 1.0, sp_alpha)
			elif is_alien:
				sp_col = Color(0.3, 1.0, 0.4, sp_alpha)
			
			if tex_spark != null:
				draw_texture_rect(tex_spark, Rect2(sp["pos"] - sp_dim * 0.5, sp_dim), false, sp_col)
			else:
				draw_circle(sp["pos"], 2.0, sp_col)


# --- NEW ANIMATED ARCADE EXPLOSION EFFECT (RESOURCE-AWARE) ---
class AnimatedExplosionEffect extends Node2D:
	var vfx_data: ExplosionVFXData = null
	var scale_mult: float = 1.0
	var is_electric: bool = false
	var is_alien: bool = false
	var custom_color: Color = Color.WHITE
	var explosion_frames: Array[Texture2D] = []
	var tex_debris: Texture2D = null
	var tex_spark: Texture2D = null
	var tex_shockwave: Texture2D = null
	var tex_fire: Texture2D = null
	var tex_smoke: Texture2D = null
	
	var elapsed: float = 0.0
	var duration: float = 0.52
	var shockwave_color: Color = Color(1.0, 0.85, 0.3, 0.85)
	var shockwave_radius: float = 58.0
	var shockwave_ring_count: int = 2
	var shockwave_ring_width: float = 3.5
	var debris_count: int = 7
	var debris_speed_min: float = 90.0
	var debris_speed_max: float = 240.0
	var debris_color: Color = Color(1.0, 1.0, 1.0)
	var debris_gravity: float = 450.0
	var sparks_count: int = 12
	var sparks_speed_min: float = 70.0
	var sparks_speed_max: float = 280.0
	var sparks_color: Color = Color(1.0, 0.85, 0.25)
	var smoke_count: int = 6
	var smoke_color: Color = Color(0.2, 0.2, 0.25, 0.75)
	var smoke_buoyancy: float = 25.0
	var screen_shake_intensity: float = 5.0
	var screen_shake_duration: float = 0.25
	var sfx_name: String = "explosion"
	var frame_size: Vector2 = Vector2(96.0, 96.0)
	
	var debris_particles: Array[Dictionary] = []
	var spark_particles: Array[Dictionary] = []
	var smoke_particles: Array[Dictionary] = []
	
	func apply_resource(res: ExplosionVFXData, scale_override: float = -1.0) -> void:
		vfx_data = res
		scale_mult = res.scale_mult if scale_override <= 0.0 else scale_override
		duration = res.duration
		is_electric = res.is_electric
		is_alien = res.is_alien
		custom_color = res.primary_color
		shockwave_color = res.shockwave_color
		shockwave_radius = res.shockwave_radius
		shockwave_ring_count = res.shockwave_ring_count
		shockwave_ring_width = res.shockwave_ring_width
		debris_count = res.debris_count
		debris_speed_min = res.debris_speed_min
		debris_speed_max = res.debris_speed_max
		debris_color = res.debris_color
		debris_gravity = res.debris_gravity
		sparks_count = res.sparks_count
		sparks_speed_min = res.sparks_speed_min
		sparks_speed_max = res.sparks_speed_max
		sparks_color = res.sparks_color
		smoke_count = res.smoke_count
		smoke_color = res.smoke_color
		smoke_buoyancy = res.smoke_buoyancy
		screen_shake_intensity = res.screen_shake_intensity
		screen_shake_duration = res.screen_shake_duration
		sfx_name = res.sfx_name
		frame_size = res.frame_size
		if res.explosion_frames.size() > 0:
			explosion_frames = res.explosion_frames
	
	func _ready() -> void:
		Global.play_sfx(sfx_name)
		Global.shake_screen(screen_shake_intensity * scale_mult, screen_shake_duration)
		
		# Outward flying metal / shrapnel debris
		var d_count := maxi(1, int(float(debris_count) * scale_mult))
		for i in range(d_count):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(debris_speed_min, debris_speed_max * scale_mult)
			debris_particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-16.0, 16.0),
				"scale": randf_range(0.8, 1.4)
			})
			
		# Sizzling sparks
		var s_count := maxi(2, int(float(sparks_count) * scale_mult))
		for i in range(s_count):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(sparks_speed_min, sparks_speed_max * scale_mult)
			spark_particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"scale": randf_range(0.6, 1.3)
			})
		
		# Rising smoke clouds
		var sm_count := maxi(1, int(float(smoke_count) * scale_mult))
		for i in range(sm_count):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(15.0, 45.0 * scale_mult)
			smoke_particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-2.0, 2.0),
				"scale": randf_range(0.7, 1.3)
			})
			
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for d in debris_particles:
			d["pos"] += d["vel"] * delta
			d["vel"].y += debris_gravity * delta
			d["vel"].x *= 0.94
			d["rot"] += d["rot_spd"] * delta
			
		for s in spark_particles:
			s["pos"] += s["vel"] * delta
			s["vel"] *= 0.92
		
		for sm in smoke_particles:
			sm["pos"] += sm["vel"] * delta
			sm["vel"].y -= smoke_buoyancy * delta
			sm["scale"] += 1.2 * delta
			sm["rot"] += sm["rot_spd"] * delta
			
		queue_redraw()
		
	func _draw() -> void:
		var t := elapsed / duration
		var num_frames := explosion_frames.size()
		
		# 1. Shockwave Flare Rings
		if t < 0.44:
			var sw_t := t / 0.44
			var sw_a := (1.0 - sw_t) * 0.9
			var sw_base_r := (10.0 + shockwave_radius * sw_t) * scale_mult
			var col := Color(shockwave_color.r, shockwave_color.g, shockwave_color.b, shockwave_color.a * sw_a)
			
			for ring_idx in range(shockwave_ring_count):
				var r_frac := 1.0 - float(ring_idx) * 0.22
				var ring_r := sw_base_r * r_frac
				var ring_w := shockwave_ring_width * r_frac * scale_mult
				var ring_col := col
				if ring_idx == 0:
					ring_col = Color(1.0, 1.0, 1.0, col.a * 0.85)
				draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 28, ring_col, ring_w)
		
		# 2. Billowing Smoke Plumes
		var sm_alpha := clampf((1.0 - t) * smoke_color.a, 0.0, 1.0)
		for sm in smoke_particles:
			var sm_dim := Vector2(20.0, 20.0) * float(sm["scale"]) * scale_mult
			var col := Color(smoke_color.r, smoke_color.g, smoke_color.b, sm_alpha)
			if tex_smoke != null:
				draw_set_transform(sm["pos"], sm["rot"], Vector2.ONE)
				draw_texture_rect(tex_smoke, Rect2(-sm_dim * 0.5, sm_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(sm["pos"], sm_dim.x * 0.4, col)
		
		# 3. High-Definition Pixel-Art Explosion Animation
		if num_frames > 0:
			var frame_idx := clampi(int(t * float(num_frames)), 0, num_frames - 1)
			var tex: Texture2D = explosion_frames[frame_idx]
			if tex != null:
				var draw_w := frame_size.x * scale_mult
				var draw_h := frame_size.y * scale_mult
				var mod_col := custom_color
				if t > 0.8:
					mod_col.a = (1.0 - t) / 0.2
				draw_texture_rect(tex, Rect2(-draw_w * 0.5, -draw_h * 0.5, draw_w, draw_h), false, mod_col)
		
		# 4. Flying Hot Debris Chunks
		var deb_a := clampf(1.0 - t * 0.85, 0.0, 1.0)
		for d in debris_particles:
			var d_dim := Vector2(8.0, 8.0) * float(d["scale"]) * scale_mult
			var col := Color(debris_color.r, debris_color.g, debris_color.b, deb_a)
			if tex_debris != null:
				draw_set_transform(d["pos"], d["rot"], Vector2.ONE)
				draw_texture_rect(tex_debris, Rect2(-d_dim * 0.5, d_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_rect(Rect2(d["pos"] - d_dim * 0.5, d_dim), col)
				
		# 5. Outward Flying Sizzling Sparks
		var sp_a := clampf(1.0 - t, 0.0, 1.0)
		for s in spark_particles:
			var sp_col := Color(sparks_color.r, sparks_color.g, sparks_color.b, sp_a)
			var sp_sz := 2.5 * float(s["scale"]) * scale_mult
			draw_circle(s["pos"], sp_sz, sp_col)


# --- POWERUP STARBURST EFFECT ---
class PowerupSparkleEffect extends Node2D:
	var tex_sparkle: Texture2D = null
	var tex_shockwave: Texture2D = null
	var stars: Array[Dictionary] = []
	var elapsed: float = 0.0
	var duration: float = 0.5
	
	func _ready() -> void:
		Global.play_sfx("powerup")
		var count := 16
		for i in range(count):
			var a := float(i) * (TAU / float(count)) + randf_range(-0.15, 0.15)
			var spd := randf_range(80.0, 190.0)
			var col := Color(1.0, 0.9, 0.2) if (i % 2 == 0) else Color(0.3, 0.9, 1.0)
			stars.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(a), sin(a)) * spd,
				"scale": randf_range(0.8, 1.6),
				"rot": randf_range(0.0, TAU),
				"rot_spd": randf_range(-8.0, 8.0),
				"color": col
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		
		for s in stars:
			s["pos"] += s["vel"] * delta
			s["vel"] *= 0.94
			s["rot"] += s["rot_spd"] * delta
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf(1.0 - t, 0.0, 1.0)
		
		# Central expanding halo ring
		if t < 0.35:
			var h_t: float = t / 0.35
			var r_size := Vector2(32.0, 32.0) * (0.3 + 2.0 * h_t)
			var r_col := Color(1.0, 0.95, 0.5, (1.0 - h_t) * 0.8)
			if tex_shockwave != null:
				draw_texture_rect(tex_shockwave, Rect2(-r_size * 0.5, r_size), false, r_col)
			else:
				draw_arc(Vector2.ZERO, r_size.x * 0.5, 0.0, TAU, 24, r_col, 2.5)
		
		for s in stars:
			var s_dim: Vector2 = Vector2(16.0, 16.0) * float(s["scale"]) * (1.0 - t * 0.6)
			var col: Color = s["color"]
			col.a = alpha
			if tex_sparkle != null:
				draw_set_transform(s["pos"], s["rot"], Vector2.ONE)
				draw_texture_rect(tex_sparkle, Rect2(-s_dim * 0.5, s_dim), false, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(s["pos"], 3.5 * s["scale"], col)


# --- WATER SPLASH EFFECT ---
class WaterSplashEffect extends Node2D:
	var tex_smoke: Texture2D = null
	var tex_spark: Texture2D = null
	var droplets: Array[Dictionary] = []
	var elapsed: float = 0.0
	var duration: float = 0.4
	
	func _ready() -> void:
		for i in range(10):
			var a := randf_range(-PI * 0.85, -PI * 0.15) # Upward cone
			var spd := randf_range(80.0, 220.0)
			droplets.append({
				"pos": Vector2(randf_range(-6.0, 6.0), 0.0),
				"vel": Vector2(cos(a), sin(a)) * spd,
				"scale": randf_range(0.6, 1.2)
			})
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		for d in droplets:
			d["pos"] += d["vel"] * delta
			d["vel"].y += 520.0 * delta # Gravity
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf(1.0 - t, 0.0, 1.0)
		var col := Color(0.65, 0.90, 1.0, alpha)
		
		# Surface ripple expansion
		var rip_w: float = 24.0 * (1.0 + t * 2.0)
		draw_line(Vector2(-rip_w * 0.5, 0.0), Vector2(rip_w * 0.5, 0.0), Color(0.8, 0.95, 1.0, alpha * 0.7), 2.0)
		
		for d in droplets:
			var d_dim: Vector2 = Vector2(8.0, 8.0) * float(d["scale"]) * (1.0 - t * 0.5)
			if tex_spark != null:
				draw_texture_rect(tex_spark, Rect2(d["pos"] - d_dim * 0.5, d_dim), false, col)
			else:
				draw_circle(d["pos"], 2.5 * d["scale"], col)


# --- LASER HIT EFFECT ---
class LaserHitEffect extends Node2D:
	var hit_normal: Vector2 = Vector2.UP
	var tex_spark: Texture2D = null
	var elapsed: float = 0.0
	var duration: float = 0.18
	
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()
	
	func _draw() -> void:
		var t: float = elapsed / duration
		var alpha: float = clampf(1.0 - t, 0.0, 1.0)
		
		# Intense plasma heat flare
		var flare_size := Vector2(28.0, 28.0) * (1.0 + t * 0.8)
		if tex_spark != null:
			draw_set_transform(Vector2.ZERO, hit_normal.angle(), Vector2.ONE)
			draw_texture_rect(tex_spark, Rect2(-flare_size * 0.5, flare_size), false, Color(0.2, 0.9, 1.0, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(Vector2.ZERO, 12.0 * alpha, Color(0.2, 0.9, 1.0, alpha))
		draw_circle(Vector2.ZERO, 5.0 * alpha, Color(1.0, 1.0, 1.0, alpha))
