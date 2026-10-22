extends Area2D

enum BulletOwner {
	PLAYER,
	ENEMY
}

@export var bullet_owner: BulletOwner = BulletOwner.PLAYER
@export var weapon_type: Global.WeaponType = Global.WeaponType.RIFLE
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 540.0
@export var damage: float = 1.0
@export var pierce_count: int = 1
@export var is_twisting: bool = false
@export var twist_phase: float = 0.0
@export var twist_amplitude: float = 16.0
@export var twist_frequency: float = 18.0
@export var is_boss_heavy: bool = false
var heavy_bullet_hp: float = 2.0

var lifetime: float = 2.5
var travel_time: float = 0.0
var base_fwd_pos: Vector2 = Vector2.ZERO
var tail_positions: Array[Vector2] = []

static var s_tex_rifle: Texture2D = null
static var s_tex_machine: Texture2D = null
static var s_tex_spread: Texture2D = null
static var s_tex_laser: Texture2D = null
static var s_tex_fire: Texture2D = null
static var s_tex_enemy: Texture2D = null
static var s_tex_boss_heavy: Texture2D = null
static var s_bullets_loaded: bool = false

static func _ensure_bullet_textures() -> void:
	if s_bullets_loaded:
		return
	s_bullets_loaded = true
	if ResourceLoader.exists("res://assets/bullets/bullet_rifle_game.png"):
		s_tex_rifle = load("res://assets/bullets/bullet_rifle_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_machine_game.png"):
		s_tex_machine = load("res://assets/bullets/bullet_machine_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_spread_game.png"):
		s_tex_spread = load("res://assets/bullets/bullet_spread_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_laser_game.png"):
		s_tex_laser = load("res://assets/bullets/bullet_laser_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_fire_game.png"):
		s_tex_fire = load("res://assets/bullets/bullet_fire_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_enemy_game.png"):
		s_tex_enemy = load("res://assets/bullets/bullet_enemy_game.png")
	if ResourceLoader.exists("res://assets/bullets/bullet_boss_heavy_game.png"):
		s_tex_boss_heavy = load("res://assets/bullets/bullet_boss_heavy_game.png")

func _ready() -> void:
	_ensure_bullet_textures()
	base_fwd_pos = global_position
	add_to_group("bullet")
	monitoring = true
	monitorable = true
	if bullet_owner == BulletOwner.PLAYER:
		add_to_group("player_bullets")
		collision_layer = 1 << 3 # Layer 4: PlayerBullets
		collision_mask = (1 << 2) # Layer 3: Enemies
	else:
		add_to_group("enemy_bullets")
		collision_layer = 1 << 4 # Layer 5: EnemyBullets
		collision_mask = (1 << 0) # Layer 1: Player
		if is_boss_heavy:
			# Boss heavy bullet: destructible by player shots (also registers on Enemies Layer 3)
			add_to_group("enemies")
			collision_layer = (1 << 4) | (1 << 2)
			lifetime = 6.0
			z_index = 6
			var col_node = get_node_or_null("CollisionShape2D")
			if col_node != null:
				var c_shape := CircleShape2D.new()
				c_shape.radius = 9.5
				col_node.shape = c_shape
			if speed >= 500.0 or speed == 260.0 or speed == 234.0:
				speed = 120.0
		else:
			if speed >= 500.0:
				speed = 234.0
			if damage == 1.0:
				damage = 1.0
	
	z_index = 5
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	travel_time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	if is_twisting:
		base_fwd_pos += direction * speed * delta
		var normal := Vector2(-direction.y, direction.x)
		var offset := normal * (sin(travel_time * twist_frequency + twist_phase) * twist_amplitude)
		global_position = base_fwd_pos + offset
		
		tail_positions.push_front(global_position)
		if tail_positions.size() > 6:
			tail_positions.pop_back()
	else:
		global_position += direction * speed * delta
		if is_boss_heavy:
			tail_positions.push_front(global_position)
			if tail_positions.size() > 5:
				tail_positions.pop_back()
	
	queue_redraw()

func _draw() -> void:
	var rot: float = direction.angle()
	
	if bullet_owner == BulletOwner.PLAYER:
		match weapon_type:
			Global.WeaponType.RIFLE:
				if s_tex_rifle != null:
					draw_texture(s_tex_rifle, -s_tex_rifle.get_size() * 0.5)
				else:
					draw_circle(Vector2.ZERO, 3.5, Color(0.9, 0.95, 1.0))
					draw_circle(Vector2.ZERO, 1.8, Color(1.0, 1.0, 1.0))
			
			Global.WeaponType.SPREAD:
				if s_tex_spread != null:
					var growth: float = clampf(travel_time * 0.35, 0.0, 0.35)
					var scale_factor: float = (0.95 + growth) * (0.94 + 0.06 * sin(travel_time * 24.0))
					draw_set_transform(Vector2.ZERO, rot, Vector2(scale_factor, scale_factor))
					draw_texture(s_tex_spread, -s_tex_spread.get_size() * 0.5)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					var growth: float = clampf(travel_time * 6.5, 0.0, 3.2)
					var r_outer: float = 4.8 + growth
					var r_mid: float = 3.4 + growth * 0.7
					var r_core: float = 2.0 + growth * 0.4
					var pulse: float = 0.88 + 0.12 * sin(travel_time * 26.0)
					draw_circle(Vector2.ZERO, r_outer * pulse, Color(1.0, 0.25, 0.05, 0.42))
					draw_circle(Vector2.ZERO, r_mid, Color(1.0, 0.52, 0.12))
					draw_circle(Vector2.ZERO, r_core * 1.3, Color(1.0, 0.85, 0.32))
					draw_circle(Vector2.ZERO, r_core * 0.75, Color(1.0, 1.0, 0.95))
			
			Global.WeaponType.MACHINE:
				if s_tex_machine != null:
					draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
					draw_texture(s_tex_machine, Vector2(-s_tex_machine.get_width() * 0.8, -s_tex_machine.get_height() * 0.5))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					var trail := -direction * 8.0
					draw_line(trail, Vector2.ZERO, Color(1.0, 0.8, 0.2), 3.0)
					draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 0.7))
			
			Global.WeaponType.LASER:
				if s_tex_laser != null:
					draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
					draw_texture(s_tex_laser, Vector2(-s_tex_laser.get_width() * 0.85, -s_tex_laser.get_height() * 0.5))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					var tail := -direction * 22.0
					draw_line(tail, Vector2.ZERO, Color(0.1, 0.8, 1.0, 0.6), 5.0)
					draw_line(tail, Vector2.ZERO, Color(0.7, 0.95, 1.0), 2.5)
			
			Global.WeaponType.FIRE:
				# Trailing fiery corkscrew tail
				for i in range(tail_positions.size()):
					var tp := to_local(tail_positions[i])
					var factor := 1.0 - float(i) / float(tail_positions.size())
					var trail_rad := 4.6 * factor
					var trail_alpha := 0.36 * factor
					draw_circle(tp, trail_rad, Color(1.0, 0.35, 0.05, trail_alpha))
					draw_circle(tp, trail_rad * 0.55, Color(1.0, 0.78, 0.18, trail_alpha * 1.4))
				
				if s_tex_fire != null:
					var pulse: float = 0.94 + 0.06 * sin(travel_time * 28.0 + twist_phase)
					draw_set_transform(Vector2.ZERO, rot, Vector2(pulse, pulse))
					draw_texture(s_tex_fire, Vector2(-s_tex_fire.get_width() * 0.75, -s_tex_fire.get_height() * 0.5))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					var pulse: float = 0.9 + 0.1 * sin(travel_time * 28.0 + twist_phase)
					var r_outer: float = 7.5 * pulse
					draw_circle(Vector2.ZERO, r_outer, Color(1.0, 0.22, 0.04, 0.40))
					var spin_angle: float = travel_time * 20.0 + twist_phase
					for k in range(3):
						var a: float = spin_angle + k * (TAU / 3.0)
						var spur_offset := Vector2(cos(a), sin(a)) * 4.2
						draw_circle(spur_offset, 2.8, Color(1.0, 0.45, 0.08, 0.75))
						draw_circle(spur_offset, 1.4, Color(1.0, 0.92, 0.35, 0.95))
					draw_circle(Vector2.ZERO, 5.2, Color(1.0, 0.52, 0.1))
					draw_circle(Vector2.ZERO, 3.4, Color(1.0, 0.86, 0.25))
					draw_circle(Vector2.ZERO, 1.8, Color(1.0, 0.98, 0.92))
	else:
		if is_boss_heavy:
			# Render trailing fading energy tail
			for i in range(tail_positions.size()):
				var tp := to_local(tail_positions[i])
				var factor := 1.0 - float(i) / float(tail_positions.size())
				draw_circle(tp, 6.5 * factor, Color(1.0, 0.22, 0.45, 0.25 * factor))
				draw_circle(tp, 3.5 * factor, Color(1.0, 0.65, 0.12, 0.38 * factor))
			
			var pulse: float = 1.0 + 0.08 * sin(travel_time * 18.0)
			var spin_rot: float = travel_time * 3.8
			if s_tex_boss_heavy != null:
				draw_set_transform(Vector2.ZERO, spin_rot, Vector2(pulse, pulse))
				draw_texture(s_tex_boss_heavy, -s_tex_boss_heavy.get_size() * 0.5)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				# Rich procedural fallback for large heavy energy orb
				draw_circle(Vector2.ZERO, 13.0 * pulse, Color(0.9, 0.1, 0.5, 0.35))
				draw_circle(Vector2.ZERO, 9.5, Color(1.0, 0.3, 0.1, 0.85))
				draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.7, 0.15))
				draw_circle(Vector2.ZERO, 3.2, Color(1.0, 0.98, 0.88))
		else:
			if s_tex_enemy != null:
				var pulse: float = 0.92 + 0.10 * sin(travel_time * 22.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
				draw_texture(s_tex_enemy, -s_tex_enemy.get_size() * 0.5)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.1, 0.1, 0.6))
				draw_circle(Vector2.ZERO, 2.8, Color(1.0, 0.3, 0.2))
				draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.9, 0.8))

func _get_vfx() -> Node:
	return get_node_or_null("/root/VFX")

func take_damage(amount: float = 1.0) -> void:
	if not is_boss_heavy:
		return
	heavy_bullet_hp -= amount
	var vfx := _get_vfx()
	if vfx != null:
		vfx.spawn_hit_sparks(global_position, -direction, Color(1.0, 0.6, 0.2))
	if heavy_bullet_hp <= 0.0:
		if vfx != null:
			vfx.spawn_hit_explosion(global_position, 1.0)
		Global.play_sfx("explosion")
		Global.add_score(150)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _handle_hit(target: Node2D) -> void:
	if target == null:
		return
	
	# Resolve parent target if hitting child hurtbox / subpart
	var actual_target: Node2D = target
	if not actual_target.has_method("take_damage") and actual_target.get_parent() != null and actual_target.get_parent().has_method("take_damage"):
		actual_target = actual_target.get_parent()
	
	if target.name == "LeftCannon" and actual_target.has_method("_on_left_part_hit"):
		actual_target._on_left_part_hit(self)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif target.name == "RightCannon" and actual_target.has_method("_on_right_part_hit"):
		actual_target._on_right_part_hit(self)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif actual_target.has_method("take_damage"):
		actual_target.take_damage(damage)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif target.is_in_group("world_solid"):
		var vfx := _get_vfx()
		if vfx != null:
			vfx.spawn_hit_sparks(global_position, -direction, Color(0.9, 0.85, 0.5))
			vfx.spawn_hit_explosion(global_position, 0.75)
		queue_free()

func _spawn_hit_vfx(hit_target: Node2D) -> void:
	var vfx := _get_vfx()
	if vfx == null:
		return
	if bullet_owner == BulletOwner.PLAYER:
		var hit_norm := -direction
		if weapon_type == Global.WeaponType.LASER:
			vfx.spawn_laser_hit(global_position, hit_norm)
		elif weapon_type == Global.WeaponType.FIRE:
			vfx.spawn_hit_sparks(global_position, hit_norm, Color(1.0, 0.45, 0.1))
			vfx.spawn_explosion(global_position, 0.75)
		else:
			var spk_col := Color(1.0, 0.9, 0.35)
			if weapon_type == Global.WeaponType.SPREAD:
				spk_col = Color(1.0, 0.5, 0.2)
			vfx.spawn_hit_sparks(global_position, hit_norm, spk_col)
		
		# Bullet Hit Explosion (48x48 animation from hitExplosion.png)
		vfx.spawn_hit_explosion(global_position)
	else:
		vfx.spawn_hit_explosion(global_position, 0.8)
		vfx.spawn_hit_sparks(global_position, -direction, Color(1.0, 0.3, 0.2))

func _decrement_pierce() -> void:
	pierce_count -= 1
	if pierce_count <= 0:
		queue_free()
