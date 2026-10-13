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
	if ResourceLoader.exists("res://assets/vfx/shockwave_ring.png"):
		tex_shockwave = load("res://assets/vfx/shockwave_ring.png")

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
# 5. FIERY ARCADE EXPLOSION
# -----------------------------------------------------------------------------
func spawn_explosion(pos: Vector2, scale_mult: float = 1.0, is_electric: bool = false, is_alien: bool = false) -> void:
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
